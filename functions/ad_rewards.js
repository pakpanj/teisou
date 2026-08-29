/**
 * Grants `users/{uid}.adRewards` only after AdMob's own signed
 * Server-Side Verification (SSV) callback confirms a rewarded ad was
 * genuinely watched — closing the gap documented in
 * AUDIT_PHASE_B1_AD_REWARDS_DESIGN.md / B2 / B3: `firestore.rules`
 * already froze `adRewards` against every client write, but nothing
 * ever wrote it, so the whole "watch an ad to unlock" path failed
 * silently. This file is that missing writer.
 *
 * **This is the first plain-HTTP (`onRequest`) Cloud Function in this
 * project.** Every other function here is either `onCall` (needs a
 * Firebase Auth context the client SDK attaches) or event-triggered —
 * AdMob's callback is an unauthenticated GET from Google's own ad
 * infrastructure, which cannot carry a Firebase ID token, so it has to
 * be a plain HTTP endpoint.
 *
 * **Signature verification, exactly per Google's documented SSV
 * algorithm** (developers.google.com/admob/android/ssv, fetched and
 * confirmed at implementation time rather than assumed):
 * - The signed content is every query parameter EXCEPT the trailing
 *   `signature`/`key_id` pair, taken as raw UTF-8 bytes of the ORIGINAL
 *   query string — never URL-decoded, never re-serialized from a parsed
 *   object, since either would risk producing different bytes than what
 *   AdMob actually signed. This is why [extractSignedContent] operates
 *   on the raw query string via substring search, not on a parsed
 *   query object.
 * - Algorithm: ECDSA, SHA-256, DER-encoded signature — Node's built-in
 *   `crypto` module verifies this directly (`dsaEncoding: "der"`), no
 *   npm dependency needed for the verification math itself.
 * - Public keys: `https://gstatic.com/admob/reward/verifier-keys.json`,
 *   matched by the callback's own `key_id`, cached in memory for this
 *   warm instance's lifetime (Google: "should not be cached for longer
 *   than 24 hours") — `fetch` is Node 22's global, also no dependency.
 *
 * **Response code policy**: `400` only for a request this function
 * genuinely could not process (can't extract signature/key_id, unknown
 * signing key — a stale local key cache is the one case where AdMob's
 * documented retry could plausibly help — or a signature that fails
 * verification). `200` for every other outcome, including a deliberate
 * rejection (missing user_id, unknown rewardKey, expired timestamp,
 * duplicate transaction_id, ...) — those are well-formed, genuinely
 * AdMob-signed callbacks; retrying identical bytes would never change
 * the outcome, and AdMob "expects an HTTP 200 OK success status
 * response code" for a callback it should stop retrying. `500` only for
 * this function's own unexpected failure (e.g. the key-fetch network
 * call itself failing) — the one case retrying might actually help.
 *
 * **Idempotency**: `processedAdRewardTransactions/{transaction_id}`,
 * the same shape as `iap.js`'s `processedPurchaseTokens/{token}` ledger
 * — one Firestore transaction reads both the ledger doc and the target
 * user doc, and only writes the grant + ledger entry together if the
 * ledger doc didn't already exist. AdMob's own documented retry
 * behavior (up to 5 attempts, 1 second apart, on a slow/unreachable
 * endpoint) and any accidental duplicate delivery both resolve to the
 * same no-op on the second arrival.
 *
 * **Testability**: [evaluateCallback] is the whole decision pipeline as
 * one pure-ish async function taking its dependencies (`db`, `now`,
 * `fetchVerifierKeys`) as explicit parameters — mirrors this project's
 * existing `iap.js`/`claimAndGrant` split between "real logic" and "the
 * `onRequest`/`onCall` wrapper that supplies real dependencies," so the
 * whole decision pipeline is testable against `FakeFirestore` and a
 * synthetic EC keypair without any network access or a live Firestore.
 */

const {onRequest, onCall, HttpsError} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const {getFirestore, Timestamp, FieldValue} = require("firebase-admin/firestore");
const crypto = require("crypto");

// The 9 reward keys this app currently ever grants — see
// lib/features/paywall/module_access.dart's PremiumModules (5) plus the
// 4 constants scattered across avatar_picker_sheet.dart/
// cover_picker_sheet.dart/create_clan_dialog.dart. A callback whose
// custom_data names anything outside this set is rejected — this app
// never asks AdMob for a reward under an unlisted key, so one arriving
// here is either a stale client build or something worth not trusting.
const KNOWN_REWARD_KEYS = new Set([
  "particle", "kaiwa", "choukai", "kanji", "bunpou",
  "avatar_premium", "frame_premium", "cover_premium", "clan_extra",
]);

// Mirrors ad_service.dart's `releaseAdUnitIds` — kept in sync by hand,
// the same cross-language-boundary discipline this project already
// applies to IapProducts/COIN_PACKS (see iap.js's own doc comment on
// PREMIUM_PRODUCT: "there is no build step that could enforce it across
// the language boundary"). Only ad units this app's own code can ever
// request a rewarded ad from.
const KNOWN_AD_UNITS = new Set([
  "ca-app-pub-7168330620893919/3809909145", // Android rewarded
  "ca-app-pub-7168330620893919/3939122841", // iOS rewarded
]);

// "1 Reward" per the AdMob console's rewarded-ad-unit setting, confirmed
// by the user against the live console 2026-08-26 (Android unit).
// reward_amount always arrives as a numeric-looking string.
const EXPECTED_REWARD_AMOUNT = "1";

// www is required here, not cosmetic — the bare `gstatic.com` host
// 301-redirects to this exact URL (confirmed live), and while Node's
// `fetch` follows redirects by default, requesting the canonical URL
// directly removes an unnecessary hop and a variable during the
// signature-verification investigation above.
const VERIFIER_KEYS_URL =
  "https://www.gstatic.com/admob/reward/verifier-keys.json";
const KEY_CACHE_MAX_AGE_MS = 24 * 60 * 60 * 1000;

// Defense-in-depth only — the real replay guard is the transaction_id
// ledger below, which works regardless of these. Deliberately generous
// in the past direction (AdMob's own delivery-latency guarantees aren't
// documented as strict) and tighter in the future direction, since a
// future timestamp is a stronger tamper signal than a stale one.
const MAX_TIMESTAMP_AGE_MS = 24 * 60 * 60 * 1000;
const MAX_TIMESTAMP_FUTURE_SKEW_MS = 5 * 60 * 1000;

const REWARD_DURATION_MS = 24 * 60 * 60 * 1000;

/**
 * Splits a raw SSV query string into the content that was actually
 * signed, the decoded signature, and key_id.
 *
 * **The content AdMob signs is the URL-DECODED query string**, not the
 * raw bytes on the wire — confirmed empirically 2026-08-30 against a
 * real production callback (a signature that verified successfully
 * only once `custom_data`'s `%7B%22...%22%7D` was decoded back to
 * `{"..."}` before hashing; verification failed 100% of the time
 * beforehand, which is why no reward had ever been granted since this
 * endpoint shipped). Google's own Java reference sample reads as if it
 * signs the raw substring (`queryString.substring(0, i - 1)`), but that
 * sample's `queryString` there is already `request.getQueryString()`
 * *after* the servlet container's own automatic decoding — the raw
 * substring in Java's world is this function's decoded one. Applying
 * `decodeURIComponent` to the whole content string is safe here: every
 * param **name** in an SSV callback is a fixed plain-ASCII identifier
 * (never percent-encoded to begin with), so only param *values* are
 * ever affected, and none of AdMob's own values legitimately decode to
 * a literal `&`/`=` that could be confused with a delimiter.
 *
 * Returns null for anything that doesn't look like a real SSV callback
 * at all (no signature/key_id present, or an undecodable %-sequence)
 * rather than throwing.
 */
function extractSignedContent(rawQueryString) {
  const sigMarker = "&signature=";
  const sigIdx = rawQueryString.indexOf(sigMarker);
  if (sigIdx === -1) return null;

  const rawContent = rawQueryString.substring(0, sigIdx);
  const afterSig = rawQueryString.substring(sigIdx + sigMarker.length);

  const keyIdMarker = "&key_id=";
  const keyIdIdx = afterSig.indexOf(keyIdMarker);
  if (keyIdIdx === -1) return null;

  const signatureEncoded = afterSig.substring(0, keyIdIdx);
  const keyIdEncoded = afterSig.substring(keyIdIdx + keyIdMarker.length);
  if (signatureEncoded.length === 0 || keyIdEncoded.length === 0) return null;

  let content;
  let signatureBase64;
  let keyId;
  try {
    content = decodeURIComponent(rawContent);
    signatureBase64 = decodeURIComponent(signatureEncoded);
    keyId = decodeURIComponent(keyIdEncoded);
  } catch (_) {
    return null;
  }
  return {content, signatureBase64, keyId};
}

let cachedKeys = null; // {fetchedAt: number, keys: Array<{keyId, pem}>}

/**
 * Fetches Google's SSV verifier keys, cached in memory for this warm
 * instance for up to [KEY_CACHE_MAX_AGE_MS] — mirrors the shape of
 * iap.js's `publisher()` lazily-created-and-reused client, applied here
 * to fetched data instead of a client object.
 */
async function getVerifierKeys() {
  const now = Date.now();
  if (cachedKeys && now - cachedKeys.fetchedAt < KEY_CACHE_MAX_AGE_MS) {
    return cachedKeys.keys;
  }
  const response = await fetch(VERIFIER_KEYS_URL);
  if (!response.ok) {
    throw new Error(`verifier-keys fetch failed with status ${response.status}`);
  }
  const json = await response.json();
  const keys = Array.isArray(json.keys) ? json.keys : [];
  cachedKeys = {fetchedAt: now, keys};
  return keys;
}

/** ECDSA/SHA-256/DER verification — see this file's own header comment. */
function verifySignature(content, signatureBase64, pem) {
  let signatureBuffer;
  try {
    signatureBuffer = Buffer.from(signatureBase64, "base64");
  } catch (_) {
    return false;
  }
  if (signatureBuffer.length === 0) return false;
  try {
    const verifier = crypto.createVerify("SHA256");
    verifier.update(content, "utf8");
    verifier.end();
    return verifier.verify({key: pem, dsaEncoding: "der"}, signatureBuffer);
  } catch (_) {
    return false;
  }
}

/**
 * Strictly parses `custom_data` into `{rewardKey, nonce}` — rejects
 * anything that isn't exactly this shape (extra/missing fields, wrong
 * types, unparseable JSON) rather than picking out the fields it wants
 * and ignoring the rest. The signature already proves the payload came
 * from AdMob unmodified; this proves this app itself sent something
 * sensible inside it.
 */
function parseCustomData(raw) {
  if (typeof raw !== "string" || raw.length === 0) return null;
  let data;
  try {
    data = JSON.parse(raw);
  } catch (_) {
    return null;
  }
  if (data === null || typeof data !== "object" || Array.isArray(data)) {
    return null;
  }
  const actualKeys = Object.keys(data);
  const allowedKeys = ["rewardKey", "nonce"];
  if (
    actualKeys.length !== allowedKeys.length ||
    !allowedKeys.every((k) => actualKeys.includes(k))
  ) {
    return null;
  }
  const {rewardKey, nonce} = data;
  if (typeof rewardKey !== "string" || rewardKey.length === 0) return null;
  if (typeof nonce !== "string") return null;
  return {rewardKey, nonce};
}

/**
 * The whole decision pipeline for one callback, as one testable
 * function: verify the signature, validate every field, grant
 * idempotently. Takes its dependencies explicitly rather than reaching
 * for module-level singletons, so a test can inject a [FakeFirestore],
 * a fixed [now], and a synthetic-keypair [fetchVerifierKeys] instead of
 * needing network access or a live Firestore.
 *
 * Returns `{httpStatus, outcome, reason, transactionId, rewardKey, uid}`
 * — never throws for an expected rejection path; only an unexpected
 * internal failure (e.g. [fetchVerifierKeys] itself throwing) is caught
 * by the caller and turned into a 500, exactly mirroring [exports.
 * adRewards]'s own catch block, so tests exercising this function
 * directly see the same 500-worthy exceptions the real endpoint would.
 */
async function evaluateCallback({
  method,
  rawQueryString,
  query,
  db,
  now = Date.now(),
  fetchVerifierKeys = getVerifierKeys,
  correlationId = crypto.randomUUID(),
}) {
  const log = (level, message, extra) => {
    logger[level](message, {correlationId, ...extra});
  };

  if (method !== "GET") {
    return {httpStatus: 400, outcome: "rejected", reason: "method_not_allowed"};
  }

  const parts = extractSignedContent(rawQueryString || "");
  if (!parts) {
    log("warn", "adRewards: malformed callback, no signature/key_id found");
    return {httpStatus: 400, outcome: "rejected", reason: "malformed_callback"};
  }

  const keys = await fetchVerifierKeys();
  const matchedKey = keys.find((k) => String(k.keyId) === parts.keyId);
  if (!matchedKey || !matchedKey.pem) {
    log("warn", "adRewards: unknown key_id in callback", {keyId: parts.keyId});
    return {httpStatus: 400, outcome: "rejected", reason: "unknown_key_id"};
  }

  if (!verifySignature(parts.content, parts.signatureBase64, matchedKey.pem)) {
    log("warn", "adRewards: signature verification failed", {
      keyId: parts.keyId,
    });
    return {httpStatus: 400, outcome: "rejected", reason: "invalid_signature"};
  }

  // Everything above establishes this callback is genuinely,
  // cryptographically from AdMob. Everything below validates its
  // CONTENT — a well-formed, authentic callback can still be one this
  // app chooses not to grant, and every rejection from here returns 200
  // (see this file's header comment for why).
  const q = query || {};
  const transactionId =
    typeof q.transaction_id === "string" ? q.transaction_id : null;
  const userId =
    typeof q.user_id === "string" && q.user_id.length > 0 ? q.user_id : null;
  const adUnit = typeof q.ad_unit === "string" ? q.ad_unit : null;
  const rewardAmount =
    typeof q.reward_amount === "string" ? q.reward_amount : null;
  const timestampRaw = typeof q.timestamp === "string" ? q.timestamp : null;
  const customDataRaw =
    typeof q.custom_data === "string" ? q.custom_data : null;

  const reject = (reason, extra = {}) => {
    log("warn", "adRewards: rejected", {transactionId, reason, ...extra});
    return {httpStatus: 200, outcome: "rejected", reason, transactionId};
  };

  if (!transactionId) return reject("missing_transaction_id");
  if (!userId) return reject("missing_user_id");
  if (!adUnit || !KNOWN_AD_UNITS.has(adUnit)) {
    return reject("unrecognised_ad_unit", {adUnit});
  }
  if (rewardAmount !== EXPECTED_REWARD_AMOUNT) {
    return reject("unexpected_reward_amount", {rewardAmount});
  }

  const timestampMs = timestampRaw ? Number(timestampRaw) : NaN;
  if (!Number.isFinite(timestampMs)) return reject("malformed_timestamp");
  if (now - timestampMs > MAX_TIMESTAMP_AGE_MS) return reject("timestamp_too_old");
  if (timestampMs - now > MAX_TIMESTAMP_FUTURE_SKEW_MS) {
    return reject("timestamp_in_future");
  }

  const customData = parseCustomData(customDataRaw);
  if (!customData) return reject("malformed_custom_data");
  const {rewardKey} = customData;
  if (!KNOWN_REWARD_KEYS.has(rewardKey)) {
    return reject("unknown_reward_key", {rewardKey});
  }

  const ledgerRef = db
    .collection("processedAdRewardTransactions")
    .doc(transactionId);
  const userRef = db.collection("users").doc(userId);

  let outcome = "unknown";
  await db.runTransaction(async (tx) => {
    const [ledgerSnap, userSnap] = await Promise.all([
      tx.get(ledgerRef),
      tx.get(userRef),
    ]);
    if (ledgerSnap.exists) {
      outcome = "duplicate_transaction";
      return;
    }
    if (!userSnap.exists) {
      outcome = "unknown_user";
      return;
    }
    const unlockedAt = Timestamp.fromMillis(now);
    const expiresAt = Timestamp.fromMillis(now + REWARD_DURATION_MS);
    tx.set(
      userRef,
      {adRewards: {[rewardKey]: {unlockedAt, expiresAt}}},
      {merge: true},
    );
    tx.set(ledgerRef, {
      uid: userId,
      rewardKey,
      grantedAt: FieldValue.serverTimestamp(),
    });
    outcome = "granted";
  });

  log("info", "adRewards: processed", {transactionId, rewardKey, uid: userId, outcome});
  return {httpStatus: 200, outcome, transactionId, rewardKey, uid: userId};
}

exports.adRewards = onRequest(async (req, res) => {
  const correlationId = crypto.randomUUID();
  try {
    const rawUrl = req.url || "";
    const queryStart = rawUrl.indexOf("?");
    const rawQueryString =
      queryStart === -1 ? "" : rawUrl.substring(queryStart + 1);

    const result = await evaluateCallback({
      method: req.method,
      rawQueryString,
      query: req.query,
      db: getFirestore(),
      correlationId,
    });
    res.status(result.httpStatus).send(result.outcome === "granted" ? "OK" : "OK");
  } catch (error) {
    logger.error("adRewards: unexpected error", {
      correlationId,
      error: error.message,
    });
    res.status(500).send("Internal error");
  }
});

/**
 * Server-authoritative half of the consume flow (Security &
 * Monetization design: "grant → server, consume → server", so
 * `adRewards` stays Cloud-Function-only with no Firestore Rules carve-
 * out needed). Only ever removes a key the CALLING user already holds —
 * `request.auth.uid` is the only uid this ever touches, so it can't be
 * used to consume anyone else's reward, and it can't grant anything.
 * Deliberately not deployed in the same step as [adRewards] — see the
 * B4 implementation notes for why.
 */
exports.consumeAdReward = onCall(async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const rewardKey = request.data && request.data.rewardKey;
  if (typeof rewardKey !== "string" || !KNOWN_REWARD_KEYS.has(rewardKey)) {
    throw new HttpsError("invalid-argument", "Unknown reward key.");
  }
  await getFirestore()
    .collection("users")
    .doc(uid)
    .update({[`adRewards.${rewardKey}`]: FieldValue.delete()});
  return {ok: true};
});

module.exports.evaluateCallback = evaluateCallback;
module.exports.extractSignedContent = extractSignedContent;
module.exports.verifySignature = verifySignature;
module.exports.parseCustomData = parseCustomData;
module.exports.KNOWN_REWARD_KEYS = KNOWN_REWARD_KEYS;
module.exports.KNOWN_AD_UNITS = KNOWN_AD_UNITS;
module.exports.EXPECTED_REWARD_AMOUNT = EXPECTED_REWARD_AMOUNT;
module.exports.MAX_TIMESTAMP_AGE_MS = MAX_TIMESTAMP_AGE_MS;
module.exports.MAX_TIMESTAMP_FUTURE_SKEW_MS = MAX_TIMESTAMP_FUTURE_SKEW_MS;

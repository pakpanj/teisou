const test = require("node:test");
const assert = require("node:assert");
const crypto = require("crypto");

const {
  evaluateCallback,
  extractSignedContent,
  parseCustomData,
  verifySignature,
  KNOWN_REWARD_KEYS,
} = require("./ad_rewards");
const {FakeFirestore} = require("./test_helpers/fake_firestore");

// A synthetic EC keypair stands in for AdMob's real signing key — the
// verification MATH (ECDSA/SHA-256/DER) is exactly what production uses;
// only the key material itself is fake, which is all a test can control
// without a live AdMob callback. P-256 (prime256v1) is the standard curve
// for this class of signature; Google's own SSV documentation doesn't
// name a curve explicitly, so this is the reasonable default rather than
// an independently-confirmed fact — the real verifier-keys.json response
// determines this in production, fetched fresh via [fetchTestKeys] below
// only as a stand-in for that network call.
const {publicKey, privateKey} = crypto.generateKeyPairSync("ec", {
  namedCurve: "prime256v1",
  publicKeyEncoding: {type: "spki", format: "pem"},
  privateKeyEncoding: {type: "pkcs8", format: "pem"},
});
const KEY_ID = "1916455855"; // Shaped like a real AdMob key_id; not a real one.

function signContent(content) {
  const signer = crypto.createSign("SHA256");
  signer.update(content, "utf8");
  signer.end();
  return signer.sign({key: privateKey, dsaEncoding: "der"}).toString("base64");
}

const AD_UNIT = "ca-app-pub-7168330620893919/3809909145";
const NOW = Date.parse("2026-08-26T12:00:00Z");
const EXPECTED_REWARD_AMOUNT = "1";

function baseParams(overrides = {}) {
  return {
    ad_network: "5450213213286189855",
    ad_unit: AD_UNIT,
    reward_amount: EXPECTED_REWARD_AMOUNT,
    reward_item: "",
    timestamp: String(NOW),
    transaction_id: "abc123def456",
    user_id: "testUid1",
    custom_data: JSON.stringify({rewardKey: "kaiwa", nonce: "nonce-1"}),
    ...overrides,
  };
}

/** The percent-encoded form actually sent on the wire. */
function queryString(params) {
  return Object.entries(params)
    .map(([k, v]) => `${k}=${encodeURIComponent(v)}`)
    .join("&");
}

/**
 * The literal, unencoded form — what AdMob actually signs (confirmed
 * against a real production callback 2026-08-30: signature verification
 * only succeeds once `custom_data`'s `%7B%22...%22%7D` is decoded back
 * to `{"..."}` before hashing). Kept as a separate function from
 * [queryString], never derived from it via `decodeURIComponent`, so a
 * bug in [extractSignedContent]'s own decode step can't cancel out
 * against an equal-and-opposite bug here and hide a regression.
 */
function decodedQueryString(params) {
  return Object.entries(params)
    .map(([k, v]) => `${k}=${v}`)
    .join("&");
}

/**
 * Builds a genuinely, correctly signed callback for [params] — signs
 * the DECODED content (what AdMob actually signs) but transmits the
 * ENCODED content (what actually arrives over HTTP), exactly mirroring
 * the real wire format this file's own header comment documents.
 */
function signedCallback(params) {
  const wireContent = queryString(params);
  const signature = signContent(decodedQueryString(params));
  return {
    rawQueryString:
      `${wireContent}&signature=${encodeURIComponent(signature)}` +
      `&key_id=${encodeURIComponent(KEY_ID)}`,
    query: {...params},
  };
}

const fetchTestKeys = async () => [{keyId: Number(KEY_ID), pem: publicKey}];

function newDbWithUser(uid = "testUid1") {
  const db = new FakeFirestore();
  db.seed(`users/${uid}`, {});
  return db;
}

function run(overrides) {
  return evaluateCallback({
    method: "GET",
    db: newDbWithUser(),
    now: NOW,
    fetchVerifierKeys: fetchTestKeys,
    ...overrides,
  });
}

test("valid signature grants the reward", async () => {
  const {rawQueryString, query} = signedCallback(baseParams());
  const db = newDbWithUser();
  const result = await evaluateCallback({
    method: "GET", rawQueryString, query, db, now: NOW,
    fetchVerifierKeys: fetchTestKeys,
  });
  assert.strictEqual(result.httpStatus, 200);
  assert.strictEqual(result.outcome, "granted");
  const userDoc = await db.collection("users").doc("testUid1").get();
  const grant = userDoc.data().adRewards.kaiwa;
  assert.ok(grant, "expected adRewards.kaiwa to be granted");
  assert.strictEqual(
    grant.expiresAt.toMillis() - grant.unlockedAt.toMillis(),
    24 * 60 * 60 * 1000,
  );
});

test("invalid signature is rejected, no grant", async () => {
  const params = baseParams();
  const content = queryString(params);
  const badSignature = Buffer.from("not-a-real-signature").toString("base64");
  const rawQueryString =
    `${content}&signature=${encodeURIComponent(badSignature)}` +
    `&key_id=${encodeURIComponent(KEY_ID)}`;
  const db = newDbWithUser();
  const result = await evaluateCallback({
    method: "GET", rawQueryString, query: {...params}, db, now: NOW,
    fetchVerifierKeys: fetchTestKeys,
  });
  assert.strictEqual(result.httpStatus, 400);
  assert.strictEqual(result.reason, "invalid_signature");
  const userDoc = await db.collection("users").doc("testUid1").get();
  assert.strictEqual(userDoc.data().adRewards, undefined);
});

test("malformed callback (no signature/key_id) is rejected", async () => {
  const result = await run({
    rawQueryString: "transaction_id=abc",
    query: {transaction_id: "abc"},
  });
  assert.strictEqual(result.httpStatus, 400);
  assert.strictEqual(result.reason, "malformed_callback");
});

test("unknown rewardKey is rejected", async () => {
  const params = baseParams({
    custom_data: JSON.stringify({rewardKey: "not_a_real_key", nonce: "n"}),
  });
  const {rawQueryString, query} = signedCallback(params);
  const db = newDbWithUser();
  const result = await evaluateCallback({
    method: "GET", rawQueryString, query, db, now: NOW,
    fetchVerifierKeys: fetchTestKeys,
  });
  assert.strictEqual(result.httpStatus, 200);
  assert.strictEqual(result.reason, "unknown_reward_key");
  const userDoc = await db.collection("users").doc("testUid1").get();
  assert.strictEqual(userDoc.data().adRewards, undefined);
});

test("UID not found is rejected, no grant, no crash", async () => {
  const params = baseParams({user_id: "nonexistentUid"});
  const {rawQueryString, query} = signedCallback(params);
  const db = new FakeFirestore(); // no user seeded at all
  const result = await evaluateCallback({
    method: "GET", rawQueryString, query, db, now: NOW,
    fetchVerifierKeys: fetchTestKeys,
  });
  assert.strictEqual(result.httpStatus, 200);
  assert.strictEqual(result.outcome, "unknown_user");
});

test("malformed custom_data is rejected", async () => {
  const params = baseParams({custom_data: "{not valid json"});
  const {rawQueryString, query} = signedCallback(params);
  const result = await evaluateCallback({
    method: "GET", rawQueryString, query, db: newDbWithUser(), now: NOW,
    fetchVerifierKeys: fetchTestKeys,
  });
  assert.strictEqual(result.httpStatus, 200);
  assert.strictEqual(result.reason, "malformed_custom_data");
});

test("first transaction_id grants", async () => {
  const {rawQueryString, query} =
    signedCallback(baseParams({transaction_id: "tx-first"}));
  const result = await evaluateCallback({
    method: "GET", rawQueryString, query, db: newDbWithUser(), now: NOW,
    fetchVerifierKeys: fetchTestKeys,
  });
  assert.strictEqual(result.outcome, "granted");
});

test("duplicate transaction_id does not grant a second time", async () => {
  const {rawQueryString, query} =
    signedCallback(baseParams({transaction_id: "tx-dup"}));
  const db = newDbWithUser();
  const first = await evaluateCallback({
    method: "GET", rawQueryString, query, db, now: NOW,
    fetchVerifierKeys: fetchTestKeys,
  });
  assert.strictEqual(first.outcome, "granted");
  const second = await evaluateCallback({
    method: "GET", rawQueryString, query, db, now: NOW + 1000,
    fetchVerifierKeys: fetchTestKeys,
  });
  assert.strictEqual(second.outcome, "duplicate_transaction");
  assert.strictEqual(second.httpStatus, 200);
  // The replay must not extend/refresh the original grant's timing.
  const userDoc = await db.collection("users").doc("testUid1").get();
  assert.strictEqual(userDoc.data().adRewards.kaiwa.unlockedAt.toMillis(), NOW);
});

test("concurrent duplicate callbacks still grant exactly once", async () => {
  const {rawQueryString, query} =
    signedCallback(baseParams({transaction_id: "tx-concurrent"}));
  const db = newDbWithUser();
  const [a, b] = await Promise.all([
    evaluateCallback({
      method: "GET", rawQueryString, query, db, now: NOW,
      fetchVerifierKeys: fetchTestKeys,
    }),
    evaluateCallback({
      method: "GET", rawQueryString, query, db, now: NOW,
      fetchVerifierKeys: fetchTestKeys,
    }),
  ]);
  const outcomes = [a.outcome, b.outcome].sort();
  assert.deepStrictEqual(outcomes, ["duplicate_transaction", "granted"]);
});

test("timestamp too old is rejected", async () => {
  const tooOld = NOW - 25 * 60 * 60 * 1000; // 25h before `now`
  const {rawQueryString, query} =
    signedCallback(baseParams({timestamp: String(tooOld)}));
  const result = await evaluateCallback({
    method: "GET", rawQueryString, query, db: newDbWithUser(), now: NOW,
    fetchVerifierKeys: fetchTestKeys,
  });
  assert.strictEqual(result.reason, "timestamp_too_old");
});

test("timestamp unreasonably in the future is rejected", async () => {
  const tooFuture = NOW + 10 * 60 * 1000; // 10 min after `now`
  const {rawQueryString, query} =
    signedCallback(baseParams({timestamp: String(tooFuture)}));
  const result = await evaluateCallback({
    method: "GET", rawQueryString, query, db: newDbWithUser(), now: NOW,
    fetchVerifierKeys: fetchTestKeys,
  });
  assert.strictEqual(result.reason, "timestamp_in_future");
});

test("expiresAt always derives from the server clock, never the callback", async () => {
  // A validly-recent-but-not-identical timestamp must not influence
  // expiresAt at all — it's always `now + 24h` from this function's own
  // clock, never from the callback's `timestamp` field.
  const {rawQueryString, query} =
    signedCallback(baseParams({timestamp: String(NOW - 5000)}));
  const db = newDbWithUser();
  await evaluateCallback({
    method: "GET", rawQueryString, query, db, now: NOW,
    fetchVerifierKeys: fetchTestKeys,
  });
  const userDoc = await db.collection("users").doc("testUid1").get();
  assert.strictEqual(
    userDoc.data().adRewards.kaiwa.expiresAt.toMillis(),
    NOW + 24 * 60 * 60 * 1000,
  );
});

test("reward amount not matching configuration is rejected", async () => {
  const {rawQueryString, query} =
    signedCallback(baseParams({reward_amount: "5"}));
  const result = await evaluateCallback({
    method: "GET", rawQueryString, query, db: newDbWithUser(), now: NOW,
    fetchVerifierKeys: fetchTestKeys,
  });
  assert.strictEqual(result.reason, "unexpected_reward_amount");
});

test("unrecognised ad_unit is rejected", async () => {
  const {rawQueryString, query} = signedCallback(
    baseParams({ad_unit: "ca-app-pub-0000000000000000/0000000000"}),
  );
  const result = await evaluateCallback({
    method: "GET", rawQueryString, query, db: newDbWithUser(), now: NOW,
    fetchVerifierKeys: fetchTestKeys,
  });
  assert.strictEqual(result.reason, "unrecognised_ad_unit");
});

test("missing user_id is rejected", async () => {
  const params = baseParams();
  delete params.user_id;
  const {rawQueryString, query} = signedCallback(params);
  const result = await evaluateCallback({
    method: "GET", rawQueryString, query, db: newDbWithUser(), now: NOW,
    fetchVerifierKeys: fetchTestKeys,
  });
  assert.strictEqual(result.reason, "missing_user_id");
});

test("non-GET method is rejected outright", async () => {
  const result = await run({method: "POST", rawQueryString: "", query: {}});
  assert.strictEqual(result.httpStatus, 400);
  assert.strictEqual(result.reason, "method_not_allowed");
});

// --- unit tests for the individual pieces, not just the pipeline ---

test("extractSignedContent finds content/signature/key_id in order", () => {
  const parts = extractSignedContent("a=1&b=2&signature=SIGVAL&key_id=42");
  assert.deepStrictEqual(parts, {
    content: "a=1&b=2",
    signatureBase64: "SIGVAL",
    keyId: "42",
  });
});

test("extractSignedContent returns null when signature/key_id are absent", () => {
  assert.strictEqual(extractSignedContent("a=1&b=2"), null);
});

test("extractSignedContent decodes the content before returning it — this is the regression test for the original bug", () => {
  // Content on the wire is percent-encoded (custom_data's JSON braces
  // and quotes); the returned `content` must be the DECODED form, since
  // that's what AdMob actually signed. Verifying against the raw,
  // still-encoded string (the original bug, live in production from
  // this endpoint's first deploy until 2026-08-30) made every real
  // callback fail signature verification, silently, forever.
  const parts = extractSignedContent(
    "custom_data=%7B%22rewardKey%22%3A%22kaiwa%22%7D&signature=SIG&key_id=42",
  );
  assert.deepStrictEqual(parts, {
    content: 'custom_data={"rewardKey":"kaiwa"}',
    signatureBase64: "SIG",
    keyId: "42",
  });
});

test("REGRESSION: verifies a real captured production AdMob SSV callback", () => {
  // A genuine callback captured from Cloud Functions logs 2026-08-29,
  // AdMob's real signing key (fetched live from
  // https://www.gstatic.com/admob/reward/verifier-keys.json, keyId
  // 3335741209) and a genuine signature — not synthetic. This is the
  // exact data that proved the original bug (verification always
  // failed against the raw, undecoded content) and proves the fix
  // (verification succeeds once the content is decoded first). If this
  // ever goes red again, ad rewards are broken in production again.
  const rawQueryString =
    "ad_network=5450213213286189855&ad_unit=3809909145&custom_data=" +
    "%7B%22rewardKey%22%3A%22choukai%22%2C%22nonce%22%3A%22ad61956ba48354" +
    "97%22%7D&reward_amount=1&reward_item=Reward&timestamp=1788035523915" +
    "&transaction_id=00065a35722fd953054b848a39105cdf&user_id=" +
    "Ci5Q25pmbwNRlLo5MTX8hucxI5C2&signature=MEUCIGxtbd35EquQf5ft6i6XDW7d" +
    "UGRHr0dlpUBm8ddXjlCjAiEAzUilmyv_mJF1HXX4RJqegHQYh7OXd3HCX0ht93VUNh4" +
    "&key_id=3335741209";
  const realAdMobPem =
    "-----BEGIN PUBLIC KEY-----\n" +
    "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE+nzvoGqvDeB9+SzE6igTl7TyK4JB\n" +
    "bglwir9oTcQta8NuG26ZpZFxt+F2NDk7asTE6/2Yc8i1ATcGIqtuS5hv0Q==\n" +
    "-----END PUBLIC KEY-----";

  const parts = extractSignedContent(rawQueryString);
  assert.ok(parts, "expected a well-formed callback");
  assert.strictEqual(
    verifySignature(parts.content, parts.signatureBase64, realAdMobPem),
    true,
    "a real AdMob-signed callback must verify against AdMob's real key",
  );
});

test("parseCustomData rejects an extra unexpected field", () => {
  assert.strictEqual(
    parseCustomData(JSON.stringify({rewardKey: "kaiwa", nonce: "n", extra: "x"})),
    null,
  );
});

test("parseCustomData rejects a missing field", () => {
  assert.strictEqual(parseCustomData(JSON.stringify({rewardKey: "kaiwa"})), null);
});

test("parseCustomData accepts exactly {rewardKey, nonce}", () => {
  assert.deepStrictEqual(
    parseCustomData(JSON.stringify({rewardKey: "kaiwa", nonce: "n"})),
    {rewardKey: "kaiwa", nonce: "n"},
  );
});

test("KNOWN_REWARD_KEYS has exactly the 9 keys documented across B1-B3", () => {
  assert.deepStrictEqual(
    [...KNOWN_REWARD_KEYS].sort(),
    [
      "avatar_premium", "bunpou", "choukai", "clan_extra", "cover_premium",
      "frame_premium", "kaiwa", "kanji", "particle",
    ],
  );
});

const {onSchedule} = require("firebase-functions/v2/scheduler");
const {getFirestore} = require("firebase-admin/firestore");
const logger = require("firebase-functions/logger");

const {publisher, ANDROID_PACKAGE, PREMIUM_PRODUCT, playConfigured} =
  require("./iap");
const {isStillActive, buildSubscriptionPatch} =
  require("./subscription_notifications");

/**
 * Self-healing backstop for `subscription.tier` — RISK-3
 * (AUDIT_COSMETIC_PROFILE_SHOP.md's payment/subscription follow-up).
 *
 * **The gap this closes**: `verifyPurchase` (`iap.js`) only ever grants
 * — a non-granting Play response throws and never touches Firestore.
 * `onPlayRtdn` (`subscription_notifications.js`) is the *only* thing
 * that can ever write `tier: "free"` back, and it depends entirely on
 * Play Console's Real-time Developer Notifications being configured and
 * actually delivering — a one-time external console step this
 * repository cannot verify or enforce. If RTDN is ever misconfigured,
 * drifts, or a single message is lost, a lapsed subscription stays
 * `premium` forever: not on app restart, not on the learner reopening a
 * purchase screen, not on Restore — `verifyPurchase`'s failure path
 * never downgrades anything.
 *
 * **Reuses, never reimplements, the decision this app already has and
 * already tests.** `isStillActive`/`buildSubscriptionPatch` are the
 * exact functions `onPlayRtdn` itself calls — same grace-period/
 * cancelled-but-active/on-hold/paused/expired/revoked handling, same
 * account-binding logic, same never-overwrite-a-known-expiry-with-null
 * rule. `publisher()`/`ANDROID_PACKAGE` are the exact Play client
 * `verifyPurchase`/`onPlayRtdn` already use. This file adds exactly one
 * new thing: *discovering* which accounts need checking, without
 * depending on Play pushing anything.
 *
 * **Two sweeps**:
 * - **Daily, near-expiry** (`sweepNearExpirySubscriptions`): premium
 *   accounts whose `subscription.expiresAt` has already passed or falls
 *   within [NEAR_EXPIRY_WINDOW_MS] — the accounts actually at risk of a
 *   missed RTDN around a real renewal/lapse boundary. Found with one
 *   targeted two-field query (needs the composite index declared in
 *   `firestore.indexes.json`), never a full collection scan — cost
 *   tracks churn near expiry, not total subscriber count.
 * - **Weekly, long-tail** (`sweepAllPremiumSubscriptions`): every
 *   premium account, batched/throttled. Catches the one case the daily
 *   query structurally cannot: a legacy account whose `expiresAt` was
 *   never set at all (a first-claim grant from before `applyExpiry`
 *   existed) — a Firestore inequality filter excludes a document
 *   missing the filtered field entirely, so no `expiresAt` query can
 *   ever find it.
 *
 * **`SUBSCRIPTION_BACKSTOP_ENABLED` gates writes, not the sweep
 * itself.** Both sweeps always run on schedule, always query, always
 * decide — but default to dry run (log the candidate and the decision,
 * write nothing) until this env var is literally `"true"`. Same
 * fail-closed-by-default posture as `PLAY_VERIFICATION_ENABLED` in
 * `iap.js`, and independently gated on it too: if Play verification
 * itself was never switched on for this project, there is no Android
 * Publisher access to check anything with, so a sweep must not guess
 * either way — same posture `onPlayRtdn` already takes.
 *
 * **Concurrency with RTDN**: both writers produce the same
 * `set(subscription: patch, {merge: true})` shape from a Play query
 * taken at their own write time, not from shared/cached state — so any
 * interleaving between an RTDN write and a sweep write for the same
 * account converges to whichever ran last being correct-as-of-then, and
 * self-corrects on the next real event or sweep either way. The
 * recently-updated guard below reduces (does not eliminate — this is
 * not a distributed lock) redundant double-processing of an account
 * RTDN just touched.
 */

/** How close to (or past) expiry a premium account has to be for the
 * daily sweep to pick it up. Three days is a wide-enough margin past
 * any real renewal/grace-period boundary to catch a missed RTDN
 * shortly after it should have fired, without checking accounts that
 * are nowhere near needing it. */
const NEAR_EXPIRY_WINDOW_MS = 3 * 24 * 60 * 60 * 1000;

/** An account touched more recently than this is presumed to already be
 * mid-flight from RTDN (or a very recent prior sweep) — skipped this
 * pass rather than redundantly re-checked. Not a lock; see this file's
 * own header comment on concurrency. */
const RECENTLY_UPDATED_GUARD_MS = 10 * 60 * 1000;

/** Weekly sweep batching — bounds how many Play API calls fire back to
 * back, with a short pause between batches, so a large premium base
 * doesn't hammer Play's quota or this function's own execution window
 * in one tight loop. */
const WEEKLY_BATCH_SIZE = 25;
const WEEKLY_BATCH_DELAY_MS = 500;

function backstopWritesEnabled() {
  return process.env.SUBSCRIPTION_BACKSTOP_ENABLED === "true";
}

function db() {
  return getFirestore();
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/** A real Firestore `Timestamp` (`.toMillis()`) or a plain `Date`
 * (`.getTime()`) — mirrors `battle_abandonment_sweep.js`'s identical
 * `turnStartedAt` handling, the same dual shape this codebase already
 * accepts wherever a stored timestamp is read back and compared. */
function toMillis(value) {
  if (!value) return null;
  if (typeof value.toMillis === "function") return value.toMillis();
  if (value instanceof Date) return value.getTime();
  return null;
}

/**
 * Whether [subscriptionData] was written too recently to be worth
 * re-checking right now. See this file's header comment on why this is
 * a guard, not a lock.
 */
function isRecentlyUpdated(
    subscriptionData, nowMs, guardMs = RECENTLY_UPDATED_GUARD_MS) {
  const updatedMs = toMillis(subscriptionData && subscriptionData.updatedAt);
  if (updatedMs === null) return false;
  return nowMs - updatedMs < guardMs;
}

/**
 * Which of [tokenDocs] (every `processedPurchaseTokens` row already
 * fetched for one uid) is the one currently governing that uid's
 * subscription — the [productId] entry with the latest `grantedAt`, or
 * `null` if none match.
 *
 * Deliberately filters/sorts in memory rather than a second `.where()`/
 * `.orderBy()` against Firestore: a single uid realistically holds at
 * most a handful of these over the account's lifetime — one per
 * distinct purchase/re-subscribe event, per `claimAndGrant`'s own
 * append-only ledger design (`iap.js`) — so fetching them all via the
 * one already-auto-indexed `uid ==` equality filter and picking the
 * newest here is both simpler and needs no second composite index,
 * unlike a `uid == && productId ==` compound filter with an `orderBy`
 * would.
 */
function pickCurrentToken(tokenDocs, productId = PREMIUM_PRODUCT) {
  let best = null;
  let bestMs = -Infinity;
  for (const doc of tokenDocs) {
    if (!doc.data || doc.data.productId !== productId) continue;
    const grantedMs = toMillis(doc.data.grantedAt);
    if (grantedMs === null) continue;
    if (grantedMs > bestMs) {
      best = doc;
      bestMs = grantedMs;
    }
  }
  return best;
}

/**
 * One candidate, start to finish: the recently-updated guard, token
 * resolution, the Play call, the exact same grant decision `onPlayRtdn`
 * itself uses, and — outside dry run — the write. Every outcome is
 * *returned*, never thrown for an expected condition, mirroring
 * `battle_abandonment_sweep.js`'s "one match's failure must never stop
 * the sweep" discipline; the caller logs and moves on regardless of
 * which outcome comes back.
 *
 * A Play API failure (network, quota, transient 5xx) is `"skipped_play_error"`
 * — **never** interpreted as "not active". See `verifyWithPlay`'s
 * identical discipline in `iap.js`: an unreachable answer is not an
 * answer, and must not be read as a denial.
 *
 * [playClient]/[firestore]/[now]/[dryRun] are all injected with real
 * defaults — the same "real logic takes its dependencies as explicit
 * parameters" seam `claimAndGrant` (`iap.js`) and `forfeitOneStaleRound`
 * (`battle_abandonment_sweep.js`) already establish, extended here to a
 * dependency (the Play client) neither of those needed to inject
 * before now.
 */
async function processCandidate({
  uid,
  subscriptionData,
  firestore = db(),
  playClient = publisher(),
  now = Date.now(),
  dryRun = !backstopWritesEnabled(),
}) {
  if (isRecentlyUpdated(subscriptionData, now)) {
    return {uid, outcome: "skipped_recently_updated"};
  }

  const tokenSnap = await firestore
      .collection("processedPurchaseTokens")
      .where("uid", "==", uid)
      .get();
  const tokenDocs = tokenSnap.docs.map((d) => ({id: d.id, data: d.data()}));
  const tokenDoc = pickCurrentToken(tokenDocs);
  if (!tokenDoc) {
    return {uid, outcome: "skipped_missing_token"};
  }

  let response;
  try {
    response = await playClient.purchases.subscriptionsv2.get({
      packageName: ANDROID_PACKAGE,
      token: tokenDoc.id,
    });
  } catch (error) {
    return {
      uid,
      outcome: "skipped_play_error",
      error: error && error.message,
    };
  }

  const firstClaimed = tokenDoc.data.claimedVia === "first-claim";
  const active = isStillActive(response.data, {firstClaimed, uid});
  const patch = buildSubscriptionPatch(active, response.data);

  if (!dryRun) {
    await firestore.collection("users").doc(uid).set(
        {subscription: patch},
        {merge: true},
    );
  }

  return {
    uid,
    outcome: active ?
      (dryRun ? "would_remain_premium" : "reconfirmed") :
      (dryRun ? "would_downgrade" : "downgraded"),
    expiresAt: patch.expiresAt || null,
  };
}

/**
 * Every premium account whose `subscription.expiresAt` is already past
 * or falls within [windowMs] of [now] — the daily sweep's candidate
 * set, found with one targeted query, never a full collection scan.
 * Needs the `subscription.tier ASC, subscription.expiresAt ASC`
 * composite index declared in `firestore.indexes.json`.
 */
async function findNearExpiryCandidates(
    firestore, now, windowMs = NEAR_EXPIRY_WINDOW_MS) {
  const snap = await firestore
      .collection("users")
      .where("subscription.tier", "==", "premium")
      .where("subscription.expiresAt", "<=", new Date(now + windowMs))
      .get();
  return snap.docs.map((d) => ({
    uid: d.id,
    subscriptionData: (d.data() || {}).subscription || {},
  }));
}

/**
 * Every premium account, full stop — the weekly sweep's candidate set.
 * A single equality filter, already covered by Firestore's automatic
 * single-field index; needs nothing new in `firestore.indexes.json`.
 * The only query that can ever find a premium account with no
 * `expiresAt` at all — [findNearExpiryCandidates]'s inequality filter
 * structurally excludes a document missing that field, the same as any
 * Firestore range filter does.
 */
async function findAllPremiumCandidates(firestore) {
  const snap = await firestore
      .collection("users")
      .where("subscription.tier", "==", "premium")
      .get();
  return snap.docs.map((d) => ({
    uid: d.id,
    subscriptionData: (d.data() || {}).subscription || {},
  }));
}

function summarize(results) {
  const summary = {};
  for (const r of results) {
    summary[r.outcome] = (summary[r.outcome] || 0) + 1;
  }
  return summary;
}

async function processAll(candidates, {firestore, now, dryRun, playClient}) {
  const results = [];
  for (const candidate of candidates) {
    try {
      results.push(
          await processCandidate(
              {...candidate, firestore, now, dryRun, playClient},
          ),
      );
    } catch (error) {
      // A bug/unexpected error for one candidate must never stop the
      // rest of the sweep — same discipline as
      // battle_abandonment_sweep.js's per-match try/catch.
      logger.error(
          "subscription_backstop: unexpected error for one candidate",
          {uid: candidate.uid, error: error && error.message},
      );
      results.push({uid: candidate.uid, outcome: "unexpected_error"});
    }
  }
  return results;
}

async function runDailySweep({
  firestore = db(),
  now = Date.now(),
  playClient,
} = {}) {
  if (!playConfigured()) {
    logger.info("subscription_backstop: daily sweep skipped — Play " +
      "verification is not configured for this project");
    return {skipped: "play_not_configured"};
  }

  const candidates = await findNearExpiryCandidates(firestore, now);
  const dryRun = !backstopWritesEnabled();
  logger.info("subscription_backstop: daily sweep starting", {
    candidates: candidates.length,
    dryRun,
  });

  const results =
    await processAll(candidates, {firestore, now, dryRun, playClient});
  const summary = summarize(results);
  logger.info("subscription_backstop: daily sweep complete", {
    candidates: candidates.length,
    dryRun,
    ...summary,
  });
  return {candidates: candidates.length, dryRun, summary};
}

async function runWeeklySweep({
  firestore = db(),
  now = Date.now(),
  batchSize = WEEKLY_BATCH_SIZE,
  batchDelayMs = WEEKLY_BATCH_DELAY_MS,
  playClient,
} = {}) {
  if (!playConfigured()) {
    logger.info("subscription_backstop: weekly sweep skipped — Play " +
      "verification is not configured for this project");
    return {skipped: "play_not_configured"};
  }

  const candidates = await findAllPremiumCandidates(firestore);
  const dryRun = !backstopWritesEnabled();
  logger.info("subscription_backstop: weekly sweep starting", {
    candidates: candidates.length,
    dryRun,
  });

  const results = [];
  for (let i = 0; i < candidates.length; i += batchSize) {
    const batch = candidates.slice(i, i + batchSize);
    results.push(
        ...await processAll(batch, {firestore, now, dryRun, playClient}),
    );
    if (i + batchSize < candidates.length) await sleep(batchDelayMs);
  }

  const summary = summarize(results);
  logger.info("subscription_backstop: weekly sweep complete", {
    candidates: candidates.length,
    dryRun,
    ...summary,
  });
  return {candidates: candidates.length, dryRun, summary};
}

exports.sweepNearExpirySubscriptions = onSchedule(
    {schedule: "every day 03:00", timeZone: "Asia/Jakarta"},
    async () => {
      await runDailySweep();
    },
);

exports.sweepAllPremiumSubscriptions = onSchedule(
    {schedule: "every monday 03:30", timeZone: "Asia/Jakarta"},
    async () => {
      await runWeeklySweep();
    },
);

// Exported for tests only.
exports._internal = {
  backstopWritesEnabled,
  isRecentlyUpdated,
  pickCurrentToken,
  processCandidate,
  processAll,
  findNearExpiryCandidates,
  findAllPremiumCandidates,
  runDailySweep,
  runWeeklySweep,
  NEAR_EXPIRY_WINDOW_MS,
  RECENTLY_UPDATED_GUARD_MS,
  WEEKLY_BATCH_SIZE,
  WEEKLY_BATCH_DELAY_MS,
};

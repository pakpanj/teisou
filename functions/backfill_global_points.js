/**
 * One-time Global Points migration for accounts that existed before the
 * live triggers (`functions/global_points.js`) were deployed.
 *
 * Decided in `GLOBAL_POINTS_FINAL_DECISION_MEMO.md`, §3: **90 days of
 * history, not full-historical and not start-from-0**. Full-historical
 * replay was rejected as highest-risk/highest-complexity (any bug in a
 * years-deep replay is nearly unverifiable, and this codebase's own
 * established convention — `backfillGlobalScore`/`backfillDisplayNameLower`/
 * `backfillUserId` — deliberately favors simple, forward-looking
 * self-heals over exact historical reconstruction). Start-from-0 was
 * rejected as unfair to genuinely active existing users. 90 days is a
 * bounded, spot-checkable middle ground, and not an arbitrary number: it
 * is exactly 3x the 30-day repeat-cycle window, generous enough to
 * capture a representative recent-activity snapshot without touching the
 * full historical record.
 *
 * **A manual, explicitly-invoked script — not a Cloud Function trigger
 * and never auto-run.** Mirrors this project's own convention for
 * one-time content/data migrations (the many `scripts/generate_*.py`
 * seed scripts): written, tested, and left for a human to run once
 * against the live project when ready, not wired into any deploy or
 * request path.
 *
 * ---
 *
 * **Reliability fix (this revision): `backfillUser` no longer writes its
 * own blind batch transaction.** The earlier version pre-checked which
 * `historyDocId`s were already awarded via a plain `firestore.getAll()`
 * *outside* any transaction, then wrote every marker/cycle/increment for
 * the "pending" ones inside one big transaction that never re-read the
 * markers it was about to write. That gap is real, not theoretical:
 * Firestore transactions only protect documents actually `.get()` inside
 * them — a `.set()` on a document the transaction never read carries no
 * conflict detection at all, so a live trigger committing a marker for
 * the same `historyDocId` in the window between the pre-check and the
 * batch transaction's commit would be silently overwritten, and
 * `globalPoints` would be incremented twice for that one attempt. Found
 * during an explicit reliability/idempotency review, proven by tracing
 * the code rather than by reproducing it live (this project has no
 * Firestore emulator to reproduce a real concurrent-transaction race
 * against).
 *
 * The fix: `backfillUser` now calls [awardPointsForHistoryDoc] — the
 * exact same function the live trigger calls — **once per pending
 * record, sequentially, in chronological order**, instead of computing
 * every attempt's outcome in memory and writing them all in one blind
 * batch. Every write this file makes now goes through that one
 * function's own transaction (read-marker-then-write-marker, atomically,
 * inside a single `runTransaction`), so a backfill call and a live
 * trigger racing on the same `historyDocId` are protected by the exact
 * same Firestore conflict-detection mechanism, not two different ones
 * that have to independently agree.
 *
 * [replayForBackfill] (the old in-memory batch-computation core) is kept
 * as a **pure preview/estimate** utility — useful for a dry-run total
 * before actually running [runBackfill] against a live project — but it
 * is no longer what performs the real writes, and its own in-memory
 * `cycles` map has no way to see a concurrent live trigger's write. Do
 * not repurpose it as an authoritative write path again.
 */

const {getFirestore} = require("firebase-admin/firestore");
const logger = require("firebase-functions/logger");

const {
  MODULES,
  difficultyMultiplierFor,
  repeatKeyFor,
  decideAward,
  toEpochMs,
  awardPointsForHistoryDoc,
} = require("./global_points");

const BACKFILL_WINDOW_MS = 90 * 24 * 60 * 60 * 1000;

/**
 * Pure **preview/estimate** core — takes an already-fetched,
 * already-filtered list of `{moduleType, historyDocId, data}` records
 * for ONE user and returns what their total points *would* be if
 * processed in this exact order with no concurrent interference. No
 * Firestore access inside this function at all, which is what makes it
 * directly unit-testable with fixture data (see
 * `backfill_global_points.test.js`) instead of needing an emulator.
 *
 * **Not the real write path** — see this file's own top doc comment for
 * why [backfillUser] instead processes records one at a time through
 * [awardPointsForHistoryDoc]'s real, per-document transaction. This
 * function remains useful as a cheap, Firestore-free way to estimate a
 * user's backfill total ahead of actually running it, and its own
 * decay/reset math is still exactly what a real, uncontested run would
 * produce — it just cannot account for another writer touching the same
 * `(uid, repeatKey)` mid-replay the way a real transaction can.
 *
 * Records MUST already be in chronological order (oldest first) — the
 * decay/reset math is order-dependent, exactly like a real sequential
 * run processes attempts as they actually happened.
 *
 * @param {{moduleType: string, historyDocId: string, data: object}[]} records
 * @return {{totalPoints: number, markers: {historyDocId: string, moduleType: string, points: number}[], finalCycles: Map<string, {attemptCountInCycle: number, cycleStartedAt: number}>}}
 */
function replayForBackfill(records) {
  const cycles = new Map();
  const markers = [];
  let totalPoints = 0;

  for (const record of records) {
    const spec = MODULES[record.moduleType];
    if (!spec) continue;

    const correct = Number(record.data.score) || 0;
    const difficulty = difficultyMultiplierFor(record.data[spec.difficultyField]);
    const key = repeatKeyFor(record.moduleType, record.data);
    const now = toEpochMs(record.data.completedAt);

    const result = decideAward({
      alreadyAwarded: false,
      cycle: cycles.get(key) || null,
      now,
      correct,
      difficulty,
    });

    // decideAward only returns null for alreadyAwarded:true, which this
    // call never passes — kept as a guard anyway so a future signature
    // change to decideAward fails loudly here rather than silently.
    if (result === null) continue;

    cycles.set(key, result.newCycle);
    totalPoints += result.points;
    markers.push({
      historyDocId: record.historyDocId,
      moduleType: record.moduleType,
      points: result.points,
    });
  }

  return {totalPoints, markers, finalCycles: cycles};
}

function db() {
  return getFirestore();
}

/**
 * Runs the real, Firestore-touching backfill for one user: fetches the
 * last 90 days of every one of the four exam-history collections, then
 * awards each pending one **through [awardPointsForHistoryDoc]**,
 * sequentially, in chronological order — the same function, the same
 * per-document transaction, the live trigger uses. This is what actually
 * closes the double-award race described in this file's own top doc
 * comment: every write to a marker/cycle/leaderboard doc in this whole
 * file now goes through exactly one transactional code path, so a live
 * trigger racing this function on the same `historyDocId` is resolved by
 * Firestore's own conflict detection, not by two independently-written
 * mechanisms that could disagree.
 *
 * The `firestore.getAll()` pre-filter below is kept as a **pure
 * optimisation** — skipping an obviously-already-awarded record avoids
 * paying for a transaction that would just no-op — but it is explicitly
 * **not treated as authoritative**: every record that survives the
 * pre-filter still gets its own full transactional check inside
 * [awardPointsForHistoryDoc], which is what actually decides whether it
 * gets awarded. A record the pre-filter missed (e.g. a live trigger
 * awarded it in the instant between the pre-filter read and this
 * function reaching it) simply gets caught by that per-record
 * transaction instead, at the cost of one wasted (but harmless, correct)
 * transaction — never at the cost of a double-award.
 *
 * Idempotent per user, for the same reason: re-running this function for
 * a uid that was already fully processed finds every record's marker
 * already set (whether by an earlier backfill run or a live trigger)
 * and awards nothing new, regardless of how many times it's re-run.
 *
 * @param {string} uid
 * @param {number} nowMs backfill "now", for computing the 90-day cutoff —
 *   parametrized rather than always `Date.now()` so this is callable
 *   deterministically from a test.
 * @param {object} [options]
 * @param {import("firebase-admin/firestore").Firestore} [options.firestore]
 *   injected Firestore instance — defaults to the real one ([db]). See
 *   [awardPointsForHistoryDoc]'s own doc comment for why this exists.
 */
async function backfillUser(uid, nowMs, options = {}) {
  const firestore = options.firestore || db();
  const cutoff = nowMs - BACKFILL_WINDOW_MS;

  const perModule = await Promise.all(
    Object.entries(MODULES).map(async ([moduleType, spec]) => {
      const snapshot = await firestore
        .collection("users")
        .doc(uid)
        .collection(spec.collection)
        .get();
      return snapshot.docs
        .map((doc) => ({moduleType, historyDocId: doc.id, data: doc.data()}))
        .filter((r) => toEpochMs(r.data.completedAt) >= cutoff);
    }),
  );

  const allRecords = perModule.flat();

  // Non-authoritative fast pre-filter only — see this function's own doc
  // comment above. Every record that survives this still goes through
  // awardPointsForHistoryDoc's real transactional check below; nothing
  // here is trusted as the final word on whether a record was awarded.
  const markerRefs = allRecords.map((r) =>
    firestore
      .collection("globalPointsState")
      .doc(uid)
      .collection("pointsAwarded")
      .doc(r.historyDocId),
  );
  const markerSnaps = markerRefs.length
    ? await firestore.getAll(...markerRefs)
    : [];
  const probablyAlreadyAwarded = new Set(
    markerSnaps.filter((s) => s.exists).map((s) => s.id),
  );

  const pending = allRecords
    .filter((r) => !probablyAlreadyAwarded.has(r.historyDocId))
    .sort(
      (a, b) => toEpochMs(a.data.completedAt) - toEpochMs(b.data.completedAt),
    );

  if (pending.length === 0) {
    logger.info("backfillGlobalPoints: nothing to do", {uid});
    return {uid, totalPoints: 0, attemptsAwarded: 0, attemptsConsidered: 0};
  }

  // Sequential, not Promise.all: each record's decay depends on the
  // repeat-cycle state committed by the one processed just before it
  // (or, if a live trigger interleaves, by whatever that trigger just
  // committed) — awarding out of order or in parallel would let two
  // records on the same repeatKey read a stale cycle at the same time.
  let totalPoints = 0;
  let attemptsAwarded = 0;
  for (const record of pending) {
    const result = await awardPointsForHistoryDoc(
      uid, record.moduleType, record.historyDocId, record.data,
      {firestore, source: "backfill"},
    );
    if (result.awarded) {
      totalPoints += result.points;
      attemptsAwarded++;
    }
  }

  logger.info("backfillGlobalPoints: done", {
    uid, totalPoints, attemptsAwarded, attemptsConsidered: pending.length,
  });
  return {uid, totalPoints, attemptsAwarded, attemptsConsidered: pending.length};
}

/**
 * Runs [backfillUser] for every uid in `leaderboard` — the manual entry
 * point. Not exported as a Cloud Function; run once, by hand, with the
 * Admin SDK already initialized (see `functions/index.js`'s
 * `initializeApp()`), e.g. via a throwaway local script that requires
 * this module. Processes users sequentially rather than in parallel to
 * keep Firestore write load predictable during a real run against a live
 * project — this is a one-time job, not a latency-sensitive path.
 *
 * @return {{processed: number, totalPointsAwarded: number, errors: {uid: string, error: string}[]}}
 */
async function runBackfill() {
  const firestore = db();
  const uidsSnapshot = await firestore.collection("leaderboard").get();
  const nowMs = Date.now();

  let processed = 0;
  let totalPointsAwarded = 0;
  const errors = [];

  for (const doc of uidsSnapshot.docs) {
    try {
      const result = await backfillUser(doc.id, nowMs);
      processed++;
      totalPointsAwarded += result.totalPoints;
    } catch (error) {
      errors.push({uid: doc.id, error: String(error)});
      logger.error("backfillGlobalPoints: failed for uid", {
        uid: doc.id, error: String(error),
      });
    }
  }

  logger.info("backfillGlobalPoints: run complete", {
    processed, totalPointsAwarded, errorCount: errors.length,
  });
  return {processed, totalPointsAwarded, errors};
}

module.exports = {
  BACKFILL_WINDOW_MS,
  replayForBackfill,
  backfillUser,
  runBackfill,
};

const {onSchedule} = require("firebase-functions/v2/scheduler");
const {getFirestore, FieldValue, FieldPath} = require("firebase-admin/firestore");
const logger = require("firebase-functions/logger");
const {wibWeekId, wibWeekStart} = require("./wib_week");

/**
 * The other way to earn coins besides topping up: placing 1st-3rd on the
 * **weekly** Top Global competition — recalculated every WIB week rather
 * than granted once and forgotten, the same "currently, not once" spirit
 * the card-skin achievement tier already uses for star totals (see
 * `card_skins.dart`), applied to the leaderboard instead of the battle
 * ladder.
 *
 * **Runs with Admin SDK privileges, same reason `onBattleMatchConcluded`
 * does** — `coins` is frozen against every client write in
 * `firestore.rules` (`isAllowedPurchaseWrite`), so a scheduled function
 * running as an admin is the only thing besides `verifyPurchase` that
 * can ever move that field.
 *
 * ## P0 fix: ranking source changed from `leaderboard.globalScore` to
 * `globalScorePeriods/{periodId}/users/{uid}` (2026, Weekly Global
 * Ranking implementation — see `TEISOU_ROADMAP_MASTER.md`)
 *
 * The historical `leaderboard/{uid}.globalScore` field has **no rule in
 * `firestore.rules` restricting its value at all** (confirmed by a
 * dedicated audit — any authenticated client could `setDoc`/`updateDoc`
 * an arbitrary `globalScore` onto their own row) — and this file used to
 * rank the real weekly coin payout directly off that unprotected field,
 * with no server-side sanity check of any kind. That was the P0.
 *
 * The fix is not a rules patch on `globalScore` alone — it's a change of
 * ranking SOURCE. `globalScorePeriods/{periodId}/users/{uid}` is written
 * **only** by `global_points.js`'s `awardPointsForHistoryDoc`, inside the
 * same server-side transaction that already computes Formula C points
 * from a real exam-history document, using the exam-history document's
 * own server-authoritative Firestore commit time (`event.time`, never a
 * client-supplied value) to decide which period an attempt counts
 * toward. No client write path to this collection exists at all (see
 * `firestore.rules`'s own `globalScorePeriods`/`globalScorePeriodAwards`
 * block) — ranking by it removes the forgeable input entirely, rather
 * than trying to sanitize it.
 *
 * `leaderboard.globalScore` itself is **unchanged and untouched by this
 * file** — it remains the app's historical "Skor Global" display metric
 * (a running average across four exam categories), it is NOT reset by
 * anything here, and it is explicitly NOT used for this payout anymore.
 * See the Weekly Global Ranking design (roadmap commit history) for why
 * fixing `globalScore`'s own rules gap was judged insufficient on its
 * own: even a perfectly rules-protected running average is still a
 * cumulative, never-resetting number, unsuited to a recurring weekly
 * prize by its very shape — a competitive weekly metric needed a
 * competitive weekly *source*, which is what `globalScorePeriods` is.
 *
 * ## Weekly period identity: WIB, not raw UTC
 *
 * The period boundary is Monday 00:00:00 WIB (`Asia/Jakarta`, UTC+7, no
 * DST) through the following Sunday 23:59:59.999 WIB — see
 * `functions/wib_week.js` for the full rationale on why this needed its
 * own `wibWeekId`/`wibWeekStart` rather than reusing this file's own
 * [isoWeekId] (which computes boundaries from the raw UTC calendar date
 * and would silently misplace the boundary by up to 7 hours relative to
 * what a WIB-timezone learner actually experiences as "this week").
 *
 * ## Grace buffer: 5 minutes
 *
 * A period is only ever paid out once **at least 5 minutes have elapsed
 * since the CURRENT period's own start** — i.e. since the moment the
 * period being paid actually closed. This isn't a real in-process delay
 * (an `onSchedule` function sleeping for 5 minutes would work, but wastes
 * billed compute time for no benefit over a pure date check) — see
 * [closedPeriodId] below, a pure function of "now" that can be, and is,
 * unit-tested with zero real waiting. The buffer exists so that any
 * attempt whose `event.time` fell right at the tail end of the closing
 * period, but whose Cloud Function trigger hadn't finished committing its
 * `globalScorePeriods` write by the exact boundary instant, still has
 * time to land before the ranking query runs.
 *
 * ## Idempotent per period, not per run
 *
 * A cold start, a retry, or a manual re-trigger must not pay the same
 * period out twice — `awardedFor` (stored on
 * `globalScorePeriodAwards/{periodId}`) is checked and set inside one
 * transaction before any coin is granted, the same processed-token shape
 * `verifyPurchase` uses for a purchase token, just keyed by period
 * instead. **Deliberately a NEW collection name, distinct from the OLD
 * `weeklyCoinAwards/{isoWeekId}` markers** — not a reused key under the
 * old `isoWeekId` format. `isoWeekId` and `wibWeekId` share the exact
 * same `YYYY-Www` STRING FORMAT (chosen for readability), which means a
 * OLD-scheme id and a NEW-scheme id computed for two DIFFERENT real
 * calendar weeks could in principle collide as the exact same string —
 * reusing `weeklyCoinAwards` would have made "did this period already
 * get paid" ambiguous between two entirely different ranking criteria.
 * A brand-new collection name removes that risk by construction, with
 * no reliance on reasoning through the two id schemes' relative
 * date-math offsets to prove they can never collide. The OLD
 * `weeklyCoinAwards/{isoWeekId}` documents this scheduled function wrote
 * before this change remain in Firestore, untouched, as inert historical
 * records — nothing reads them anymore.
 */

const REWARDS = [500, 300, 100];

/** How long after a period's own start the PREVIOUS (just-closed) period
 * is considered safe to pay out — see this file's own "Grace buffer"
 * section above. */
const GRACE_BUFFER_MS = 5 * 60 * 1000;

/** ISO week id like `2026-W34` — stable regardless of what day/time the
 * schedule actually fires on, so a retry on the same week is recognised
 * as the same week even if it lands a few minutes into the next day.
 *
 * **Retired from the weekly payout as of the Weekly Global Ranking
 * implementation — no longer called by [awardTopGlobalCoinsOnce] or the
 * scheduled function below.** Kept, exported, and still covered by
 * `award_top_coins.test.js` purely because it is the id scheme every
 * pre-existing `weeklyCoinAwards/{id}` document already in Firestore
 * uses — deleting the function would not delete those documents, and
 * this project's own established discipline (see e.g. `isoWeekId`'s
 * sibling `wibWeekId`'s own doc comment) is to leave a superseded pure
 * function in place rather than pretend history didn't happen. Nothing
 * in this file computes a *new* id with this function anymore — see
 * [closedPeriodId]/`wibWeekId` for what the live payout actually uses
 * now. */
function isoWeekId(date) {
  const d = new Date(Date.UTC(
      date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(),
  ));
  const dayNum = d.getUTCDay() || 7;
  d.setUTCDate(d.getUTCDate() + 4 - dayNum);
  const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
  const weekNum = Math.ceil((((d - yearStart) / 86400000) + 1) / 7);
  return `${d.getUTCFullYear()}-W${String(weekNum).padStart(2, "0")}`;
}

/**
 * The id of the most recently CLOSED WIB week that is safely past the
 * [GRACE_BUFFER_MS] grace window — or `null` if no period is yet safe to
 * pay relative to `nowMs` (we are still within the grace window right
 * after a boundary).
 *
 * Pure function of `nowMs` — no Firestore access, no real waiting — so
 * every grace-buffer/boundary scenario (Sunday 23:59:59 WIB, Monday
 * 00:00:00 WIB, "payout invoked at Monday 00:03" vs "...00:06", etc.) is
 * directly unit-testable by passing a specific instant, matching this
 * project's own established pure-function-first discipline (see
 * `global_points.js`'s own [decideAward] doc comment on why the
 * interesting decision is kept Firestore-free).
 *
 * @param {number} nowMs epoch ms — the instant to evaluate against.
 *   Callers must pass a genuine server clock read (`Date.now()` in
 *   production), never anything client-influenced.
 * @return {string|null}
 */
function closedPeriodId(nowMs) {
  const now = new Date(nowMs);
  const currentPeriodStart = wibWeekStart(now);
  const msSinceCurrentPeriodStart = now.getTime() - currentPeriodStart.getTime();

  if (msSinceCurrentPeriodStart < GRACE_BUFFER_MS) {
    // Still inside the grace window right after the most recent
    // boundary — the period that just closed is NOT yet safe to pay.
    // Deliberately returns null rather than "the period before that
    // one" — a caller invoked during the grace window must wait, not
    // silently pay out a stale period instead.
    return null;
  }

  // Grace has elapsed since the CURRENT period started, so the PREVIOUS
  // period (the one that just closed, ending exactly at
  // currentPeriodStart) is safe.
  const previousPeriodInstant = new Date(currentPeriodStart.getTime() - 1);
  return wibWeekId(previousPeriodInstant);
}

/**
 * Ranks `globalScorePeriods/{periodId}/users`, selects the top
 * [REWARDS.length] winners with the approved deterministic tie-break
 * (points DESC, then attempts DESC, then uid ASC), and — inside one
 * transaction, guarded by a `globalScorePeriodAwards/{periodId}` marker
 * — records the historical payout and credits each winner's `coins`.
 * Idempotent: a second call for a `periodId` that has already been paid
 * is a safe no-op (matches `verifyPurchase`'s own processed-token
 * shape, and this file's own pre-existing idempotency contract before
 * this rewrite).
 *
 * @param {import("firebase-admin/firestore").Firestore} db
 * @param {string} periodId a WIB week id, e.g. `"2026-W36"` — the
 *   caller (either [runWeeklyPayoutIfDue] below, or a test) is
 *   responsible for having already decided this period is safely
 *   closed; this function itself performs no grace-buffer check of its
 *   own, matching this file's established separation of "decide when"
 *   ([closedPeriodId]) from "do the ranking/payout"
 *   (this function) — see `global_points.js`'s own [decideAward] vs.
 *   [awardPointsForHistoryDoc] split for the same reasoning applied to
 *   a sibling concern.
 * @return {Promise<{uid: string, rank: number, points: number,
 *   attempts: number, reward: number}[]>} the winners, in rank order —
 *   an empty array if the period has fewer than [REWARDS.length]
 *   participants (fewer winners is fine, matching this file's own
 *   pre-existing "fewer than 3 entries" behavior).
 */
async function awardTopGlobalCoinsOnce(db, periodId) {
  const awardRef = db.collection("globalScorePeriodAwards").doc(periodId);
  const topSnap = await db
      .collection("globalScorePeriods")
      .doc(periodId)
      .collection("users")
      .orderBy("points", "desc")
      .orderBy("attempts", "desc")
      .orderBy(FieldPath.documentId(), "asc")
      .limit(REWARDS.length)
      .get();

  const winners = topSnap.docs.map((doc, i) => {
    const data = doc.data() || {};
    return {
      uid: doc.id,
      rank: i + 1,
      points: typeof data.points === "number" ? data.points : 0,
      attempts: typeof data.attempts === "number" ? data.attempts : 0,
      reward: REWARDS[i],
    };
  });

  await db.runTransaction(async (tx) => {
    const awardSnap = await tx.get(awardRef);
    if (awardSnap.exists) return;
    tx.set(awardRef, {
      periodId,
      finalizedAt: FieldValue.serverTimestamp(),
      winners,
    });
    for (const {uid, reward} of winners) {
      tx.set(
          db.collection("users").doc(uid),
          {coins: FieldValue.increment(reward)},
          {merge: true},
      );
    }
  });

  logger.info("awardTopGlobalCoins: period processed", {
    periodId, winnerCount: winners.length,
  });
  return winners;
}

/**
 * Orchestration entry point: determines whether a period is currently
 * safe to pay (grace buffer elapsed) and, if so, runs
 * [awardTopGlobalCoinsOnce] for it. A no-op (logged, not an error) when
 * called during the grace window — the schedule can fire again later
 * (or, if manually re-triggered early for any reason, simply defers
 * rather than paying a stale/incomplete standing).
 *
 * @param {import("firebase-admin/firestore").Firestore} db
 * @param {number} nowMs epoch ms, a genuine server clock read.
 * @return {Promise<{skipped: true, reason: string}|{skipped: false,
 *   periodId: string, winners: object[]}>}
 */
async function runWeeklyPayoutIfDue(db, nowMs) {
  const periodId = closedPeriodId(nowMs);
  if (periodId === null) {
    logger.info("awardTopGlobalCoins: within grace buffer, deferring", {nowMs});
    return {skipped: true, reason: "grace-buffer"};
  }
  const winners = await awardTopGlobalCoinsOnce(db, periodId);
  return {skipped: false, periodId, winners};
}

exports.awardTopGlobalCoins = onSchedule(
    {schedule: "every monday 00:00", timeZone: "Asia/Jakarta"},
    async () => {
      const db = getFirestore();
      await runWeeklyPayoutIfDue(db, Date.now());
    },
);

module.exports.isoWeekId = isoWeekId;
module.exports.closedPeriodId = closedPeriodId;
module.exports.awardTopGlobalCoinsOnce = awardTopGlobalCoinsOnce;
module.exports.runWeeklyPayoutIfDue = runWeeklyPayoutIfDue;
module.exports.REWARDS = REWARDS;
module.exports.GRACE_BUFFER_MS = GRACE_BUFFER_MS;

const {onSchedule} = require("firebase-functions/v2/scheduler");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");

/**
 * The other way to earn coins besides topping up: placing 1st-3rd on
 * Skor Global, recalculated every week rather than granted once and
 * forgotten — the same "currently, not once" spirit the card-skin
 * achievement tier already uses for star totals (see `card_skins.dart`),
 * applied to the leaderboard instead of the battle ladder.
 *
 * **Runs with Admin SDK privileges, same reason `onBattleMatchConcluded`
 * does** — `coins` is frozen against every client write in
 * `firestore.rules` (`isAllowedPurchaseWrite`), so a scheduled function
 * running as an admin is the only thing besides `verifyPurchase` that
 * can ever move that field.
 *
 * **Ranking source**: `leaderboard/{uid}`, ordered by `globalScore` —
 * the exact same field and collection the app's own Skor Global tab
 * (`LeaderboardScreen`) sorts by, so "who this pays out to" and "who the
 * app shows in 1st/2nd/3rd" can never quietly disagree.
 *
 * **Idempotent per week, not per run.** A cold start, a retry, or a
 * manual re-trigger must not pay the same week out twice — `awardedFor`
 * (stored on `weeklyCoinAwards/{isoWeek}`) is checked and set inside one
 * transaction before any coin is granted, the same processed-token
 * shape `verifyPurchase` uses for a purchase token, just keyed by week
 * instead.
 */

const REWARDS = [500, 300, 100];

/** ISO week id like `2026-W34` — stable regardless of what day/time the
 * schedule actually fires on, so a retry on the same week is recognised
 * as the same week even if it lands a few minutes into the next day. */
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

async function awardTopGlobalCoinsOnce(db, weekId) {
  const awardRef = db.collection("weeklyCoinAwards").doc(weekId);
  const topSnap = await db
      .collection("leaderboard")
      .orderBy("globalScore", "desc")
      .limit(REWARDS.length)
      .get();

  const winners = topSnap.docs.map((doc, i) => ({
    uid: doc.id,
    reward: REWARDS[i],
  }));

  await db.runTransaction(async (tx) => {
    const awardSnap = await tx.get(awardRef);
    if (awardSnap.exists) return;
    tx.set(awardRef, {
      awardedAt: FieldValue.serverTimestamp(),
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

  return winners;
}

exports.awardTopGlobalCoins = onSchedule(
    {schedule: "every monday 00:00", timeZone: "Asia/Jakarta"},
    async () => {
      const db = getFirestore();
      const weekId = isoWeekId(new Date());
      await awardTopGlobalCoinsOnce(db, weekId);
    },
);

module.exports.isoWeekId = isoWeekId;
module.exports.awardTopGlobalCoinsOnce = awardTopGlobalCoinsOnce;
module.exports.REWARDS = REWARDS;

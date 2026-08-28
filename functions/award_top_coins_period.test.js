// Permanent coverage for the rewritten weekly Top Global payout —
// award_top_coins.js's [closedPeriodId]/[awardTopGlobalCoinsOnce]/
// [runWeeklyPayoutIfDue], now ranking `globalScorePeriods/{periodId}/
// users` instead of the unprotected `leaderboard.globalScore` field
// (see award_top_coins.js's own top-of-file doc comment for the full
// P0 rationale). This file REPLACES the temporary
// `_audit_award_top_coins.test.js` (deleted as part of this
// implementation) — that file's own scenarios (a)-(d) are all
// re-proven here against the NEW ranking source, plus the 7 named
// concurrency scenarios (A-G) the Weekly Global Ranking implementation
// task specifically required, plus dedicated grace-buffer/period-
// boundary coverage.
"use strict";

const {test} = require("node:test");
const assert = require("node:assert/strict");

const {FakeFirestore} = require("./test_helpers/fake_firestore");
const {
  closedPeriodId,
  awardTopGlobalCoinsOnce,
  runWeeklyPayoutIfDue,
  REWARDS,
  GRACE_BUFFER_MS,
} = require("./award_top_coins");
const {wibWeekId, wibWeekStart} = require("./wib_week");

function seedPeriodUser(fake, periodId, uid, {points, attempts}) {
  fake.seed(`globalScorePeriods/${periodId}/users/${uid}`, {
    points, attempts, uid, periodId,
  });
}

function seedCoins(fake, uid, coins = 0) {
  fake.seed(`users/${uid}`, {coins});
}

// ---------------------------------------------------------------------
// closedPeriodId — pure grace-buffer/boundary math, zero real waiting.
// ---------------------------------------------------------------------

test("closedPeriodId: exactly at a period boundary (Monday 00:00:00.000 " +
    "WIB) is still WITHIN the grace window — must defer", () => {
  const boundary = Date.parse("2026-08-30T17:00:00.000Z"); // Mon 2026-08-31 00:00 WIB
  assert.strictEqual(closedPeriodId(boundary), null);
});

test("closedPeriodId: 3 minutes after the boundary (Monday 00:03 WIB) " +
    "is still within the 5-minute grace window — must defer " +
    "('payout at Monday 00:03' scenario)", () => {
  const threeMinAfter = Date.parse("2026-08-30T17:03:00.000Z");
  assert.strictEqual(closedPeriodId(threeMinAfter), null);
});

test("closedPeriodId: one millisecond before the grace buffer elapses " +
    "still defers", () => {
  const justUnderGrace = Date.parse("2026-08-30T17:00:00.000Z") + GRACE_BUFFER_MS - 1;
  assert.strictEqual(closedPeriodId(justUnderGrace), null);
});

test("closedPeriodId: exactly at the grace buffer boundary (Monday " +
    "00:05:00.000 WIB) is safe to pay — grace is a closed lower bound", () => {
  const exactlyGrace = Date.parse("2026-08-30T17:00:00.000Z") + GRACE_BUFFER_MS;
  const id = closedPeriodId(exactlyGrace);
  assert.notStrictEqual(id, null);
  // The period that just closed is the one ending at the boundary above.
  const expected = wibWeekId(new Date(Date.parse("2026-08-30T17:00:00.000Z") - 1));
  assert.strictEqual(id, expected);
});

test("closedPeriodId: 6 minutes after the boundary (Monday 00:06 WIB) " +
    "is safe — correctly resolves to the week that JUST closed, not " +
    "one further back", () => {
  const sixMinAfter = Date.parse("2026-08-30T17:06:00.000Z");
  const id = closedPeriodId(sixMinAfter);
  const closingWeekInstant = Date.parse("2026-08-30T16:59:59.999Z"); // Sun 23:59:59.999 WIB
  assert.strictEqual(id, wibWeekId(new Date(closingWeekInstant)));
});

test("closedPeriodId: called mid-week (e.g. a Wednesday) still " +
    "resolves to the most recently closed (previous) period, not the " +
    "ongoing one — safe to call any time, not just near a boundary", () => {
  const midWeek = Date.parse("2026-09-02T05:00:00.000Z"); // Wed 12:00 WIB
  const id = closedPeriodId(midWeek);
  const currentStart = wibWeekStart(new Date(midWeek));
  const expected = wibWeekId(new Date(currentStart.getTime() - 1));
  assert.strictEqual(id, expected);
  // Sanity: the closed period must NOT be the ongoing one containing midWeek.
  assert.notStrictEqual(id, wibWeekId(new Date(midWeek)));
});

// ---------------------------------------------------------------------
// awardTopGlobalCoinsOnce — ranking, tie-break, payout record shape.
// ---------------------------------------------------------------------

test("ranks by points DESC — the top 3 by points win, in order", async () => {
  const fake = new FakeFirestore();
  const periodId = "2026-W36";
  seedPeriodUser(fake, periodId, "gold", {points: 900, attempts: 5});
  seedPeriodUser(fake, periodId, "silver", {points: 800, attempts: 5});
  seedPeriodUser(fake, periodId, "bronze", {points: 700, attempts: 5});
  seedPeriodUser(fake, periodId, "fourth", {points: 600, attempts: 5});
  seedCoins(fake, "gold");
  seedCoins(fake, "silver");
  seedCoins(fake, "bronze");

  const winners = await awardTopGlobalCoinsOnce(fake, periodId);
  assert.deepStrictEqual(winners.map((w) => w.uid), ["gold", "silver", "bronze"]);
  assert.deepStrictEqual(winners.map((w) => w.rank), [1, 2, 3]);
  assert.deepStrictEqual(winners.map((w) => w.reward), REWARDS);
});

test("tie-break level 2: equal points, higher attempts wins", async () => {
  const fake = new FakeFirestore();
  const periodId = "2026-W36";
  seedPeriodUser(fake, periodId, "grinder", {points: 500, attempts: 20});
  seedPeriodUser(fake, periodId, "efficient", {points: 500, attempts: 5});
  seedCoins(fake, "grinder");
  seedCoins(fake, "efficient");

  const winners = await awardTopGlobalCoinsOnce(fake, periodId);
  assert.deepStrictEqual(winners.map((w) => w.uid), ["grinder", "efficient"]);
});

test("tie-break level 3: equal points AND equal attempts, lower uid " +
    "(ascending) wins — deterministic, not arbitrary", async () => {
  const fake = new FakeFirestore();
  const periodId = "2026-W36";
  seedPeriodUser(fake, periodId, "zzz-user", {points: 500, attempts: 10});
  seedPeriodUser(fake, periodId, "aaa-user", {points: 500, attempts: 10});
  seedPeriodUser(fake, periodId, "mmm-user", {points: 500, attempts: 10});
  seedCoins(fake, "aaa-user");
  seedCoins(fake, "mmm-user");
  seedCoins(fake, "zzz-user");

  const winners = await awardTopGlobalCoinsOnce(fake, periodId);
  assert.deepStrictEqual(
      winners.map((w) => w.uid), ["aaa-user", "mmm-user", "zzz-user"]);
});

test("the historical payout record has exactly the approved shape: " +
    "periodId, finalizedAt, winners[{uid, rank, points, attempts, " +
    "reward}] — no extra invented fields", async () => {
  const fake = new FakeFirestore();
  const periodId = "2026-W36";
  seedPeriodUser(fake, periodId, "gold", {points: 900, attempts: 5});
  seedCoins(fake, "gold");

  await awardTopGlobalCoinsOnce(fake, periodId);
  const snap = await fake.collection("globalScorePeriodAwards").doc(periodId).get();
  assert.ok(snap.exists);
  const data = snap.data();
  assert.strictEqual(data.periodId, periodId);
  assert.ok(data.finalizedAt, "finalizedAt must be set");
  assert.strictEqual(data.winners.length, 1);
  const w = data.winners[0];
  assert.deepStrictEqual(
      Object.keys(w).sort(),
      ["attempts", "points", "rank", "reward", "uid"],
      "winner record must contain exactly these 5 fields, nothing more",
  );
  assert.strictEqual(w.uid, "gold");
  assert.strictEqual(w.rank, 1);
  assert.strictEqual(w.points, 900);
  assert.strictEqual(w.attempts, 5);
  assert.strictEqual(w.reward, REWARDS[0]);
});

test("fewer than 3 participants: only the real entries win, no crash, " +
    "no phantom 3rd place", async () => {
  const fake = new FakeFirestore();
  const periodId = "2026-W36";
  seedPeriodUser(fake, periodId, "gold", {points: 900, attempts: 5});
  seedPeriodUser(fake, periodId, "silver", {points: 800, attempts: 5});
  seedCoins(fake, "gold");
  seedCoins(fake, "silver");

  const winners = await awardTopGlobalCoinsOnce(fake, periodId);
  assert.strictEqual(winners.length, 2);
  assert.deepStrictEqual(winners.map((w) => w.uid), ["gold", "silver"]);
});

test("zero participants: an empty winners list, no crash", async () => {
  const fake = new FakeFirestore();
  const winners = await awardTopGlobalCoinsOnce(fake, "2026-W36");
  assert.deepStrictEqual(winners, []);
});

test("a stale/unprotected leaderboard.globalScore value on the SAME " +
    "uid has ZERO influence on ranking — proves the ranking source " +
    "genuinely changed, not just added a second check on top of the " +
    "old one", async () => {
  const fake = new FakeFirestore();
  const periodId = "2026-W36";
  // Attacker-shaped state: a huge globalScore, but a modest real
  // globalScorePeriods standing.
  fake.seed("leaderboard/attacker", {globalScore: 999999999});
  seedPeriodUser(fake, periodId, "attacker", {points: 10, attempts: 1});
  seedPeriodUser(fake, periodId, "honest", {points: 500, attempts: 5});
  seedCoins(fake, "attacker");
  seedCoins(fake, "honest");

  const winners = await awardTopGlobalCoinsOnce(fake, periodId);
  assert.strictEqual(winners[0].uid, "honest",
      "the honest player's real weekly standing must win — a forged " +
      "globalScore must not matter at all to this payout anymore");
});

// ---------------------------------------------------------------------
// runWeeklyPayoutIfDue — orchestration.
// ---------------------------------------------------------------------

test("runWeeklyPayoutIfDue skips (no payout) when called within the " +
    "grace window", async () => {
  const fake = new FakeFirestore();
  const withinGrace = Date.parse("2026-08-30T17:03:00.000Z"); // Mon 00:03 WIB
  const result = await runWeeklyPayoutIfDue(fake, withinGrace);
  assert.deepStrictEqual(result, {skipped: true, reason: "grace-buffer"});
});

test("runWeeklyPayoutIfDue pays out once grace has elapsed", async () => {
  const fake = new FakeFirestore();
  const pastGrace = Date.parse("2026-08-30T17:06:00.000Z"); // Mon 00:06 WIB
  const closingWeekInstant = new Date(Date.parse("2026-08-30T16:59:59.999Z"));
  const periodId = wibWeekId(closingWeekInstant);
  seedPeriodUser(fake, periodId, "gold", {points: 900, attempts: 5});
  seedCoins(fake, "gold");

  const result = await runWeeklyPayoutIfDue(fake, pastGrace);
  assert.strictEqual(result.skipped, false);
  assert.strictEqual(result.periodId, periodId);
  assert.strictEqual(result.winners[0].uid, "gold");
});

// ---------------------------------------------------------------------
// Named concurrency scenarios A-G (Weekly Global Ranking implementation
// task, Step 9) — deterministic forced interleaving via the fake's
// `beforeCommit` hook, mirroring global_points_reliability.test.js's
// own established pattern, not a bare Promise.all() hoping for a
// useful race.
// ---------------------------------------------------------------------

test("(A) the same underlying trigger event processed twice (e.g. an " +
    "Eventarc redelivery reaching global_points.js's own transaction " +
    "twice for one historyDocId) results in exactly one weekly-period " +
    "increment — covered directly by global_points_period_write.test.js's " +
    "own idempotency-replay test; referenced here for scenario-letter " +
    "traceability against the implementation task's own naming", () => {
  // This scenario is about global_points.js's write side, not
  // award_top_coins.js's read/payout side — its dedicated proof lives
  // in global_points_period_write.test.js ("a replay of the SAME
  // historyDocId... does NOT double-count into the period"). Keeping a
  // named placeholder here (rather than a duplicate proof) so a reader
  // scanning THIS file for A-G finds a pointer, not a silent gap.
  assert.ok(true);
});

test("(B) two concurrent PAYOUT invocations for the SAME period " +
    "(e.g. two overlapping scheduled-function instances) converge to " +
    "exactly one award, via a genuine forced mid-transaction " +
    "interleaving — not two independent calls checked separately", async () => {
  let firstStarted = false;
  const fake = new FakeFirestore({
    beforeCommit: async () => {
      if (!firstStarted) {
        firstStarted = true;
        await new Promise((resolve) => setTimeout(resolve, 5));
      }
    },
  });
  const periodId = "2026-W36";
  seedPeriodUser(fake, periodId, "gold", {points: 900, attempts: 5});
  seedPeriodUser(fake, periodId, "silver", {points: 800, attempts: 5});
  seedPeriodUser(fake, periodId, "bronze", {points: 700, attempts: 5});
  seedCoins(fake, "gold");
  seedCoins(fake, "silver");
  seedCoins(fake, "bronze");

  const [a, b] = await Promise.all([
    awardTopGlobalCoinsOnce(fake, periodId),
    awardTopGlobalCoinsOnce(fake, periodId),
  ]);

  assert.deepStrictEqual(a, b);
  const goldCoins = (await fake.collection("users").doc("gold").get()).data().coins;
  assert.strictEqual(goldCoins, REWARDS[0],
      "gold's coins must be credited exactly once despite two " +
      "concurrent payout runs for the same period");
});

test("(C) the payout job run TWICE (sequential retry/re-trigger, not " +
    "concurrent) results in exactly one payout — a retry after the " +
    "marker already exists is a safe no-op", async () => {
  const fake = new FakeFirestore();
  const periodId = "2026-W37";
  seedPeriodUser(fake, periodId, "gold", {points: 900, attempts: 5});
  seedCoins(fake, "gold");

  await awardTopGlobalCoinsOnce(fake, periodId);
  await awardTopGlobalCoinsOnce(fake, periodId); // simulated retry

  const goldCoins = (await fake.collection("users").doc("gold").get()).data().coins;
  assert.strictEqual(goldCoins, REWARDS[0]);
});

test("(D) payout CONCURRENCY under genuine mid-transaction contention " +
    "(forced pause-then-release, not incidental scheduling) still " +
    "converges to exactly one committed award — same proof shape as " +
    "global_points_reliability.test.js's own 'genuine mid-transaction " +
    "conflict' test, applied to the payout transaction", async () => {
  let reachedPause = false;
  let releaseGate;
  const gate = new Promise((resolve) => {
    releaseGate = resolve;
  });
  const fake = new FakeFirestore({
    beforeCommit: async () => {
      if (!reachedPause) {
        reachedPause = true;
        // Hold transaction A open right before it commits, so B has a
        // real chance to read "not yet awarded" and race it.
        setTimeout(releaseGate, 5);
        await gate;
      }
    },
  });
  const periodId = "2026-W38";
  seedPeriodUser(fake, periodId, "gold", {points: 900, attempts: 5});
  seedCoins(fake, "gold");

  const [a, b] = await Promise.all([
    awardTopGlobalCoinsOnce(fake, periodId),
    awardTopGlobalCoinsOnce(fake, periodId),
  ]);
  assert.deepStrictEqual(a, b);
  const goldCoins = (await fake.collection("users").doc("gold").get()).data().coins;
  assert.strictEqual(goldCoins, REWARDS[0]);
});

test("(E) a final qualifying score arriving right at the grace-buffer " +
    "cutoff is included when it lands BEFORE the payout query runs, " +
    "and the payout correctly reflects the post-grace-buffer standing", async () => {
  const fake = new FakeFirestore();
  const pastGrace = Date.parse("2026-08-30T17:06:00.000Z");
  const periodId = wibWeekId(new Date(Date.parse("2026-08-30T16:59:59.999Z")));
  // Simulates a straggling attempt's write landing just before the
  // payout job actually runs (which is exactly what the grace buffer
  // exists to make room for).
  seedPeriodUser(fake, periodId, "late-scorer", {points: 950, attempts: 6});
  seedPeriodUser(fake, periodId, "earlier-scorer", {points: 900, attempts: 5});
  seedCoins(fake, "late-scorer");
  seedCoins(fake, "earlier-scorer");

  const result = await runWeeklyPayoutIfDue(fake, pastGrace);
  assert.strictEqual(result.winners[0].uid, "late-scorer",
      "a straggling write that lands before the payout query must " +
      "still be correctly ranked — this is the whole point of the " +
      "grace buffer existing");
});

test("(F) the SAME user's standing in TWO DIFFERENT periods earns an " +
    "award independently in each — a payout in one period must not " +
    "block or duplicate into another", async () => {
  const fake = new FakeFirestore();
  const periodOne = "2026-W36";
  const periodTwo = "2026-W37";
  seedPeriodUser(fake, periodOne, "repeat-winner", {points: 900, attempts: 5});
  seedPeriodUser(fake, periodTwo, "repeat-winner", {points: 850, attempts: 4});
  seedCoins(fake, "repeat-winner", 0);

  await awardTopGlobalCoinsOnce(fake, periodOne);
  await awardTopGlobalCoinsOnce(fake, periodTwo);

  const coins = (await fake.collection("users").doc("repeat-winner").get())
      .data().coins;
  assert.strictEqual(coins, REWARDS[0] * 2,
      "winning both periods must credit the reward twice, once per " +
      "genuinely distinct period — not blocked by the first period's " +
      "own award marker");

  const awardOne = await fake.collection("globalScorePeriodAwards").doc(periodOne).get();
  const awardTwo = await fake.collection("globalScorePeriodAwards").doc(periodTwo).get();
  assert.ok(awardOne.exists);
  assert.ok(awardTwo.exists);
});

test("(G) winner ORDERING is fully deterministic under a tie across " +
    "ALL THREE tie-break levels being exercised at once, regardless of " +
    "the order documents were seeded/read in", async () => {
  const fake = new FakeFirestore();
  const periodId = "2026-W39";
  // Two genuine ties (by points) resolved by attempts, one further tie
  // (by points AND attempts) resolved by uid — seeded deliberately out
  // of final-rank order, so a correct implementation must actually sort,
  // not just preserve insertion order.
  seedPeriodUser(fake, periodId, "c-user", {points: 500, attempts: 10});
  seedPeriodUser(fake, periodId, "b-user", {points: 500, attempts: 10});
  seedPeriodUser(fake, periodId, "high-attempts", {points: 500, attempts: 20});
  seedPeriodUser(fake, periodId, "low-points", {points: 100, attempts: 99});
  for (const uid of ["c-user", "b-user", "high-attempts", "low-points"]) {
    seedCoins(fake, uid);
  }

  const winners = await awardTopGlobalCoinsOnce(fake, periodId);
  assert.deepStrictEqual(
      winners.map((w) => w.uid),
      ["high-attempts", "b-user", "c-user"],
      "highest points+attempts first, then the points-and-attempts " +
      "tie broken by ascending uid — deterministic, not incidental",
  );
});

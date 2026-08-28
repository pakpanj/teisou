// Migration/cutover safety — Weekly Global Ranking implementation, Step
// 13: "the old payout path must be retired or redirected safely as part
// of this implementation... this must be explicitly tested." Two
// distinct claims are proven here, not just asserted in a doc comment:
//
//   1. STRUCTURALLY — the deployed award_top_coins.js source no longer
//      contains any code path that reads leaderboard.globalScore or
//      writes to the OLD weeklyCoinAwards collection at all. There is
//      only one payout function now, not two coexisting ones — a
//      source-level scan, the same "prove an absence, don't just trust
//      a rewrite" discipline this codebase already uses elsewhere (see
//      Dart's own coach_wiring_test.dart / no_hardcoded_ui_strings_test.dart
//      for the same pattern applied to different concerns).
//   2. FUNCTIONALLY — a pre-existing OLD-scheme weeklyCoinAwards marker
//      (simulating a real historical write from before this deployment)
//      has zero influence on the NEW globalScorePeriodAwards payout for
//      the "same" real week — the two collections are provably
//      independent, so no accidental collision between an old marker
//      id and a new one (even though both use the same YYYY-Www STRING
//      FORMAT, see award_top_coins.js's own doc comment on why a shared
//      collection name was deliberately avoided) can silently block or
//      duplicate a payout.
"use strict";

const {test} = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const {FakeFirestore} = require("./test_helpers/fake_firestore");
const {awardTopGlobalCoinsOnce, REWARDS} = require("./award_top_coins");

test("STRUCTURAL: award_top_coins.js's source no longer references " +
    "the OLD ranking source (leaderboard collection / globalScore " +
    "field) anywhere in its live code — only in doc-comment prose " +
    "explaining the history, which mentions the words but never as " +
    "executable code", () => {
  const source = fs.readFileSync(
      path.join(__dirname, "award_top_coins.js"), "utf8",
  );

  // Strip out comment blocks (/* ... */ and // ...) before scanning —
  // the doc comments legitimately discuss the old field/collection by
  // name (that's the whole point of documenting the fix honestly), only
  // EXECUTABLE code referencing them would be a real regression.
  const withoutBlockComments = source.replace(/\/\*[\s\S]*?\*\//g, "");
  const withoutComments = withoutBlockComments
      .split("\n")
      .map((line) => line.replace(/\/\/.*$/, ""))
      .join("\n");

  assert.ok(
      !withoutComments.includes('collection("leaderboard")'),
      "no executable code may read the leaderboard collection for " +
      "ranking purposes anymore",
  );
  assert.ok(
      !withoutComments.includes(".globalScore"),
      "no executable code may reference globalScore anymore",
  );
  assert.ok(
      !withoutComments.includes('collection("weeklyCoinAwards")'),
      "no executable code may write to the OLD weeklyCoinAwards " +
      "marker collection anymore — the live payout uses " +
      "globalScorePeriodAwards exclusively",
  );
  assert.ok(
      withoutComments.includes('collection("globalScorePeriods")'),
      "sanity: the NEW ranking source must actually be present",
  );
  assert.ok(
      withoutComments.includes('collection("globalScorePeriodAwards")'),
      "sanity: the NEW marker collection must actually be present",
  );
});

test("FUNCTIONAL: a pre-existing OLD-scheme weeklyCoinAwards marker " +
    "for what would be 'the same real week' under the old isoWeekId " +
    "scheme has ZERO effect on the NEW payout — no accidental " +
    "collision, no accidental skip, no accidental double-write into " +
    "the old collection", async () => {
  const fake = new FakeFirestore();
  const periodId = "2026-W36";

  // Simulate the OLD scheduled function having already run and paid
  // out under the old scheme, before this deployment — same STRING
  // FORMAT id by construction (both schemes use YYYY-Www), which is
  // exactly the scenario a shared collection name would have put at
  // risk.
  fake.seed(`weeklyCoinAwards/${periodId}`, {
    awardedAt: new Date(),
    winners: [{uid: "old-winner", reward: REWARDS[0]}],
  });
  fake.seed("leaderboard/old-winner", {globalScore: 999});

  fake.seed(`globalScorePeriods/${periodId}/users/new-winner`, {
    points: 900, attempts: 5, uid: "new-winner", periodId,
  });
  fake.seed("users/new-winner", {coins: 0});

  const winners = await awardTopGlobalCoinsOnce(fake, periodId);

  assert.strictEqual(winners.length, 1);
  assert.strictEqual(winners[0].uid, "new-winner",
      "the NEW payout must run normally and rank the real " +
      "globalScorePeriods participant — completely unaffected by the " +
      "pre-existing OLD marker sharing the same string id");

  const newAward = await fake
      .collection("globalScorePeriodAwards").doc(periodId).get();
  assert.ok(newAward.exists,
      "the new payout must have written its OWN marker, not been " +
      "blocked by the old marker's existence under a different " +
      "collection name");

  const newWinnerCoins =
    (await fake.collection("users").doc("new-winner").get()).data().coins;
  assert.strictEqual(newWinnerCoins, REWARDS[0],
      "the new winner must actually be paid, not silently skipped");

  // The OLD marker/old-winner's coins must be completely untouched —
  // no double-write, no re-processing of stale state.
  const oldMarkerStillIntact = await fake
      .collection("weeklyCoinAwards").doc(periodId).get();
  assert.deepStrictEqual(
      oldMarkerStillIntact.data().winners,
      [{uid: "old-winner", reward: REWARDS[0]}],
      "the old marker document must be left exactly as it was — this " +
      "run must never touch the old collection at all",
  );
  const oldWinnerCoins = await fake.collection("users").doc("old-winner").get();
  assert.strictEqual(oldWinnerCoins.exists, false,
      "old-winner was never seeded a users/ doc by this test and the " +
      "new payout must not have created one either — proves the new " +
      "run never iterated or touched anything from the old marker");
});

/**
 * Regression coverage for battle_stars.js — the Card Game Mode star
 * ladder (promotion, demotion, loss protection, streak bonus, season
 * carry). Uses Node's built-in test runner, same as the other two.
 *
 * Run from functions/: `node --test`
 *
 * The ladder is worth testing this closely because none of it is
 * visible in a screenshot: a wrong floor or an off-by-one in the
 * division arithmetic looks exactly like a correct one until a player
 * happens to lose at 0 stars, weeks later.
 */

const {test} = require("node:test");
const assert = require("node:assert");

const {
  TIERS,
  STARS_PER_DIVISION,
  DIVISIONS_PER_TIER,
  tierBase,
  totalStars,
  rankFromTotal,
  seasonForDate,
  rollOverIfNewSeason,
  applyOutcome,
  readRank,
  outcomeFor,
} = require("./battle_stars")._internal;

function rank(tier, division, stars, extra) {
  return Object.assign({tier, division, stars, season: 1, winStreak: 0},
      extra || {});
}

/** Plays [outcomes] in order from [start], returning the final rank. */
function play(start, outcomes) {
  let current = start;
  for (const outcome of outcomes) {
    current = applyOutcome(current, outcome).rank;
  }
  return current;
}

// --- The ladder's shape ---

test("the whole climb is 90 stars, as the notes' table totals", () => {
  assert.strictEqual(tierBase("emerald"), 90);
  assert.strictEqual(tierBase("bronze"), 0);
  assert.strictEqual(tierBase("silver"), 15);
  assert.strictEqual(tierBase("gold"), 35);
  assert.strictEqual(tierBase("diamond"), 60);
});

test("totalStars and rankFromTotal round-trip across the whole ladder",
    () => {
      for (let total = 0; total <= 120; total++) {
        const back = totalStars(
            Object.assign(rankFromTotal(total), {season: 1, winStreak: 0}),
        );
        assert.strictEqual(back, total, `total ${total}`);
      }
    });

test("a fresh player is Bronze V with no stars", () => {
  assert.deepStrictEqual(rankFromTotal(0),
      {tier: "bronze", division: 5, stars: 0});
});

test("divisions run V down to I within a tier", () => {
  // Bronze is 3 stars per division, so every 3rd star is a division.
  assert.strictEqual(rankFromTotal(2).division, 5);
  assert.strictEqual(rankFromTotal(3).division, 4);
  assert.strictEqual(rankFromTotal(12).division, 1);
  assert.strictEqual(rankFromTotal(14).stars, 2); // Bronze I, 2/3
});

test("filling division I promotes to the next tier at division V", () => {
  const promoted = applyOutcome(rank("bronze", 1, 2), "win").rank;
  assert.strictEqual(promoted.tier, "silver");
  assert.strictEqual(promoted.division, 5);
  assert.strictEqual(promoted.stars, 0);
});

test("emerald accumulates without divisions", () => {
  const deep = rankFromTotal(90 + 47);
  assert.strictEqual(deep.tier, "emerald");
  assert.strictEqual(deep.stars, 47);
  // and it keeps going rather than capping
  assert.strictEqual(applyOutcome(
      rank("emerald", 1, 47), "win").rank.stars, 48);
});

// --- Wins, losses, draws ---

test("a win is +1 and a draw moves nothing", () => {
  assert.strictEqual(applyOutcome(rank("gold", 5, 1), "win").delta, 1);
  assert.strictEqual(applyOutcome(rank("gold", 5, 1), "draw").delta, 0);
});

test("a loss costs a star from Gold up", () => {
  const result = applyOutcome(rank("gold", 5, 3), "loss");
  assert.strictEqual(result.delta, -1);
  assert.strictEqual(result.rank.stars, 2);
});

test("Bronze and Silver lose nothing on a loss", () => {
  for (const tier of ["bronze", "silver"]) {
    const result = applyOutcome(rank(tier, 3, 1), "loss");
    assert.strictEqual(result.delta, 0, tier);
    assert.deepStrictEqual(
        [result.rank.tier, result.rank.division, result.rank.stars],
        [tier, 3, 1],
        tier,
    );
  }
});

test("losing at 0 stars drops one division, landing near its top", () => {
  const result = applyOutcome(rank("gold", 4, 0), "loss");
  assert.strictEqual(result.rank.division, 5);
  assert.strictEqual(result.rank.stars, STARS_PER_DIVISION.gold - 1);
});

test("a tier once reached is never lost", () => {
  // Gold V with nothing banked: ten straight losses cannot reach Silver.
  const floored = play(rank("gold", 5, 0), Array(10).fill("loss"));
  assert.strictEqual(floored.tier, "gold");
  assert.strictEqual(floored.division, 5);
  assert.strictEqual(floored.stars, 0);
});

test("a loss absorbed by the floor reports a delta of 0, not -1", () => {
  // The result screen shows this number; claiming a star was lost when
  // the standing did not move would be a lie to the player.
  assert.strictEqual(applyOutcome(rank("gold", 5, 0), "loss").delta, 0);
});

// --- Streak bonus ---

test("the third consecutive win is worth 2, the first two are worth 1",
    () => {
      let current = rank("gold", 5, 0);
      const deltas = [];
      for (let i = 0; i < 4; i++) {
        const applied = applyOutcome(current, "win");
        deltas.push(applied.delta);
        current = applied.rank;
      }
      // Fourth win keeps the bonus — the streak is a state, not a
      // one-off reward on exactly the third win.
      assert.deepStrictEqual(deltas, [1, 1, 2, 2]);
    });

test("a loss breaks the streak; a draw does not", () => {
  const afterLoss = play(rank("gold", 5, 0), ["win", "win", "loss"]);
  assert.strictEqual(afterLoss.winStreak, 0);

  const afterDraw = play(rank("gold", 5, 0), ["win", "win", "draw"]);
  assert.strictEqual(afterDraw.winStreak, 2);
  // ...so the next win is still the third of the streak, worth 2.
  assert.strictEqual(applyOutcome(afterDraw, "win").delta, 2);
});

test("Bronze to Gold takes 35 wins regardless of losses", () => {
  // The notes' own headline promise for loss protection.
  let current = rank("bronze", 5, 0);
  let wins = 0;
  while (current.tier !== "gold") {
    current = applyOutcome(current, "win").rank;
    wins++;
    current = applyOutcome(current, "loss").rank; // freely interleaved
    assert.ok(wins < 100, "never reached Gold");
  }
  assert.strictEqual(wins, 35);
});

// --- Seasons ---

test("seasons are two months long, counted from Jan-Feb 2026", () => {
  assert.strictEqual(seasonForDate(new Date(Date.UTC(2026, 0, 1))), 1);
  assert.strictEqual(seasonForDate(new Date(Date.UTC(2026, 1, 28))), 1);
  assert.strictEqual(seasonForDate(new Date(Date.UTC(2026, 2, 1))), 2);
  assert.strictEqual(seasonForDate(new Date(Date.UTC(2026, 11, 31))), 6);
  assert.strictEqual(seasonForDate(new Date(Date.UTC(2027, 0, 1))), 7);
});

test("a clock set before the epoch clamps to season 1, never negative",
    () => {
      assert.strictEqual(seasonForDate(new Date(Date.UTC(2019, 5, 1))), 1);
    });

test("a new season carries 70% of the stars climbed, and rolls back the "
    + "standing accordingly", () => {
  // Diamond V, 0 stars = 60 climbed; 70% = 42 = Gold II, 2/5.
  const carried = rollOverIfNewSeason(rank("diamond", 5, 0), 2);
  assert.strictEqual(carried.season, 2);
  assert.strictEqual(totalStars(carried), 42);
  assert.strictEqual(carried.tier, "gold");
});

test("the season rollover clears the win streak", () => {
  const carried = rollOverIfNewSeason(
      rank("gold", 5, 2, {winStreak: 5}), 3);
  assert.strictEqual(carried.winStreak, 0);
});

test("a rank already in the current season is left untouched", () => {
  const current = rank("gold", 3, 2, {season: 4, winStreak: 2});
  assert.deepStrictEqual(rollOverIfNewSeason(current, 4), current);
  // and an impossible future season is not "rolled back" either
  assert.deepStrictEqual(rollOverIfNewSeason(current, 3), current);
});

test("carrying over never falls below Bronze V", () => {
  const carried = rollOverIfNewSeason(rank("bronze", 5, 0, {season: 1}), 2);
  assert.strictEqual(totalStars(carried), 0);
  assert.strictEqual(carried.tier, "bronze");
});

// --- Reading what is actually stored ---

test("a player who has never played reads as a fresh Bronze V", () => {
  assert.deepStrictEqual(readRank(undefined),
      {tier: "bronze", division: 5, stars: 0, season: 1, winStreak: 0});
  assert.deepStrictEqual(readRank({}),
      {tier: "bronze", division: 5, stars: 0, season: 1, winStreak: 0});
});

test("a corrupt or unknown tier falls back to Bronze rather than "
    + "propagating", () => {
  // Reached only if something wrote nonsense; the ladder must still
  // resolve rather than throwing inside a transaction.
  const parsed = readRank({cardGameRank: {tier: "platinum", stars: 2}});
  assert.strictEqual(parsed.tier, "bronze");
  assert.strictEqual(parsed.division, DIVISIONS_PER_TIER);
});

test("outcome is read from the match result, per player", () => {
  assert.strictEqual(outcomeFor("a", "a"), "win");
  assert.strictEqual(outcomeFor("b", "a"), "loss");
  assert.strictEqual(outcomeFor("a", "draw"), "draw");
});

test("every tier the app knows about has a place on the ladder", () => {
  // Guards the pairing between this file and card_game_rank.dart: a
  // tier added there without a STARS_PER_DIVISION entry here would
  // silently compute NaN totals.
  for (const tier of TIERS) {
    if (tier === "emerald") continue;
    assert.strictEqual(typeof STARS_PER_DIVISION[tier], "number", tier);
  }
});

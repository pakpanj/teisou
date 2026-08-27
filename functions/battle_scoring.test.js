/**
 * Regression coverage for the RomajiConverter port in battle_scoring.js
 * — mirrors test/romaji_converter_test.dart's cases exactly, since the
 * whole point of porting is staying in step with the Dart original
 * (see battle_scoring.js's own doc comment on why two copies exist at
 * all). Uses Node's built-in test runner (`node --test`), no extra
 * dependency needed — this is the first test this functions/ folder
 * has ever had.
 *
 * Run from functions/: `node --test`
 */

const {test} = require("node:test");
const assert = require("node:assert");

const {toRomaji, resolveCorrectRomaji, scoreAnswer} =
  require("./battle_scoring")._internal;
const {FakeFirestore} = require("./test_helpers/fake_firestore");

test("plain base kana convert one-to-one", () => {
  assert.strictEqual(toRomaji("あか"), "aka");
  assert.strictEqual(toRomaji("さくら"), "sakura");
});

test("youon converts as one mora, not per-character garbage", () => {
  assert.strictEqual(toRomaji("きょう"), "kyou");
  assert.strictEqual(toRomaji("しゃしん"), "shashin");
});

test("sokuon doubles the following mora's leading consonant", () => {
  assert.strictEqual(toRomaji("がっこう"), "gakkou");
  assert.strictEqual(toRomaji("きっぷ"), "kippu");
});

test("sokuon followed by youon resolves through the two-character match", () => {
  assert.strictEqual(toRomaji("いっしょ"), "issho");
});

test("katakana sokuon (ッ) is handled the same way as hiragana っ", () => {
  assert.strictEqual(toRomaji("ポケット"), "poketto");
  assert.strictEqual(toRomaji("ロケット"), "roketto");
});

test("sokuon at the end of a string is dropped rather than crashing", () => {
  assert.strictEqual(toRomaji("がっ"), "ga");
});

test("a character with no dataset entry passes through unchanged", () => {
  assert.strictEqual(toRomaji("学生"), "学生");
});

test("resolveCorrectRomaji resolves a real kana id", () => {
  const resolved = resolveCorrectRomaji("hiragana_ka");
  assert.ok(resolved);
  assert.strictEqual(resolved.answerInHiragana, false);
  assert.strictEqual(resolved.correctRomaji, "ka");
});

test("resolveCorrectRomaji resolves a real kanji-word id, marked "+
  "answerInHiragana", () => {
  // Any real "{kanjiId}|{word}" pair from kanji_word_readings.json —
  // 学生 (gakusei) under 学 is the exact example NOTES_CARD_GAME_MODE.md
  // itself cites for this schema.
  const resolved = resolveCorrectRomaji("kanji_gaku|学生");
  assert.ok(resolved, "expected kanji_gaku|学生 to resolve — if this " +
    "fails, re-check the id against kanji_word_readings.json");
  assert.strictEqual(resolved.answerInHiragana, true);
  assert.strictEqual(resolved.correctRomaji, "gakusei");
});

test("resolveCorrectRomaji returns null for an id that doesn't exist", () => {
  assert.strictEqual(resolveCorrectRomaji("nonexistent_id"), null);
  assert.strictEqual(
      resolveCorrectRomaji("kanji_gaku|nonexistent_word"), null,
  );
});

// =====================================================================
// scoreAnswer's conclusion self-heal — C2 STAGE 2 blocker fix
//
// Exercises the real, unmodified `scoreAnswer` directly (via the
// `dbInstance` parameter added for exactly this purpose) against
// `FakeFirestore`, rather than a hand-written mirror — per the review
// request's own "test production code directly when DI makes it
// possible" instruction. `resolveCorrectRomaji`/`toRomaji` still run for
// real here too (using a genuine `kana_data.json` id), so this is the
// real card-resolution and correctness path, not a stand-in for it.
// =====================================================================

const PLAYER_A = "uidA1234567890123456789012";
const PLAYER_B = "uidB1234567890123456789012";
const MAIN_PHASE_ROUNDS = 20; // mirrors battle_scoring.js's own constant
const TOTAL_ROUNDS = 40; // mirrors battle_scoring.js's own constant

// A real, resolvable card id (see the "resolveCorrectRomaji resolves a
// real kana id" test above for the same id family) — its own correct
// romaji is irrelevant to most of these tests since they only ever
// submit "" (always wrong, exactly what an abandonment forfeit writes),
// but `scoreAnswer` returns early if the card doesn't resolve at all, so
// a fake `"card_0"`-style id (as `battle_abandonment_sweep.test.js` uses
// for its own, unrelated purposes) would silently break every test here.
const VALID_CARD = "hiragana_a";

function turnOrderFor(rounds) {
  return Array.from({length: rounds}, (_, i) => ({
    round: i,
    deckOwnerUid: i % 2 === 0 ? PLAYER_A : PLAYER_B,
    cardId: VALID_CARD,
  }));
}

function seedFullDeckMatch(db, matchId, overrides = {}) {
  db.seed(`battleMatches/${matchId}`, {
    players: [PLAYER_A, PLAYER_B],
    status: "active",
    turnOrder: turnOrderFor(TOTAL_ROUNDS),
    officialScore: {[PLAYER_A]: 0, [PLAYER_B]: 0},
    result: null,
    scoredRounds: {},
    ...overrides,
  });
}

/** Scores round [n] as a forfeit — the identical shape both C1's
 * client-side timeout and Stage 2's sweep write (`text: ""`). */
function forfeit(matchId, round, db) {
  return scoreAnswer(matchId, round, "", db);
}

async function scoreInOrder(matchId, order, db) {
  for (const round of order) await forfeit(matchId, round, db);
}

// --- 1/2. Baseline: creation order and the review's own scramble ---

test("1. normal creation order 0..39, all forfeited: draw, exactly once", async () => {
  const db = new FakeFirestore();
  seedFullDeckMatch(db, "m1");
  await scoreInOrder("m1", Array.from({length: TOTAL_ROUNDS}, (_, i) => i), db);

  const match = await db.collection("battleMatches").doc("m1").get();
  assert.strictEqual(match.data().status, "finished");
  assert.strictEqual(match.data().result, "draw");
});

test("2. the review's own scramble (25,20,24,21,23,22,26..39) after 0..19: draw", async () => {
  const db = new FakeFirestore();
  seedFullDeckMatch(db, "m1");
  await scoreInOrder("m1", Array.from({length: MAIN_PHASE_ROUNDS}, (_, i) => i), db);
  const order = [25, 20, 24, 21, 23, 22, ...Array.from({length: 14}, (_, i) => i + 26)];
  assert.strictEqual(order.length, 20);
  await scoreInOrder("m1", order, db);

  const match = await db.collection("battleMatches").doc("m1").get();
  assert.strictEqual(match.data().status, "finished");
  assert.strictEqual(match.data().result, "draw");
});

// --- 3/4. The exact bug: round 39 first ---

test("3. round 39 first, then 0..38 in order: self-heals to finished/draw", async () => {
  const db = new FakeFirestore();
  seedFullDeckMatch(db, "m1");
  await forfeit("m1", TOTAL_ROUNDS - 1, db); // 39 arrives before anything else
  let match = await db.collection("battleMatches").doc("m1").get();
  assert.strictEqual(match.data().status, "active"); // not concluded yet — correct, most of the deck is missing
  assert.strictEqual(match.data().scoredRounds["39"], true); // but round 39 itself IS marked

  await scoreInOrder("m1", Array.from({length: TOTAL_ROUNDS - 1}, (_, i) => i), db);

  match = await db.collection("battleMatches").doc("m1").get();
  assert.strictEqual(match.data().status, "finished");
  assert.strictEqual(match.data().result, "draw");
});

test("4. round 39 first, then every other round in a random-looking order: eventually concludes", async () => {
  const db = new FakeFirestore();
  seedFullDeckMatch(db, "m1");
  const rest = [17, 3, 29, 8, 22, 0, 35, 11, 26, 19, 6, 31, 14, 2, 38, 9,
    24, 1, 33, 15, 7, 27, 20, 5, 36, 12, 30, 4, 21, 10, 34, 16, 25, 13,
    28, 32, 18, 23, 37];
  assert.strictEqual(
      new Set(rest).size, TOTAL_ROUNDS - 1,
      "sanity: every round 0..38 present exactly once",
  );
  await forfeit("m1", TOTAL_ROUNDS - 1, db);
  await scoreInOrder("m1", rest, db);

  const match = await db.collection("battleMatches").doc("m1").get();
  assert.strictEqual(match.data().status, "finished");
  assert.strictEqual(match.data().result, "draw");
  for (let r = 0; r < TOTAL_ROUNDS; r++) {
    assert.strictEqual(match.data().scoredRounds[String(r)], true);
  }
});

// --- 5/6. Duplicate delivery ---

test("5. a duplicate trigger for an ordinary round never double-scores", async () => {
  const db = new FakeFirestore();
  seedFullDeckMatch(db, "m1");
  // Round 0's deck owner is PLAYER_A, so PLAYER_B answers it correctly.
  await scoreAnswer("m1", 0, "a", db);
  await scoreAnswer("m1", 0, "a", db); // redelivered
  const match = await db.collection("battleMatches").doc("m1").get();
  assert.strictEqual(match.data().officialScore[PLAYER_B], 1); // not 2
});

test("6. a duplicate round-39 trigger causes no issue, before or after self-heal", async () => {
  const db = new FakeFirestore();
  seedFullDeckMatch(db, "m1");
  await forfeit("m1", TOTAL_ROUNDS - 1, db);
  await forfeit("m1", TOTAL_ROUNDS - 1, db); // redelivered while still incomplete
  await scoreInOrder("m1", Array.from({length: TOTAL_ROUNDS - 1}, (_, i) => i), db);
  await forfeit("m1", TOTAL_ROUNDS - 1, db); // redelivered again, after conclusion

  const match = await db.collection("battleMatches").doc("m1").get();
  assert.strictEqual(match.data().status, "finished");
  assert.strictEqual(match.data().result, "draw");
});

// --- 7. Concurrent invocations that could both notice completion ---

test("7. two concurrent final scoring invocations produce exactly one conclusion", async () => {
  // Same real-transaction-interleaving technique already established in
  // this codebase (battle_abandonment_sweep.test.js's "two genuinely
  // concurrent sweep attempts", global_points_reliability.test.js) —
  // rounds 0..37 already scored and tied; rounds 38 and 39 are BOTH
  // still missing and are scored genuinely concurrently, so neither
  // invocation's own read can already see the other's write.
  const db = new FakeFirestore();
  seedFullDeckMatch(db, "m1", {scoredRounds: (() => {
    const s = {};
    for (let r = 0; r < TOTAL_ROUNDS - 2; r++) s[String(r)] = true;
    return s;
  })()});

  await Promise.all([
    forfeit("m1", TOTAL_ROUNDS - 2, db),
    forfeit("m1", TOTAL_ROUNDS - 1, db),
  ]);

  const match = await db.collection("battleMatches").doc("m1").get();
  assert.strictEqual(match.data().status, "finished");
  assert.strictEqual(match.data().result, "draw");
  assert.strictEqual(match.data().scoredRounds[String(TOTAL_ROUNDS - 2)], true);
  assert.strictEqual(match.data().scoredRounds[String(TOTAL_ROUNDS - 1)], true);
});

test("7b. two concurrent redeliveries of the SAME already-conclusive round: exactly one write", async () => {
  const db = new FakeFirestore();
  seedFullDeckMatch(db, "m1", {scoredRounds: (() => {
    const s = {};
    for (let r = 0; r < TOTAL_ROUNDS - 1; r++) s[String(r)] = true;
    return s;
  })()});

  await Promise.all([
    forfeit("m1", TOTAL_ROUNDS - 1, db),
    forfeit("m1", TOTAL_ROUNDS - 1, db),
  ]);

  const match = await db.collection("battleMatches").doc("m1").get();
  assert.strictEqual(match.data().status, "finished");
  assert.strictEqual(match.data().result, "draw");
});

// --- 8/9. General completeness property ---

test("8. all 40 rounds scored, in any of several orders: always ends finished", async () => {
  const orders = [
    Array.from({length: TOTAL_ROUNDS}, (_, i) => i),
    Array.from({length: TOTAL_ROUNDS}, (_, i) => TOTAL_ROUNDS - 1 - i),
    [TOTAL_ROUNDS - 1, ...Array.from({length: TOTAL_ROUNDS - 1}, (_, i) => i)],
  ];
  for (const order of orders) {
    const db = new FakeFirestore();
    seedFullDeckMatch(db, "m1");
    await scoreInOrder("m1", order, db);
    const match = await db.collection("battleMatches").doc("m1").get();
    assert.strictEqual(match.data().status, "finished");
  }
});

test("9. an incomplete deck (one round still missing) stays active", async () => {
  const db = new FakeFirestore();
  seedFullDeckMatch(db, "m1");
  const allButOne = Array.from({length: TOTAL_ROUNDS}, (_, i) => i)
      .filter((r) => r !== 17);
  await scoreInOrder("m1", allButOne, db);

  const match = await db.collection("battleMatches").doc("m1").get();
  assert.strictEqual(match.data().status, "active");
  assert.strictEqual(match.data().result, null);
  assert.strictEqual(match.data().scoredRounds["17"], undefined);
});

// --- 10/11. Winner and draw rules unchanged ---

test("10. winner calculation unchanged: a decisive score at round 19 concludes exactly as before", async () => {
  const db = new FakeFirestore();
  seedFullDeckMatch(db, "m1");
  // Rounds 0-18 all forfeited except round 0, answered correctly by
  // PLAYER_B (round 0's deck owner is PLAYER_A).
  await scoreAnswer("m1", 0, "a", db);
  await scoreInOrder("m1", Array.from({length: MAIN_PHASE_ROUNDS - 1}, (_, i) => i + 1), db);

  const match = await db.collection("battleMatches").doc("m1").get();
  assert.strictEqual(match.data().status, "finished");
  assert.strictEqual(match.data().result, PLAYER_B); // the only player with a point
  assert.strictEqual(match.data().officialScore[PLAYER_B], 1);
  assert.strictEqual(match.data().officialScore[PLAYER_A], 0);
});

test("11. draw calculation unchanged: an all-forfeit deck ends exactly tied", async () => {
  const db = new FakeFirestore();
  seedFullDeckMatch(db, "m1");
  await scoreInOrder("m1", Array.from({length: TOTAL_ROUNDS}, (_, i) => i), db);

  const match = await db.collection("battleMatches").doc("m1").get();
  assert.strictEqual(match.data().result, "draw");
  assert.strictEqual(match.data().officialScore[PLAYER_A], 0);
  assert.strictEqual(match.data().officialScore[PLAYER_B], 0);
});

// --- 12. Perfect Draw's own inputs are unaffected ---

test("12. a Perfect-Draw-shaped final state (20-20) concludes correctly via self-heal, even when a non-39 round arrives last", async () => {
  // Deliberately NOT constructed by organically playing all 40 rounds
  // correctly in sequence: under the pre-existing (unchanged by this
  // fix) early-conclusion rule, strict alternating ownership means any
  // correct answer past round 19 immediately creates a 1-point gap and
  // concludes the match with a winner right there — so a "both players
  // answer everything correctly, in order" run can never actually reach
  // a tied 20-20 state this way, regardless of this fix. Reaching a
  // genuine Perfect Draw depends on real trigger-completion timing this
  // synchronous test cannot faithfully reproduce; that is a pre-existing
  // property of the win-early rule, unrelated to and unaffected by this
  // change, so it is not what this test is for.
  //
  // What this test actually verifies: given a match already in a
  // Perfect-Draw-consistent state (officialScore already 20 for one
  // player, 19 for the other, only ONE round of theirs still
  // unscored — seeded directly rather than played out, to sidestep the
  // above), does the self-heal path reach `result: "draw"` correctly
  // when the LAST round to arrive is NOT round 39? The pre-fix code
  // could only ever reach a draw from round `TOTAL_ROUNDS - 1`'s own
  // invocation — this proves the fix generalizes correctly, and that
  // the officialScore/turnOrder values `isPerfectDraw` (battle_stars.js,
  // untouched) would read are exactly what a real Perfect Draw needs.
  const db = new FakeFirestore();
  const allExceptRound20 = Object.fromEntries(
      Array.from({length: TOTAL_ROUNDS}, (_, i) => i)
          .filter((r) => r !== 20)
          .map((r) => [String(r), true]),
  );
  // Round 20 is even -> deckOwnerUid PLAYER_A -> answerer PLAYER_B.
  // PLAYER_A already holds all 20 of their own (odd) rounds; PLAYER_B
  // holds 19 of their 20 (every even round except the still-pending 20).
  seedFullDeckMatch(db, "m1", {
    scoredRounds: allExceptRound20,
    officialScore: {[PLAYER_A]: 20, [PLAYER_B]: 19},
  });

  await scoreAnswer("m1", 20, "a", db); // the last piece, correct

  const match = await db.collection("battleMatches").doc("m1").get();
  assert.strictEqual(match.data().status, "finished");
  assert.strictEqual(match.data().result, "draw"); // not a PLAYER_B win off a stale partial read
  assert.strictEqual(match.data().officialScore[PLAYER_A], 20);
  assert.strictEqual(match.data().officialScore[PLAYER_B], 20);

  // The exact shape isPerfectDraw (battle_stars.js) reads: each player's
  // officialScore equals the count of rounds they were ever assigned to
  // answer, across the whole match.
  for (const uid of [PLAYER_A, PLAYER_B]) {
    const roundsAnswered = match.data().turnOrder
        .filter((e) => e.deckOwnerUid !== uid).length;
    assert.strictEqual(roundsAnswered, 20);
    assert.strictEqual(match.data().officialScore[uid], roundsAnswered);
  }
});

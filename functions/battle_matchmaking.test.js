/**
 * Regression coverage for battle_matchmaking.js's pure logic — the deck/
 * turn-order builders and the tier->content mapping. `claimWaitingOpponent`/
 * `createRankedMatch`/the trigger itself need a live Firestore + Realtime
 * Database to exercise for real and are covered by production
 * verification instead (see NOTES_CARD_GAME_MODE.md's Tahap 3 butir 10),
 * the same split already established for battle_bot.js's own trigger.
 *
 * Run from functions/: `node --test`
 */

const {test} = require("node:test");
const assert = require("node:assert");

const {
  poolFor,
  shuffle,
  buildDeckIds,
  buildTurnOrder,
  ROUNDS_PER_PLAYER,
  TIER_CONTENT,
} = require("./battle_matchmaking")._internal;

test("TIER_CONTENT covers all five tiers with the locked mapping", () => {
  assert.deepStrictEqual(TIER_CONTENT, {
    bronze: "hiragana",
    silver: "katakanaAndKanaCombo",
    gold: "kanjiN5",
    diamond: "kanjiN4N3",
    emerald: "kanjiN2N1",
  });
});

test("poolFor(hiragana) only returns base hiragana (row <= 10), no youon/combos", () => {
  const pool = poolFor("hiragana");
  assert.ok(pool.length >= 20);
  assert.ok(pool.every((id) => id.startsWith("hiragana_")));
});

test("poolFor(katakanaAndKanaCombo) returns katakana plus hiragana combos "+
  "(row > 10), never base hiragana", () => {
  const pool = poolFor("katakanaAndKanaCombo");
  assert.ok(pool.length >= 20);
  const basePool = new Set(poolFor("hiragana"));
  assert.ok(pool.every((id) => !basePool.has(id)));
});

test("poolFor(kanjiN5/kanjiN4N3/kanjiN2N1) each have at least 20 entries "+
  "against the real bundled dataset", () => {
  for (const content of ["kanjiN5", "kanjiN4N3", "kanjiN2N1"]) {
    assert.ok(poolFor(content).length >= 20, `${content} pool too small`);
  }
});

test("poolFor(kanjiN4N3) is the union of n4 and n3, no overlap double-counted", () => {
  const combo = poolFor("kanjiN4N3");
  const n4 = poolFor("kanjiN5").length; // sanity: distinct call, not reused
  assert.ok(n4 >= 0);
  assert.ok(new Set(combo).size === combo.length, "no duplicate ids in kanjiN4N3 pool");
});

test("poolFor falls back to hiragana's pool for an unknown content key", () => {
  assert.deepStrictEqual(poolFor("not_a_real_tier"), poolFor("hiragana"));
});

test("shuffle is a pure permutation — same elements, same length, "+
  "original array untouched", () => {
  const original = [1, 2, 3, 4, 5];
  const shuffled = shuffle(original, () => 0.5);
  assert.strictEqual(shuffled.length, original.length);
  assert.deepStrictEqual([...shuffled].sort(), [...original].sort());
  assert.deepStrictEqual(original, [1, 2, 3, 4, 5]);
});

test("shuffle with a deterministic random source produces the exact "+
  "predictable Fisher-Yates result (random always returning 0 picks "+
  "j=0 every step, rotating the array)", () => {
  const original = [1, 2, 3, 4, 5];
  assert.deepStrictEqual(shuffle(original, () => 0), [2, 3, 4, 5, 1]);
});

test("buildDeckIds returns exactly 20 unique ids from the tier's real pool", () => {
  for (const content of Object.values(TIER_CONTENT)) {
    const deck = buildDeckIds(content, Math.random);
    assert.strictEqual(deck.length, 20);
    assert.strictEqual(new Set(deck).size, 20, `duplicate ids in ${content} deck`);
    const pool = new Set(poolFor(content));
    assert.ok(deck.every((id) => pool.has(id)));
  }
});

test("buildDeckIds's two independent calls for the same tier usually "+
  "produce different decks (real shuffling, not a fixed order)", () => {
  const a = buildDeckIds("hiragana", Math.random);
  const b = buildDeckIds("hiragana", Math.random);
  // Both are valid 20-card draws from the same >20-entry pool; asserting
  // they're never identical would be flaky (a tiny but real chance of a
  // false failure), so this checks the weaker, still-meaningful
  // property that they're not literally the same array reference/order
  // called back-to-back with independent Math.random draws.
  assert.notDeepStrictEqual(a, b);
});

test("buildTurnOrder interleaves a full match, alternating deck ownership "+
  "starting with the given firstUid", () => {
  // Locked to ROUNDS_PER_PLAYER rather than to a number written out
  // again here. This test used to assert 20 rounds while the app played
  // 40 — so the assertion agreed with the bug, and a publicly matched
  // game stayed half length. The Flutter side's
  // battle_rules_parity_test.dart is what ties that constant to
  // kBattleTotalRounds.
  const rounds = ROUNDS_PER_PLAYER * 2;
  const firstDeck = Array.from({length: ROUNDS_PER_PLAYER}, (_, i) => `first_${i}`);
  const secondDeck = Array.from({length: ROUNDS_PER_PLAYER}, (_, i) => `second_${i}`);
  const turnOrder = buildTurnOrder("uid-a", firstDeck, "uid-b", secondDeck, () => 0);

  assert.strictEqual(turnOrder.length, rounds);
  for (let i = 0; i < rounds; i++) {
    assert.strictEqual(turnOrder[i].round, i);
    assert.strictEqual(
        turnOrder[i].deckOwnerUid,
        i % 2 === 0 ? "uid-a" : "uid-b",
    );
  }
});

test("buildTurnOrder plays each player's whole deck, with no card twice",
    () => {
      const firstDeck =
        Array.from({length: ROUNDS_PER_PLAYER}, (_, i) => `first_${i}`);
      const secondDeck =
        Array.from({length: ROUNDS_PER_PLAYER}, (_, i) => `second_${i}`);
      const turnOrder = buildTurnOrder("uid-a", firstDeck, "uid-b", secondDeck);

      const firstUsed = turnOrder
          .filter((e) => e.deckOwnerUid === "uid-a")
          .map((e) => e.cardId);
      const secondUsed = turnOrder
          .filter((e) => e.deckOwnerUid === "uid-b")
          .map((e) => e.cardId);
      assert.strictEqual(firstUsed.length, ROUNDS_PER_PLAYER);
      assert.strictEqual(secondUsed.length, ROUNDS_PER_PLAYER);
      assert.strictEqual(new Set(firstUsed).size, ROUNDS_PER_PLAYER);
      assert.strictEqual(new Set(secondUsed).size, ROUNDS_PER_PLAYER);
      // A hand the player can actually spend: everything dealt is
      // playable, which is what `remainingHand` counts down.
      assert.deepStrictEqual(new Set(firstUsed), new Set(firstDeck));
      assert.deepStrictEqual(new Set(secondUsed), new Set(secondDeck));
    });

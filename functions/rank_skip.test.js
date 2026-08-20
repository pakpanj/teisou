/**
 * Coverage for the rank-skip exam's decisions — which cards a tier is
 * examined on, what counts as a right answer, and which tiers a player
 * may aim at.
 *
 * The promotion itself is not tested here: it is `promoteToTierFloor`
 * in battle_stars.js, which needs Firestore, and the ladder arithmetic
 * it stands on already has its own coverage in battle_stars.test.js.
 *
 * Run from functions/: `node --test`
 */

const {test} = require("node:test");
const assert = require("node:assert");

const kanaData = require("./data/kana_data.json");
const {resolveCorrectRomaji} = require("./battle_scoring")._internal;
const {
  QUESTIONS,
  PASS_MARK,
  SKIPPABLE,
  poolFor,
  sample,
  isCorrect,
  tiersAbove,
} = require("./rank_skip")._internal;

test("every tier is examined on cards the grader can actually score", () => {
  // The failure this catches is silent and total: a pool holding ids
  // resolveCorrectRomaji returns null for would mark every answer
  // wrong, and the player would fail an exam nobody could pass.
  for (const tier of SKIPPABLE) {
    const pool = poolFor(tier);
    assert.ok(pool.length >= QUESTIONS,
        `${tier} has only ${pool.length} cards, needs ${QUESTIONS}`);
    for (const id of pool) {
      assert.ok(resolveCorrectRomaji(id), `${tier}: ${id} does not resolve`);
    }
  }
});

test("the pools match the tiers the app plays those cards at", () => {
  // Mirrors `_poolFor` in battle_deck_builder.dart. Two copies of this
  // mapping exist because the server cannot import Dart; this is the
  // check that keeps them the same, so examining a tier on cards it
  // never deals fails here rather than confusing a player.
  const silver = new Set(poolFor("silver"));
  const bronzeKana = kanaData
      .filter((k) => k.type === "hiragana" && (k.row || 0) <= 10)
      .map((k) => k.id);

  assert.ok(bronzeKana.length > 0);
  for (const id of bronzeKana) {
    assert.ok(!silver.has(id),
        `${id} is Bronze's own hiragana and must not be in Silver's exam`);
  }
  for (const id of silver) {
    const kana = kanaData.find((k) => k.id === id);
    assert.ok(kana, `${id} is not kana at all`);
    assert.ok(kana.type === "katakana" || (kana.row || 0) > 10);
  }

  // Gold and up are kanji words, which are the ids carrying a "|".
  for (const tier of ["gold", "diamond", "emerald"]) {
    for (const id of poolFor(tier)) {
      assert.ok(id.includes("|"), `${tier}: ${id} is not a kanji word card`);
    }
  }
});

test("kanji tiers are answered in hiragana, the way their battles are", () => {
  // Gold and up use KanaKeyboard in a match (`answersWithKanaKeyboard`).
  // An exam that accepted romaji there would be an easier test than the
  // tier it admits you to.
  for (const tier of ["gold", "diamond", "emerald"]) {
    const id = poolFor(tier)[0];
    assert.strictEqual(resolveCorrectRomaji(id).answerInHiragana, true);
  }
  const silverId = poolFor("silver")[0];
  assert.strictEqual(resolveCorrectRomaji(silverId).answerInHiragana, false);
});

test("an answer is marked by the same rule a match uses", () => {
  const kana = kanaData.find((k) => k.type === "katakana" && k.romaji === "a");
  assert.ok(kana, "expected a katakana card reading 'a'");

  assert.ok(isCorrect(kana.id, kana.romaji));
  assert.ok(isCorrect(kana.id, ` ${kana.romaji.toUpperCase()} `),
      "case and surrounding space must not decide a rank");
  assert.ok(!isCorrect(kana.id, "zzz"));
  assert.ok(!isCorrect(kana.id, ""));
  assert.ok(!isCorrect(kana.id, null), "an unanswered card is not correct");
  assert.ok(!isCorrect("no_such_card", "a"));
});

test("only tiers above the one held can be aimed at", () => {
  // Both halves matter. Skipping down would erase a climb; re-taking
  // the tier already held would spend a cooldown on nothing.
  assert.deepStrictEqual(tiersAbove("bronze"),
      ["silver", "gold", "diamond", "emerald"]);
  assert.deepStrictEqual(tiersAbove("gold"), ["diamond", "emerald"]);
  assert.deepStrictEqual(tiersAbove("emerald"), []);
  assert.ok(!tiersAbove("silver").includes("silver"));
  assert.ok(!tiersAbove("silver").includes("bronze"));
});

test("the pass mark is reachable and not a formality", () => {
  assert.ok(PASS_MARK <= QUESTIONS);
  assert.ok(PASS_MARK / QUESTIONS >= 0.8,
      "a mark a lucky run could reach would make the ladder pointless");
});

test("a drawn exam has no repeats", () => {
  // Twenty questions, one of them asked three times, is a seventeen
  // question exam — and an easier one, since a card seen once is a card
  // already worked out.
  const drawn = sample(poolFor("gold"), QUESTIONS);
  assert.strictEqual(drawn.length, QUESTIONS);
  assert.strictEqual(new Set(drawn).size, QUESTIONS);
});

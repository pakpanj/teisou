/**
 * Regression coverage for battle_bot.js — the Card Game Mode bot
 * opponent (Tahap 3 butir 8 in NOTES_CARD_GAME_MODE.md). Uses Node's
 * built-in test runner (`node --test`), same as battle_scoring.test.js.
 *
 * Run from functions/: `node --test`
 */

const {test} = require("node:test");
const assert = require("node:assert");

const {toRomaji} = require("./battle_scoring")._internal;
const {
  hiraganaForRomaji,
  mutateHiragana,
  buildBotAnswer,
  difficultyFor,
} = require("./battle_bot")._internal;
const readings = require("./data/kanji_word_readings.json");

// The 6 readings in the real dataset that hiraganaForRomaji cannot
// synthesize (see the doc comment on hiraganaForRomaji itself for why
// each one fails) — buildBotAnswer degrades gracefully for these
// rather than crashing, so they're excluded from the full-dataset
// round-trip assertion below and checked separately instead.
const KNOWN_UNRESOLVABLE = new Set([
  "botchan", "setchuu", "kouhu", "Wang", "Yō", "Yō Mei",
]);

test("hiraganaForRomaji round-trips through toRomaji for the whole "+
  "real dataset, except 6 known edge cases", () => {
  let resolved = 0;
  let unresolved = 0;
  for (const key in readings) {
    const romaji = readings[key];
    const hira = hiraganaForRomaji(romaji);
    if (hira === null) {
      assert.ok(
          KNOWN_UNRESOLVABLE.has(romaji),
          `unexpected new unresolvable reading: ${key} -> ${romaji}`,
      );
      unresolved++;
      continue;
    }
    const roundTrip = toRomaji(hira);
    const normalized = romaji.toLowerCase().replace(/['\-\s]+/g, "");
    assert.strictEqual(
        roundTrip.toLowerCase(), normalized,
        `${key}: ${romaji} -> ${hira} -> ${roundTrip}`,
    );
    resolved++;
  }
  assert.strictEqual(unresolved, KNOWN_UNRESOLVABLE.size);
  assert.ok(resolved > 7000, "sanity check: dataset should be large");
});

test("hiraganaForRomaji handles plain kana without gemination or youon", () => {
  assert.strictEqual(hiraganaForRomaji("gakusei"), "がくせい");
});

test("hiraganaForRomaji handles sokuon (doubled consonant)", () => {
  assert.strictEqual(hiraganaForRomaji("gakkou"), "がっこう");
});

test("hiraganaForRomaji handles youon", () => {
  assert.strictEqual(hiraganaForRomaji("kyoushi"), "きょうし");
});

test("hiraganaForRomaji splits on apostrophes as a segment boundary", () => {
  const hira = hiraganaForRomaji("ren'ai");
  assert.notStrictEqual(hira, null);
  assert.strictEqual(toRomaji(hira).toLowerCase(), "renai");
});

test("hiraganaForRomaji splits on hyphens as a segment boundary", () => {
  const hira = hiraganaForRomaji("ken-eki");
  assert.notStrictEqual(hira, null);
});

test("hiraganaForRomaji splits on spaces as a segment boundary", () => {
  const hira = hiraganaForRomaji("keiken ga asai");
  assert.notStrictEqual(hira, null);
});

test("hiraganaForRomaji returns null for the tch-spelled edge cases, "+
  "not a wrong guess", () => {
  assert.strictEqual(hiraganaForRomaji("botchan"), null);
  assert.strictEqual(hiraganaForRomaji("setchuu"), null);
});

test("mutateHiragana never returns the exact input unchanged", () => {
  const random = (() => {
    let i = 0;
    const seq = [0.1, 0.4, 0.7, 0.2, 0.9, 0.3];
    return () => seq[i++ % seq.length];
  })();
  for (const word of ["がくせい", "さくら", "とうきょう", "あ"]) {
    const mutated = mutateHiragana(word, random);
    assert.notStrictEqual(mutated, word, `mutation of ${word} was a no-op`);
  }
});

test("mutateHiragana prefers a dakuten/handakuten flip when one exists", () => {
  // "か" has が as a dakuten pair, so a mutation must pick that path
  // (not the adjacent-swap fallback) for a single-character input.
  const random = () => 0;
  assert.strictEqual(mutateHiragana("か", random), "が");
});

test("difficultyFor falls back to hiragana's curve for an unknown tier key", () => {
  assert.deepStrictEqual(difficultyFor("not_a_real_tier"), difficultyFor("hiragana"));
});

test("difficultyFor returns a stricter curve for higher tiers", () => {
  const n5 = difficultyFor("kanjiN5");
  const n1 = difficultyFor("kanjiN2N1");
  assert.ok(n1.correctProbability > n5.correctProbability);
  assert.ok(n1.revealMaxSec < n5.revealMaxSec);
});

test("buildBotAnswer returns null for an unresolvable cardId", () => {
  assert.strictEqual(buildBotAnswer("hiragana", "not_a_real_card_id"), null);
});

test("buildBotAnswer's correct/wrong split roughly matches the tier's "+
  "correctProbability over many trials", () => {
  const cardId = "hiragana_ka";
  const trials = 2000;
  let correct = 0;
  for (let i = 0; i < trials; i++) {
    const answer = buildBotAnswer("hiragana", cardId, Math.random);
    if (answer.text === "ka") correct++;
  }
  const rate = correct / trials;
  // hiragana's correctProbability is 0.50 — allow generous slack since
  // this is a real random sample, not a seeded one.
  assert.ok(rate > 0.4 && rate < 0.6, `observed correct rate ${rate}`);
});

test("buildBotAnswer's revealAt always falls within the tier's delay range", () => {
  const cardId = "hiragana_ka";
  for (let i = 0; i < 50; i++) {
    const before = Date.now();
    const answer = buildBotAnswer("hiragana", cardId, Math.random);
    const delaySec = (answer.revealAt.getTime() - before) / 1000;
    assert.ok(delaySec >= 14 && delaySec <= 31, `delay out of range: ${delaySec}`);
  }
});

test("buildBotAnswer on a real kanji-word card produces the correct "+
  "hiragana when forced correct", () => {
  const random = () => 0; // < any correctProbability, so always "correct"
  const answer = buildBotAnswer("kanjiN5", "kanji_gaku|学生", random);
  assert.notStrictEqual(answer, null);
  assert.strictEqual(toRomaji(answer.text), "gakusei");
});

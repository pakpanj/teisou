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

const {toRomaji, resolveCorrectRomaji} = require("./battle_scoring")._internal;

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

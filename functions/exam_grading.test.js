// Permanent regression coverage for exam_grading.js — the server-side
// re-grading half of the Exam-History Authority fix (see
// TEISOU_ROADMAP_MASTER.md's "Exam-History Authority" sections). Pure
// unit tests against the real mirrored `functions/data/*` datasets, no
// Firestore double needed — `gradeAttempt` takes plain data in, returns
// plain data out.
"use strict";

const {test} = require("node:test");
const assert = require("node:assert/strict");

const {
  gradeAttempt,
  gradeKana,
  gradeDokkai,
  gradeChoukai,
  gradeKanjiCombo,
  dedupeAndCap,
  MAX_TOTAL,
} = require("./exam_grading");

// ---------------------------------------------------------------------
// 1. Each of the four modules grades a genuinely correct real answer
//    correctly (property required by the implementation task's Phase 8,
//    item 1: "legitimate attempts for all 4 modules produce correct
//    server score").
// ---------------------------------------------------------------------
test("gradeKana: a real, correct hiragana answer scores 1/1", () => {
  const result = gradeKana([{contentId: "hiragana_a", submittedText: "a"}]);
  assert.deepStrictEqual(result, {serverScore: 1, serverTotal: 1});
});

test("gradeKana: a real but WRONG answer scores 0/1 — the submitted " +
    "text must match, not just the contentId existing", () => {
  const result = gradeKana([{contentId: "hiragana_a", submittedText: "zzz"}]);
  assert.deepStrictEqual(result, {serverScore: 0, serverTotal: 1});
});

test("gradeDokkai: a real, correct question option scores 1/1", () => {
  const result = gradeDokkai([{
    contentId: "dokkai_surat_sahabat_pena|dokkai_surat_sahabat_pena_q0",
    submittedText: "アメリカ",
  }]);
  assert.deepStrictEqual(result, {serverScore: 1, serverTotal: 1});
});

test("gradeDokkai: a real question, wrong option text scores 0/1", () => {
  const result = gradeDokkai([{
    contentId: "dokkai_surat_sahabat_pena|dokkai_surat_sahabat_pena_q0",
    submittedText: "中国",
  }]);
  assert.deepStrictEqual(result, {serverScore: 0, serverTotal: 1});
});

test("gradeChoukai: a real, correct question option scores 1/1", () => {
  const result = gradeChoukai([{
    contentId: "choukai_n5_jam_berapa|choukai_n5_jam_berapa_q1",
    submittedText: "三時半",
  }]);
  assert.deepStrictEqual(result, {serverScore: 1, serverTotal: 1});
});

test("gradeKanjiCombo: a real kanji reading (onyomi) is accepted", () => {
  const result = gradeKanjiCombo([
    {contentId: "一|reading", submittedText: "イチ"},
  ]);
  assert.deepStrictEqual(result, {serverScore: 1, serverTotal: 1});
});

test("gradeKanjiCombo: a real kanji reading (kunyomi, okurigana marker " +
    "stripped) is also accepted — any real reading counts, not just " +
    "whichever one a particular session's distractor set targeted", () => {
  const result = gradeKanjiCombo([
    {contentId: "一|reading", submittedText: "ひとつ"}, // marker stripped from "ひと-つ"
  ]);
  assert.deepStrictEqual(result, {serverScore: 1, serverTotal: 1});
});

test("gradeKanjiCombo: a real kanji meaning (either language) is " +
    "accepted", () => {
  const result = gradeKanjiCombo([
    {contentId: "一|meaning", submittedText: "one"},
  ]);
  assert.deepStrictEqual(result, {serverScore: 1, serverTotal: 1});
});

test("gradeKanjiCombo: a real compound-word (Kotoba-sourced) reading " +
    "question is graded from the kotoba pool", () => {
  const result = gradeKanjiCombo([
    {contentId: "宗教|reading", submittedText: "しゅうきょう"},
  ]);
  assert.deepStrictEqual(result, {serverScore: 1, serverTotal: 1});
});

// ---------------------------------------------------------------------
// 2. Forged score/total cannot influence the server's own grade — the
//    grader never reads docData.score/total at all, only answers.
// ---------------------------------------------------------------------
test("gradeAttempt ignores any score/total-shaped fields mixed into an " +
    "answer entry — only contentId/submittedText are read", () => {
  const result = gradeAttempt("kana", [{
    contentId: "hiragana_a", submittedText: "a",
    score: 999999, total: 1, // attacker noise, must be ignored
  }]);
  assert.deepStrictEqual(result, {serverScore: 1, serverTotal: 1});
});

test("gradeAttempt: a fabricated document with NO real answers at all " +
    "(or a missing/malformed answers field) grades to 0/0 — the exact " +
    "P0 exploit's score=999999 case is now worth nothing", () => {
  assert.deepStrictEqual(gradeAttempt("kana", undefined),
      {serverScore: 0, serverTotal: 0});
  assert.deepStrictEqual(gradeAttempt("kana", null),
      {serverScore: 0, serverTotal: 0});
  assert.deepStrictEqual(gradeAttempt("kana", "not an array"),
      {serverScore: 0, serverTotal: 0});
  assert.deepStrictEqual(
      gradeAttempt("kana", [{contentId: "hiragana_a", submittedText: "999999"}]),
      {serverScore: 0, serverTotal: 1},
      "a bogus submittedText is graded exactly like any other wrong answer",
  );
});

test("gradeAttempt: an answer citing a contentId that doesn't exist in " +
    "the real dataset contributes to serverTotal (it was submitted) but " +
    "never to serverScore", () => {
  const result = gradeAttempt("kana", [
    {contentId: "hiragana_a", submittedText: "a"},
    {contentId: "no_such_kana_id", submittedText: "whatever"},
  ]);
  assert.deepStrictEqual(result, {serverScore: 1, serverTotal: 2});
});

// ---------------------------------------------------------------------
// 3. Anti-farming: dedupe + cap at the real per-module session ceiling,
//    BEFORE grading — this is what makes serverTotal non-forgeable.
// ---------------------------------------------------------------------
test("dedupeAndCap: the exact same contentId submitted 500 times counts " +
    "once, not 500 times", () => {
  const answers = Array.from({length: 500},
      () => ({contentId: "hiragana_a", submittedText: "a"}));
  const result = dedupeAndCap(answers, MAX_TOTAL.kana);
  assert.strictEqual(result.length, 1);
});

test("gradeKana: submitting the same real, correct contentId 500 times " +
    "still scores at most MAX_TOTAL.kana (10), never 500 — closes the " +
    "P0 audit's farming class at the grading layer itself", () => {
  const answers = Array.from({length: 500},
      () => ({contentId: "hiragana_a", submittedText: "a"}));
  const result = gradeKana(answers);
  assert.ok(result.serverTotal <= MAX_TOTAL.kana);
  assert.strictEqual(result.serverScore, 1); // one distinct real item
});

test("dedupeAndCap: more DISTINCT real contentIds than a module's real " +
    "session could ever contain is capped at the module's own ceiling, " +
    "not the attacker-chosen array length", () => {
  const answers = Array.from({length: 200},
      (_, i) => ({contentId: `fake-distinct-${i}`, submittedText: "x"}));
  const result = dedupeAndCap(answers, MAX_TOTAL.dokkai);
  assert.strictEqual(result.length, MAX_TOTAL.dokkai);
});

// ---------------------------------------------------------------------
// 4. Grading is deterministic and versioned.
// ---------------------------------------------------------------------
test("gradeAttempt throws on an unknown module type rather than " +
    "silently grading it as 0 — a typo'd/forged moduleType must be " +
    "visible, not swallowed", () => {
  assert.throws(() => gradeAttempt("not-a-real-module", []));
});

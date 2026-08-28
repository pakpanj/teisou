/**
 * Server-side exam grading — the Exam-History Authority fix (see
 * `TEISOU_ROADMAP_MASTER.md`'s P0 audit + design + implementation
 * sections). Grades a client-submitted `answers` array against this
 * project's own bundled content datasets, mirrored into `functions/data/`
 * (copies of `assets/data/{kana,dokkai,choukai,kanji}_data.json` and
 * `assets/data/kotoba/*.json`) — the SAME datasets the app itself ships,
 * never anything generated per-install or per-device. This is what makes
 * "the server independently determines score" possible without
 * re-implementing any exam UI's question-selection/distractor-generation
 * logic: grading is a lookup against real, static, authored content, not
 * a live computation.
 *
 * **Every dataset load is lazy and cached per warm instance** — mirroring
 * this project's own established `db()`-style lazy-getter convention
 * (`global_points.js`, `award_top_coins.js`) — so a cold start that never
 * needs, say, the 3.3MB kanji dataset (a pure Kana attempt) never pays to
 * parse it.
 *
 * **`answers` is deduplicated by `contentId` and capped at each module's
 * own real session-size ceiling BEFORE grading** — this is what closes
 * the P0 audit's test B2/test C farming class at the source: `serverTotal`
 * is a SERVER-COUNTED value derived from this capped, deduplicated list,
 * never the raw (attacker-controllable) length of whatever array a
 * client submits. Submitting the same real, easy contentId 500 times, or
 * submitting more entries than a real session could ever contain, has no
 * effect beyond the module's own real ceiling.
 */

const fs = require("fs");
const path = require("path");

const DATA_DIR = path.join(__dirname, "data");

/** Real per-module session-size ceilings — Kana's fixed
 * `ExamRepository.questionsPerExam` (10), and the other three modules'
 * `sessionQuestionTarget`/generation `count` default (50). Choukai's own
 * clips are all far smaller than 50 questions in practice, so 50 is a
 * generous, still-real ceiling for it too — not a magic number invented
 * for this file. */
const MAX_TOTAL = {
  kana: 10,
  dokkai: 50,
  choukai: 50,
  kanjiCombo: 50,
};

let _kanaMap = null;
/** @return {Map<string, string>} kana id -> romaji */
function loadKana() {
  if (_kanaMap) return _kanaMap;
  const raw = JSON.parse(
      fs.readFileSync(path.join(DATA_DIR, "kana_data.json"), "utf8"));
  _kanaMap = new Map(raw.map((k) => [k.id, k.romaji]));
  return _kanaMap;
}

/** @return {Map<string, {options: string[], correctIndex: number}>}
 * "{passageId}|{questionId}" -> the real question, for Dokkai. */
let _dokkaiMap = null;
function loadDokkai() {
  if (_dokkaiMap) return _dokkaiMap;
  const raw = JSON.parse(
      fs.readFileSync(path.join(DATA_DIR, "dokkai_data.json"), "utf8"));
  _dokkaiMap = new Map();
  for (const passage of raw) {
    for (const q of passage.questions) {
      _dokkaiMap.set(`${passage.id}|${q.id}`, {
        options: q.options, correctIndex: q.correctIndex,
      });
    }
  }
  return _dokkaiMap;
}

/** Same shape as [loadDokkai], for Choukai — "{clipId}|{questionId}". */
let _choukaiMap = null;
function loadChoukai() {
  if (_choukaiMap) return _choukaiMap;
  const raw = JSON.parse(
      fs.readFileSync(path.join(DATA_DIR, "choukai_data.json"), "utf8"));
  _choukaiMap = new Map();
  for (const clip of raw) {
    for (const q of clip.questions) {
      _choukaiMap.set(`${clip.id}|${q.id}`, {
        options: q.options, correctIndex: q.correctIndex,
      });
    }
  }
  return _choukaiMap;
}

/** @return {Map<string, {onyomi: string[], kunyomi: string[],
 *   meanings: string[], meaningsEn: string[]}>} kanji character -> entry.
 *   Kanji characters are unique across the whole dataset (confirmed by
 *   this project's own `kanji_char_lists.py`-locked authoring discipline
 *   — no character appears at two JLPT levels), so a bare `Map` keyed by
 *   character alone is exact, not approximate. */
let _kanjiMap = null;
function loadKanjiByCharacter() {
  if (_kanjiMap) return _kanjiMap;
  const raw = JSON.parse(
      fs.readFileSync(path.join(DATA_DIR, "kanji_data.json"), "utf8"));
  _kanjiMap = new Map(raw.map((k) => [k.character, {
    onyomi: k.onyomi || [],
    kunyomi: k.kunyomi || [],
    meanings: k.meanings || [],
    meaningsEn: k.meaningsEn || [],
  }]));
  return _kanjiMap;
}

/** @return {Map<string, string>} compound-word kanji string -> its real
 * reading, built once from every `functions/data/kotoba/*.json` category
 * file (mirroring `assets/data/kotoba/*.json`, the same files
 * `KanjiComboRepository._compoundPool` draws from). If more than one
 * word happens to share the same kanji string (not expected, not
 * asserted elsewhere in this dataset either), the first one found wins —
 * an acceptable, documented simplification: whichever real word the
 * client's own pool search would have found is what its `reading` is
 * checked against either way. */
let _kotobaByKanji = null;
function loadKotobaByKanji() {
  if (_kotobaByKanji) return _kotobaByKanji;
  _kotobaByKanji = new Map();
  const kotobaDir = path.join(DATA_DIR, "kotoba");
  for (const file of fs.readdirSync(kotobaDir)) {
    if (!file.endsWith(".json") || file.startsWith("_")) continue;
    const raw = JSON.parse(
        fs.readFileSync(path.join(kotobaDir, file), "utf8"));
    for (const w of raw) {
      if (w.kanji && !_kotobaByKanji.has(w.kanji)) {
        _kotobaByKanji.set(w.kanji, w.reading);
      }
    }
  }
  return _kotobaByKanji;
}

/** Mirrors `KanjiComboRepository._stripOkuriganaMarker` exactly — the
 * "-" marker `generateMutationDistractors` needs to know an okurigana
 * boundary, stripped before anything is ever compared/displayed. */
function stripOkuriganaMarker(reading) {
  return reading.replace(/-/g, "");
}

/**
 * Deduplicates [answers] by `contentId` (first occurrence wins) and caps
 * the result at [max] entries — the anti-farming gate every grader below
 * runs its input through before counting anything. See this file's own
 * top doc comment for why this, not a bounds-check on the raw array, is
 * what actually closes the P0 audit's farming class.
 *
 * @param {Array<{contentId: string, submittedText: string}>} answers
 * @param {number} max
 */
function dedupeAndCap(answers, max) {
  if (!Array.isArray(answers)) return [];
  const seen = new Set();
  const result = [];
  for (const a of answers) {
    if (!a || typeof a.contentId !== "string") continue;
    if (seen.has(a.contentId)) continue;
    seen.add(a.contentId);
    result.push(a);
    if (result.length >= max) break;
  }
  return result;
}

function gradeKana(answers) {
  const kana = loadKana();
  const deduped = dedupeAndCap(answers, MAX_TOTAL.kana);
  let score = 0;
  for (const a of deduped) {
    const romaji = kana.get(a.contentId);
    if (romaji !== undefined && a.submittedText === romaji) score++;
  }
  return {serverScore: score, serverTotal: deduped.length};
}

function gradeIndexed(datasetMap, answers, max) {
  const deduped = dedupeAndCap(answers, max);
  let score = 0;
  for (const a of deduped) {
    const q = datasetMap.get(a.contentId);
    if (!q) continue;
    const correctText = q.options[q.correctIndex];
    if (correctText !== undefined && a.submittedText === correctText) score++;
  }
  return {serverScore: score, serverTotal: deduped.length};
}

function gradeDokkai(answers) {
  return gradeIndexed(loadDokkai(), answers, MAX_TOTAL.dokkai);
}

function gradeChoukai(answers) {
  return gradeIndexed(loadChoukai(), answers, MAX_TOTAL.choukai);
}

/**
 * `contentId` here is `"{contentKey}|{promptKind}"` (see
 * `KanjiComboQuestion.contentKey`/`.promptKind` on the Dart side) —
 * either a bare kanji character (single mode) or a compound word's
 * kanji string (combination mode), plus which of `reading`/`meaning`
 * was asked. A submitted answer is correct if it equals ANY of the real
 * onyomi/kunyomi (for a reading prompt) or either language's real
 * meaning (for a meaning prompt) belonging to that exact content item —
 * not just the one specific reading the client's own distractor
 * generator happened to pick as "the" target, since any of a kanji's
 * real readings is a genuinely correct answer regardless of which one a
 * particular session's question was built around.
 */
function gradeKanjiCombo(answers) {
  const kanji = loadKanjiByCharacter();
  const kotoba = loadKotobaByKanji();
  const deduped = dedupeAndCap(answers, MAX_TOTAL.kanjiCombo);
  let score = 0;
  for (const a of deduped) {
    const sep = a.contentId.lastIndexOf("|");
    if (sep === -1) continue;
    const key = a.contentId.slice(0, sep);
    const kind = a.contentId.slice(sep + 1);

    let candidates = [];
    const kanjiEntry = kanji.get(key);
    if (kanjiEntry) {
      candidates = kind === "reading" ?
        [...kanjiEntry.onyomi, ...kanjiEntry.kunyomi].map(stripOkuriganaMarker) :
        [...kanjiEntry.meanings, ...kanjiEntry.meaningsEn];
    } else if (kotoba.has(key)) {
      // Combination mode is always a reading question — see
      // `_buildQuestions`' own `answerOf: (w) => w.reading` call site.
      candidates = [kotoba.get(key)];
    }
    if (candidates.includes(a.submittedText)) score++;
  }
  return {serverScore: score, serverTotal: deduped.length};
}

/**
 * @param {string} moduleType one of the four `global_points.js` `MODULES`
 *   keys.
 * @param {Array<{contentId: string, submittedText: string}>} answers raw,
 *   client-submitted, untrusted.
 * @return {{serverScore: number, serverTotal: number}}
 */
function gradeAttempt(moduleType, answers) {
  switch (moduleType) {
    case "kana":
      return gradeKana(answers);
    case "dokkai":
      return gradeDokkai(answers);
    case "choukai":
      return gradeChoukai(answers);
    case "kanjiCombo":
      return gradeKanjiCombo(answers);
    default:
      throw new Error(`unknown module type: ${moduleType}`);
  }
}

/** Bumped only if the grading algorithm or a mirrored dataset changes in
 * a way that could shift already-graded results — lets a future audit
 * distinguish "graded under these rules" from "graded under different
 * ones", the same spirit as this project's own deployment-hash labels. */
const GRADING_VERSION = 1;

module.exports = {
  MAX_TOTAL,
  GRADING_VERSION,
  dedupeAndCap,
  stripOkuriganaMarker,
  loadKana,
  loadDokkai,
  loadChoukai,
  loadKanjiByCharacter,
  loadKotobaByKanji,
  gradeKana,
  gradeDokkai,
  gradeChoukai,
  gradeKanjiCombo,
  gradeAttempt,
};

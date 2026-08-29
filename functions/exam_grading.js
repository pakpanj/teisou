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
 *
 * **`gradeAttempt` also derives `difficultyValue`/`repeatValue`** — the
 * Global-Points Metadata Authority follow-up fix (see
 * `TEISOU_ROADMAP_MASTER.md`'s own section by that name). A confirmed
 * P0 farming vector let a client bypass the 0.6^(n-1) repeat-cycle
 * decay indefinitely by inventing a fresh `type`/`jlptLevel`/`itemId`
 * string per fabricated document — this file now derives both values
 * from the SAME real, dataset-verified content `answers` actually
 * reference, collapsing the repeat-key space to the finite set of real
 * content identities instead of any client-invented string. See
 * `majorityOf`/`deriveKanaType`/`deriveMajorityLevel`/
 * `deriveChoukaiClipId`/`deriveKanjiComboRepeatValue` below.
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
/** @return {Map<string, {romaji: string, type: string}>} kana id ->
 * {romaji, type} — `type` (`hiragana`/`katakana`) is the same trusted
 * field the P0 metadata-authority fix derives Kana's difficulty/repeat
 * identity from, so it travels alongside `romaji` in the one map rather
 * than needing a second lookup. */
function loadKana() {
  if (_kanaMap) return _kanaMap;
  const raw = JSON.parse(
      fs.readFileSync(path.join(DATA_DIR, "kana_data.json"), "utf8"));
  _kanaMap = new Map(raw.map((k) => [k.id, {romaji: k.romaji, type: k.type}]));
  return _kanaMap;
}

/** @return {Map<string, {options: string[], correctIndex: number,
 *   jlptLevel: string}>} "{passageId}|{questionId}" -> the real
 *   question, for Dokkai — `jlptLevel` is the passage's own real level,
 *   carried alongside the grading fields for the same reason as
 *   [loadKana]'s `type`. */
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
        jlptLevel: passage.jlptLevel,
      });
    }
  }
  return _dokkaiMap;
}

/** Same shape as [loadDokkai], for Choukai — "{clipId}|{questionId}" ->
 * {options, correctIndex, jlptLevel, clipId}. `clipId` is carried
 * explicitly (not just re-derived by re-splitting the map key later)
 * since Choukai's repeat identity is the real clip id itself, not its
 * level — see this file's own `deriveChoukaiClipId`. */
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
        jlptLevel: clip.jlptLevel, clipId: clip.id,
      });
    }
  }
  return _choukaiMap;
}

/** @return {Map<string, {onyomi: string[], kunyomi: string[],
 *   meanings: string[], meaningsEn: string[], jlptLevel: string}>} kanji
 *   character -> entry. Kanji characters are unique across the whole
 *   dataset (confirmed by this project's own `kanji_char_lists.py`-
 *   locked authoring discipline — no character appears at two JLPT
 *   levels), so a bare `Map` keyed by character alone is exact, not
 *   approximate. `jlptLevel` is the character's own real level, used by
 *   the P0 metadata-authority fix's difficulty derivation. */
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
    jlptLevel: k.jlptLevel,
  }]));
  return _kanjiMap;
}

/** @return {Map<string, {reading: string, jlptLevel: string}>}
 * compound-word kanji string -> {reading, jlptLevel}, built once from
 * every `functions/data/kotoba/*.json` category file (mirroring
 * `assets/data/kotoba/*.json`, the same files
 * `KanjiComboRepository._compoundPool` draws from). If more than one
 * word happens to share the same kanji string (not expected, not
 * asserted elsewhere in this dataset either), the first one found wins —
 * an acceptable, documented simplification: whichever real word the
 * client's own pool search would have found is what its `reading`/
 * `jlptLevel` are checked against either way. */
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
        _kotobaByKanji.set(w.kanji, {reading: w.reading, jlptLevel: w.jlptLevel});
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

/** Neutral sentinel returned for `difficultyValue`/`repeatValue` when a
 * submission has zero valid (dataset-resolvable) answers to derive
 * anything from — old-client/malformed submissions, per the P0
 * metadata-authority fix. Deliberately not `null`/`undefined`: this
 * value only ever reaches `repeatKeyFor(moduleType, {[field]: value})`/
 * `difficultyMultiplierFor(value)`, and `serverScore` is already 0 for
 * every submission that hits this path, so the resulting points are `0
 * × anything = 0` regardless — this sentinel exists purely so the
 * stored `examHistoryGraded` record and the repeat-cycle bucket it
 * lands in are legible ("ungraded", not "undefined" or a stringified
 * `null`), not because its exact value is scoring-relevant.
 */
const UNGRADED = "ungraded";

/**
 * Deterministic majority vote over [values] (already filtered to only
 * the real, dataset-resolved values — never raw client strings). Ties
 * resolve to the lexicographically smallest candidate, so the same
 * input always produces the same output with no randomness — see the
 * P0 metadata-authority design's own tie-break rule.
 *
 * @param {string[]} values
 * @return {string|null} the majority value, or `null` if [values] is
 *   empty (caller substitutes [UNGRADED]).
 */
function majorityOf(values) {
  if (values.length === 0) return null;
  const counts = new Map();
  for (const v of values) counts.set(v, (counts.get(v) || 0) + 1);
  let best = null;
  let bestCount = -1;
  for (const [value, count] of counts) {
    if (count > bestCount || (count === bestCount && value < best)) {
      best = value;
      bestCount = count;
    }
  }
  return best;
}

/**
 * Kana's difficulty AND repeat identity are the same concept (`type`),
 * unlike the other three modules — see `global_points.js`'s own
 * `MODULES` doc comment for why. Derived from the REAL `type` of every
 * valid (dataset-resolved) answer, via set membership rather than
 * majority: `hiragana` if every valid answer is hiragana, `katakana` if
 * every valid answer is katakana, `mixed` if both scripts genuinely
 * appear — `mixed` is a real, legitimate composition category (all
 * three map to the identical 1.0 difficulty multiplier, so there is
 * nothing to escalate here either way), not an attacker's chosen label,
 * so a majority vote would be the wrong tool: a 9-hiragana/1-katakana
 * REAL session is genuinely mixed, not "mostly hiragana".
 *
 * @param {Array<{contentId: string}>} deduped
 * @param {Map<string, {type: string}>} kanaMap
 * @return {string} `hiragana`/`katakana`/`mixed`/[UNGRADED]
 */
function deriveKanaType(deduped, kanaMap) {
  let sawHiragana = false;
  let sawKatakana = false;
  for (const a of deduped) {
    const entry = kanaMap.get(a.contentId);
    if (!entry) continue;
    if (entry.type === "hiragana") sawHiragana = true;
    else if (entry.type === "katakana") sawKatakana = true;
  }
  if (sawHiragana && sawKatakana) return "mixed";
  if (sawHiragana) return "hiragana";
  if (sawKatakana) return "katakana";
  return UNGRADED;
}

function gradeKana(answers) {
  const kana = loadKana();
  const deduped = dedupeAndCap(answers, MAX_TOTAL.kana);
  let score = 0;
  for (const a of deduped) {
    const entry = kana.get(a.contentId);
    if (entry !== undefined && a.submittedText === entry.romaji) score++;
  }
  const type = deriveKanaType(deduped, kana);
  return {
    serverScore: score, serverTotal: deduped.length,
    difficultyValue: type, repeatValue: type,
  };
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
  return {deduped, score};
}

/** Majority real `jlptLevel` among [deduped]'s valid, dataset-resolved
 * answers — shared by Dokkai (difficulty AND repeat identity),
 * Choukai's difficulty, and KanjiCombo's difficulty. See
 * `majorityOf`'s own doc comment for the tie-break rule; a document
 * mixing content from two real levels (never possible via the app's own
 * UI, only via a direct/forged Firestore write) still resolves
 * deterministically rather than being rejected outright — the result
 * is bounded by the same real levels the content actually belongs to,
 * never a client-invented one.
 *
 * @param {Array<{contentId: string}>} deduped
 * @param {Map<string, {jlptLevel: string}>} datasetMap
 * @return {string} a real `N5`.."N1" value, or [UNGRADED].
 */
function deriveMajorityLevel(deduped, datasetMap) {
  const levels = [];
  for (const a of deduped) {
    const entry = datasetMap.get(a.contentId);
    if (entry && entry.jlptLevel) levels.push(entry.jlptLevel);
  }
  return majorityOf(levels) ?? UNGRADED;
}

function gradeDokkai(answers) {
  const dokkai = loadDokkai();
  const {deduped, score} = gradeIndexed(dokkai, answers, MAX_TOTAL.dokkai);
  const level = deriveMajorityLevel(deduped, dokkai);
  return {
    serverScore: score, serverTotal: deduped.length,
    // Dokkai's difficulty AND repeat identity are both `jlptLevel` (its
    // own `itemId` is a fresh timestamp every session and was never a
    // legitimate repeat key — see `global_points.js`'s `MODULES` doc
    // comment, unchanged by this fix), so the same derived level serves
    // both, exactly mirroring the pre-fix `repeatField===difficultyField`
    // design intent, just server-derived instead of client-trusted.
    difficultyValue: level, repeatValue: level,
  };
}

/** Majority real clip id among [deduped]'s valid Choukai answers —
 * Choukai's repeat identity (unlike Dokkai's) is the clip itself, not
 * its level, since `itemId` was always meant to be the real, stable
 * `clip.id` (confirmed via `choukai_exam_screen.dart`'s own
 * `itemId: clip.id`) rather than a per-session value. Deriving it from
 * `answers` closes the farming vector while collapsing the repeat-key
 * space to exactly the dataset's own finite, real clip ids (150 today)
 * instead of any client-invented string. */
function deriveChoukaiClipId(deduped, choukaiMap) {
  const clipIds = [];
  for (const a of deduped) {
    const entry = choukaiMap.get(a.contentId);
    if (entry && entry.clipId) clipIds.push(entry.clipId);
  }
  return majorityOf(clipIds) ?? UNGRADED;
}

function gradeChoukai(answers) {
  const choukai = loadChoukai();
  const {deduped, score} = gradeIndexed(choukai, answers, MAX_TOTAL.choukai);
  return {
    serverScore: score, serverTotal: deduped.length,
    difficultyValue: deriveMajorityLevel(deduped, choukai),
    repeatValue: deriveChoukaiClipId(deduped, choukai),
  };
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
/** Resolves one `{contentKey}|{promptKind}` answer's `key` half against
 * both trusted content maps, returning which one matched and that
 * entry's own real `jlptLevel` — shared between grading and the P0
 * metadata-authority derivation below, so both read the exact same
 * resolution instead of two independently-written lookups that could
 * drift apart.
 *
 * @return {{mode: "single"|"combo", jlptLevel: string}|null}
 */
function resolveKanjiComboKey(key, kanji, kotoba) {
  const kanjiEntry = kanji.get(key);
  if (kanjiEntry) return {mode: "single", jlptLevel: kanjiEntry.jlptLevel};
  const kotobaEntry = kotoba.get(key);
  if (kotobaEntry) return {mode: "combo", jlptLevel: kotobaEntry.jlptLevel};
  return null;
}

/**
 * KanjiCombo's repeat identity reproduces the existing, already-real
 * `itemId` shape (`single_n5`/`combo_n1`, see
 * `KanjiComboExamScreen._onComplete`'s own `itemId:` construction) —
 * `mode` (single kanji vs. compound word) and `level` are both derived
 * from the majority of [deduped]'s real, resolved content rather than
 * trusted from `docData.itemId` directly, closing the P0 metadata-
 * authority farming vector while keeping the bucket shape a learner's
 * own history would already recognize.
 *
 * @param {Array<{mode: string, jlptLevel: string}>} resolved every
 *   valid answer's own [resolveKanjiComboKey] result.
 * @return {string} `"{mode}_{level}"` lowercased, or [UNGRADED].
 */
function deriveKanjiComboRepeatValue(resolved) {
  if (resolved.length === 0) return UNGRADED;
  const mode = majorityOf(resolved.map((r) => r.mode));
  const level = majorityOf(resolved.map((r) => r.jlptLevel).filter(Boolean));
  if (!mode || !level) return UNGRADED;
  return `${mode}_${level.toLowerCase()}`;
}

function gradeKanjiCombo(answers) {
  const kanji = loadKanjiByCharacter();
  const kotoba = loadKotobaByKanji();
  const deduped = dedupeAndCap(answers, MAX_TOTAL.kanjiCombo);
  let score = 0;
  const resolved = [];
  for (const a of deduped) {
    const sep = a.contentId.lastIndexOf("|");
    if (sep === -1) continue;
    const key = a.contentId.slice(0, sep);
    const kind = a.contentId.slice(sep + 1);

    const match = resolveKanjiComboKey(key, kanji, kotoba);
    if (match) resolved.push(match);

    let candidates = [];
    const kanjiEntry = kanji.get(key);
    if (kanjiEntry) {
      candidates = kind === "reading" ?
        [...kanjiEntry.onyomi, ...kanjiEntry.kunyomi].map(stripOkuriganaMarker) :
        [...kanjiEntry.meanings, ...kanjiEntry.meaningsEn];
    } else if (kotoba.has(key)) {
      // Combination mode is always a reading question — see
      // `_buildQuestions`' own `answerOf: (w) => w.reading` call site.
      candidates = [kotoba.get(key).reading];
    }
    if (candidates.includes(a.submittedText)) score++;
  }
  return {
    serverScore: score, serverTotal: deduped.length,
    // Reuses the SAME `resolved` list the repeat-identity derivation
    // below builds from — one resolution pass, not two independently-
    // written lookups that could drift apart (Phase 3's own instruction).
    difficultyValue: majorityOf(resolved.map((r) => r.jlptLevel).filter(Boolean)) ?? UNGRADED,
    repeatValue: deriveKanjiComboRepeatValue(resolved),
  };
}

/**
 * @param {string} moduleType one of the four `global_points.js` `MODULES`
 *   keys.
 * @param {Array<{contentId: string, submittedText: string}>} answers raw,
 *   client-submitted, untrusted.
 * @return {{serverScore: number, serverTotal: number, difficultyValue:
 *   string, repeatValue: string}} `difficultyValue`/`repeatValue` are the
 *   P0 metadata-authority fix's server-derived replacements for
 *   `docData[spec.difficultyField]`/`docData[spec.repeatField]` — see
 *   `TEISOU_ROADMAP_MASTER.md`'s "Global-Points Metadata Authority"
 *   sections. Both are derived from the SAME deduplicated/capped answer
 *   list [dedupeAndCap] already produces for grading (Phase 3's own
 *   "avoid three independent pipelines" instruction), never from
 *   `answers`' un-deduped raw form and never from any client-supplied
 *   field. [UNGRADED] when zero valid answers exist — harmless, since
 *   `serverScore` is already 0 in that case and `0 × anything = 0`.
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
  UNGRADED,
  dedupeAndCap,
  stripOkuriganaMarker,
  majorityOf,
  loadKana,
  loadDokkai,
  loadChoukai,
  loadKanjiByCharacter,
  loadKotobaByKanji,
  deriveKanaType,
  deriveMajorityLevel,
  deriveChoukaiClipId,
  deriveKanjiComboRepeatValue,
  gradeKana,
  gradeDokkai,
  gradeChoukai,
  gradeKanjiCombo,
  gradeAttempt,
};

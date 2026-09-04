/**
 * Card Game Mode's bot opponent — Tahap 3 butir 8 in
 * NOTES_CARD_GAME_MODE.md. "Bentuk konkret bot — dikonfirmasi: server
 * yang memutuskan": a bot match is a completely ordinary
 * `battleMatches` doc, one `players` entry set to the `BOT_UID`
 * sentinel instead of a real Firebase Auth uid. Whenever the match doc
 * shows it's the bot's turn to *answer* (never when the bot merely owns
 * the deck a human is answering from — that needs no bot logic at all),
 * this file's trigger immediately rolls the dice, writes an answer, and
 * lets `battle_scoring.js`'s own trigger score it exactly like a human
 * answer — one scoring pipeline for both, per the notes' explicit
 * reasoning ("supaya bintang/poin/EXP dari lawan bot lewat SATU sumber
 * kebenaran yang sama dengan lawan manusia").
 *
 * **The delay is cosmetic, not security-critical.** The correct/wrong
 * decision and the answer text are both decided and written the moment
 * it's the bot's turn — nothing waits. `revealAt` (write time + a
 * random delay from the tier's range) is carried alongside so a human
 * opponent's client can choose to hold off *displaying* "bot menjawab:
 * ..." until that time, for the illusion of the bot thinking — but
 * `officialScore` is already final by then regardless. A modified
 * client that ignores `revealAt` only sees the bot answer sooner, never
 * a different result. (The Flutter client doesn't honor `revealAt` yet
 * — see NOTES_CARD_GAME_MODE.md's butir 8 entry for why that's
 * deliberately deferred rather than skipped silently.)
 */

const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");

const kanaData = require("./data/kana_data.json");
const {resolveCorrectRomaji} = require("./battle_scoring")._internal;

function db() {
  return getFirestore();
}

const BOT_UID = "BOT";

/** Locked in NOTES_CARD_GAME_MODE.md's "Kurva kesulitan" table — keyed
 * by `BattleMatch.cardTierContent`'s Dart-side string key
 * (card_game_rank.dart's `CardTierContentX.key`), so no separate
 * translation table is needed between the two sides. */
const DIFFICULTY = {
  hiragana: {correctProbability: 0.50, revealMinSec: 15, revealMaxSec: 30},
  katakanaAndKanaCombo: {correctProbability: 0.65, revealMinSec: 10, revealMaxSec: 25},
  kanjiN5: {correctProbability: 0.80, revealMinSec: 6, revealMaxSec: 18},
  kanjiN4N3: {correctProbability: 0.92, revealMinSec: 3, revealMaxSec: 12},
  kanjiN2N1: {correctProbability: 0.97, revealMinSec: 2, revealMaxSec: 8},
};

function difficultyFor(cardTierContent) {
  return DIFFICULTY[cardTierContent] || DIFFICULTY.hiragana;
}

// --- Synthesizing a hiragana answer from a romaji reading ---
//
// Kanji cards are answered in hiragana, but this dataset only stores
// each word's *romaji* reading (see battle_scoring.js's own doc
// comment on why — there is no stored hiragana form anywhere). The bot
// still needs to "type" something. Building a general romaji->hiragana
// converter was explicitly rejected elsewhere in the notes as
// ambiguous ("'ji' bisa berarti じ atau ぢ") — but that concern doesn't
// apply here: the synthesized hiragana is never shown as a claimed-
// correct dictionary spelling or taught to anyone, it only needs to
// **round-trip through this same file's own toRomaji-equivalent
// forward converter** back to the original romaji, so the scorer
// agrees it's correct. Self-consistency with one specific function,
// not linguistic accuracy, is the actual requirement — and that's
// fully achievable: every hiragana romaji string in kana_data.json is
// unique (verified — no two hiragana share a romaji), so the reverse
// lookup below is unambiguous by construction.

const HIRAGANA_ROMAJI_TO_CHAR = {};
for (const k of kanaData) {
  if (k.type === "hiragana") {
    HIRAGANA_ROMAJI_TO_CHAR[k.romaji] = k.character;
  }
}

// Every consonant letter this dataset's hiragana romaji strings actually
// start with (verified against the real kana_data.json, not guessed) —
// "c" matters here specifically for ち/ちゃ/ちゅ/ちょ's "ch-" romaji, which
// an earlier version of this list missed, silently breaking gemination
// detection for every reading containing one (e.g. "icchi").
const CONSONANTS = new Set("bcdfghjkmprstwyz".split(""));

/** Best-effort romaji -> hiragana, good enough to round-trip through
 * this file's own `toRomaji` (imported from battle_scoring.js) for
 * 7268 of the 7274 real readings in `data/kanji_word_readings.json`
 * (verified by a full-dataset script, not just spot-checked — see
 * NOTES_CARD_GAME_MODE.md's Tahap 3 butir 8 entry for the exact
 * command). Returns `null` on the remaining 6, which `buildBotAnswer`
 * already handles gracefully (empty-string answer, scored as wrong,
 * never a crash): "botchan"/"setchuu" use Hepburn's "tch"-before-ち
 * gemination spelling, which this function deliberately does not
 * special-case (see the comment in `hiraganaForSegment` below); two
 * more ("Wang", the two "Yō..." readings) aren't standard Hepburn at
 * all — a pinyin surname and macron'd non-ASCII readings; and
 * "kouhu" is a likely "hu" vs "fu" spelling quirk in the source
 * dataset. All six are rare proper-noun/loanword edge cases, not
 * common vocabulary. */
function hiraganaForRomaji(romaji) {
  // Apostrophes ("ren'ai"), hyphens ("ken-eki"), and spaces ("keiken ga
  // asai" — several dataset readings are short phrases, not single
  // compound words) all exist in Hepburn purely to mark a segment
  // boundary a human reader needs — most often disambiguating an ん
  // before a vowel/y from what would otherwise greedy-parse as the next
  // mora starting with n (without the mark, "renai" reads as re-na-i,
  // not the intended re-n-ai). None of the three ever produces a
  // character of its own, so each segment is parsed independently and
  // the results are simply concatenated — real Japanese has no spaces
  // between words either.
  return romaji
      .split(/['\-\s]+/)
      .map((segment) => hiraganaForSegment(segment))
      .reduce((acc, part) => (acc === null || part === null ? null : acc + part), "");
}

function hiraganaForSegment(romaji) {
  const lower = romaji.toLowerCase();
  let out = "";
  let i = 0;
  while (i < lower.length) {
    // Gemination (っ): two identical consonant letters in a row (not
    // "nn", which is ん followed by a vowel-less n-start mora, handled
    // by the normal table lookup below instead).
    if (
      i + 1 < lower.length &&
      lower[i] === lower[i + 1] &&
      CONSONANTS.has(lower[i])
    ) {
      out += "っ";
      i += 1;
      continue;
    }
    // Deliberately NOT handling "tch"-style spelling (Hepburn's other
    // common way to write gemination before ち/ちゃ/ちゅ/ちょ, e.g.
    // "botchan") as an alternate trigger here, even though it's more
    // linguistically standard than plain letter-doubling: `toRomaji`
    // (this file's own forward converter, ported from
    // romaji_converter.dart) always re-encodes っ + ちゃ as "ccha", not
    // "tcha" — doubling the *next mora's own first letter*, unconditionally.
    // Matching that exactly is what self-consistency actually requires,
    // even though it means the ~2 dataset readings spelled the "tch" way
    // ("botchan", "setchuu") can never round-trip correctly no matter how
    // this function is written — the mismatch is between the *stored
    // reading* and what the scorer computes, a pre-existing correctness
    // gap in the dataset/scorer pair that predates this file and affects
    // a human player typing the right hiragana for those two words too,
    // not something introduced or fixable here. See
    // NOTES_CARD_GAME_MODE.md's Tahap 3 butir 8 entry.

    let matched = false;
    for (let len = 3; len >= 1; len--) {
      if (i + len > lower.length) continue;
      const chunk = lower.slice(i, i + len);
      const char = HIRAGANA_ROMAJI_TO_CHAR[chunk];
      if (char) {
        out += char;
        i += len;
        matched = true;
        break;
      }
    }
    if (!matched) return null;
  }
  return out;
}

// --- Wrong-answer distractors ---
//
// A wrong answer should be *plausible* wrong, not empty or random
// noise — the notes point at kanji_combo_repository.dart's
// dakuten/vowel-row mutation distractors as the pattern worth reusing
// (not the code itself, which is Dart). This ports the same idea: flip
// one mora's voicing or shift it within its vowel row.

const DAKUTEN_PAIRS = [
  ["か", "が"], ["き", "ぎ"], ["く", "ぐ"], ["け", "げ"], ["こ", "ご"],
  ["さ", "ざ"], ["し", "じ"], ["す", "ず"], ["せ", "ぜ"], ["そ", "ぞ"],
  ["た", "だ"], ["ち", "ぢ"], ["つ", "づ"], ["て", "で"], ["と", "ど"],
  ["は", "ば"], ["ひ", "び"], ["ふ", "ぶ"], ["へ", "べ"], ["ほ", "ぼ"],
];
const HANDAKUTEN_PAIRS = [
  ["は", "ぱ"], ["ひ", "ぴ"], ["ふ", "ぷ"], ["へ", "ぺ"], ["ほ", "ぽ"],
];

/** Mutates one randomly-picked character of [hiragana] via a dakuten/
 * handakuten toggle where possible, falling back to swapping two
 * adjacent characters if none of them have one — always returns
 * *something different* from the input (never silently equal), since a
 * "wrong answer" identical to the right one would be a real scoring
 * bug, not just an unconvincing distractor. */
function mutateHiragana(hiragana, random) {
  const chars = Array.from(hiragana);
  if (chars.length === 0) return hiragana;

  const pairs = [...DAKUTEN_PAIRS, ...HANDAKUTEN_PAIRS];
  const mutable = [];
  for (let i = 0; i < chars.length; i++) {
    for (const [plain, marked] of pairs) {
      if (chars[i] === plain) mutable.push([i, marked]);
      if (chars[i] === marked) mutable.push([i, plain]);
    }
  }
  if (mutable.length > 0) {
    const [index, replacement] = mutable[Math.floor(random() * mutable.length)];
    chars[index] = replacement;
    return chars.join("");
  }
  if (chars.length >= 2) {
    const i = Math.floor(random() * (chars.length - 1));
    const swapped = [...chars];
    [swapped[i], swapped[i + 1]] = [swapped[i + 1], swapped[i]];
    return swapped.join("");
  }
  // Single character with no dakuten/handakuten form (e.g. あ) — no
  // structural mutation is available, so just pick a different vowel
  // kana entirely as a last resort.
  return chars[0] === "あ" ? "い" : "あ";
}

// --- Deciding and writing the bot's move ---

function randomInRange(min, max, random) {
  return min + random() * (max - min);
}

/** Builds the bot's answer text (correct or a plausible wrong one) and
 * a `revealAt` timestamp for the given card. `random` is injectable for
 * tests; production calls always use `Math.random`. */
function buildBotAnswer(cardTierContentKey, cardId, random = Math.random) {
  const resolved = resolveCorrectRomaji(cardId);
  if (!resolved) return null;

  const difficulty = difficultyFor(cardTierContentKey);
  const isCorrect = random() < difficulty.correctProbability;
  const revealDelaySec = randomInRange(
      difficulty.revealMinSec, difficulty.revealMaxSec, random,
  );

  let text;
  if (!resolved.answerInHiragana) {
    // Kana card — the correct answer is already the exact string the
    // scorer compares against; a wrong one is simply a different real
    // kana's romaji (still a real mora, never gibberish).
    text = isCorrect ?
      resolved.correctRomaji :
      kanaData[Math.floor(random() * kanaData.length)].romaji;
  } else {
    const correctHiragana = hiraganaForRomaji(resolved.correctRomaji);
    if (correctHiragana === null) {
      // Could not synthesize even the correct form for this reading —
      // one of the 6 known dataset edge cases documented on
      // `hiraganaForRomaji` above (or, in principle, an unknown one)
      // — fail toward "bot answers wrong" rather than crash the
      // trigger or write nothing.
      text = "";
    } else {
      text = isCorrect ? correctHiragana : mutateHiragana(correctHiragana, random);
    }
  }

  return {
    text,
    revealAt: new Date(Date.now() + revealDelaySec * 1000),
  };
}

/** Writes the bot's answer for [round] and advances the match's
 * `currentRound` — the same shape `BattleRepository.submitAnswer` uses
 * on the client side, just performed here by the Cloud Function on the
 * bot's behalf. Guards against double-processing (already-answered
 * round, or the round having moved on) inside the transaction, same as
 * the Dart original. */
async function playBotTurn(matchId, round, cardId, cardTierContentKey) {
  const answer = buildBotAnswer(cardTierContentKey, cardId);
  if (!answer) return;

  const matchRef = db().collection("battleMatches").doc(matchId);
  const answerRef = matchRef.collection("answers").doc(String(round));

  await db().runTransaction(async (transaction) => {
    const snapshot = await transaction.get(matchRef);
    const match = snapshot.data();
    if (!match) return;
    if (match.currentRound !== round) return;

    transaction.set(answerRef, {
      byUid: BOT_UID,
      text: answer.text,
      submittedAt: FieldValue.serverTimestamp(),
      revealAt: answer.revealAt,
    });
    transaction.update(matchRef, {
      currentRound: round + 1,
      turnStartedAt: FieldValue.serverTimestamp(),
    });
  });
}

exports.onBattleMatchWritten = onDocumentWritten(
    "battleMatches/{matchId}",
    async (event) => {
      const after = event.data.after;
      if (!after || !after.exists) return; // deleted
      const match = after.data();
      if (match.result) return; // already concluded
      // FASE C — a match with anyone in `absence` is paused (see
      // `BattleMatch.absence`'s own doc comment), and this had no
      // awareness of that at all before this check: `result` stays null
      // for the whole pause, so without this the bot would keep playing
      // turns while the human opponent's own 30-second recovery window
      // was still open, racing ahead of a match `battle_screen.dart`
      // itself was showing as fully frozen.
      if (match.absence && Object.keys(match.absence).length > 0) return;

      const players = match.players || [];
      if (!players.includes(BOT_UID)) return; // not a bot match

      const round = match.currentRound;
      const turnOrder = match.turnOrder || [];
      if (round < 0 || round >= turnOrder.length) return;
      const entry = turnOrder.find((e) => e.round === round);
      if (!entry) return;

      const answerer = players.find((p) => p !== entry.deckOwnerUid) ||
        entry.deckOwnerUid;
      if (answerer !== BOT_UID) return; // bot owns the deck, not answering

      const matchId = event.params.matchId;
      const answerRef = db()
          .collection("battleMatches").doc(matchId)
          .collection("answers").doc(String(round));
      const existing = await answerRef.get();
      if (existing.exists) return; // already played (retry safety)

      // **Wait for the card to actually be on the table.** Its owner has
      // ten seconds to choose which of their cards to send, and the bot
      // used to answer the instant the round opened — so on every round a
      // human owned, the bot answered the dealt card before the human
      // could pick anything, and the choice never happened. The reveal is
      // always written (the owner's own client writes the dealt card if
      // the window runs out), and that write re-triggers this function.
      const playedCards = match.playedCards || {};
      const cardId = playedCards[String(round)];
      if (entry.deckOwnerUid !== BOT_UID && !cardId) return;

      await playBotTurn(
          matchId, round, cardId || entry.cardId, match.cardTierContent);
    },
);

exports.BOT_UID = BOT_UID;

// Exported for tests only.
exports._internal = {hiraganaForRomaji, mutateHiragana, buildBotAnswer, difficultyFor};

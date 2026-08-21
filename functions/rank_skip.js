/**
 * The rank-skip exam.
 *
 * A learner who already reads kanji had no way into Card Game Mode
 * except by grinding hiragana at Bronze and katakana at Silver, which is
 * where the request for this came from: *"agar user tidak bosan di
 * hiragana dan katakana"*. This lets them prove the target tier's own
 * cards and start there instead.
 *
 * **Graded here, on the server, and not by the app.** That is the whole
 * design constraint, and it is not caution for its own sake:
 * `firestore.rules` lets a signed-in user write anything under
 * `users/{uid}/**`, which includes `examHistory`. A function that read a
 * client-written score and promoted on the strength of it would hand
 * every player a one-line route to Emerald — exactly the hole the rules
 * close by forbidding client writes to `cardGameRank` in the first
 * place. So the answer key never leaves the server: it is written to
 * `rankSkipExams/{uid}`, a collection `firestore.rules` denies the
 * client outright, and only the card ids go back to the app.
 *
 * What this does *not* defend against is a modified app, which holds the
 * whole dataset in its assets and can therefore answer any card it is
 * shown. That is equally true of every battle already played, and
 * closing it would mean not shipping the content offline at all. The
 * threat this design does close is the cheap one: forging a result with
 * a single Firestore write from an unmodified client.
 */

const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");

const kanaData = require("./data/kana_data.json");
const kanjiIdsByLevel = require("./data/kanji_ids_by_level.json");
const battleScoring = require("./battle_scoring");
const battleStars = require("./battle_stars");

const {toRomaji, resolveCorrectRomaji} = battleScoring._internal;

function db() {
  return getFirestore();
}

/** Cards per exam. Matches a battle's main phase, so "pass the exam"
 * and "play a round of that tier" ask for the same stretch of work. */
const QUESTIONS = 20;

/** Cards that must be right. Deliberately high: this replaces roughly
 * thirty won matches, and a pass mark that a lucky run could reach
 * would make the ladder below it pointless. */
const PASS_MARK = 18;

/** How long a failed attempt is locked out for. Long enough that
 * grinding the exam is slower than climbing, short enough that a child
 * who was simply not ready today is not shut out of the mode. */
const COOLDOWN_HOURS = 24;

/** How long a drawn exam stays valid.
 *
 * Twenty cards at thirty seconds each is ten minutes of answering; the
 * rest is slack for loading, reading, and a phone that rings. Tightened
 * from thirty minutes once the app grew a per-card clock: that clock is
 * the pressure a player feels, but it runs on their device and can be
 * edited away, while this cannot. Without a ceiling here, an exam left
 * open is an exam taken with a dictionary.
 *
 * Expiring is not failing — see the handler. Running out of time with
 * the app closed is not the same as answering wrongly, and does not
 * cost the day's wait. */
const SESSION_MINUTES = 15;

/** Bronze is where everyone starts, so there is nothing to skip to. */
const SKIPPABLE = ["silver", "gold", "diamond", "emerald"];

/**
 * The cards a tier is played with — the same mapping as
 * `CardGameTierX.cardContent` and `_poolFor` on the client, restated
 * here because the server cannot import Dart.
 *
 * **Kept honest by a test** (`rank_skip.test.js`) rather than by
 * intention: the two lists are compared against the same source data,
 * so a change to one that is not made to the other fails the build
 * instead of quietly examining the wrong characters.
 */
function poolFor(tier) {
  switch (tier) {
    case "silver":
      return kanaData
          .filter((k) => k.type === "katakana" ||
              (k.type === "hiragana" && (k.row || 0) > 10))
          .map((k) => k.id);
    case "gold":
      return kanjiIdsByLevel.n5 || [];
    case "diamond":
      return (kanjiIdsByLevel.n4 || []).concat(kanjiIdsByLevel.n3 || []);
    case "emerald":
      return (kanjiIdsByLevel.n2 || []).concat(kanjiIdsByLevel.n1 || []);
    default:
      return [];
  }
}

/** Picks [count] distinct ids, or as many as the pool holds. */
function sample(pool, count) {
  const copy = pool.slice();
  for (let i = copy.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [copy[i], copy[j]] = [copy[j], copy[i]];
  }
  return copy.slice(0, Math.min(count, copy.length));
}

/**
 * Whether one typed answer matches one card, by exactly the rule a
 * battle uses — `battle_scoring`'s, imported rather than rewritten, so
 * an exam cannot mark right an answer a match would mark wrong.
 */
function isCorrect(cardId, answerText) {
  const resolved = resolveCorrectRomaji(cardId);
  if (!resolved) return false;
  let typed = (answerText || "").trim();
  if (resolved.answerInHiragana) typed = toRomaji(typed);
  return typed.length > 0 &&
      typed.toLowerCase() === resolved.correctRomaji.trim().toLowerCase();
}

function examRef(uid) {
  return db().collection("rankSkipExams").doc(uid);
}

/** Tiers strictly above the one held now, in ladder order. */
function tiersAbove(currentTier) {
  const order = battleStars._internal.TIERS;
  const at = order.indexOf(currentTier);
  return order.slice(at + 1).filter((t) => SKIPPABLE.includes(t));
}

exports.startRankSkipExam = onCall(async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in first.");

  const targetTier = request.data && request.data.targetTier;
  if (!SKIPPABLE.includes(targetTier)) {
    throw new HttpsError("invalid-argument", "Unknown target tier.");
  }

  const userSnap = await db().collection("users").doc(uid).get();
  const current = battleStars._internal.readRank(userSnap.data());
  if (!tiersAbove(current.tier).includes(targetTier)) {
    // Includes the tier already held: an exam that cannot raise anyone
    // is a way to waste a cooldown, not a feature.
    throw new HttpsError(
        "failed-precondition",
        "That tier is not above your current rank.",
    );
  }

  const ref = examRef(uid);
  const existing = (await ref.get()).data() || {};
  const lockedUntil = existing.lockedUntil && existing.lockedUntil.toDate();
  if (lockedUntil && lockedUntil > new Date()) {
    throw new HttpsError("resource-exhausted", "Still cooling down.", {
      lockedUntil: lockedUntil.toISOString(),
    });
  }

  const cardIds = sample(poolFor(targetTier), QUESTIONS);
  if (cardIds.length < QUESTIONS) {
    throw new HttpsError("internal", "Not enough cards for that tier.");
  }

  const sessionId = ref.collection("_").doc().id;
  await ref.set({
    lockedUntil: existing.lockedUntil || null,
    session: {
      sessionId,
      tier: targetTier,
      cardIds,
      startedAt: FieldValue.serverTimestamp(),
    },
  }, {merge: true});

  // Only the ids. The client resolves them against its own bundled
  // data, exactly as it resolves a battle's `turnOrder`.
  return {
    sessionId,
    targetTier,
    cardIds,
    questions: cardIds.length,
    passMark: PASS_MARK,
  };
});

exports.submitRankSkipExam = onCall(async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in first.");

  const sessionId = request.data && request.data.sessionId;
  const answers = (request.data && request.data.answers) || [];
  if (!sessionId || !Array.isArray(answers)) {
    throw new HttpsError("invalid-argument", "sessionId and answers.");
  }

  const ref = examRef(uid);
  const stored = (await ref.get()).data() || {};
  const session = stored.session;
  if (!session || session.sessionId !== sessionId) {
    throw new HttpsError("failed-precondition", "No exam in progress.");
  }

  const startedAt = session.startedAt && session.startedAt.toDate();
  const expired = startedAt &&
      Date.now() - startedAt.getTime() > SESSION_MINUTES * 60 * 1000;
  if (expired) {
    // Cleared without a cooldown. Running out of time is not the same
    // as answering wrongly, and a child who put the phone down should
    // not be locked out for a day because of it.
    await ref.set({session: FieldValue.delete()}, {merge: true});
    throw new HttpsError("deadline-exceeded", "That exam expired.");
  }

  const cardIds = session.cardIds || [];
  let correct = 0;
  for (let i = 0; i < cardIds.length; i++) {
    if (isCorrect(cardIds[i], answers[i])) correct++;
  }
  const passed = correct >= PASS_MARK;

  const update = {session: FieldValue.delete()};
  if (!passed) {
    update.lockedUntil = new Date(
        Date.now() + COOLDOWN_HOURS * 60 * 60 * 1000,
    );
  }
  await ref.set(update, {merge: true});

  let promoted = false;
  if (passed) {
    const result = await battleStars.promoteToTierFloor(uid, session.tier);
    promoted = result.changed;
  }

  return {
    passed,
    promoted,
    correct,
    total: cardIds.length,
    passMark: PASS_MARK,
    targetTier: session.tier,
    lockedUntil: update.lockedUntil ?
        update.lockedUntil.toISOString() : null,
  };
});

exports._internal = {
  QUESTIONS,
  PASS_MARK,
  COOLDOWN_HOURS,
  SKIPPABLE,
  poolFor,
  sample,
  isCorrect,
  tiersAbove,
};

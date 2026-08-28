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

function examRef(firestore, uid) {
  return firestore.collection("rankSkipExams").doc(uid);
}

/** Tiers strictly above the one held now, in ladder order. */
function tiersAbove(currentTier) {
  const order = battleStars._internal.TIERS;
  const at = order.indexOf(currentTier);
  return order.slice(at + 1).filter((t) => SKIPPABLE.includes(t));
}

/**
 * Reads a stored date field back as a plain JS `Date`, accepting either
 * shape: a real Firestore `Timestamp` (`.toDate()`, what production
 * Firestore hands back for a field that was written as a `Date`) or an
 * already-plain `Date` (what a test's in-memory Firestore double may
 * store directly, since faithfully reproducing the Admin SDK's own
 * Date-to-Timestamp auto-coercion is a broader change than this file's
 * own fix needs — see the Rank-Skip Fix Phase note in
 * TEISOU_ROADMAP_MASTER.md for why that coercion was tried and reverted
 * at the shared-fake level instead of added here unconditionally).
 */
function toJsDate(value) {
  if (!value) return null;
  return typeof value.toDate === "function" ? value.toDate() : value;
}

/**
 * Core logic behind `startRankSkipExam`, pulled out so tests can pass a
 * `firestore` double — the same injection shape `spend_coins.js`'s
 * `spendCoinsFor`/`award_xp.js`'s `awardXpFor` already established in
 * this codebase. Added specifically because making the regression
 * tests for the fix below deterministic requires forcing two calls
 * into genuine interleaving around a real `runTransaction` retry, which
 * needs a Firestore double this file previously had no way to receive.
 *
 * **Rank-Skip Fix Phase (2026-08-29), BUG #1 (TOCTOU/cooldown race)**:
 * this used to read `lockedUntil` with a plain, non-transactional
 * `ref.get()` and then write the new session with a plain `ref.set()`
 * that unconditionally re-asserted whatever `lockedUntil` value it had
 * just read (`lockedUntil: existing.lockedUntil || null`). A
 * `submitRankSkipExam` call racing in between those two steps — reading
 * the same still-unlocked state, failing, and writing a fresh
 * `lockedUntil` — would have its own fresh lock silently clobbered back
 * to stale/null by this function's own later write, defeating the
 * cooldown outright (proven in the Rank-Skip Exam Audit, 2026-08-29).
 *
 * Fixed by making the whole read-then-write a single transaction on
 * `rankSkipExams/{uid}`, the same document `submitRankSkipExam`'s own
 * transaction below now also participates in — Firestore's optimistic
 * concurrency control means whichever of the two calls commits first
 * wins outright, and the other is forced to retry against the fresh
 * state rather than blindly overwriting it. The write itself no longer
 * even mentions `lockedUntil` at all: a `set(..., {merge: true})` that
 * never names a field leaves it exactly as it stood, which is both
 * simpler than "explicitly re-assert what I just read" and removes the
 * clobbering mechanism at its source, independent of the transaction
 * wrapping it.
 */
async function startRankSkipExamFor(uid, targetTier, options = {}) {
  if (!SKIPPABLE.includes(targetTier)) {
    throw new HttpsError("invalid-argument", "Unknown target tier.");
  }

  const firestore = options.firestore || db();

  const userSnap = await firestore.collection("users").doc(uid).get();
  const current = battleStars._internal.readRank(userSnap.data());
  if (!tiersAbove(current.tier).includes(targetTier)) {
    // Includes the tier already held: an exam that cannot raise anyone
    // is a way to waste a cooldown, not a feature.
    throw new HttpsError(
        "failed-precondition",
        "That tier is not above your current rank.",
    );
  }

  const ref = examRef(firestore, uid);

  return firestore.runTransaction(async (transaction) => {
    const existing = (await transaction.get(ref)).data() || {};
    const lockedUntil = toJsDate(existing.lockedUntil);
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
    transaction.set(ref, {
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
}

exports.startRankSkipExam = onCall(async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in first.");
  return startRankSkipExamFor(uid, request.data && request.data.targetTier);
});

/**
 * Core logic behind `submitRankSkipExam` — see `startRankSkipExamFor`'s
 * doc comment for the shared DI rationale. `options.promoteToTierFloor`
 * defaults to the real `battleStars.promoteToTierFloor` and exists so a
 * test can inject a controllable stand-in (e.g. one that throws, to
 * prove BUG #2's fix below) without needing its own Firestore double for
 * `battle_stars.js`'s internals — this file calls that function, it
 * does not reimplement any part of what it decides, so there remains
 * exactly one place that knows how a tier maps onto stars.
 *
 * **Rank-Skip Fix Phase (2026-08-29), BUG #2 (submit/promotion
 * atomicity)**: this used to delete the exam `session` unconditionally
 * — pass or fail — before ever calling `promoteToTierFloor`. If that
 * call then threw (a transient Firestore error, for instance;
 * `promoteToTierFloor` itself is already a correctly idempotent
 * transaction — the risk was never inside it, only in what could go
 * wrong *reaching* it), the whole call rejected with the session
 * already gone: a genuinely passed attempt, unrecoverable, with no
 * reward and no record that it ever happened.
 *
 * Fixed by **not deleting the session on a pass at all** inside the
 * grading step below. Grading (this function's first transaction, on
 * `rankSkipExams/{uid}`) only ever writes something when the attempt
 * FAILS (the cooldown + session-delete, exactly as before — still one
 * atomic write, still what makes BUG #1's fix work, since this is the
 * same transaction `startRankSkipExamFor` now conflicts against). On a
 * PASS, the session is left untouched on purpose: it is the durable,
 * re-readable record that *this exact attempt* passed, which is what
 * makes a retry after a downstream promotion failure safe — grading is
 * a pure function of `session.cardIds` + the submitted `answers`, so
 * re-submitting the same `sessionId` after a transient failure
 * re-derives the identical `passed: true` result and simply tries
 * `promoteToTierFloor` again, which is where the *real* idempotency
 * guarantee already lives (a second, successful call after a failed
 * first one — or two overlapping successful calls — both converge to
 * exactly one promotion, proven in `battle_stars.js`'s own transaction:
 * it only ever writes when the player's current standing is still
 * below the target tier's floor). Promotion is attempted, and only once
 * it has actually committed does a **second**, separate transaction
 * finally clear the session — guarded by re-checking the session's own
 * `sessionId` still matches, so a finalize that runs after the player
 * has already started a brand-new exam (nothing here blocks that; see
 * the audit's own recorded design note) cannot delete the wrong one.
 *
 * This is deliberately **not** a single cross-document transaction
 * spanning both `rankSkipExams/{uid}` and `users/{uid}` — that would
 * mean either reimplementing `promoteToTierFloor`'s own transaction
 * inline (a second place that knows the tier-to-stars mapping, which
 * both this file's own top-of-file doc comment and the fix
 * instructions for this phase explicitly rule out) or threading an
 * external transaction handle into `battle_stars.js`, a broader change
 * to a file no bug was found in. Two transactions plus
 * `promoteToTierFloor`'s own pre-existing idempotency is the smaller,
 * already-proven-safe shape.
 */
async function submitRankSkipExamFor(uid, sessionId, answers, options = {}) {
  if (!sessionId || !Array.isArray(answers)) {
    throw new HttpsError("invalid-argument", "sessionId and answers.");
  }

  const firestore = options.firestore || db();
  const promote = options.promoteToTierFloor || battleStars.promoteToTierFloor;
  const ref = examRef(firestore, uid);

  const graded = await firestore.runTransaction(async (transaction) => {
    const stored = (await transaction.get(ref)).data() || {};
    const session = stored.session;
    if (!session || session.sessionId !== sessionId) {
      throw new HttpsError("failed-precondition", "No exam in progress.");
    }

    const startedAt = toJsDate(session.startedAt);
    const expired = startedAt &&
        Date.now() - startedAt.getTime() > SESSION_MINUTES * 60 * 1000;
    if (expired) {
      // Cleared without a cooldown. Running out of time is not the same
      // as answering wrongly, and a child who put the phone down should
      // not be locked out for a day because of it.
      transaction.set(ref, {session: FieldValue.delete()}, {merge: true});
      throw new HttpsError("deadline-exceeded", "That exam expired.");
    }

    const cardIds = session.cardIds || [];
    let correct = 0;
    for (let i = 0; i < cardIds.length; i++) {
      if (isCorrect(cardIds[i], answers[i])) correct++;
    }
    const passed = correct >= PASS_MARK;

    let lockedUntilDate = null;
    if (!passed) {
      lockedUntilDate = new Date(
          Date.now() + COOLDOWN_HOURS * 60 * 60 * 1000,
      );
      transaction.set(ref, {
        session: FieldValue.delete(),
        lockedUntil: lockedUntilDate,
      }, {merge: true});
    }
    // On a pass: no write here. See the doc comment above for why.

    return {
      passed,
      correct,
      total: cardIds.length,
      tier: session.tier,
      lockedUntilDate,
    };
  });

  let promoted = false;
  if (graded.passed) {
    const result = await promote(uid, graded.tier);
    promoted = result.changed;

    // Now that promotion has actually committed, finalize the session —
    // an idempotent no-op if some other racing call already cleared it
    // (or if a new exam has since overwritten it, guarded by re-checking
    // the sessionId).
    await firestore.runTransaction(async (transaction) => {
      const stored = (await transaction.get(ref)).data() || {};
      if (stored.session && stored.session.sessionId === sessionId) {
        transaction.set(ref, {session: FieldValue.delete()}, {merge: true});
      }
    });
  }

  return {
    passed: graded.passed,
    promoted,
    correct: graded.correct,
    total: graded.total,
    passMark: PASS_MARK,
    targetTier: graded.tier,
    lockedUntil: graded.lockedUntilDate ?
        graded.lockedUntilDate.toISOString() : null,
  };
}

exports.submitRankSkipExam = onCall(async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in first.");

  const sessionId = request.data && request.data.sessionId;
  const answers = (request.data && request.data.answers) || [];
  return submitRankSkipExamFor(uid, sessionId, answers);
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
  toJsDate,
  startRankSkipExamFor,
  submitRankSkipExamFor,
};

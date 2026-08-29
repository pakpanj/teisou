/**
 * Global Points — Formula C, server-authoritative.
 *
 * `points = correct × difficultyMultiplier × 10 × 0.6^(n-1)`
 *
 * Decided in `GLOBAL_POINTS_FINAL_DECISION_MEMO.md`: an uncapped,
 * accumulate-forever ranking number for the "Top Global" leaderboard,
 * distinct from the older `globalScore` (a running-average of
 * score-percentage per category, capped at 100 per category — kept
 * unchanged elsewhere for its own purposes, never touched by this file).
 *
 * **Every interesting decision here is a pure function** — formula,
 * difficulty mapping, repeat-key derivation, and the award/idempotency/
 * reset decision all take plain data in and return plain data out, with
 * zero Firestore calls inside them. This mirrors `iap_states.js`'s own
 * split (`subscriptionGrants`, `isRetryablePlayState`) — the part worth
 * unit-testing is kept free of Admin SDK plumbing, which is why
 * `global_points.test.js` needs no emulator at all.
 *
 * **`decideAward` is the single place idempotency, the repeat-cycle
 * counter, and the reset window all meet** — deliberately one function
 * rather than three, since a caller (the live trigger, or the backfill
 * replay in `backfill_global_points.js`) always needs all three answered
 * together for one attempt: was this already awarded, what's `n` now,
 * and does the points at that `n` clear a 30-day-old cycle first.
 *
 * **Exam-history CONTENT honesty — CLOSED for score/total (P0 fix).**
 * This paragraph used to say `correct = Number(docData.score) || 0`
 * trusted the client's own self-reported score outright — that gap is
 * now closed. `correct` is `graded.serverScore`, computed by
 * [exam_grading.js]'s `gradeAttempt` independently re-grading
 * `docData.answers` (raw submitted answers, untrusted, but objectively
 * checkable) against this project's own bundled/mirrored content. A
 * forged `score`/`total` (the P0 audit's exact `score: 999999`
 * reproduction) no longer has any path into Global Points or the Weekly
 * Global Ranking payout — see `TEISOU_ROADMAP_MASTER.md`'s
 * "Exam-History Authority" audit + design + implementation sections for
 * the full history.
 *
 * **Difficulty/repeat-key metadata authority — CLOSED (follow-up P0
 * fix, "Global-Points Metadata Authority").** The paragraph above only
 * closed `score`/`total`; `docData[spec.difficultyField]`/
 * `docData[spec.repeatField]` were left reading raw, client-supplied
 * `type`/`jlptLevel`/`itemId` unvalidated — a SEPARATE, later-audited P0
 * vulnerability, not the bounded ~2.2x gap this paragraph originally
 * estimated. The real severity: `repeatKeyFor`'s entire anti-farming
 * defense was a client-invented string with no validation, so an
 * attacker could bypass the `0.6^(n-1)` decay indefinitely by inventing
 * a fresh value per fabricated document, reusing the same real (once-
 * obtained) correct answers — proven unbounded (linear amplification
 * with no ceiling, confirmed empirically at 20x/50 docs for Kana, 8x/20
 * docs for Choukai), not merely bounded. Fixed by deriving both
 * `difficulty`/`repeatKey` (below) from `graded.difficultyValue`/
 * `graded.repeatValue` — [exam_grading.js]'s `gradeAttempt` now derives
 * both from the SAME real, dataset-verified content the deduplicated
 * `answers` actually reference, never from `docData` directly. See
 * `TEISOU_ROADMAP_MASTER.md`'s "Global-Points Metadata Authority" audit
 * + design + implementation sections for the full history.
 */

const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const logger = require("firebase-functions/logger");
const {wibWeekId} = require("./wib_week");
const {gradeAttempt, GRADING_VERSION} = require("./exam_grading");

/** Points per correct answer at the lowest difficulty tier. */
const K = 10;

/** Per-repeat decay — see the Final Decision Memo's convergence analysis:
 * `Σ decay^i` for `i=0..∞` converges to `1/(1-0.6) = 2.5`, so even with
 * no reset at all, farming one item forever has a hard ceiling of
 * `base × 2.5` — the 30-day reset (below) only controls how many times a
 * year that ceiling can be re-earned, not whether it exists. */
const DECAY = 0.6;

/** Rolling reset window, in milliseconds — a repeat cycle for a given
 * `(uid, repeatKey)` starts over (n back to 1) once this much time has
 * passed since the cycle's first attempt, per the Final Decision Memo's
 * simulation (30 days chosen over 7/14 specifically because a *shorter*
 * window lets a determined farmer re-harvest the convergence ceiling
 * more times per year, not fewer). */
const REPEAT_CYCLE_WINDOW_MS = 30 * 24 * 60 * 60 * 1000;

/**
 * Difficulty multiplier by level/mode key. Kana carries no JLPT level at
 * all (`ExamResult.mode` is hiragana/katakana/mixed, pre-JLPT content),
 * so every kana mode maps to the same multiplier as N5 — both are the
 * app's entry tier. Keys are matched case-insensitively against whatever
 * the exam-history document's own field holds (`type` for kana,
 * `jlptLevel` for the other three) so a stray "n5" vs "N5" casing
 * difference across modules can't silently fall through to the
 * `unknown` default below.
 */
const DIFFICULTY_BY_LEVEL = {
  hiragana: 1.0,
  katakana: 1.0,
  mixed: 1.0,
  n5: 1.0,
  n4: 1.2,
  n3: 1.5,
  n2: 1.8,
  n1: 2.2,
};

/**
 * @param {string} levelOrMode kana's `mode` ("hiragana"/"katakana"/"mixed")
 *   or the other three modules' `jlptLevel` ("N5".."N1")
 * @return {number} difficulty multiplier, or `1.0` (the lowest tier, never
 *   `0` — an unrecognised value must never zero out an otherwise-earned
 *   attempt) if the value doesn't match anything known.
 */
function difficultyMultiplierFor(levelOrMode) {
  const key = String(levelOrMode || "").toLowerCase();
  return Object.prototype.hasOwnProperty.call(DIFFICULTY_BY_LEVEL, key)
    ? DIFFICULTY_BY_LEVEL[key]
    : 1.0;
}

/**
 * The four Ujian exam-history collections that feed Global Points in V1
 * (per the Final Decision Memo — Kotoba/Bunpou/Bab/Battle are explicitly
 * out of scope).
 *
 * **`repeatField` and `difficultyField` are deliberately separate**, and
 * differ for two of the four modules — this is not an oversight, it was
 * caught while writing `backfill_global_points.test.js` against
 * realistic fixture data (Choukai/Kanji-Kombinasi's `itemId` values like
 * `"choukai_n5_jam_berapa"`/`"single_n5"` are not themselves a bare
 * `"N5"`..`"N1"` string `difficultyMultiplierFor` can read):
 * - `repeatField` — matches the Final Decision Memo's table exactly:
 *   Kana repeats by `mode`, Dokkai by `jlptLevel` (its own `itemId` is a
 *   fresh timestamp every session and can never repeat by construction —
 *   confirmed by reading `dokkai_exam_screen.dart`, so it is
 *   deliberately NOT used here), Choukai by `itemId` (which already *is*
 *   `clip.id`, stable and real), Kanji-Kombinasi by `itemId` (which
 *   already encodes `{mode}_{level}`, e.g. "single_n5").
 * - `difficultyField` — always the field that actually holds a bare JLPT
 *   level string. Kana has none (pre-JLPT, `difficultyMultiplierFor`
 *   reads its `mode` value directly since kana's mode names are
 *   themselves keys in `DIFFICULTY_BY_LEVEL`). The other three all write
 *   a real `jlptLevel` field on their `SimpleExamResult` document
 *   independently of whatever `itemId` happens to encode — confirmed by
 *   reading `choukai_exam_screen.dart`/`kanji_combo_exam_screen.dart`,
 *   both of which pass `jlptLevel: ...` as a field distinct from
 *   `itemId` at submit time.
 */
const MODULES = {
  kana: {collection: "examHistory", repeatField: "type", difficultyField: "type"},
  dokkai: {collection: "dokkaiExamHistory", repeatField: "jlptLevel", difficultyField: "jlptLevel"},
  choukai: {collection: "choukaiExamHistory", repeatField: "itemId", difficultyField: "jlptLevel"},
  kanjiCombo: {collection: "kanjiComboExamHistory", repeatField: "itemId", difficultyField: "jlptLevel"},
};

/**
 * @param {string} moduleType one of `MODULES`' keys
 * @param {object} doc the exam-history document's own data (`toMap()`
 *   shape — `type`/`jlptLevel`/`itemId`/`score`/`total`)
 * @return {string} the repeat-cycle key for this attempt, scoped to
 *   `moduleType` so e.g. Dokkai's "N5" and Kanji-Kombinasi's "N5" never
 *   collide with each other.
 */
function repeatKeyFor(moduleType, doc) {
  const spec = MODULES[moduleType];
  if (!spec) throw new Error(`unknown module type: ${moduleType}`);
  const value = doc && doc[spec.repeatField];
  return `${moduleType}:${value}`;
}

/**
 * The one function every caller (live trigger, backfill replay) goes
 * through for "should this attempt earn points, and how many". Pure —
 * `alreadyAwarded`/`cycle`/`now` are all passed in, nothing is read from
 * Firestore inside this function.
 *
 * @param {object} args
 * @param {boolean} args.alreadyAwarded whether a `pointsAwarded` marker
 *   already exists for this exact history document — the idempotency
 *   check. When `true`, every other argument is ignored and `null` is
 *   returned: this attempt has already been paid, replay/retry must be a
 *   pure no-op.
 * @param {{attemptCountInCycle: number, cycleStartedAt: number}|null}
 *   args.cycle the repeat-cycle state for this `(uid, repeatKey)` before
 *   this attempt, or `null`/`undefined` if this is the first attempt
 *   ever recorded for that key.
 * @param {number} args.now attempt timestamp, epoch ms (the exam
 *   history document's own `completedAt`, not wall-clock "now" — this is
 *   what makes the same function correct for both the live trigger,
 *   where the attempt just happened, and the backfill replay, where
 *   attempts are historical).
 * @param {number} args.correct number of correct answers this attempt
 * @param {number} args.difficulty difficulty multiplier (see
 *   [difficultyMultiplierFor])
 * @return {null|{points: number, newCycle: {attemptCountInCycle: number,
 *   cycleStartedAt: number}}} `null` if nothing should be awarded
 *   (already-awarded case only — a legitimate zero-correct attempt still
 *   returns a real result with `points: 0`, since "attempted" is what's
 *   being rewarded, and a 0-point award still advances the cycle so a
 *   later good attempt on the same day counts as attempt 2, not a fresh
 *   attempt 1).
 */
function decideAward({alreadyAwarded, cycle, now, correct, difficulty}) {
  if (alreadyAwarded) return null;

  const cycleExpired =
    !cycle || now - cycle.cycleStartedAt > REPEAT_CYCLE_WINDOW_MS;
  const n = cycleExpired ? 1 : cycle.attemptCountInCycle + 1;
  const cycleStartedAt = cycleExpired ? now : cycle.cycleStartedAt;

  const points = correct * difficulty * K * Math.pow(DECAY, n - 1);

  return {
    points,
    newCycle: {attemptCountInCycle: n, cycleStartedAt},
  };
}

function db() {
  return getFirestore();
}

/**
 * gRPC status codes the Admin SDK surfaces on `error.code` for failures
 * that are transient — the operation may well succeed if simply retried,
 * nothing about the request itself was wrong. Matched against Google's
 * own documented meaning for each code, not guessed:
 * - 4 DEADLINE_EXCEEDED, 14 UNAVAILABLE — the network/server hiccuped.
 * - 8 RESOURCE_EXHAUSTED — a quota/rate limit, temporary by nature.
 * - 10 ABORTED — a transaction lost a contention race; Firestore's own
 *   SDK already retries this internally up to its own limit, but if that
 *   limit is ever exhausted (heavy concurrent write load on the same
 *   marker/cycle/leaderboard doc — exactly the shape a backfill run
 *   overlapping live traffic produces), the error that escapes still
 *   carries this code and is worth one more retry at the platform level.
 * - 13 INTERNAL — a generic server-side fault, Google's own guidance is
 *   this is safe to retry.
 *
 * Deliberately **not** included: anything else, most importantly no
 * `.code` at all — which is exactly the shape of this file's own
 * `throw new Error("unknown module type: ...")`. That is a genuine code/
 * data-shape bug that will fail identically forever; retrying it for up
 * to 24 hours (Eventarc's own retry ceiling) would waste a full day
 * before anyone notices, for zero chance of ever succeeding. Defaulting
 * unrecognised errors to non-retryable is the safe direction — a
 * transient error missing from this set costs one lost invocation
 * (findable in the log line [isRetryableError]'s caller writes either
 * way); a permanent error wrongly retried costs a wasted day.
 */
const RETRYABLE_GRPC_CODES = new Set([4, 8, 10, 13, 14]);

/**
 * @param {unknown} error whatever `awardPointsForHistoryDoc` threw
 * @return {boolean} true only for errors whose `.code` is a known
 *   transient gRPC status — see [RETRYABLE_GRPC_CODES].
 */
function isRetryableError(error) {
  return Boolean(
    error && typeof error === "object" && RETRYABLE_GRPC_CODES.has(error.code),
  );
}

/**
 * The one Firestore-touching function in this file (besides the trigger
 * wiring below) — everything it decides comes from [decideAward], read
 * and written inside a single transaction so a concurrent duplicate
 * invocation (the live trigger retried by the platform, or — this is
 * the part that used to be unsafe, see `backfill_global_points.js`'s own
 * doc comment — a backfill run processing the same document at the same
 * time) can never award twice: the marker is read via `transaction.get`
 * and written via `transaction.set` **inside one transaction**, so
 * Firestore's own optimistic-concurrency conflict detection covers it.
 * If another writer commits a marker for this exact `historyDocId`
 * between this transaction's read and its own commit attempt, Firestore
 * aborts and automatically re-runs this callback — the second run reads
 * `markerSnap.exists === true` and [decideAward] returns `null`, so
 * nothing is written twice. `historyDocId` is the exam history
 * document's own id — created once by the client at submit time — used
 * as the idempotency key precisely because it can never repeat on its
 * own.
 *
 * **Every caller now goes through this exact function** — the live
 * trigger below, and `backfill_global_points.js`'s `backfillUser`,
 * which used to write markers with a blind pre-transaction check
 * instead (the race this rewrite closes). One code path, one proof of
 * correctness, rather than two that have to be kept in sync by hand.
 *
 * Deliberately outside any transaction retry loop of its own: Firestore
 * transactions already retry internally on contention, and this
 * function's own body has no side effect outside the transaction to
 * worry about re-running. A transaction that throws (contention retries
 * exhausted, a network fault mid-transaction) is guaranteed by
 * Firestore's own atomicity contract to have written **nothing** — so a
 * caller that retries this whole function after such a failure is safe
 * by construction, not by any extra bookkeeping here.
 *
 * @param {string} uid
 * @param {string} moduleType one of `MODULES`' keys
 * @param {string} historyDocId the newly-created history document's id
 * @param {object} docData the newly-created history document's data
 * @param {object} [options]
 * @param {import("firebase-admin/firestore").Firestore} [options.firestore]
 *   injected Firestore instance — defaults to the real one ([db]).
 *   Exists so tests can pass a fake implementing just enough of the
 *   Admin SDK surface to prove the transaction's conflict/retry
 *   behaviour without a live emulator — see
 *   `test_helpers/fake_firestore.js`'s own doc comment for why a
 *   pure-function test cannot stand in for this proof.
 * @param {"live"|"backfill"} [options.source] tagged onto the marker
 *   purely for observability (which path awarded a given attempt) —
 *   never affects the decision itself.
 * @param {number} [options.eventTimeMs] the triggering Cloud Functions
 *   v2 CloudEvent's own `event.time` (Firestore's authoritative server
 *   commit timestamp for the history document's creation), as epoch
 *   ms — **only ever supplied by the live trigger**
 *   ([globalPointsTriggerFor]'s handler below). This is the sole input
 *   used to decide which weekly competition period (see
 *   `functions/wib_week.js`) this attempt's points count toward —
 *   deliberately never `docData.completedAt` (the exam-history
 *   document's own `completedAt` field), because that value is chosen
 *   by the client at submit time and a malicious client could set it
 *   to any past or future instant to land a farmed score in whichever
 *   week is most favorable. When `eventTimeMs` is omitted (every
 *   `backfill_global_points.js` call, by construction — see that
 *   file's own call site, which never passes this option), **no
 *   weekly-period write happens at all**: a backfill replay is
 *   awarding points for a *historical* attempt after the fact, and
 *   retroactively injecting it into a *current* live weekly
 *   competition it was never actually part of would be exactly the
 *   kind of forgeable, non-authoritative period assignment this
 *   parameter exists to prevent. The historical `globalPoints` total on
 *   `leaderboard/{uid}` — and everything else this function already
 *   did — is completely unaffected either way; this is a strictly
 *   additive write gated on an extra condition, not a replacement of
 *   any existing behavior.
 * @return {Promise<{awarded: boolean, points: number, periodId:
 *   (string|null)}>} `awarded: false` means [decideAward] found this
 *   `historyDocId` already paid; callers that need a running total (the
 *   backfill runner) add `points` only when `awarded` is true.
 *   `periodId` is the WIB week id the weekly-period write landed in, or
 *   `null` when no period write happened (already-awarded, or no
 *   `eventTimeMs` supplied).
 */
async function awardPointsForHistoryDoc(
  uid, moduleType, historyDocId, docData, options = {},
) {
  const spec = MODULES[moduleType];
  if (!spec) throw new Error(`unknown module type: ${moduleType}`);

  const firestore = options.firestore || db();
  const source = options.source || "live";

  // Server-authoritative — Exam-History Authority fix (see
  // TEISOU_ROADMAP_MASTER.md's P0 audit + design + implementation
  // sections). `docData.score`/`docData.total` are client-reported,
  // display-only fields as of this fix — Global Points now consumes
  // ONLY `graded.serverScore`, computed here by independently regrading
  // `docData.answers` (also client-submitted, but raw and unjudged —
  // see exam_grading.js's own top doc comment for why a raw answer
  // array, unlike a self-reported score, can be objectively checked
  // against real content this function has its own copy of) against
  // this project's own bundled/mirrored content datasets. A client
  // that submits a document with no `answers` at all, or answers that
  // don't match anything real, is graded `serverScore: 0` — exactly
  // the P0 audit's forged `score: 999999` case, now worth nothing.
  const graded = gradeAttempt(moduleType, docData.answers);
  const correct = graded.serverScore;

  // Global-Points Metadata Authority fix (see TEISOU_ROADMAP_MASTER.md's
  // section by that name). `docData[spec.difficultyField]`/
  // `docData[spec.repeatField]` used to be trusted directly here — a
  // confirmed P0 farming vector, since a client could invent a fresh
  // `type`/`jlptLevel`/`itemId` string on every fabricated document to
  // bypass the 0.6^(n-1) repeat-cycle decay indefinitely (proven:
  // unbounded amplification, scaling linearly with fabricated-document
  // count, no ceiling). `difficultyValue`/`repeatValue` are now derived
  // by `gradeAttempt` itself, from the SAME real, dataset-verified
  // content the deduplicated `answers` actually reference — never from
  // `docData` directly. `repeatKeyFor` is still used unchanged (its own
  // pure `${moduleType}:${value}` logic and test coverage are untouched)
  // but is now called with a synthetic single-field object carrying the
  // SERVER-derived value under the same `spec.repeatField` name, rather
  // than `docData` itself.
  const difficulty = difficultyMultiplierFor(graded.difficultyValue);
  const repeatKey = repeatKeyFor(moduleType, {[spec.repeatField]: graded.repeatValue});
  const completedAtMs = toEpochMs(docData.completedAt);

  // Server-authoritative only — see this function's own doc comment on
  // [options.eventTimeMs] above for why `docData.completedAt` must
  // never be used here.
  const periodId = Number.isFinite(options.eventTimeMs) ?
    wibWeekId(new Date(options.eventTimeMs)) :
    null;

  const markerRef = firestore
    .collection("globalPointsState")
    .doc(uid)
    .collection("pointsAwarded")
    .doc(historyDocId);
  const cycleRef = firestore
    .collection("globalPointsState")
    .doc(uid)
    .collection("repeatCycles")
    .doc(repeatKey);
  const leaderboardRef = firestore.collection("leaderboard").doc(uid);
  // Trusted grading result — Exam-History Authority fix. Server-only
  // writable (see firestore.rules' own `examHistoryGraded` block), keyed
  // by the exact same `historyDocId` used as the points-idempotency key
  // above, so "graded once" and "awarded once" are the SAME guarantee,
  // not two separate ones to keep in sync — see this file's own doc
  // comment further up for why that reuse was chosen over a second,
  // independent idempotency mechanism.
  const gradedRef = firestore.collection("examHistoryGraded").doc(historyDocId);
  const periodRef = periodId ?
    firestore
      .collection("globalScorePeriods")
      .doc(periodId)
      .collection("users")
      .doc(uid) :
    null;

  return firestore.runTransaction(async (transaction) => {
    const [markerSnap, cycleSnap] = await Promise.all([
      transaction.get(markerRef),
      transaction.get(cycleRef),
    ]);

    const cycle = cycleSnap.exists ? cycleSnap.data() : null;
    const result = decideAward({
      alreadyAwarded: markerSnap.exists,
      cycle,
      now: completedAtMs,
      correct,
      difficulty,
    });

    if (result === null) {
      logger.info("globalPoints: skipped, already awarded", {
        uid, moduleType, historyDocId, source,
      });
      return {awarded: false, points: 0, periodId: null};
    }

    transaction.set(markerRef, {
      awarded: true,
      points: result.points,
      moduleType,
      source,
      awardedAt: FieldValue.serverTimestamp(),
    });
    transaction.set(cycleRef, result.newCycle);
    transaction.set(gradedRef, {
      uid,
      moduleType,
      historyDocId,
      serverScore: graded.serverScore,
      serverTotal: graded.serverTotal,
      gradingVersion: GRADING_VERSION,
      gradedAt: FieldValue.serverTimestamp(),
    });
    transaction.set(
      leaderboardRef,
      {
        globalPoints: FieldValue.increment(result.points),
        globalPointsUpdatedAt: FieldValue.serverTimestamp(),
      },
      {merge: true},
    );

    // Weekly-competition write — same transaction, same already-proven
    // once-per-historyDocId idempotency gate as the two writes above
    // (this whole block is unreachable once `markerSnap.exists` is
    // true on a later replay, exactly like the leaderboard increment
    // above it), so this can never double-count a single attempt into
    // a period twice. Deliberately no extra read of the period
    // document first — `FieldValue.increment` composes safely with an
    // as-yet-nonexistent document (Firestore creates it with the
    // increment's own value), and the only guard this write actually
    // needs is "has this historyDocId already been processed", which
    // is exactly what the marker/decideAward gate above already
    // provides. No client-controlled value is stored: `points` and
    // `attempts` are both server-computed deltas, `uid`/`periodId` are
    // server-derived identifiers, `updatedAt` is a server timestamp.
    if (periodRef) {
      transaction.set(
        periodRef,
        {
          points: FieldValue.increment(result.points),
          attempts: FieldValue.increment(1),
          uid,
          periodId,
          updatedAt: FieldValue.serverTimestamp(),
        },
        {merge: true},
      );
    }

    logger.info("globalPoints: awarded", {
      uid, moduleType, historyDocId, points: result.points,
      repeatKey, n: result.newCycle.attemptCountInCycle, source, periodId,
    });
    return {awarded: true, points: result.points, periodId};
  });
}

/** Accepts a Firestore Timestamp, an ISO string (Dokkai/Choukai/
 * Kanji-Kombinasi's `SimpleExamResult.completedAt`), a plain Date, or a
 * plain epoch-ms number — the first two are the actual shapes
 * `completedAt` takes across the four live history collections (kana's
 * `ExamResult` writes a Firestore Timestamp, the other three write an
 * ISO string via `DateTime.toIso8601String()`); the number/Date cases
 * are for callers (tests, and any future writer) that already have an
 * epoch value in hand rather than a Firestore-shaped one — a plain
 * `typeof === "number"` value must be trusted as-is, not silently
 * discarded to `Date.now()`, or a caller passing an intentionally old
 * timestamp (exactly what the backfill replay's own fixtures do) would
 * have its resulting "now" silently substituted with the real wall-clock
 * time instead, which is indistinguishable from a real bug until closely
 * inspected — found exactly this way while writing
 * `backfill_global_points.test.js` against realistic fixture data. */
function toEpochMs(completedAt) {
  if (completedAt && typeof completedAt.toMillis === "function") {
    return completedAt.toMillis();
  }
  if (typeof completedAt === "number" && Number.isFinite(completedAt)) {
    return completedAt;
  }
  if (typeof completedAt === "string") {
    const parsed = Date.parse(completedAt);
    if (!Number.isNaN(parsed)) return parsed;
  }
  if (completedAt instanceof Date) return completedAt.getTime();
  return Date.now();
}

/**
 * The retry/rethrow decision itself, extracted from the `onDocumentCreated`
 * wiring below so it can be unit-tested directly — constructing a real
 * `CloudEvent` well enough to invoke a Cloud Function object built by
 * `onDocumentCreated` is not something worth building just for this, when
 * the interesting logic is a handful of plain arguments in, a resolve-or-
 * reject out.
 *
 * @param {string} moduleType one of `MODULES`' keys
 * @param {string} uid
 * @param {string} historyDocId
 * @param {object} docData
 * @param {string} [eventId] the triggering CloudEvent's own id, logged for
 *   correlation — `undefined` is tolerated (some callers, like a direct
 *   test invocation, may not have one).
 * @param {object} [options] forwarded to [awardPointsForHistoryDoc] —
 *   primarily `{firestore}` for tests, see that function's own doc
 *   comment.
 * @return {Promise<{awarded: boolean, points: number}>} resolves on
 *   success **or** on a deliberately-swallowed non-retryable failure
 *   (`{awarded: false, points: 0}`); rejects (rethrows) only for a
 *   retryable failure, which is the signal `globalPointsTriggerFor`'s
 *   `retry: true` registration needs Eventarc to actually redeliver the
 *   event.
 */
async function handleHistoryDocCreated(
  moduleType, uid, historyDocId, docData, eventId, options = {},
) {
  try {
    return await awardPointsForHistoryDoc(
      uid, moduleType, historyDocId, docData, {...options, source: "live"},
    );
  } catch (error) {
    const retryable = isRetryableError(error);
    const logFields = {
      uid,
      moduleType,
      historyDocId,
      eventId,
      errorCode: error && error.code,
      errorMessage: error && error.message ? error.message : String(error),
      retryable,
    };
    if (retryable) {
      // Rethrow: with `retry: true` on the trigger registration below,
      // this tells Eventarc to redeliver the same event later
      // (exponential backoff, up to its own ~24h ceiling). Each
      // redelivery re-enters this function and calls
      // awardPointsForHistoryDoc fresh — safe by that function's own
      // atomicity guarantee (a failed transaction writes nothing), so a
      // retry can only ever reach "awarded exactly once" or "still not
      // awarded", never a double-award. There is no callback in the
      // Firestore-trigger API that fires once Eventarc's own retry
      // budget is exhausted — this log line is written on *every*
      // attempt, so if retries do run out, the last one of these lines
      // *is* the exhaustion record, distinguishable only by being the
      // last, not by any special marker.
      logger.error("globalPoints: retryable failure, will retry", logFields);
      throw error;
    }
    // A non-retryable error (most likely a genuine code/data-shape bug —
    // e.g. an unrecognised module type) would fail identically on every
    // redelivery. Swallowing it here, deliberately not rethrown, is what
    // keeps a permanent bug from being retried for a full day for zero
    // chance of succeeding — matching this file's own reasoning on
    // RETRYABLE_GRPC_CODES above.
    logger.error("globalPoints: permanent failure, not retrying", logFields);
    return {awarded: false, points: 0};
  }
}

/**
 * Builds an `onDocumentCreated` handler for one of the four exam-history
 * collections — a thin wrapper so `index.js` can register all four with
 * one line each, mirroring this file's own sibling triggers
 * (`onDirectMessageCreated`, `onClanMessageCreated`, etc.) rather than
 * inventing a new registration shape. The retry/rethrow decision itself
 * lives in [handleHistoryDocCreated] above; this function only extracts
 * the CloudEvent's own fields and hands them off.
 *
 * **`retry: true` is set explicitly** — Cloud Functions v2's own default
 * is `retry: false` (confirmed by reading the installed
 * `firebase-functions` package's source,
 * `lib/v2/providers/firestore.js`'s `retry: opts.retry ?? false`; the
 * previous version of this trigger passed only a bare path string, which
 * left it at that default). Combined with [handleHistoryDocCreated]'s
 * classification, this gives Eventarc a genuine reason to retry a
 * transient failure — the gap the earlier reliability audit found:
 * swallowing every error meant retry being off was moot anyway, since
 * the platform never even saw a failure to retry.
 *
 * **The exam history document itself is never at risk from any of
 * this.** It was written by the client, via a completely separate write,
 * before this trigger ever runs — nothing in this function conditions
 * on it, deletes it, or can cause it to be rolled back. A retry here
 * only re-runs the points-award attempt; the history stays the
 * unconditional source of truth throughout.
 *
 * @param {string} moduleType one of `MODULES`' keys
 */
function globalPointsTriggerFor(moduleType) {
  const spec = MODULES[moduleType];
  if (!spec) throw new Error(`unknown module type: ${moduleType}`);

  return onDocumentCreated(
    {document: `users/{uid}/${spec.collection}/{historyDocId}`, retry: true},
    async (event) => {
      const snapshot = event.data;
      if (!snapshot) return;
      const {uid, historyDocId} = event.params;
      // `event.time` is the CloudEvent's own server-assigned commit
      // timestamp (an RFC-3339/ISO-8601 string) — passed through as
      // [awardPointsForHistoryDoc]'s `eventTimeMs` option so the weekly
      // competition period this attempt counts toward is decided from
      // a value the client never controls, never from the exam-history
      // document's own client-supplied `completedAt` field. Reusing
      // [toEpochMs] here (already proven against real ISO strings from
      // the other three modules' `completedAt` fields) rather than a
      // fresh `Date.parse` call.
      await handleHistoryDocCreated(
        moduleType, uid, historyDocId, snapshot.data(), event.id,
        {eventTimeMs: toEpochMs(event.time)},
      );
    },
  );
}

module.exports = {
  K,
  DECAY,
  REPEAT_CYCLE_WINDOW_MS,
  DIFFICULTY_BY_LEVEL,
  RETRYABLE_GRPC_CODES,
  MODULES,
  difficultyMultiplierFor,
  repeatKeyFor,
  decideAward,
  isRetryableError,
  awardPointsForHistoryDoc,
  handleHistoryDocCreated,
  globalPointsTriggerFor,
  toEpochMs,
};

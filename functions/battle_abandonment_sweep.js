/**
 * Server-authoritative resolution for a Card Game Mode match nobody is
 * left to advance — the C2 finding in AUDIT_PHASE_C_BATTLE_RELIABILITY.md:
 * `presence_service.dart` exists but was never wired to a provisioned
 * Realtime Database, there is no server-side timeout anywhere, and the
 * only thing that can ever move a match toward `result` is a live
 * client's own per-round `Timer` (`battle_screen.dart`'s
 * `_ensureTimerFor`/`_handleTimeout`) forcing an empty forfeit answer.
 * The moment both players stop looking at the screen, nothing is left to
 * write that forfeit, and the match sits `status: "active"` forever.
 *
 * **This invents no new gameplay rule.** It performs exactly the write a
 * live client's own timeout handler already performs —
 * `battle_repository.dart`'s `forfeitRoundOnTimeout`/`submitAnswer`:
 * create an empty `answers/{round}` doc for whoever was supposed to
 * answer, advance `currentRound`, reset `turnStartedAt` — inside the same
 * `currentRound == round` transaction guard. The existing, unmodified
 * `battle_scoring.js`/`onBattleAnswerCreated` pipeline is what actually
 * scores it and eventually writes `result`/`status: "finished"`, using
 * its own already-correct winner rule (higher `officialScore` once every
 * round through the main phase is processed, or `"draw"` if the whole 40
 * rounds are exhausted still level) — unchanged, not reimplemented here.
 * `battle_stars.js`'s `onBattleMatchConcluded` trigger — already written
 * to watch for `result` appearing from ANY source, per its own doc
 * comment naming "an abandoned-match sweeper" as an anticipated future
 * caller — then pays stars exactly once, through its own pre-existing
 * `starsApplied` claim transaction. Nothing here duplicates or bypasses
 * either of those.
 *
 * **One stale round per sweep, per match — not the whole match at once.**
 * This mirrors the *shape* of the existing client mechanism exactly (one
 * timeout, one forfeit, wait for the next), just server-triggered instead
 * of client-triggered, rather than inventing a more aggressive
 * "resolve everything immediately" behavior with no client-side
 * precedent. A truly abandoned match still reaches a result in bounded
 * time (at most [MAX_ROUNDS] sweep cycles), and a match where a player
 * merely stepped away briefly is not steamrolled by a single sweep pass
 * that outpaces them coming back.
 *
 * **Idempotent by construction, not by anything new.** The forfeit write
 * reuses the exact transaction shape (guarded on `currentRound == round`)
 * that already makes a client's own double-advance safe — a concurrent
 * sweep run, a real player's answer landing at the same moment, or two
 * overlapping scheduled invocations all resolve to "exactly one of these
 * writes wins, the rest are silent no-ops," the same guarantee this
 * codebase already relies on for the client-side timeout path.
 */

const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const logger = require("firebase-functions/logger");

/**
 * Mirrors `lib/core/constants/battle_rules.dart`'s `kBattleTotalRounds` —
 * kept in sync by hand, the same unavoidable cross-language split this
 * project already carries for `battle_scoring.js`'s own
 * `MAIN_PHASE_ROUNDS`/`TOTAL_ROUNDS` and the ported `RomajiConverter`.
 */
const MAX_ROUNDS = 40;

/**
 * The one round where Stage 2 can activate — mirrors `battle_scoring.js`'s
 * `MAIN_PHASE_ROUNDS - 1` (kept in sync by hand, the same cross-file split
 * this constant's own sibling [MAX_ROUNDS] already carries for
 * `TOTAL_ROUNDS`). This is exactly the first round `scoreAnswer` is even
 * willing to look at the scoreboard, so it is also the earliest point a
 * "still tied, no forfeit can ever change that" verdict can honestly be
 * reached — nothing earlier is skippable without risking a round a
 * reconnecting player could have won outright.
 *
 * See `AUDIT_C2_ABANDONMENT_DESIGN_REVIEW.md`'s Design C for the reasoning
 * behind choosing this exact boundary over any other round number: it is
 * the only one already meaningful to the existing scoring code, not a
 * new value invented for this purpose.
 */
const STAGE2_TRIGGER_ROUND = 19;

/**
 * How long a round may sit with nobody answering before it counts as
 * abandoned rather than merely slow. `lib/core/constants/battle_rules.dart`
 * bounds the longest a *live* client would ever legitimately still be
 * sitting on one round at 40s (`kBattleCardChoiceSeconds` 10s to choose a
 * card + `kBattleMainPhaseSeconds` 30s to answer it; every later round is
 * shorter). Three minutes is a wide margin past that — generous enough to
 * absorb a slow reconnect or a backgrounded app's delayed timer tick
 * without racing a client that is still genuinely there, while still
 * being unambiguous evidence nobody live is on the other end.
 */
const STALE_THRESHOLD_MS = 3 * 60 * 1000;

/**
 * The two-sided "leaving the match" grace period (2026-08-30, generalized
 * from a single-slot marker 2026-09) — mirrors
 * `lib/core/constants/battle_rules.dart`'s `kBattleAbsenceGracePeriodSeconds`
 * (kept in sync by hand, the same split every other cross-language
 * constant in this pair of files already carries).
 *
 * **Distinct from [STALE_THRESHOLD_MS], on purpose, not a duplicate of
 * it.** That threshold detects a round nobody is answering (silence with
 * no explicit signal either way) and forfeits *one round* at a time — a
 * genuinely abandoned match can still take many sweep cycles to reach a
 * result. This one instead watches `BattleMatch.absence` — a map keyed by
 * uid, each entry written by that player's own device the moment it
 * notices them leave (`lib/data/repositories/battle_repository.dart`'s
 * `markAbsent`, called from `battle_screen.dart`'s `dispose()`/lifecycle
 * observer) — and, once the *relevant* grace period(s) are up, ends the
 * whole match immediately (a win for whoever is still present, or
 * `abandoned` if nobody ever came back) rather than forfeiting it round by
 * round. A player who force-kills the app (no chance for their own device
 * to write an `absence` entry at all) is not covered by this path — that
 * case still falls through to [STALE_THRESHOLD_MS]'s slower, unmodified
 * sweep, which remains the backstop it always was.
 */
const ABANDON_GRACE_PERIOD_MS = 30 * 1000;

function db() {
  return getFirestore();
}

/**
 * Resolves [matchId]'s absence state once enough of the relevant grace
 * period(s) have elapsed — the server-authoritative half of the
 * two-sided pause system (`BattleMatch.absence`'s own doc comment has
 * the full picture this implements).
 *
 * Re-reads `absence` fresh *inside* the transaction every time, the same
 * way the single-sided version this replaces always did — so a player
 * reconnecting (their own client's `clearAbsence` removing their key)
 * always wins any race against a sweep/callable invocation trying to
 * finalize at the same moment, whichever write Firestore actually
 * commits first.
 *
 * Three shapes, entirely driven by how many of `match.players` currently
 * have an entry in `absence`:
 *   - **zero** — nothing to resolve: `"no_absence"`.
 *   - **one** (KASUS 1/2) — once that one player's own grace period is
 *     up, the *other* player wins and this one loses (`result`/
 *     `status: "finished"`, same shape `battle_scoring.js` already
 *     writes for a normal conclusion, so `battle_stars.js`'s
 *     `onBattleMatchConcluded` trigger pays stars through its own
 *     existing, unmodified `starsApplied` idempotency transaction —
 *     nothing new needed there). This is also what a KASUS 3 sub-case
 *     (3A/3B) naturally becomes the instant one of two absent players
 *     returns — `clearAbsence` removes their key, shrinking the map to
 *     one, and the very next time this runs it is simply this branch
 *     again, off the remaining player's own original `since` timestamp.
 *     No special transition handling was needed for that case.
 *   - **two** (KASUS 3, neither has returned) — resolves only once the
 *     LATER of the two players' own individual deadlines has passed
 *     (i.e. *both* have separately run out), and only ever to
 *     `"abandoned"`: no winner, no loser, `result` deliberately never
 *     gets written (stays absent/null), which is what makes
 *     `battle_stars.js`'s own `if (!match.result) return;` gate skip
 *     this match automatically — no star movement, no code change
 *     needed there either. If only one of the two deadlines has passed
 *     so far, this returns `"not_yet_due"` — the match stays paused
 *     rather than resolving off half the picture.
 *
 * Returns a reason string; `"finalized_win"`/`"finalized_abandoned"` are
 * the only outcomes that actually wrote anything. Every other outcome —
 * including a uid present in `absence` that somehow isn't one of
 * `match.players` (should be unreachable, `firestore.rules` only ever
 * lets a player add/remove their own key) — is a deliberate, observable
 * no-op: safe to call early, safe to call twice, safe to call
 * concurrently, safe to call for a match nobody has ever left.
 */
async function resolveOneMatchAbsence(matchId, now, dbInstance = db()) {
  const matchRef = dbInstance.collection("battleMatches").doc(matchId);
  return dbInstance.runTransaction(async (transaction) => {
    const snap = await transaction.get(matchRef);
    const match = snap.data();
    if (!match) return "no_such_match";
    if (match.status !== "active" || match.result) {
      return "already_concluded";
    }

    const players = match.players || [];
    const absence = match.absence || {};
    const absentUids = players.filter(
        (p) => Object.prototype.hasOwnProperty.call(absence, p),
    );
    if (absentUids.length === 0) return "no_absence";

    const deadlineOf = (uid) => {
      const since = absence[uid] && absence[uid].since;
      if (!since) return null;
      const sinceMs = typeof since.toMillis === "function" ?
          since.toMillis() : since.getTime();
      return sinceMs + ABANDON_GRACE_PERIOD_MS;
    };

    if (absentUids.length === 1) {
      const loser = absentUids[0];
      const deadline = deadlineOf(loser);
      if (deadline === null) return "no_timestamp";
      if (now < deadline) return "not_yet_due";

      const winner = players.find((p) => p !== loser);
      if (!winner) return "unknown_player";

      transaction.set(matchRef, {
        result: winner,
        status: "finished",
        abandonedBy: loser,
      }, {merge: true});
      return "finalized_win";
    }

    // KASUS 3 — every player currently on this match is absent. Only
    // ever resolves to "abandoned", and only once *both* players' own
    // deadlines have separately elapsed — the later of the two, never
    // the earlier, so a match where the two players left seconds apart
    // is not finalized off just the first one's clock running out.
    const deadlines = absentUids.map(deadlineOf);
    if (deadlines.some((d) => d === null)) return "no_timestamp";
    const latestDeadline = Math.max(...deadlines);
    if (now < latestDeadline) return "not_yet_due";

    transaction.set(matchRef, {
      status: "abandoned",
      abandonedBy: absentUids,
    }, {merge: true});
    return "finalized_abandoned";
  });
}

/**
 * The client-callable half — the still-present player's own
 * `BattleScreen` (watching `absence` via its own live match listener)
 * calls this the moment its own local countdown for the *opponent's*
 * entry reaches zero, giving near-exact grace-period precision whenever
 * at least one participant is actually present to trigger it. [sweepOnce]
 * below is the backstop for when neither player is present to call this
 * at all.
 *
 * Deliberately takes no other input than [matchId] — the caller does not
 * get to assert who lost, who's still absent, or when; every fact this
 * needs (who is in `absence`, each entry's own `since`, each one's own
 * deadline) is re-derived entirely from the match document itself,
 * inside the same transaction [resolveOneMatchAbsence] always uses. A
 * malicious or buggy client calling this early, calling it twice, or
 * calling it for a match with an empty `absence` map can only ever
 * produce a safe no-op — never an early or fabricated result, and never
 * a result the client itself gets to pick.
 */
const resolveBattleAbandonment = onCall(async (request) => {
  const matchId = request.data && request.data.matchId;
  if (typeof matchId !== "string" || matchId.length === 0) {
    throw new HttpsError("invalid-argument", "matchId is required");
  }
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "sign-in required");
  }
  const outcome = await resolveOneMatchAbsence(matchId, Date.now());
  return {
    outcome,
    finalized: outcome === "finalized_win" || outcome === "finalized_abandoned",
  };
});

/**
 * The one write both the staleness-gated (Stage 1/round 19) and the
 * unconditional (Stage 2, rounds 20-39) paths perform — kept in one place
 * so the two can never drift into writing subtly different shapes.
 * Mirrors exactly what `battle_repository.dart`'s `submitAnswer` writes
 * for a real forfeit, plus the `forfeitedBySweep` marker.
 */
function writeForfeit(transaction, matchRef, match, round, turnEntry) {
  const players = match.players || [];
  const deckOwner = turnEntry.deckOwnerUid;
  const answerer = players.find((p) => p !== deckOwner) || deckOwner;

  const answerRef = matchRef.collection("answers").doc(String(round));
  transaction.set(answerRef, {
    byUid: answerer,
    text: "",
    submittedAt: FieldValue.serverTimestamp(),
    // Purely informational, for anyone reading raw Firestore data later
    // — nothing in the app or in battle_scoring.js reads this field;
    // scoring an empty `text` already treats it as a wrong answer
    // exactly like a client-forced timeout would.
    forfeitedBySweep: true,
  });
  // `.set(..., {merge: true})` rather than `.update()` — equivalent
  // here since `match` was just confirmed to exist above, and this
  // keeps the write compatible with `FakeFirestore` (its `runTransaction`
  // fake only implements `.get()`/`.set()`, matching every other
  // Cloud Function's transaction in this codebase — none of them use
  // `.update()` inside a transaction either).
  transaction.set(matchRef, {
    currentRound: round + 1,
    turnStartedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
}

/**
 * One stale-round forfeit for one match, inside the same transaction
 * shape `submitAnswer`/`forfeitRoundOnTimeout` already use client-side.
 * Returns `"advanced"` on a real write, or a reason string for why
 * nothing was written — every non-"advanced" outcome is a deliberate,
 * safe no-op, never a thrown error for an expected condition.
 *
 * **Stage 2**: when the round being forfeited is [STAGE2_TRIGGER_ROUND],
 * the same transaction also reads the score standing after this forfeit
 * (which a forfeit never changes, so this is really "the score standing
 * after rounds 0..18") and decides, using only that already-fetched data,
 * whether the two players are tied. A forfeit can never add a point, so a
 * tie here is not a snapshot that might change later if we wait longer —
 * it is the final word on rounds 0..18, and every remaining round is
 * either about to be forfeited too (tied stays tied) or answered for real
 * by someone who came back (which is exactly the case the bulk pass below
 * is built to back off from, see `bulkForfeitRemainingRounds`). If tied,
 * once this transaction commits, [bulkForfeitRemainingRounds] runs
 * immediately, in the same function invocation, so a genuinely-abandoned
 * tied match does not sit through dozens more 2-minute sweep cycles for
 * no reason (see `AUDIT_C2_ABANDONMENT_DESIGN_REVIEW.md` for the ~2.6h
 * worst case this replaces).
 *
 * A decisive score at round 19 needs no special handling at all: the
 * existing, unmodified `battle_scoring.js` trigger concludes the match
 * with a winner the moment it processes this same forfeit's `answers/19`
 * document, exactly as it always has.
 *
 * [dbInstance] is accepted explicitly (defaulting to the real Firestore
 * client) so a test can pass a `FakeFirestore` instead — the same
 * "real logic takes its dependencies as parameters" split already used
 * by `ad_rewards.js`'s `evaluateCallback` and `iap.js`'s `claimAndGrant`.
 */
async function forfeitOneStaleRound(matchId, now, dbInstance = db()) {
  const matchRef = dbInstance.collection("battleMatches").doc(matchId);

  const outcome = await dbInstance.runTransaction(async (transaction) => {
    const snap = await transaction.get(matchRef);
    const match = snap.data();
    if (!match) return {status: "no_such_match"};
    if (match.status !== "active" || match.result) {
      return {status: "already_concluded"};
    }

    // Only a match that has actually started is eligible — a friend/clan
    // challenge nobody has accepted yet is a different, unrelated state
    // (see `BattleMatch.isAwaitingAccept`'s own doc comment: the round
    // clock is not even running until the accept). Forcing a result onto
    // an invite nobody answered would not be resolving an abandoned
    // match, it would be inventing an outcome for one that never began —
    // explicitly out of this sweep's scope.
    const inviteState = match.inviteState;
    if (inviteState === "pending" || inviteState === "declined") {
      return {status: "not_started"};
    }

    // FASE C/D — a match with anyone in `absence` is paused, and a
    // paused match's round clock must not run: `turnStartedAt` is
    // deliberately frozen while this is true (see `clearAbsence`'s own
    // doc comment — it refreshes `turnStartedAt` only once *nobody* is
    // left absent), so treating a stale `turnStartedAt` as evidence of
    // real abandonment here would double-punish a player who is already
    // being handled by [resolveOneMatchAbsence]'s own, more specific
    // 30-second window. This sweep's own staleness path resumes acting
    // on this match automatically the moment `absence` empties out
    // again, with no special re-arming needed.
    if (match.absence && Object.keys(match.absence).length > 0) {
      return {status: "paused"};
    }

    const round = match.currentRound || 0;
    if (round < 0 || round >= MAX_ROUNDS) return {status: "no_rounds_left"};

    // `.toMillis()` for a real Firestore `Timestamp`; `.getTime()` covers
    // a plain `Date` too — the Admin SDK always returns a real
    // `Timestamp` for a stored field, but this stays cheap defensive
    // coding rather than a hard assumption about the exact type.
    const turnStartedAt = match.turnStartedAt;
    const staleSince = turnStartedAt
      ? (typeof turnStartedAt.toMillis === "function" ?
          turnStartedAt.toMillis() : turnStartedAt.getTime())
      : null;
    if (staleSince === null || now - staleSince < STALE_THRESHOLD_MS) {
      return {status: "not_stale"};
    }

    const turnOrder = match.turnOrder || [];
    const turnEntry = turnOrder.find((e) => e.round === round);
    if (!turnEntry) return {status: "no_turn_entry"};

    writeForfeit(transaction, matchRef, match, round, turnEntry);

    let triggerStage2 = false;
    if (round === STAGE2_TRIGGER_ROUND) {
      const players = match.players || [];
      const officialScore = match.officialScore || {};
      const scores = players.map((p) => officialScore[p] || 0);
      triggerStage2 = players.length === 2 && scores[0] === scores[1];
    }
    return {status: "advanced", triggerStage2};
  });

  if (outcome.status === "advanced" && outcome.triggerStage2) {
    logger.info(
        "battle_abandonment_sweep: round 19 stale and tied — starting Stage 2",
        {matchId},
    );
    const bulk = await bulkForfeitRemainingRounds(matchId, dbInstance);
    logger.info("battle_abandonment_sweep: Stage 2 finished", {
      matchId,
      ...bulk,
    });
  }

  return outcome.status;
}

/**
 * One forfeit write for [round], with no staleness check — used only by
 * [bulkForfeitRemainingRounds], and only for rounds after
 * [STAGE2_TRIGGER_ROUND]'s own tie has already been established by
 * [forfeitOneStaleRound]'s own staleness-gated transaction. Waiting out
 * another 3-minute window per round here would be exactly the "puluhan
 * kali menunggu sweep berikutnya" this stage exists to avoid — a forfeit
 * cannot change the score, so once tied-at-19 is proven, every later
 * round contributes nothing new to wait for.
 *
 * Still guarded by the identical `currentRound == round` equality check
 * every other write in this file and in `battle_repository.dart` uses —
 * removing the staleness *wait* is not the same as removing the race
 * *guard*. Returns `"advanced"` on a real write, or the reason nothing
 * was written; a reconnected client's real answer landing on this exact
 * round wins the transaction the same way it always has, and this
 * function simply reports that back to its caller instead of retrying.
 */
async function forfeitRoundUnconditionally(matchId, round, dbInstance) {
  const matchRef = dbInstance.collection("battleMatches").doc(matchId);
  return dbInstance.runTransaction(async (transaction) => {
    const snap = await transaction.get(matchRef);
    const match = snap.data();
    if (!match) return "no_such_match";
    if (match.status !== "active" || match.result) return "already_concluded";
    if ((match.currentRound || 0) !== round) return "raced";

    const turnOrder = match.turnOrder || [];
    const turnEntry = turnOrder.find((e) => e.round === round);
    if (!turnEntry) return "no_turn_entry";

    writeForfeit(transaction, matchRef, match, round, turnEntry);
    return "advanced";
  });
}

/**
 * Stage 2's bulk pass: forfeits rounds `STAGE2_TRIGGER_ROUND + 1` through
 * `MAX_ROUNDS - 1` **sequentially** — one transaction fully committed
 * before the next begins, deliberately not `Promise.all`'d. A burst of
 * 20-40 parallel transactions against the same `matchRef` would mean
 * every one of them contending with every other for the same document,
 * each retry re-reading and re-writing again; running them one at a time
 * means the only contention this pass can ever hit is against a real
 * client's own answer, which is exactly the case it needs to detect
 * anyway (see the loop's early-exit below) — never against itself.
 *
 * Stops the instant one round's write does not land as `"advanced"` —
 * that is either a real reconnected player's answer having already taken
 * that round (`"raced"`), or the match having concluded/vanished by some
 * other path in the meantime. Either way, this pass has no business
 * continuing to forfeit rounds after that: the match is no longer
 * provably abandoned, and whatever comes next is genuine activity for
 * ordinary Stage 1 monitoring to pick back up, not something this bulk
 * pass should override.
 *
 * Because every round from `STAGE2_TRIGGER_ROUND + 1` on is a forfeit
 * (never a real point for either side), and the transactional guard
 * ensures this pass can never write two different things for the same
 * round, running this again for a match that is already past this point
 * (already concluded, or already raced away from the sweep) is a safe,
 * cheap no-op — the very first iteration's transaction returns
 * `"already_concluded"` or `"raced"` immediately and the loop ends.
 */
async function bulkForfeitRemainingRounds(matchId, dbInstance = db()) {
  let forfeited = 0;
  for (let round = STAGE2_TRIGGER_ROUND + 1; round < MAX_ROUNDS; round++) {
    const outcome = await forfeitRoundUnconditionally(matchId, round, dbInstance);
    if (outcome !== "advanced") {
      return {forfeited, stoppedEarly: true, reason: outcome};
    }
    forfeited++;
  }
  return {forfeited, stoppedEarly: false};
}

async function sweepOnce(dbInstance = db(), now = Date.now()) {
  const activeSnap = await dbInstance
      .collection("battleMatches")
      .where("status", "==", "active")
      .get();

  let advanced = 0;
  let inspected = 0;
  let abandonedFinalized = 0;
  for (const doc of activeSnap.docs) {
    inspected++;
    try {
      // The explicit-absence path runs first and, on its own, skips the
      // staleness check entirely for this match this cycle — a match
      // that just got finalized this way has nothing left for
      // [forfeitOneStaleRound] to usefully do (`already_concluded` is
      // its own safe no-op if it ran anyway, but there is no reason to
      // pay for the extra transaction). A match still paused but not yet
      // past its deadline(s) falls straight through to that same
      // no-op — [forfeitOneStaleRound]'s own `absence`-non-empty guard
      // (see its doc comment) is what actually skips the round-clock
      // check for it.
      const absenceOutcome = await resolveOneMatchAbsence(doc.id, now, dbInstance);
      if (absenceOutcome === "finalized_win" ||
          absenceOutcome === "finalized_abandoned") {
        abandonedFinalized++;
        logger.info("battle_abandonment_sweep: finalized a match via absence", {
          matchId: doc.id,
          outcome: absenceOutcome,
        });
        continue;
      }

      const outcome = await forfeitOneStaleRound(doc.id, now, dbInstance);
      if (outcome === "advanced") {
        advanced++;
        logger.info("battle_abandonment_sweep: forfeited a stale round", {
          matchId: doc.id,
        });
      }
    } catch (error) {
      // One match's failure must never stop the sweep from checking the
      // rest — logged and skipped, picked up again next cycle.
      logger.error("battle_abandonment_sweep: failed for one match", {
        matchId: doc.id,
        error: error.message,
      });
    }
  }
  logger.info("battle_abandonment_sweep: cycle complete", {
    inspected,
    advanced,
    abandonedFinalized,
  });
  return {inspected, advanced, abandonedFinalized};
}

exports.sweepAbandonedBattleMatches = onSchedule(
    {schedule: "every 2 minutes"},
    async () => {
      await sweepOnce();
    },
);

exports.resolveBattleAbandonment = resolveBattleAbandonment;

// Exported for tests only.
exports._internal = {
  forfeitOneStaleRound,
  sweepOnce,
  bulkForfeitRemainingRounds,
  forfeitRoundUnconditionally,
  resolveOneMatchAbsence,
  STALE_THRESHOLD_MS,
  MAX_ROUNDS,
  STAGE2_TRIGGER_ROUND,
  ABANDON_GRACE_PERIOD_MS,
};

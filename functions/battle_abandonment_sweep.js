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

function db() {
  return getFirestore();
}

/**
 * One stale-round forfeit for one match, inside the same transaction
 * shape `submitAnswer`/`forfeitRoundOnTimeout` already use client-side.
 * Returns `"advanced"` on a real write, or a reason string for why
 * nothing was written — every non-"advanced" outcome is a deliberate,
 * safe no-op, never a thrown error for an expected condition.
 *
 * [dbInstance] is accepted explicitly (defaulting to the real Firestore
 * client) so a test can pass a `FakeFirestore` instead — the same
 * "real logic takes its dependencies as parameters" split already used
 * by `ad_rewards.js`'s `evaluateCallback` and `iap.js`'s `claimAndGrant`.
 */
async function forfeitOneStaleRound(matchId, now, dbInstance = db()) {
  const matchRef = dbInstance.collection("battleMatches").doc(matchId);

  return dbInstance.runTransaction(async (transaction) => {
    const snap = await transaction.get(matchRef);
    const match = snap.data();
    if (!match) return "no_such_match";
    if (match.status !== "active" || match.result) return "already_concluded";

    // Only a match that has actually started is eligible — a friend/clan
    // challenge nobody has accepted yet is a different, unrelated state
    // (see `BattleMatch.isAwaitingAccept`'s own doc comment: the round
    // clock is not even running until the accept). Forcing a result onto
    // an invite nobody answered would not be resolving an abandoned
    // match, it would be inventing an outcome for one that never began —
    // explicitly out of this sweep's scope.
    const inviteState = match.inviteState;
    if (inviteState === "pending" || inviteState === "declined") {
      return "not_started";
    }

    const round = match.currentRound || 0;
    if (round < 0 || round >= MAX_ROUNDS) return "no_rounds_left";

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
      return "not_stale";
    }

    const turnOrder = match.turnOrder || [];
    const turnEntry = turnOrder.find((e) => e.round === round);
    if (!turnEntry) return "no_turn_entry";

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
    return "advanced";
  });
}

async function sweepOnce(dbInstance = db(), now = Date.now()) {
  const activeSnap = await dbInstance
      .collection("battleMatches")
      .where("status", "==", "active")
      .get();

  let advanced = 0;
  let inspected = 0;
  for (const doc of activeSnap.docs) {
    inspected++;
    try {
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
  });
  return {inspected, advanced};
}

exports.sweepAbandonedBattleMatches = onSchedule(
    {schedule: "every 2 minutes"},
    async () => {
      await sweepOnce();
    },
);

// Exported for tests only.
exports._internal = {forfeitOneStaleRound, sweepOnce, STALE_THRESHOLD_MS, MAX_ROUNDS};

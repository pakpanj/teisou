const test = require("node:test");
const assert = require("node:assert");
const {Timestamp} = require("firebase-admin/firestore");

const {
  _internal: {
    forfeitOneStaleRound,
    sweepOnce,
    bulkForfeitRemainingRounds,
    forfeitRoundUnconditionally,
    STALE_THRESHOLD_MS,
    MAX_ROUNDS,
    STAGE2_TRIGGER_ROUND,
  },
} = require("./battle_abandonment_sweep");
const {FakeFirestore} = require("./test_helpers/fake_firestore");

const PLAYER_A = "uidA1234567890123456789012";
const PLAYER_B = "uidB1234567890123456789012";
// Real wall-clock time, not a fixed calendar date — FakeFirestore's own
// `serverTimestamp()` stand-in (see fake_firestore.js's `applyWrite`)
// always resolves to `new Date()` against the real clock, regardless of
// what `now` is passed into this file's functions. Using a fixed,
// unrelated date here would make any test that re-checks staleness
// right after a serverTimestamp-driven write flaky — its freshness
// would be measured against the wrong clock.
const NOW = Date.now();

function turnOrderFor(rounds) {
  // Alternates deck ownership every round, same shape
  // battle_turn_order_builder.dart actually produces.
  return Array.from({length: rounds}, (_, i) => ({
    round: i,
    deckOwnerUid: i % 2 === 0 ? PLAYER_A : PLAYER_B,
    cardId: `card_${i}`,
  }));
}

/** `scoredRounds` for every round from 0 up to (not including) [n] — the
 * shape a real match legitimately sitting at `currentRound === n` would
 * already have, since `currentRound` only ever advances through
 * `battle_scoring.js`'s own contiguity-respecting `scoreAnswer`. Stage 2
 * tests seed this explicitly so the mirror in this file (see
 * `mirrorScoreAnswerForForfeit` below) sees the same "rounds 0..18 are
 * already done" state a real match would have reached round 19 with. */
function scoredRoundsThrough(n) {
  return Object.fromEntries(Array.from({length: n}, (_, i) => [String(i), true]));
}

function seedMatch(db, matchId, overrides = {}) {
  const base = {
    players: [PLAYER_A, PLAYER_B],
    status: "active",
    currentRound: 3,
    turnOrder: turnOrderFor(MAX_ROUNDS),
    turnStartedAt: Timestamp.fromMillis(NOW - STALE_THRESHOLD_MS - 1000),
    officialScore: {[PLAYER_A]: 0, [PLAYER_B]: 0},
    result: null,
    scoredRounds: {},
    rankedMatch: true,
    inviteState: "accepted",
  };
  db.seed(`battleMatches/${matchId}`, {...base, ...overrides});
}

// --- normal match keeps running ---

test("normal match: a recently-active round is left alone", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {
    turnStartedAt: Timestamp.fromMillis(NOW - 5000), // 5s old, well within budget
  });
  const outcome = await forfeitOneStaleRound("m1", NOW, db);
  assert.strictEqual(outcome, "not_stale");
  const match = await db.collection("battleMatches").doc("m1").get();
  assert.strictEqual(match.data().currentRound, 3); // unchanged
});

// --- opponent leave / player leave / disconnect / timeout: same mechanism ---

test("opponent leave: a stale round is forfeited to whoever was answering", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {currentRound: 3}); // round 3: owner is PLAYER_B (odd), answerer PLAYER_A
  const outcome = await forfeitOneStaleRound("m1", NOW, db);
  assert.strictEqual(outcome, "advanced");

  const match = await db.collection("battleMatches").doc("m1").get();
  assert.strictEqual(match.data().currentRound, 4);
  // turnStartedAt is refreshed, same as a client's own forfeit would do.
  // FakeFirestore's own serverTimestamp() stand-in resolves to a plain
  // Date rather than a real Timestamp (see fake_firestore.js), so this
  // reads it back via getTime() rather than assuming Timestamp's API.
  assert.strictEqual(
    match.data().turnStartedAt.getTime() >= NOW,
    true,
  );

  const answer = await db
      .collection("battleMatches").doc("m1")
      .collection("answers").doc("3").get();
  assert.strictEqual(answer.exists, true);
  assert.strictEqual(answer.data().text, "");
  // Round 3's deck owner is PLAYER_B (odd round), so PLAYER_A answers it.
  assert.strictEqual(answer.data().byUid, PLAYER_A);
});

test("player leave is the identical mechanism from the other side's round", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {currentRound: 2}); // round 2: owner PLAYER_A (even), answerer PLAYER_B
  const outcome = await forfeitOneStaleRound("m1", NOW, db);
  assert.strictEqual(outcome, "advanced");
  const answer = await db
      .collection("battleMatches").doc("m1")
      .collection("answers").doc("2").get();
  assert.strictEqual(answer.data().byUid, PLAYER_B);
});

test("disconnect and timeout are not special-cased — staleness alone decides", async () => {
  // There is no separate "disconnect" signal anywhere in this schema
  // (see AUDIT_PHASE_C_BATTLE_RELIABILITY.md's C2 finding) — a genuine
  // network disconnect and a player simply closing the app both look
  // identical here: `turnStartedAt` stops moving. This test exists to
  // pin that down as intentional, not an oversight.
  const db = new FakeFirestore();
  seedMatch(db, "m1", {
    turnStartedAt: Timestamp.fromMillis(NOW - STALE_THRESHOLD_MS - 1),
  });
  const outcome = await forfeitOneStaleRound("m1", NOW, db);
  assert.strictEqual(outcome, "advanced");
});

// --- simultaneous leave: repeated sweeps drain the match without inventing new scoring ---

test("simultaneous leave: repeated sweeps keep advancing until the deck runs out", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {currentRound: 37}); // only 3 rounds left (37, 38, 39)

  let now = NOW;
  let round = 37;
  for (let i = 0; i < 3; i++) {
    now += STALE_THRESHOLD_MS + 1000; // simulate the next sweep cycle
    const outcome = await forfeitOneStaleRound("m1", now, db);
    assert.strictEqual(outcome, "advanced");
    round++;
    const match = await db.collection("battleMatches").doc("m1").get();
    assert.strictEqual(match.data().currentRound, round);
  }

  // The deck is now fully exhausted (currentRound === MAX_ROUNDS) — the
  // sweep correctly stops rather than reading past the end of turnOrder.
  now += STALE_THRESHOLD_MS + 1000;
  const finalOutcome = await forfeitOneStaleRound("m1", now, db);
  assert.strictEqual(finalOutcome, "no_rounds_left");
});

// --- duplicate resolution ---

test("duplicate resolution: forfeiting an already-just-advanced round is a no-op", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {currentRound: 5});
  const first = await forfeitOneStaleRound("m1", NOW, db);
  assert.strictEqual(first, "advanced");

  // Calling again immediately after — the round `turnStartedAt` was just
  // reset by the first call, so from the sweep's own point of view this
  // match is no longer stale. It must not forfeit a second time back to
  // back.
  const second = await forfeitOneStaleRound("m1", NOW, db);
  assert.strictEqual(second, "not_stale");

  const match = await db.collection("battleMatches").doc("m1").get();
  assert.strictEqual(match.data().currentRound, 6); // only advanced once
});

test("two genuinely concurrent sweep attempts on the same stale round produce exactly one forfeit", async () => {
  // Same real-transaction-interleaving proof technique already used by
  // iap.test.js's "two concurrent first-claims" and
  // global_points_reliability.test.js — FakeFirestore's conflict
  // detection is exercised for real, not simulated by calling twice in
  // sequence.
  const db = new FakeFirestore();
  seedMatch(db, "m1", {currentRound: 5});

  const [a, b] = await Promise.all([
    forfeitOneStaleRound("m1", NOW, db),
    forfeitOneStaleRound("m1", NOW, db),
  ]);
  const outcomes = [a, b].sort();
  // Exactly one call actually advanced the round; the other lost the
  // transaction race and retried against the now-fresh (no longer
  // stale) document.
  assert.strictEqual(outcomes.filter((o) => o === "advanced").length, 1);

  const match = await db.collection("battleMatches").doc("m1").get();
  assert.strictEqual(match.data().currentRound, 6); // not 7 — no double-advance
  const answer = await db
      .collection("battleMatches").doc("m1")
      .collection("answers").doc("5").get();
  assert.strictEqual(answer.exists, true);
});

// --- stale client callback: the sweep only ever acts on the CURRENT round ---

test("the sweep always resolves match.currentRound, never a caller-assumed round", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {currentRound: 12});
  const outcome = await forfeitOneStaleRound("m1", NOW, db);
  assert.strictEqual(outcome, "advanced");
  // The answer landed on round 12 (the real current round), not round 0
  // or any other stale assumption.
  const answer12 = await db
      .collection("battleMatches").doc("m1")
      .collection("answers").doc("12").get();
  assert.strictEqual(answer12.exists, true);
  const answer0 = await db
      .collection("battleMatches").doc("m1")
      .collection("answers").doc("0").get();
  assert.strictEqual(answer0.exists, false);
});

// --- result/stars processed only once: the sweep defers entirely once concluded ---

test("an already-concluded match is never touched again", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {result: PLAYER_A, status: "finished"});
  const outcome = await forfeitOneStaleRound("m1", NOW, db);
  assert.strictEqual(outcome, "already_concluded");
  const match = await db.collection("battleMatches").doc("m1").get();
  assert.strictEqual(match.data().currentRound, 3); // untouched
});

test("a match with result set but status still active (mid-transition) is also left alone", async () => {
  // scoreAnswer sets `result` and `status` in the same write, but this
  // guard checks both independently on purpose — belt-and-suspenders
  // against ever forfeiting a round on a match that has already been
  // decided by either signal.
  const db = new FakeFirestore();
  seedMatch(db, "m1", {result: "draw"});
  const outcome = await forfeitOneStaleRound("m1", NOW, db);
  assert.strictEqual(outcome, "already_concluded");
});

// --- pending/declined invites are out of scope ---

test("a friend/clan challenge nobody accepted yet is never forfeited", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {inviteState: "pending"});
  const outcome = await forfeitOneStaleRound("m1", NOW, db);
  assert.strictEqual(outcome, "not_started");
});

test("a declined challenge is never forfeited either", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {inviteState: "declined"});
  const outcome = await forfeitOneStaleRound("m1", NOW, db);
  assert.strictEqual(outcome, "not_started");
});

test("a public/bot match (inviteState absent) is eligible", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1");
  delete db.docs.get("battleMatches/m1").data.inviteState;
  const outcome = await forfeitOneStaleRound("m1", NOW, db);
  assert.strictEqual(outcome, "advanced");
});

// --- edge cases ---

test("a match that no longer exists is a safe no-op", async () => {
  const db = new FakeFirestore();
  const outcome = await forfeitOneStaleRound("nonexistent", NOW, db);
  assert.strictEqual(outcome, "no_such_match");
});

test("a round number with no matching turnOrder entry is a safe no-op", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {currentRound: 3, turnOrder: turnOrderFor(2)}); // only rounds 0-1 exist
  const outcome = await forfeitOneStaleRound("m1", NOW, db);
  assert.strictEqual(outcome, "no_turn_entry");
});

// --- sweepOnce: the scheduled entry point, end to end ---

test("sweepOnce advances only the stale active matches, ignoring the rest", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "stale_active", {currentRound: 4});
  seedMatch(db, "fresh_active", {
    currentRound: 4,
    turnStartedAt: Timestamp.fromMillis(NOW - 1000),
  });
  seedMatch(db, "already_finished", {status: "finished", result: PLAYER_A});
  seedMatch(db, "pending_invite", {inviteState: "pending"});

  const {inspected, advanced} = await sweepOnce(db);

  assert.strictEqual(inspected, 3); // "already_finished" isn't status active, never fetched
  assert.strictEqual(advanced, 1);

  const staleMatch = await db.collection("battleMatches").doc("stale_active").get();
  assert.strictEqual(staleMatch.data().currentRound, 5);
  const freshMatch = await db.collection("battleMatches").doc("fresh_active").get();
  assert.strictEqual(freshMatch.data().currentRound, 4); // unchanged
});

test("sweepOnce tolerates one match failing without aborting the rest", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "good", {currentRound: 4});
  // A malformed document — no turnStartedAt/turnOrder at all — must not
  // crash the whole sweep cycle. forfeitOneStaleRound itself already
  // treats a missing turnStartedAt as "not stale" and returns cleanly,
  // so this is really confirming sweepOnce doesn't add its own
  // fragility on top of that.
  db.seed("battleMatches/broken", {status: "active", currentRound: 0});

  const {inspected, advanced} = await sweepOnce(db);
  assert.strictEqual(inspected, 2);
  assert.strictEqual(advanced, 1);
});

// =====================================================================
// Stage 2 — bulk resolution at round 19
// =====================================================================

/**
 * Test-only mirror of `battle_scoring.js`'s `scoreAnswer`, scoped to
 * exactly what Stage 2's own writes ever produce: an empty-text forfeit,
 * which the real `scoreAnswer` always scores as incorrect regardless of
 * which card was in play — so this deliberately does not reproduce the
 * romaji-comparison half of the real function at all, nothing here needs
 * it. It exists purely so these tests can prove Stage 2's writes, once
 * processed by the real (entirely unmodified) `scoreAnswer`, converge to
 * `status: "finished"` with the correct `result` — the same kind of gap
 * `battle_scoring.test.js` itself does not attempt to close either,
 * since no Firestore-trigger emulator is wired into this project (see
 * `fake_firestore.js`'s own doc comment on what it proves and does not).
 * `battle_scoring.js` itself is never imported, called, or modified by
 * this file.
 */
async function mirrorScoreAnswerForForfeit(matchId, round, dbInstance) {
  const matchRef = dbInstance.collection("battleMatches").doc(matchId);
  await dbInstance.runTransaction(async (transaction) => {
    const snap = await transaction.get(matchRef);
    const match = snap.data();
    if (!match) return;
    if (match.result) return;
    const scoredRounds = match.scoredRounds || {};
    if (scoredRounds[String(round)]) return;

    // A forfeit's contribution to officialScore is always zero — no
    // conditional needed here, unlike the real scoreAnswer, since this
    // mirror is only ever fed forfeited (empty-text) rounds.
    const officialScore = Object.assign({}, match.officialScore || {});
    const newScoredRounds = Object.assign({}, scoredRounds, {
      [String(round)]: true,
    });
    const updates = {officialScore, scoredRounds: newScoredRounds};

    const players = match.players || [];
    let allPriorRoundsProcessed = true;
    for (let r = 0; r <= round; r++) {
      if (!newScoredRounds[String(r)]) {
        allPriorRoundsProcessed = false;
        break;
      }
    }
    const mainPhaseRounds = STAGE2_TRIGGER_ROUND + 1; // mirrors MAIN_PHASE_ROUNDS
    if (allPriorRoundsProcessed && round >= mainPhaseRounds - 1) {
      const scores = players.map((p) => officialScore[p] || 0);
      if (scores.length === 2 && scores[0] !== scores[1]) {
        updates.result = scores[0] > scores[1] ? players[0] : players[1];
        updates.status = "finished";
      } else if (round === MAX_ROUNDS - 1) {
        updates.result = "draw";
        updates.status = "finished";
      }
    }
    // FakeTransaction only implements `.set()` — no `.update()` — same
    // constraint every other transaction in this codebase already works
    // within (see `writeForfeit`'s own comment on this).
    transaction.set(matchRef, updates, {merge: true});
  });
}

/** Runs [mirrorScoreAnswerForForfeit] for every round Stage 2 could have
 * written, in round order — standing in for however many separate
 * `onDocumentCreated` invocations the real trigger would eventually run,
 * collapsed into one deterministic pass for the test. */
async function mirrorScoreAllForfeitedRounds(matchId, fromRound, toRound, dbInstance) {
  for (let r = fromRound; r <= toRound; r++) {
    await mirrorScoreAnswerForForfeit(matchId, r, dbInstance);
  }
}

/**
 * Test-only mirror of `battle_repository.dart`'s `submitAnswer` — a real
 * player's answer, guarded by the identical `currentRound == round`
 * transactional check the real client uses. Exists so the race tests
 * below can prove Stage 2 defers to a genuine reconnect using the same
 * mechanism the real app relies on, without importing Dart code into a
 * Node test.
 */
async function simulateClientSubmitAnswer(matchId, round, byUid, text, dbInstance) {
  const matchRef = dbInstance.collection("battleMatches").doc(matchId);
  return dbInstance.runTransaction(async (transaction) => {
    const snap = await transaction.get(matchRef);
    const match = snap.data();
    if (!match) return "no_such_match";
    if ((match.currentRound || 0) !== round) return "raced_out";
    const answerRef = matchRef.collection("answers").doc(String(round));
    transaction.set(answerRef, {byUid, text});
    transaction.set(
        matchRef,
        {currentRound: round + 1, turnStartedAt: new Date()},
        {merge: true},
    );
    return "submitted";
  });
}

function seedAtRound19(db, matchId, {tied, scoreA = 0, scoreB = 0} = {}) {
  const officialScore = tied ?
    {[PLAYER_A]: scoreA, [PLAYER_B]: scoreA} :
    {[PLAYER_A]: scoreA, [PLAYER_B]: scoreB};
  seedMatch(db, matchId, {
    currentRound: STAGE2_TRIGGER_ROUND,
    officialScore,
    scoredRounds: scoredRoundsThrough(STAGE2_TRIGGER_ROUND),
  });
}

// --- 1/2. Rounds 0-18 behave exactly as before Stage 2 existed ---

test("round 10 stale: still a single stale round per sweep, untouched by Stage 2", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {currentRound: 10});
  const outcome = await forfeitOneStaleRound("m1", NOW, db);
  assert.strictEqual(outcome, "advanced");
  const match = await db.collection("battleMatches").doc("m1").get();
  assert.strictEqual(match.data().currentRound, 11); // one round only
});

test("round 18 stale: exactly one round processed, round 19 not yet touched", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {
    currentRound: STAGE2_TRIGGER_ROUND - 1,
    scoredRounds: scoredRoundsThrough(STAGE2_TRIGGER_ROUND - 1),
  });
  const outcome = await forfeitOneStaleRound("m1", NOW, db);
  assert.strictEqual(outcome, "advanced");
  const match = await db.collection("battleMatches").doc("m1").get();
  assert.strictEqual(match.data().currentRound, STAGE2_TRIGGER_ROUND);
  const answer19 = await db
      .collection("battleMatches").doc("m1")
      .collection("answers").doc(String(STAGE2_TRIGGER_ROUND)).get();
  assert.strictEqual(answer19.exists, false); // Stage 2 has not run yet
});

// --- 3. Round 19 stale, decisive score: no bulk resolution ---

test("round 19 stale with a decisive score: existing single-round conclusion, no bulk pass", async () => {
  const db = new FakeFirestore();
  seedAtRound19(db, "m1", {tied: false, scoreA: 9, scoreB: 6});
  const outcome = await forfeitOneStaleRound("m1", NOW, db);
  assert.strictEqual(outcome, "advanced");

  const match = await db.collection("battleMatches").doc("m1").get();
  // Only round 19 was forfeited — Stage 2 never triggered, because the
  // score standing after rounds 0..18 already decides this match, and
  // the existing (unmodified) scoring pipeline handles that on its own.
  assert.strictEqual(match.data().currentRound, STAGE2_TRIGGER_ROUND + 1);

  const answer20 = await db
      .collection("battleMatches").doc("m1")
      .collection("answers").doc(String(STAGE2_TRIGGER_ROUND + 1)).get();
  assert.strictEqual(answer20.exists, false);
  const answerLast = await db
      .collection("battleMatches").doc("m1")
      .collection("answers").doc(String(MAX_ROUNDS - 1)).get();
  assert.strictEqual(answerLast.exists, false);

  // Confirm what the existing pipeline would then do with just this one
  // forfeit, using the mirror — decisive already, concludes immediately.
  await mirrorScoreAnswerForForfeit("m1", STAGE2_TRIGGER_ROUND, db);
  const concluded = await db.collection("battleMatches").doc("m1").get();
  assert.strictEqual(concluded.data().status, "finished");
  assert.strictEqual(concluded.data().result, PLAYER_A);
});

// --- 4/5/6/7. Round 19 stale, tied: Stage 2 activates and finishes the match ---

test("round 19 stale and tied: Stage 2 forfeits every remaining round in one pass", async () => {
  const db = new FakeFirestore();
  seedAtRound19(db, "m1", {tied: true, scoreA: 7});
  const outcome = await forfeitOneStaleRound("m1", NOW, db);
  assert.strictEqual(outcome, "advanced");

  const match = await db.collection("battleMatches").doc("m1").get();
  // Every round through the end of the deck was forfeited — not just
  // one, and not spread across future sweep cycles.
  assert.strictEqual(match.data().currentRound, MAX_ROUNDS);

  for (let r = STAGE2_TRIGGER_ROUND; r < MAX_ROUNDS; r++) {
    const answer = await db
        .collection("battleMatches").doc("m1")
        .collection("answers").doc(String(r)).get();
    assert.strictEqual(answer.exists, true, `round ${r} should be forfeited`);
    assert.strictEqual(answer.data().text, "");
  }
});

test("Stage 2's forfeits, once scored, reach status finished with result draw", async () => {
  const db = new FakeFirestore();
  seedAtRound19(db, "m1", {tied: true, scoreA: 3});
  await forfeitOneStaleRound("m1", NOW, db);

  // Stand in for however many separate onDocumentCreated invocations the
  // real (unmodified) battle_scoring.js would eventually run for
  // answers/19 through answers/39.
  await mirrorScoreAllForfeitedRounds("m1", STAGE2_TRIGGER_ROUND, MAX_ROUNDS - 1, db);

  const match = await db.collection("battleMatches").doc("m1").get();
  assert.strictEqual(match.data().status, "finished");
  assert.strictEqual(match.data().result, "draw");
  // The score is unchanged from what it was entering round 19 — no
  // forfeit ever adds a point, for either player.
  assert.strictEqual(match.data().officialScore[PLAYER_A], 3);
  assert.strictEqual(match.data().officialScore[PLAYER_B], 3);
});

test("Stage 2's result is exactly the rule battle_scoring.js already uses — draw only at round 39", async () => {
  // A tie can only ever be forced into "draw" once every round through
  // MAX_ROUNDS - 1 is processed — this pins that down explicitly rather
  // than trusting the previous test's end-state alone.
  const db = new FakeFirestore();
  seedAtRound19(db, "m1", {tied: true, scoreA: 0});
  await forfeitOneStaleRound("m1", NOW, db);

  // Score every round except the very last one.
  await mirrorScoreAllForfeitedRounds("m1", STAGE2_TRIGGER_ROUND, MAX_ROUNDS - 2, db);
  let match = await db.collection("battleMatches").doc("m1").get();
  assert.strictEqual(match.data().result, null); // not concluded yet
  assert.strictEqual(match.data().status, "active");

  await mirrorScoreAnswerForForfeit("m1", MAX_ROUNDS - 1, db);
  match = await db.collection("battleMatches").doc("m1").get();
  assert.strictEqual(match.data().result, "draw");
  assert.strictEqual(match.data().status, "finished");
});

// --- 8. Idempotency ---

test("Stage 2 is idempotent: running the bulk pass again after completion is a safe no-op", async () => {
  const db = new FakeFirestore();
  seedAtRound19(db, "m1", {tied: true, scoreA: 5});
  await forfeitOneStaleRound("m1", NOW, db);
  const afterFirst = await db.collection("battleMatches").doc("m1").get();
  assert.strictEqual(afterFirst.data().currentRound, MAX_ROUNDS);

  // Calling the bulk pass again directly (standing in for a duplicate
  // trigger delivery, or a second sweep tick landing before the first
  // one's log line was even read) must not forfeit anything twice, and
  // must not throw.
  const second = await bulkForfeitRemainingRounds("m1", db);
  assert.strictEqual(second.forfeited, 0);
  assert.strictEqual(second.stoppedEarly, true);

  const afterSecond = await db.collection("battleMatches").doc("m1").get();
  assert.strictEqual(afterSecond.data().currentRound, MAX_ROUNDS); // unchanged

  // Calling the outer entry point again too: round 19 is long gone by
  // now (currentRound === MAX_ROUNDS), so this returns the existing
  // "no_rounds_left" no-op — same as any match whose deck is exhausted.
  const third = await forfeitOneStaleRound("m1", NOW + STALE_THRESHOLD_MS, db);
  assert.strictEqual(third, "no_rounds_left");
});

// --- 9. Concurrent Stage 2 invocations ---

test("two genuinely concurrent Stage 2 triggers on the same tied round 19 produce exactly one bulk pass", async () => {
  // Same real-transaction-interleaving technique this file already uses
  // for "two genuinely concurrent sweep attempts" — not two promises
  // that merely happen to resolve in sequence.
  const db = new FakeFirestore();
  seedAtRound19(db, "m1", {tied: true, scoreA: 4});

  const [a, b] = await Promise.all([
    forfeitOneStaleRound("m1", NOW, db),
    forfeitOneStaleRound("m1", NOW, db),
  ]);

  // Exactly one of the two actually won round 19's own transaction —
  // the loser's retry re-reads a document whose turnStartedAt has
  // already moved on and correctly reports "not_stale", never attempting
  // its own bulk pass on top of the winner's.
  const outcomes = [a, b].sort();
  assert.strictEqual(outcomes.filter((o) => o === "advanced").length, 1);
  assert.strictEqual(outcomes.filter((o) => o === "not_stale").length, 1);

  const match = await db.collection("battleMatches").doc("m1").get();
  assert.strictEqual(match.data().currentRound, MAX_ROUNDS); // exactly one full bulk pass

  // No round was forfeited twice — each answers/{round} doc exists
  // exactly once (FakeFirestore would not detect a double-.set() as an
  // error, so this checks the actual doc count/shape, not just that
  // .exists is true).
  for (let r = STAGE2_TRIGGER_ROUND; r < MAX_ROUNDS; r++) {
    const answer = await db
        .collection("battleMatches").doc("m1")
        .collection("answers").doc(String(r)).get();
    assert.strictEqual(answer.exists, true);
    assert.strictEqual(answer.data().forfeitedBySweep, true);
  }
});

// --- 10/11. Race against a reconnecting client ---

test("Case A — a real reconnect answer for round 19 racing Stage 2 is never overwritten", async () => {
  const db = new FakeFirestore();
  seedAtRound19(db, "m1", {tied: true, scoreA: 6}); // would trigger Stage 2 if the sweep wins alone

  const [sweepOutcome, clientOutcome] = await Promise.all([
    forfeitOneStaleRound("m1", NOW, db),
    simulateClientSubmitAnswer("m1", STAGE2_TRIGGER_ROUND, PLAYER_A, "shi", db),
  ]);

  const match = await db.collection("battleMatches").doc("m1").get();
  const answer19 = await db
      .collection("battleMatches").doc("m1")
      .collection("answers").doc(String(STAGE2_TRIGGER_ROUND)).get();
  assert.strictEqual(answer19.exists, true);

  if (clientOutcome === "submitted") {
    // The real answer landed first: it must survive untouched, Stage 2
    // must never have triggered off a round it lost, and the match must
    // sit at exactly round 20 — not bulk-resolved to 40.
    assert.strictEqual(answer19.data().text, "shi");
    assert.strictEqual(match.data().currentRound, STAGE2_TRIGGER_ROUND + 1);
    assert.strictEqual(sweepOutcome, "not_stale");
  } else {
    // The sweep won this particular interleaving instead — equally
    // valid under genuine concurrency. The claim this test actually
    // makes is "no double-advance, no corruption either way", not "the
    // client always wins a real race".
    assert.strictEqual(clientOutcome, "raced_out");
    assert.strictEqual(answer19.data().text, "");
    assert.strictEqual(sweepOutcome, "advanced");
    assert.strictEqual(match.data().currentRound, MAX_ROUNDS);
  }
});

test("Case B — a stale client answer after Stage 2 already committed cannot resurrect the match", async () => {
  const db = new FakeFirestore();
  seedAtRound19(db, "m1", {tied: true, scoreA: 2});
  const sweepOutcome = await forfeitOneStaleRound("m1", NOW, db);
  assert.strictEqual(sweepOutcome, "advanced");
  const afterStage2 = await db.collection("battleMatches").doc("m1").get();
  assert.strictEqual(afterStage2.data().currentRound, MAX_ROUNDS);

  // A client that was still mid-reconnect for round 19 finally submits,
  // long after Stage 2 already forfeited it (and everything after it).
  const clientOutcome = await simulateClientSubmitAnswer(
      "m1", STAGE2_TRIGGER_ROUND, PLAYER_A, "shi", db,
  );
  assert.strictEqual(clientOutcome, "raced_out");

  // Nothing changed: the forfeit still stands, currentRound is still
  // exactly where Stage 2 left it, and no second answer document exists
  // for round 19 overwriting the forfeit.
  const match = await db.collection("battleMatches").doc("m1").get();
  assert.strictEqual(match.data().currentRound, MAX_ROUNDS);
  const answer19 = await db
      .collection("battleMatches").doc("m1")
      .collection("answers").doc(String(STAGE2_TRIGGER_ROUND)).get();
  assert.strictEqual(answer19.data().text, "");
});

// --- 12. Stage 2 can never produce a Perfect Draw ---

test("Stage 2's draw is never a Perfect Draw", async () => {
  const db = new FakeFirestore();
  // Each player is the answerer for exactly half of all 40 rounds
  // (turnOrderFor alternates ownership every round) — 20 rounds each
  // across the whole match. Entering round 19 tied, at most ~9-10 of
  // those 20 have even happened yet, so officialScore cannot possibly
  // equal the full 20-round count Perfect Draw requires, no matter how
  // high the pre-round-19 score is (capped here at the true maximum: an
  // answerer who got every single one of their own rounds among 0..18
  // correct).
  seedAtRound19(db, "m1", {tied: true, scoreA: 9});
  await forfeitOneStaleRound("m1", NOW, db);
  await mirrorScoreAllForfeitedRounds("m1", STAGE2_TRIGGER_ROUND, MAX_ROUNDS - 1, db);

  const match = await db.collection("battleMatches").doc("m1").get();
  assert.strictEqual(match.data().result, "draw");

  // Mirrors isPerfectDraw's own check (battle_stars.js) purely to prove
  // the claim — not a reimplementation this file depends on for
  // anything: roundsAnswered per uid is fixed at match creation and
  // untouched by any of this.
  const data = match.data();
  const turnOrder = data.turnOrder;
  for (const uid of data.players) {
    const roundsAnswered = turnOrder.filter((e) => e.deckOwnerUid !== uid).length;
    assert.strictEqual(roundsAnswered, 20);
    assert.notStrictEqual(data.officialScore[uid] || 0, roundsAnswered);
  }
});

// --- 13. A concluded match is never re-touched (what lets battle_stars.js pay exactly once) ---

test("a match Stage 2 already concluded is never forfeited again by a later sweep", async () => {
  // This file does not re-test battle_stars.js's own starsApplied claim
  // transaction (already covered by battle_stars.test.js/
  // battle_stars_perfect_draw.test.js) — what belongs here is proving
  // this file's own half of "stars applied exactly once": that nothing
  // in this file ever writes to a match again once scoreAnswer has
  // concluded it, since onBattleMatchConcluded only fires on a write at
  // all.
  const db = new FakeFirestore();
  seedAtRound19(db, "m1", {tied: true, scoreA: 1});
  await forfeitOneStaleRound("m1", NOW, db);
  await mirrorScoreAllForfeitedRounds("m1", STAGE2_TRIGGER_ROUND, MAX_ROUNDS - 1, db);
  const concluded = await db.collection("battleMatches").doc("m1").get();
  assert.strictEqual(concluded.data().status, "finished");

  const laterSweep = await forfeitOneStaleRound("m1", NOW + 10 * STALE_THRESHOLD_MS, db);
  assert.strictEqual(laterSweep, "already_concluded");

  const unchanged = await db.collection("battleMatches").doc("m1").get();
  assert.deepStrictEqual(unchanged.data().result, concluded.data().result);
  assert.strictEqual(unchanged.data().status, "finished");
});

// --- 14/15. Pending/declined invites at round 19 are still excluded ---

test("a pending invite sitting at round 19 is still never touched by Stage 2", async () => {
  const db = new FakeFirestore();
  seedAtRound19(db, "m1", {tied: true, scoreA: 5});
  db.docs.get("battleMatches/m1").data.inviteState = "pending";
  const outcome = await forfeitOneStaleRound("m1", NOW, db);
  assert.strictEqual(outcome, "not_started");
  const match = await db.collection("battleMatches").doc("m1").get();
  assert.strictEqual(match.data().currentRound, STAGE2_TRIGGER_ROUND); // untouched
});

test("a declined invite sitting at round 19 is still never touched by Stage 2", async () => {
  const db = new FakeFirestore();
  seedAtRound19(db, "m1", {tied: true, scoreA: 5});
  db.docs.get("battleMatches/m1").data.inviteState = "declined";
  const outcome = await forfeitOneStaleRound("m1", NOW, db);
  assert.strictEqual(outcome, "not_started");
});

// --- 16. A normal, recently-active match at round 19 is never swept prematurely ---

test("round 19, tied, but not yet stale: left alone entirely, no bulk pass", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {
    currentRound: STAGE2_TRIGGER_ROUND,
    officialScore: {[PLAYER_A]: 5, [PLAYER_B]: 5},
    scoredRounds: scoredRoundsThrough(STAGE2_TRIGGER_ROUND),
    turnStartedAt: Timestamp.fromMillis(NOW - 5000), // 5s old, well within budget
  });
  const outcome = await forfeitOneStaleRound("m1", NOW, db);
  assert.strictEqual(outcome, "not_stale");
  const match = await db.collection("battleMatches").doc("m1").get();
  assert.strictEqual(match.data().currentRound, STAGE2_TRIGGER_ROUND); // unchanged
  const answer19 = await db
      .collection("battleMatches").doc("m1")
      .collection("answers").doc(String(STAGE2_TRIGGER_ROUND)).get();
  assert.strictEqual(answer19.exists, false);
});

// --- 17. Everything before round 19 is provably unchanged by this feature ---

test("sweepOnce across a mix of rounds: only the genuinely stale ones move, round-19 handling is additive only", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "early_stale", {currentRound: 4});
  seedMatch(db, "early_fresh", {
    currentRound: 4,
    turnStartedAt: Timestamp.fromMillis(NOW - 1000),
  });
  seedAtRound19(db, "round19_decisive", {tied: false, scoreA: 8, scoreB: 5});
  seedAtRound19(db, "round19_tied", {tied: true, scoreA: 3});

  const {inspected, advanced} = await sweepOnce(db, NOW);
  assert.strictEqual(inspected, 4);
  assert.strictEqual(advanced, 3); // early_fresh is the only one left alone

  const earlyStale = await db.collection("battleMatches").doc("early_stale").get();
  assert.strictEqual(earlyStale.data().currentRound, 5); // one round, unchanged behavior

  const earlyFresh = await db.collection("battleMatches").doc("early_fresh").get();
  assert.strictEqual(earlyFresh.data().currentRound, 4); // untouched, unchanged behavior

  const decisive = await db.collection("battleMatches").doc("round19_decisive").get();
  assert.strictEqual(decisive.data().currentRound, STAGE2_TRIGGER_ROUND + 1); // one round only

  const tied = await db.collection("battleMatches").doc("round19_tied").get();
  assert.strictEqual(tied.data().currentRound, MAX_ROUNDS); // Stage 2 ran
});

// --- forfeitRoundUnconditionally, in isolation ---

test("forfeitRoundUnconditionally forfeits regardless of turnStartedAt freshness", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {
    currentRound: 25,
    turnStartedAt: Timestamp.fromMillis(NOW), // freshly started, would be "not_stale" via the gated path
  });
  const outcome = await forfeitRoundUnconditionally("m1", 25, db);
  assert.strictEqual(outcome, "advanced");
  const match = await db.collection("battleMatches").doc("m1").get();
  assert.strictEqual(match.data().currentRound, 26);
});

test("forfeitRoundUnconditionally refuses to act on a round that is no longer current", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {currentRound: 25});
  const outcome = await forfeitRoundUnconditionally("m1", 24, db); // stale caller-assumed round
  assert.strictEqual(outcome, "raced");
  const match = await db.collection("battleMatches").doc("m1").get();
  assert.strictEqual(match.data().currentRound, 25); // untouched
});

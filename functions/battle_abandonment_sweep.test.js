const test = require("node:test");
const assert = require("node:assert");
const {Timestamp} = require("firebase-admin/firestore");

const {
  _internal: {forfeitOneStaleRound, sweepOnce, STALE_THRESHOLD_MS, MAX_ROUNDS},
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

const test = require("node:test");
const assert = require("node:assert");
const {Timestamp} = require("firebase-admin/firestore");

const {
  _internal: {
    resolveOneAbandonment,
    sweepOnce,
    ABANDON_GRACE_PERIOD_MS,
    STALE_THRESHOLD_MS,
  },
} = require("./battle_abandonment_sweep");
const {FakeFirestore} = require("./test_helpers/fake_firestore");

const PLAYER_A = "uidA1234567890123456789012";
const PLAYER_B = "uidB1234567890123456789012";
const NOW = Date.now();

function turnOrderFor(rounds) {
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
    currentRound: 5,
    turnOrder: turnOrderFor(40),
    // Fresh, so the pre-existing per-round staleness sweep never fires
    // as a confound in these tests — the whole point here is the
    // *explicit* abandon path, independent of round timing.
    turnStartedAt: Timestamp.fromMillis(NOW),
    officialScore: {[PLAYER_A]: 0, [PLAYER_B]: 0},
    result: null,
    scoredRounds: {},
    rankedMatch: true,
    inviteState: "accepted",
    abandon: null,
  };
  db.seed(`battleMatches/${matchId}`, {...base, ...overrides});
}

async function readMatch(db, matchId) {
  const snap = await db.collection("battleMatches").doc(matchId).get();
  return snap.data();
}

// --- ABANDON_GRACE_PERIOD_MS is exactly 30 seconds ---

test("the grace period is exactly 30 seconds, mirroring " +
    "kBattleAbandonGracePeriodSeconds", () => {
  assert.strictEqual(ABANDON_GRACE_PERIOD_MS, 30 * 1000);
});

// --- not yet due ---

test("before 30 seconds have passed, the match is untouched and stays " +
    "resumable", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {
    abandon: {uid: PLAYER_A, since: Timestamp.fromMillis(NOW - 10 * 1000)},
  });
  const outcome = await resolveOneAbandonment("m1", NOW, db);
  assert.strictEqual(outcome, "not_yet_due");
  const match = await readMatch(db, "m1");
  assert.strictEqual(match.status, "active");
  assert.strictEqual(match.result, null);
  assert.deepStrictEqual(match.abandon, {
    uid: PLAYER_A,
    since: Timestamp.fromMillis(NOW - 10 * 1000),
  });
});

test("at 29.9 seconds, still not due — the boundary is exclusive of a " +
    "match that just barely hasn't reached it", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {
    abandon: {uid: PLAYER_A, since: Timestamp.fromMillis(NOW - 29900)},
  });
  const outcome = await resolveOneAbandonment("m1", NOW, db);
  assert.strictEqual(outcome, "not_yet_due");
});

// --- exactly due / finalization ---

test("at exactly 30 seconds, the match is finalized: the player who " +
    "left loses, their opponent wins", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {
    abandon: {uid: PLAYER_A, since: Timestamp.fromMillis(NOW - ABANDON_GRACE_PERIOD_MS)},
  });
  const outcome = await resolveOneAbandonment("m1", NOW, db);
  assert.strictEqual(outcome, "finalized");
  const match = await readMatch(db, "m1");
  assert.strictEqual(match.status, "finished");
  assert.strictEqual(match.result, PLAYER_B, "the opponent must win");
  assert.strictEqual(match.abandonedBy, PLAYER_A);
});

test("well past 30 seconds, still finalizes correctly (a sweep that " +
    "runs late is not a different outcome)", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {
    abandon: {uid: PLAYER_B, since: Timestamp.fromMillis(NOW - 5 * 60 * 1000)},
  });
  const outcome = await resolveOneAbandonment("m1", NOW, db);
  assert.strictEqual(outcome, "finalized");
  const match = await readMatch(db, "m1");
  assert.strictEqual(match.result, PLAYER_A, "B left, A must win");
});

// --- reconnect ---

test("if the player reconnects (clears their own abandon mark) before " +
    "the deadline, resolving finds nothing to finalize", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {abandon: null}); // already cleared, as if they returned
  const outcome = await resolveOneAbandonment("m1", NOW, db);
  assert.strictEqual(outcome, "reconnected");
  const match = await readMatch(db, "m1");
  assert.strictEqual(match.status, "active");
  assert.strictEqual(match.result, null);
});

test("race at the deadline: a reconnect that lands before the resolve " +
    "transaction reads the document wins deterministically — the match " +
    "is never finalized once abandon is truly cleared", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {
    abandon: {uid: PLAYER_A, since: Timestamp.fromMillis(NOW - ABANDON_GRACE_PERIOD_MS - 1)},
  });
  // The reconnect write happens first, in real Firestore terms — model
  // that here as clearing abandon before resolveOneAbandonment runs at
  // all, since FakeFirestore's transactions are not concurrent
  // coroutines the way real Firestore's are; the meaningful guarantee
  // under test is that resolveOneAbandonment re-reads fresh state
  // inside its own transaction rather than trusting anything captured
  // earlier, which is exactly what makes "whoever's write lands first
  // wins" true regardless of which one that turns out to be.
  await db.collection("battleMatches").doc("m1").set(
      {abandon: null}, {merge: true});
  const outcome = await resolveOneAbandonment("m1", NOW, db);
  assert.strictEqual(outcome, "reconnected");
  const match = await readMatch(db, "m1");
  assert.strictEqual(match.status, "active");
});

// --- idempotency ---

test("resolving an already-finalized match a second time is a safe " +
    "no-op — the result is never overwritten or double-applied",
async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {
    abandon: {uid: PLAYER_A, since: Timestamp.fromMillis(NOW - ABANDON_GRACE_PERIOD_MS)},
  });
  const first = await resolveOneAbandonment("m1", NOW, db);
  assert.strictEqual(first, "finalized");
  const second = await resolveOneAbandonment("m1", NOW, db);
  assert.strictEqual(second, "already_concluded");
  const match = await readMatch(db, "m1");
  assert.strictEqual(match.result, PLAYER_B, "still B — never re-decided");
});

test("two overlapping resolve calls for the same match converge to " +
    "exactly one finalization, not two conflicting ones", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {
    abandon: {uid: PLAYER_A, since: Timestamp.fromMillis(NOW - ABANDON_GRACE_PERIOD_MS)},
  });
  const [a, b] = await Promise.all([
    resolveOneAbandonment("m1", NOW, db),
    resolveOneAbandonment("m1", NOW, db),
  ]);
  const outcomes = [a, b].sort();
  assert.deepStrictEqual(outcomes, ["already_concluded", "finalized"]);
});

// --- no abandon marker at all ---

test("a match with no abandon marker is left completely alone", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1"); // abandon: null from the base seed
  const outcome = await resolveOneAbandonment("m1", NOW, db);
  assert.strictEqual(outcome, "reconnected");
  const match = await readMatch(db, "m1");
  assert.strictEqual(match.status, "active");
});

// --- already-concluded matches are untouched ---

test("a match that already has a result (concluded some other way, " +
    "e.g. a real answer) is never touched even with an abandon marker",
async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {
    status: "finished",
    result: PLAYER_A,
    abandon: {uid: PLAYER_B, since: Timestamp.fromMillis(NOW - ABANDON_GRACE_PERIOD_MS)},
  });
  const outcome = await resolveOneAbandonment("m1", NOW, db);
  assert.strictEqual(outcome, "already_concluded");
  const match = await readMatch(db, "m1");
  assert.strictEqual(match.result, PLAYER_A, "untouched, not overwritten to B");
});

// --- sweep wiring ---

test("sweepOnce finalizes an abandoned match via the new path, without " +
    "needing the older per-round staleness sweep to also fire", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {
    abandon: {uid: PLAYER_A, since: Timestamp.fromMillis(NOW - ABANDON_GRACE_PERIOD_MS - 5000)},
  });
  const result = await sweepOnce(db, NOW);
  assert.strictEqual(result.abandonedFinalized, 1);
  const match = await readMatch(db, "m1");
  assert.strictEqual(match.status, "finished");
  assert.strictEqual(match.result, PLAYER_B);
});

test("sweepOnce still runs the pre-existing per-round staleness check " +
    "for a match with no abandon marker at all — the older mechanism " +
    "is unmodified and still the backstop for a force-killed app",
async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {
    abandon: null,
    turnStartedAt: Timestamp.fromMillis(NOW - STALE_THRESHOLD_MS - 1000),
  });
  const result = await sweepOnce(db, NOW);
  assert.strictEqual(result.abandonedFinalized, 0);
  assert.strictEqual(result.advanced, 1, "the old round-forfeit path still ran");
});

test("sweepOnce leaves a healthy, recently-active match with no " +
    "abandon marker completely alone", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1");
  const result = await sweepOnce(db, NOW);
  assert.strictEqual(result.abandonedFinalized, 0);
  assert.strictEqual(result.advanced, 0);
  const match = await readMatch(db, "m1");
  assert.strictEqual(match.status, "active");
});

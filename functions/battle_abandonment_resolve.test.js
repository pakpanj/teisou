const test = require("node:test");
const assert = require("node:assert");
const {Timestamp} = require("firebase-admin/firestore");

const {
  _internal: {
    resolveOneMatchAbsence,
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
    // *explicit* absence path, independent of round timing.
    turnStartedAt: Timestamp.fromMillis(NOW),
    officialScore: {[PLAYER_A]: 0, [PLAYER_B]: 0},
    result: null,
    scoredRounds: {},
    rankedMatch: true,
    inviteState: "accepted",
    absence: {},
  };
  db.seed(`battleMatches/${matchId}`, {...base, ...overrides});
}

async function readMatch(db, matchId) {
  const snap = await db.collection("battleMatches").doc(matchId).get();
  return snap.data();
}

function absenceFor(uid, msAgo) {
  return {[uid]: {since: Timestamp.fromMillis(NOW - msAgo)}};
}

// --- ABANDON_GRACE_PERIOD_MS is exactly 30 seconds ---

test("the grace period is exactly 30 seconds, mirroring " +
    "kBattleAbsenceGracePeriodSeconds", () => {
  assert.strictEqual(ABANDON_GRACE_PERIOD_MS, 30 * 1000);
});

// --- KASUS 1/2: exactly one player absent ---

test("before 30 seconds have passed, the match is untouched and stays " +
    "resumable", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {absence: absenceFor(PLAYER_A, 10 * 1000)});
  const outcome = await resolveOneMatchAbsence("m1", NOW, db);
  assert.strictEqual(outcome, "not_yet_due");
  const match = await readMatch(db, "m1");
  assert.strictEqual(match.status, "active");
  assert.strictEqual(match.result, null);
  assert.ok(PLAYER_A in match.absence, "the mark must survive untouched");
});

test("at 29.9 seconds, still not due — the boundary is exclusive of a " +
    "match that just barely hasn't reached it", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {absence: absenceFor(PLAYER_A, 29900)});
  const outcome = await resolveOneMatchAbsence("m1", NOW, db);
  assert.strictEqual(outcome, "not_yet_due");
});

test("at exactly 30 seconds, the match is finalized: the player who " +
    "left loses, their opponent wins", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {absence: absenceFor(PLAYER_A, ABANDON_GRACE_PERIOD_MS)});
  const outcome = await resolveOneMatchAbsence("m1", NOW, db);
  assert.strictEqual(outcome, "finalized_win");
  const match = await readMatch(db, "m1");
  assert.strictEqual(match.status, "finished");
  assert.strictEqual(match.result, PLAYER_B, "the opponent must win");
  assert.strictEqual(match.abandonedBy, PLAYER_A);
});

test("well past 30 seconds, still finalizes correctly (a sweep that " +
    "runs late is not a different outcome)", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {absence: absenceFor(PLAYER_B, 5 * 60 * 1000)});
  const outcome = await resolveOneMatchAbsence("m1", NOW, db);
  assert.strictEqual(outcome, "finalized_win");
  const match = await readMatch(db, "m1");
  assert.strictEqual(match.result, PLAYER_A, "B left, A must win");
});

test("symmetric: it is B's own absence and B's own deadline that " +
    "decides B's loss, exactly mirroring A's case with no special " +
    "casing by player position", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {absence: absenceFor(PLAYER_B, ABANDON_GRACE_PERIOD_MS)});
  const outcome = await resolveOneMatchAbsence("m1", NOW, db);
  assert.strictEqual(outcome, "finalized_win");
  const match = await readMatch(db, "m1");
  assert.strictEqual(match.result, PLAYER_A);
  assert.strictEqual(match.abandonedBy, PLAYER_B);
});

// --- reconnect ---

test("if the player reconnects (their key is removed from absence) " +
    "before the deadline, resolving finds nothing to finalize", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {absence: {}}); // already cleared, as if they returned
  const outcome = await resolveOneMatchAbsence("m1", NOW, db);
  assert.strictEqual(outcome, "no_absence");
  const match = await readMatch(db, "m1");
  assert.strictEqual(match.status, "active");
  assert.strictEqual(match.result, null);
});

test("race at the deadline: a reconnect that lands before the resolve " +
    "transaction reads the document wins deterministically — the match " +
    "is never finalized once the player's key is truly gone", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {
    absence: absenceFor(PLAYER_A, ABANDON_GRACE_PERIOD_MS + 1),
  });
  // The reconnect write happens first, in real Firestore terms — model
  // that here as clearing the key before resolveOneMatchAbsence runs at
  // all, since FakeFirestore's transactions are not concurrent
  // coroutines the way real Firestore's are; the meaningful guarantee
  // under test is that resolveOneMatchAbsence re-reads fresh state
  // inside its own transaction rather than trusting anything captured
  // earlier, which is exactly what makes "whoever's write lands first
  // wins" true regardless of which one that turns out to be.
  //
  // Re-`seed`ed rather than `.set(..., {merge: true})`, deliberately:
  // this fake's `applyWrite` recursively deep-merges nested plain-object
  // fields under merge semantics (see its own doc comment), so writing
  // `{absence: {}}` onto an existing non-empty `absence` map would merge
  // in *zero* keys and leave the old ones untouched — not the same thing
  // real Firestore's `.update({absence: newMap})` does (a whole-field
  // replace, which is what `battle_repository.dart`'s `clearAbsence`
  // actually relies on in production). `seed()` is this fake's own
  // "test-only seam... bypassing any transaction" — a full document
  // replace, which is what a genuine reconnect write actually is here.
  seedMatch(db, "m1", {absence: {}});
  const outcome = await resolveOneMatchAbsence("m1", NOW, db);
  assert.strictEqual(outcome, "no_absence");
  const match = await readMatch(db, "m1");
  assert.strictEqual(match.status, "active");
});

// --- idempotency ---

test("resolving an already-finalized match a second time is a safe " +
    "no-op — the result is never overwritten or double-applied",
async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {absence: absenceFor(PLAYER_A, ABANDON_GRACE_PERIOD_MS)});
  const first = await resolveOneMatchAbsence("m1", NOW, db);
  assert.strictEqual(first, "finalized_win");
  const second = await resolveOneMatchAbsence("m1", NOW, db);
  assert.strictEqual(second, "already_concluded");
  const match = await readMatch(db, "m1");
  assert.strictEqual(match.result, PLAYER_B, "still B — never re-decided");
});

test("two overlapping resolve calls for the same match converge to " +
    "exactly one finalization, not two conflicting ones", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {absence: absenceFor(PLAYER_A, ABANDON_GRACE_PERIOD_MS)});
  const [a, b] = await Promise.all([
    resolveOneMatchAbsence("m1", NOW, db),
    resolveOneMatchAbsence("m1", NOW, db),
  ]);
  const outcomes = [a, b].sort();
  assert.deepStrictEqual(outcomes, ["already_concluded", "finalized_win"]);
});

// --- no absence entries at all ---

test("a match with an empty absence map is left completely alone", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1"); // absence: {} from the base seed
  const outcome = await resolveOneMatchAbsence("m1", NOW, db);
  assert.strictEqual(outcome, "no_absence");
  const match = await readMatch(db, "m1");
  assert.strictEqual(match.status, "active");
});

// --- already-concluded matches are untouched ---

test("a match that already has a result (concluded some other way, " +
    "e.g. a real answer) is never touched even with an absence entry " +
    "still sitting on the doc", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {
    status: "finished",
    result: PLAYER_A,
    absence: absenceFor(PLAYER_B, ABANDON_GRACE_PERIOD_MS),
  });
  const outcome = await resolveOneMatchAbsence("m1", NOW, db);
  assert.strictEqual(outcome, "already_concluded");
  const match = await readMatch(db, "m1");
  assert.strictEqual(match.result, PLAYER_A, "untouched, not overwritten to B");
});

// --- KASUS 3: both players absent ---

test("KASUS 3: both players absent, neither deadline has passed yet — " +
    "stays paused", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {
    absence: {
      ...absenceFor(PLAYER_A, 5000),
      ...absenceFor(PLAYER_B, 3000),
    },
  });
  const outcome = await resolveOneMatchAbsence("m1", NOW, db);
  assert.strictEqual(outcome, "not_yet_due");
  const match = await readMatch(db, "m1");
  assert.strictEqual(match.status, "active");
});

test("KASUS 3D: both players absent and only the EARLIER of the two " +
    "deadlines has passed — still not due, since resolving must wait " +
    "for the LATER deadline, not the earlier one", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {
    // A left 40s ago (past their own deadline); B left only 10s ago
    // (not past theirs). Resolving now would be deciding off half the
    // picture.
    absence: {
      ...absenceFor(PLAYER_A, ABANDON_GRACE_PERIOD_MS + 10000),
      ...absenceFor(PLAYER_B, 10000),
    },
  });
  const outcome = await resolveOneMatchAbsence("m1", NOW, db);
  assert.strictEqual(outcome, "not_yet_due");
  const match = await readMatch(db, "m1");
  assert.strictEqual(match.status, "active");
});

test("KASUS 3D: both players absent and BOTH deadlines have passed — " +
    "the match becomes abandoned, with no winner and no loser", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {
    absence: {
      ...absenceFor(PLAYER_A, ABANDON_GRACE_PERIOD_MS + 15000),
      ...absenceFor(PLAYER_B, ABANDON_GRACE_PERIOD_MS + 2000),
    },
  });
  const outcome = await resolveOneMatchAbsence("m1", NOW, db);
  assert.strictEqual(outcome, "finalized_abandoned");
  const match = await readMatch(db, "m1");
  assert.strictEqual(match.status, "abandoned");
  assert.strictEqual(
      match.result, null, "no result — this must never move the star ladder",
  );
  assert.deepStrictEqual(
      [...match.abandonedBy].sort(), [PLAYER_A, PLAYER_B].sort(),
  );
});

test("KASUS 3A: only A returns before the deadline — the map shrinks " +
    "to just B, and resolving now correctly falls through to the " +
    "single-absent rule off B's own original timestamp (A wins once " +
    "B's own deadline passes)", async () => {
  const db = new FakeFirestore();
  // Both originally left at the same moment; A has since reconnected
  // (their key removed), leaving only B's original entry behind.
  seedMatch(db, "m1", {
    absence: absenceFor(PLAYER_B, ABANDON_GRACE_PERIOD_MS),
  });
  const outcome = await resolveOneMatchAbsence("m1", NOW, db);
  assert.strictEqual(outcome, "finalized_win");
  const match = await readMatch(db, "m1");
  assert.strictEqual(match.result, PLAYER_A, "A returned, B did not — A wins");
  assert.strictEqual(match.status, "finished");
});

test("KASUS 3B: symmetric — only B returns, A's own deadline decides " +
    "A's loss", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {
    absence: absenceFor(PLAYER_A, ABANDON_GRACE_PERIOD_MS),
  });
  const outcome = await resolveOneMatchAbsence("m1", NOW, db);
  assert.strictEqual(outcome, "finalized_win");
  const match = await readMatch(db, "m1");
  assert.strictEqual(match.result, PLAYER_B, "B returned, A did not — B wins");
});

test("KASUS 3C: both return before either deadline — the map is " +
    "empty, resolving is a pure no-op, and the match stays exactly as " +
    "resumable/active as it always was", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {absence: {}});
  const outcome = await resolveOneMatchAbsence("m1", NOW, db);
  assert.strictEqual(outcome, "no_absence");
  const match = await readMatch(db, "m1");
  assert.strictEqual(match.status, "active");
  assert.strictEqual(match.result, null);
});

test("a uid inside absence that is somehow not one of the match's real " +
    "players is ignored rather than trusted — defensive only, should " +
    "be unreachable given firestore.rules only lets a player write " +
    "their own key", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {
    absence: {"not-a-real-player": {since: Timestamp.fromMillis(NOW - 999999)}},
  });
  const outcome = await resolveOneMatchAbsence("m1", NOW, db);
  assert.strictEqual(outcome, "no_absence");
});

// --- race conditions across the two-sided design ---

test("B reconnecting a moment before a resolve call runs — while A is " +
    "still separately, genuinely past their own deadline — produces " +
    "exactly 'A loses to B', never a fabricated draw and never an " +
    "abandoned result for a match where someone is plainly still " +
    "there", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {
    absence: {
      ...absenceFor(PLAYER_A, ABANDON_GRACE_PERIOD_MS + 1),
      ...absenceFor(PLAYER_B, ABANDON_GRACE_PERIOD_MS + 1),
    },
  });
  // B's reconnect write lands first — re-seeded (a full document
  // replace, this fake's own "bypassing any transaction" test seam)
  // rather than a merge write, for the same reason the earlier
  // reconnect test uses `seedMatch` instead of `.set(..., {merge:
  // true})`: this fake's merge write deep-merges nested map fields, so
  // it cannot express "this key is now gone" at all.
  seedMatch(db, "m1", {absence: absenceFor(PLAYER_A, ABANDON_GRACE_PERIOD_MS + 1)});
  const outcome = await resolveOneMatchAbsence("m1", NOW, db);
  assert.strictEqual(outcome, "finalized_win");
  const match = await readMatch(db, "m1");
  assert.strictEqual(match.result, PLAYER_B, "B reconnected — A is the only one still gone");
  assert.notStrictEqual(match.status, "abandoned", "B is plainly still there");
});

test("race: two concurrent resolve calls on a both-absent, both-past-" +
    "deadline match converge to exactly one 'abandoned' finalization",
async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {
    absence: {
      ...absenceFor(PLAYER_A, ABANDON_GRACE_PERIOD_MS + 5000),
      ...absenceFor(PLAYER_B, ABANDON_GRACE_PERIOD_MS + 5000),
    },
  });
  const [a, b] = await Promise.all([
    resolveOneMatchAbsence("m1", NOW, db),
    resolveOneMatchAbsence("m1", NOW, db),
  ]);
  const outcomes = [a, b].sort();
  assert.deepStrictEqual(outcomes, ["already_concluded", "finalized_abandoned"]);
  const match = await readMatch(db, "m1");
  assert.strictEqual(match.status, "abandoned");
  assert.strictEqual(match.result, null);
});

test("a player returning at exactly the instant their own deadline " +
    "would have passed is never finalized against — the key being " +
    "gone always wins over the clock", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {absence: {}});
  const outcome = await resolveOneMatchAbsence("m1", NOW, db);
  assert.strictEqual(outcome, "no_absence");
});

// --- sweep wiring ---

test("sweepOnce finalizes an abandoned-by-timeout match via the new " +
    "path, without needing the older per-round staleness sweep to " +
    "also fire", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {
    absence: absenceFor(PLAYER_A, ABANDON_GRACE_PERIOD_MS + 5000),
  });
  const result = await sweepOnce(db, NOW);
  assert.strictEqual(result.abandonedFinalized, 1);
  const match = await readMatch(db, "m1");
  assert.strictEqual(match.status, "finished");
  assert.strictEqual(match.result, PLAYER_B);
});

test("sweepOnce finalizes a KASUS 3D both-absent match to 'abandoned' " +
    "via the same path", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {
    absence: {
      ...absenceFor(PLAYER_A, ABANDON_GRACE_PERIOD_MS + 5000),
      ...absenceFor(PLAYER_B, ABANDON_GRACE_PERIOD_MS + 5000),
    },
  });
  const result = await sweepOnce(db, NOW);
  assert.strictEqual(result.abandonedFinalized, 1);
  const match = await readMatch(db, "m1");
  assert.strictEqual(match.status, "abandoned");
  assert.strictEqual(match.result, null);
});

test("sweepOnce still runs the pre-existing per-round staleness check " +
    "for a match with an empty absence map — the older mechanism is " +
    "unmodified and still the backstop for a force-killed app",
async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {
    absence: {},
    turnStartedAt: Timestamp.fromMillis(NOW - STALE_THRESHOLD_MS - 1000),
  });
  const result = await sweepOnce(db, NOW);
  assert.strictEqual(result.abandonedFinalized, 0);
  assert.strictEqual(result.advanced, 1, "the old round-forfeit path still ran");
});

test("sweepOnce does NOT run the per-round staleness forfeit for a " +
    "match that is merely paused (absence non-empty, deadline not yet " +
    "due) — the round clock must stay frozen during a pause, not " +
    "quietly forfeit a round underneath it", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1", {
    absence: absenceFor(PLAYER_A, 5000), // well within the grace period
    // Also stale by the *old* per-round measure, to prove the pause
    // guard — not luck — is what's skipping it.
    turnStartedAt: Timestamp.fromMillis(NOW - STALE_THRESHOLD_MS - 1000),
  });
  const result = await sweepOnce(db, NOW);
  assert.strictEqual(result.abandonedFinalized, 0, "not due yet");
  assert.strictEqual(result.advanced, 0, "must not forfeit a round while paused");
  const match = await readMatch(db, "m1");
  assert.strictEqual(match.currentRound, 5, "round clock frozen");
});

test("sweepOnce leaves a healthy, recently-active match with an empty " +
    "absence map completely alone", async () => {
  const db = new FakeFirestore();
  seedMatch(db, "m1");
  const result = await sweepOnce(db, NOW);
  assert.strictEqual(result.abandonedFinalized, 0);
  assert.strictEqual(result.advanced, 0);
  const match = await readMatch(db, "m1");
  assert.strictEqual(match.status, "active");
});

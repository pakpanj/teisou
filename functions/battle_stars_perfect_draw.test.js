/**
 * Coverage for the Perfect Draw rule added to battle_stars.js — see that
 * file's own doc comment on [isPerfectDraw] for why it is derived
 * entirely from `officialScore`/`turnOrder`/`result` (all already
 * written by the unmodified battle_scoring.js) rather than a new
 * tracked field.
 */

const {test} = require("node:test");
const assert = require("node:assert");

const {
  isPerfectDraw,
  outcomeFor,
  applyOutcome,
  applyToPlayer,
} = require("./battle_stars")._internal;
const {FakeFirestore} = require("./test_helpers/fake_firestore");

const PLAYER_A = "uidA1234567890123456789012";
const PLAYER_B = "uidB1234567890123456789012";

/** 40-entry turnOrder, alternating deck ownership exactly like
 * `battle_turn_order_builder.dart`/`battle_matchmaking.js`'s real
 * `buildTurnOrder` — 20 rounds owned by each player. */
function fullTurnOrder() {
  return Array.from({length: 40}, (_, i) => ({
    round: i,
    deckOwnerUid: i % 2 === 0 ? PLAYER_A : PLAYER_B,
    cardId: `card_${i}`,
  }));
}

function drawnMatch(overrides = {}) {
  return {
    players: [PLAYER_A, PLAYER_B],
    result: "draw",
    turnOrder: fullTurnOrder(),
    officialScore: {[PLAYER_A]: 20, [PLAYER_B]: 20},
    ...overrides,
  };
}

// --- isPerfectDraw: score interpretation ---

test("20/20 vs 20/20 is a Perfect Draw", () => {
  const match = drawnMatch();
  assert.strictEqual(isPerfectDraw(match), true);
});

test("19/20 vs 19/20 is a draw but NOT perfect", () => {
  const match = drawnMatch({
    officialScore: {[PLAYER_A]: 19, [PLAYER_B]: 19},
  });
  assert.strictEqual(isPerfectDraw(match), false);
});

test("a decided win (result is a uid, not 'draw') is never a Perfect Draw", () => {
  // 20/20 vs 19/20 never reaches isPerfectDraw as a draw in the first
  // place — battle_scoring.js only ever sets result to a uid here, so
  // outcomeFor's own `result === "draw"` branch is never taken. Checked
  // directly too, as a defensive guarantee.
  const match = drawnMatch({
    result: PLAYER_A,
    officialScore: {[PLAYER_A]: 20, [PLAYER_B]: 19},
  });
  assert.strictEqual(isPerfectDraw(match), false);
});

test("naive score-only reading would be wrong here — this is why roundsAnswered matters",
    () => {
      // A match decided early (main phase only, 20 total rounds instead
      // of the full 40 a draw requires) can never actually reach
      // isPerfectDraw with result:"draw" in real play (battle_scoring.js
      // only declares a draw at round 39). But if some future bug or a
      // hand-built fixture ever produced this shape, the function must
      // not be fooled by a raw "score looks maxed" — it must use each
      // player's OWN answered-round count (10 here, not 20), not a
      // hardcoded assumption.
      const match = {
        players: [PLAYER_A, PLAYER_B],
        result: "draw",
        turnOrder: fullTurnOrder().slice(0, 20), // only 20 of 40 rounds exist
        officialScore: {[PLAYER_A]: 10, [PLAYER_B]: 10},
      };
      assert.strictEqual(isPerfectDraw(match), true); // 10/10 each — genuinely perfect for THIS shape
      const imperfect = {...match, officialScore: {[PLAYER_A]: 9, [PLAYER_B]: 10}};
      assert.strictEqual(isPerfectDraw(imperfect), false);
    });

// --- timeout / forfeit / empty answer all disqualify "perfect" the same way ---

test("a timeout/forfeit (scored as wrong, per battle_scoring.js) is never hidden inside a perfect score",
    () => {
      // battle_scoring.js scores an empty `text` (which is exactly what
      // a timeout, a client forfeit, and battle_abandonment_sweep.js's
      // server forfeit all write) as `correct: false`, unconditionally.
      // So ANY forfeited round for a player reduces THEIR OWN
      // officialScore below their personal roundsAnswered count — there
      // is no way for a forfeit to exist and still read as "perfect."
      const oneForfeit = drawnMatch({
        officialScore: {[PLAYER_A]: 19, [PLAYER_B]: 20}, // A had exactly one forfeited/wrong round
      });
      assert.strictEqual(isPerfectDraw(oneForfeit), false);
    });

test("pins the battle_scoring.js guarantee isPerfectDraw depends on: an "
    + "empty answer can never score as correct", () => {
  // isPerfectDraw never reads `answers/*` itself — it trusts
  // officialScore entirely, which is only trustworthy for this purpose
  // because battle_scoring.js's own correctness check unconditionally
  // rejects an empty answer (exactly what a timeout/forfeit writes).
  // battle_scoring.js is deliberately not modified by this feature and
  // exports no direct "isCorrect" helper to call instead — so this
  // pins the actual source text of the guarantee, the same "source
  // check" approach this codebase already uses elsewhere (e.g.
  // coach_wiring_test.dart) for a cross-file dependency that would
  // otherwise fail silently if the other file ever changed underneath
  // it.
  const fs = require("fs");
  const source = fs.readFileSync("./battle_scoring.js", "utf8");
  assert.match(
      source,
      /typedRomaji\.length > 0 &&/,
      "battle_scoring.js no longer guards on a non-empty answer — "
      + "isPerfectDraw's core assumption (a forfeit/timeout can never "
      + "score as correct) may no longer hold",
  );
});

test("all-forfeited match (both players 0/20) is a draw but never perfect", () => {
  const bothAbandoned = drawnMatch({
    officialScore: {[PLAYER_A]: 0, [PLAYER_B]: 0},
  });
  assert.strictEqual(isPerfectDraw(bothAbandoned), false);
});

// --- outcomeFor / applyOutcome: the star delta itself ---

test("outcomeFor returns 'perfectDraw' only when the draw is perfect", () => {
  assert.strictEqual(outcomeFor(PLAYER_A, "draw", true), "perfectDraw");
  assert.strictEqual(outcomeFor(PLAYER_A, "draw", false), "draw");
  assert.strictEqual(outcomeFor(PLAYER_A, "draw"), "draw"); // defaults to false
});

test("a Perfect Draw grants exactly +1, same as this project's own table", () => {
  const rank = {tier: "gold", division: 3, stars: 2, season: 1, winStreak: 0};
  const applied = applyOutcome(rank, "perfectDraw");
  assert.strictEqual(applied.delta, 1);
});

test("a normal draw still grants +0, unchanged by this feature", () => {
  const rank = {tier: "gold", division: 3, stars: 2, season: 1, winStreak: 0};
  const applied = applyOutcome(rank, "draw");
  assert.strictEqual(applied.delta, 0);
});

test("a Perfect Draw never gets the win streak's +2 bonus, even mid-streak", () => {
  const rank = {tier: "gold", division: 3, stars: 2, season: 1, winStreak: 5};
  const applied = applyOutcome(rank, "perfectDraw");
  assert.strictEqual(applied.delta, 1); // flat +1, not the win path's +2
});

test("a Perfect Draw does not touch the win streak, same as an ordinary draw", () => {
  const rank = {tier: "gold", division: 3, stars: 2, season: 1, winStreak: 5};
  const applied = applyOutcome(rank, "perfectDraw");
  assert.strictEqual(applied.rank.winStreak, 5); // unchanged, not reset, not incremented
});

test("ordinary win/loss deltas are completely unaffected by this change", () => {
  const rank = {tier: "gold", division: 3, stars: 2, season: 1, winStreak: 0};
  assert.strictEqual(applyOutcome(rank, "win").delta, 1);
  assert.strictEqual(applyOutcome(rank, "loss").delta, -1);
});

// --- applyToPlayer: the actual write, for both players ---

test("applyToPlayer writes +1 for a Perfect Draw, for each player independently", async () => {
  const db = new FakeFirestore();
  db.seed(`users/${PLAYER_A}`, {
    cardGameRank: {tier: "gold", division: 3, stars: 2, season: 1, winStreak: 0},
  });
  db.seed(`users/${PLAYER_B}`, {
    cardGameRank: {tier: "silver", division: 2, stars: 1, season: 1, winStreak: 0},
  });

  const appliedA = await applyToPlayer(PLAYER_A, "draw", 1, true, db);
  const appliedB = await applyToPlayer(PLAYER_B, "draw", 1, true, db);

  assert.strictEqual(appliedA.delta, 1);
  assert.strictEqual(appliedB.delta, 1);

  const userA = await db.collection("users").doc(PLAYER_A).get();
  assert.strictEqual(userA.data().cardGameRank.stars, 3);
  const userB = await db.collection("users").doc(PLAYER_B).get();
  assert.strictEqual(userB.data().cardGameRank.stars, 2);
});

// --- Idempotency: the same claim-transaction pattern the real trigger
// uses, exercised directly against FakeFirestore's real conflict
// detection (the same technique already proven for iap.test.js's "two
// concurrent first-claims" and battle_abandonment_sweep.test.js's
// concurrent-sweep test). Mirrors onBattleMatchConcluded's own claim
// shape (battle_stars.js, unmodified by this feature) rather than
// re-implementing new idempotency logic — Perfect Draw introduces no
// new idempotency surface of its own; it composes with the existing one.

async function claimStars(db, matchId, maxAttempts = 3) {
  const matchRef = db.collection("battleMatches").doc(matchId);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(matchRef);
    const data = snap.data();
    if (!data || !data.result || data.starsApplied) return false;
    const attempts = data.starsAttempts || 0;
    if (attempts >= maxAttempts) return false;
    tx.set(matchRef, {starsApplied: true, starsAttempts: attempts + 1}, {merge: true});
    return true;
  });
}

test("duplicate conclusion (retry after the first already succeeded) never claims twice", async () => {
  const db = new FakeFirestore();
  db.seed("battleMatches/m1", {result: "draw", starsApplied: false, starsAttempts: 0});

  const first = await claimStars(db, "m1");
  assert.strictEqual(first, true);
  const second = await claimStars(db, "m1"); // simulates Cloud Functions' at-least-once redelivery
  assert.strictEqual(second, false);
});

test("two genuinely concurrent match-conclusion deliveries only let one claim stars", async () => {
  const db = new FakeFirestore();
  db.seed("battleMatches/m1", {result: "draw", starsApplied: false, starsAttempts: 0});

  const [a, b] = await Promise.all([claimStars(db, "m1"), claimStars(db, "m1")]);
  const claims = [a, b].filter((x) => x === true);
  assert.strictEqual(claims.length, 1); // exactly one winner, never both, never zero
});

test("with the claim guard composed correctly, a Perfect Draw still applies +1 exactly once per player",
    async () => {
      const db = new FakeFirestore();
      db.seed("battleMatches/m1", {result: "draw", starsApplied: false, starsAttempts: 0});
      db.seed(`users/${PLAYER_A}`, {
        cardGameRank: {tier: "gold", division: 3, stars: 2, season: 1, winStreak: 0},
      });

      // Simulates two overlapping trigger invocations for the same
      // concluded match — only the winner of the claim goes on to call
      // applyToPlayer at all, exactly as the real trigger does.
      const attempts = await Promise.all([
        claimStars(db, "m1").then((won) =>
          won ? applyToPlayer(PLAYER_A, "draw", 1, true, db) : null),
        claimStars(db, "m1").then((won) =>
          won ? applyToPlayer(PLAYER_A, "draw", 1, true, db) : null),
      ]);
      const realApplications = attempts.filter((a) => a !== null);
      assert.strictEqual(realApplications.length, 1);

      const user = await db.collection("users").doc(PLAYER_A).get();
      assert.strictEqual(user.data().cardGameRank.stars, 3); // +1, not +2
    });

test("an ordinary (non-perfect) draw's existing +0 behavior is provably unchanged", async () => {
  const db = new FakeFirestore();
  db.seed(`users/${PLAYER_A}`, {
    cardGameRank: {tier: "gold", division: 3, stars: 2, season: 1, winStreak: 0},
  });
  const applied = await applyToPlayer(PLAYER_A, "draw", 1, false, db);
  assert.strictEqual(applied.delta, 0);
  const user = await db.collection("users").doc(PLAYER_A).get();
  assert.strictEqual(user.data().cardGameRank.stars, 2); // unchanged
});

test("an ordinary win's existing behavior is provably unchanged", async () => {
  const db = new FakeFirestore();
  db.seed(`users/${PLAYER_A}`, {
    cardGameRank: {tier: "gold", division: 3, stars: 2, season: 1, winStreak: 0},
  });
  const applied = await applyToPlayer(PLAYER_A, PLAYER_A, 1, false, db);
  assert.strictEqual(applied.delta, 1);
});

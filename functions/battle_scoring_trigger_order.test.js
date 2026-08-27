/**
 * C2 STAGE 2 — FINAL TRIGGER ORDERING REVIEW (read-only audit support).
 *
 * **Historical record — the bug this file diagnoses is now fixed.** This
 * ran against a hand-written mirror specifically because that earlier
 * review was read-only and forbidden from touching `battle_scoring.js`
 * at all. A later, explicitly-scoped follow-up fixed the underlying
 * conclusion self-heal gap directly in `battle_scoring.js` (see that
 * file's own doc comment on `scoreAnswer`), and `battle_scoring.test.js`
 * now covers every scenario here — and more — against the real,
 * unmodified production function via dependency injection, not a mirror.
 * This file's own mirror was deliberately never updated to reflect the
 * fix, so its "FINDING" test below still passes by correctly reproducing
 * the *old*, pre-fix behavior — it is retained as-is as a record of what
 * the bug looked like, not as current regression coverage. Treat
 * `battle_scoring.test.js` as authoritative for whether out-of-order
 * trigger completion is safe today.
 *
 * Stage 2 (`battle_abandonment_sweep.js`'s `bulkForfeitRemainingRounds`)
 * writes `answers/20` through `answers/39` as 20 separate, sequential
 * transactions, each committing within milliseconds of the last. Each of
 * those documents independently triggers `battle_scoring.js`'s
 * `onBattleAnswerCreated` (`onDocumentCreated`) — 20 separate Cloud
 * Functions v2 invocations that Google does **not** guarantee complete in
 * creation order. In ordinary gameplay, rounds are seconds-to-minutes
 * apart, so an out-of-order completion is exceedingly unlikely to matter;
 * Stage 2's tight burst makes the window for it to matter far larger.
 *
 * This file traces `scoreAnswer`'s own conclusion logic against that
 * out-of-order possibility using a **line-for-line mirror**, since
 * `scoreAnswer` itself is not exported by `battle_scoring.js` (and this
 * audit is explicitly forbidden from adding an export or otherwise
 * touching that file). `mirrorScoreAnswer` below is checked against the
 * real function's exact source (read in full immediately before writing
 * this) field by field — it is not a simplification, it is the same
 * decision tree.
 *
 * `battle_scoring.js` is never imported, called, or modified by this file.
 */

const test = require("node:test");
const assert = require("node:assert");

const {FakeFirestore} = require("./test_helpers/fake_firestore");

const MAIN_PHASE_ROUNDS = 20; // battle_scoring.js's own constant
const TOTAL_ROUNDS = 40; // battle_scoring.js's own constant

const PLAYER_A = "uidA1234567890123456789012";
const PLAYER_B = "uidB1234567890123456789012";

function turnOrderFor(rounds) {
  return Array.from({length: rounds}, (_, i) => ({
    round: i,
    deckOwnerUid: i % 2 === 0 ? PLAYER_A : PLAYER_B,
    cardId: `card_${i}`,
  }));
}

/**
 * Mirrors `battle_scoring.js`'s `scoreAnswer`, scoped to what this audit
 * needs: an empty-text forfeit (always incorrect, exactly like a real
 * `scoreAnswer` treats `typedRomaji.length === 0`), so the
 * card-resolution/romaji-comparison half of the real function is
 * deliberately omitted — nothing here needs it, and every line that
 * *is* present matches the real function's control flow exactly,
 * including the specific scoping bug this audit is checking for: the
 * conclusion check only ever looks at `r = 0..round` (this invocation's
 * own round number), and the `round === TOTAL_ROUNDS - 1` branch is only
 * ever reachable from round 39's own invocation.
 */
async function mirrorScoreAnswer(matchId, round, dbInstance) {
  const matchRef = dbInstance.collection("battleMatches").doc(matchId);
  await dbInstance.runTransaction(async (transaction) => {
    const matchSnap = await transaction.get(matchRef);
    const match = matchSnap.data();
    if (!match) return;
    if (match.result) return; // already concluded — nothing left to score

    const scoredRounds = match.scoredRounds || {};
    if (scoredRounds[String(round)]) return; // already processed (retry)

    const turnEntry = (match.turnOrder || []).find((e) => e.round === round);
    if (!turnEntry) return;

    // A forfeit's text is always "" — always incorrect, unconditionally,
    // same as the real scoreAnswer's `typedRomaji.length > 0` check.
    const correct = false;

    const players = match.players || [];
    const deckOwner = turnEntry.deckOwnerUid;
    const answerer = players.find((p) => p !== deckOwner) || deckOwner;

    const officialScore = Object.assign({}, match.officialScore || {});
    if (correct) {
      officialScore[answerer] = (officialScore[answerer] || 0) + 1;
    }

    const newScoredRounds = Object.assign({}, scoredRounds, {
      [String(round)]: true,
    });

    const updates = {officialScore, scoredRounds: newScoredRounds};

    let allPriorRoundsProcessed = true;
    for (let r = 0; r <= round; r++) {
      if (!newScoredRounds[String(r)]) {
        allPriorRoundsProcessed = false;
        break;
      }
    }

    if (allPriorRoundsProcessed && round >= MAIN_PHASE_ROUNDS - 1) {
      const scores = players.map((p) => officialScore[p] || 0);
      if (scores.length === 2 && scores[0] !== scores[1]) {
        updates.result = scores[0] > scores[1] ? players[0] : players[1];
        updates.status = "finished";
      } else if (round === TOTAL_ROUNDS - 1) {
        updates.result = "draw";
        updates.status = "finished";
      }
    }

    // FakeTransaction only implements `.set()`, not `.update()` — the
    // same constraint every transaction in this codebase's test suite
    // already works within.
    transaction.set(matchRef, updates, {merge: true});
  });
}

function scoredRoundsThrough(n) {
  return Object.fromEntries(Array.from({length: n}, (_, i) => [String(i), true]));
}

/** Seeds a match exactly the way Stage 2 would have left it the instant
 * `bulkForfeitRemainingRounds` finishes: rounds 0-19 already genuinely
 * scored and tied, rounds 20-39's `answers/{round}` documents already
 * written (forfeited, `text: ""`), but **none of rounds 20-39 have had
 * their `onBattleAnswerCreated` trigger run yet** — that is the exact
 * gap this file is auditing. */
function seedPostStage2Writes(db, matchId, {tiedScore = 5} = {}) {
  db.seed(`battleMatches/${matchId}`, {
    players: [PLAYER_A, PLAYER_B],
    status: "active",
    currentRound: TOTAL_ROUNDS,
    turnOrder: turnOrderFor(TOTAL_ROUNDS),
    officialScore: {[PLAYER_A]: tiedScore, [PLAYER_B]: tiedScore},
    result: null,
    scoredRounds: scoredRoundsThrough(MAIN_PHASE_ROUNDS), // 0..19 already scored
  });
  for (let r = MAIN_PHASE_ROUNDS; r < TOTAL_ROUNDS; r++) {
    db.seed(`battleMatches/${matchId}/answers/${r}`, {
      byUid: r % 2 === 0 ? PLAYER_B : PLAYER_A,
      text: "",
      forfeitedBySweep: true,
    });
  }
}

async function scoreInOrder(matchId, order, db) {
  for (const round of order) {
    await mirrorScoreAnswer(matchId, round, db);
  }
}

// ---------------------------------------------------------------------
// 1/2/3. Out-of-order trigger completion for rounds 20-39
// ---------------------------------------------------------------------

test("triggers completing in creation order (20..39) conclude correctly — baseline", async () => {
  const db = new FakeFirestore();
  seedPostStage2Writes(db, "m1");
  await scoreInOrder("m1", Array.from({length: 20}, (_, i) => i + MAIN_PHASE_ROUNDS), db);

  const match = await db.collection("battleMatches").doc("m1").get();
  assert.strictEqual(match.data().status, "finished");
  assert.strictEqual(match.data().result, "draw");
  for (let r = 0; r < TOTAL_ROUNDS; r++) {
    assert.strictEqual(match.data().scoredRounds[String(r)], true);
  }
});

test("out-of-order but round 39 still processed last: converges correctly", async () => {
  // The exact scramble named in the review request: 25, 20, 24, 21, 23,
  // 22, 26..39. Round 39 happens to land last in this particular order,
  // so this is NOT yet the failure case — included because it was asked
  // for explicitly, and to show that *some* out-of-order arrivals are
  // harmless (contiguity only cares about completeness, not sequence).
  const db = new FakeFirestore();
  seedPostStage2Writes(db, "m1");
  const order = [25, 20, 24, 21, 23, 22, ...Array.from({length: 14}, (_, i) => i + 26)];
  assert.strictEqual(order.length, 20); // sanity: every round 20-39 present exactly once
  await scoreInOrder("m1", order, db);

  const match = await db.collection("battleMatches").doc("m1").get();
  assert.strictEqual(match.data().status, "finished");
  assert.strictEqual(match.data().result, "draw");
});

test("FINDING: round 39's trigger completing before full contiguity leaves the match stuck active forever", async () => {
  // The failure case the baseline above does not exercise: round 39 (the
  // ONLY round whose own invocation ever checks `round === TOTAL_ROUNDS
  // - 1`) completes FIRST, before rounds 20-38 have finished. No other
  // round's invocation ever re-checks round 39's condition — each one
  // only evaluates contiguity through its OWN round number — so once
  // this happens, nothing left to run will ever conclude the match.
  const db = new FakeFirestore();
  seedPostStage2Writes(db, "m1");
  const order = [
    TOTAL_ROUNDS - 1, // 39, first
    25, 20, 24, 21, 23, 22,
    ...Array.from({length: 13}, (_, i) => i + 26), // 26..38
  ];
  assert.strictEqual(order.length, 20);
  await scoreInOrder("m1", order, db);

  const match = await db.collection("battleMatches").doc("m1").get();

  // Every round genuinely was scored — no data was lost, and no round
  // was scored twice (scoredRounds is a plain flag map, not a counter,
  // so a double-write would not even be observable as a count here; the
  // officialScore assertion below is what actually rules out double
  // scoring).
  for (let r = 0; r < TOTAL_ROUNDS; r++) {
    assert.strictEqual(
        match.data().scoredRounds[String(r)], true,
        `round ${r} should be marked scored`,
    );
  }
  // No forfeit ever added a point — the score is exactly what it was
  // when Stage 2 started, for both players, not double-counted.
  assert.strictEqual(match.data().officialScore[PLAYER_A], 5);
  assert.strictEqual(match.data().officialScore[PLAYER_B], 5);

  // THE ACTUAL FINDING: despite every round being fully and correctly
  // scored, the match never reached a conclusion. This reproduces a real
  // gap in the existing, unmodified battle_scoring.js — not something
  // this test asserts should be fixed here, only that it demonstrably
  // happens.
  assert.strictEqual(match.data().status, "active");
  assert.strictEqual(match.data().result, null);
});

// ---------------------------------------------------------------------
// 4. Duplicate trigger delivery for several rounds, interspersed
// ---------------------------------------------------------------------

test("duplicate trigger delivery for several rounds does not double-score or double-conclude", async () => {
  const db = new FakeFirestore();
  seedPostStage2Writes(db, "m1");
  const order = [
    20, 21, 22, 22, 23, 24, 25, 25, 26, 27, 28, 29, 30, 30, 31, 32, 33, 34,
    35, 36, 37, 38, 39, 39,
  ];
  await scoreInOrder("m1", order, db);

  const match = await db.collection("battleMatches").doc("m1").get();
  assert.strictEqual(match.data().status, "finished");
  assert.strictEqual(match.data().result, "draw");
  // Redelivery must be a genuine no-op — the score is still exactly the
  // pre-Stage-2 tied value, not incremented by any repeated call.
  assert.strictEqual(match.data().officialScore[PLAYER_A], 5);
  assert.strictEqual(match.data().officialScore[PLAYER_B], 5);
});

test("duplicate trigger for round 39 specifically, arriving early and then again: still gets stuck (same finding, not a separate bug)", async () => {
  // Confirms the round-39-early finding is not somehow masked or fixed
  // by Cloud Functions' at-least-once redelivery — redelivering round
  // 39's trigger again later does not help, because the SECOND call for
  // round 39 hits `scoredRounds[39]` already true and returns
  // immediately (the idempotency guard), it does not re-run the
  // contiguity check either.
  const db = new FakeFirestore();
  seedPostStage2Writes(db, "m1");
  await mirrorScoreAnswer("m1", TOTAL_ROUNDS - 1, db); // 39 first
  await mirrorScoreAnswer("m1", TOTAL_ROUNDS - 1, db); // redelivered
  await scoreInOrder("m1", [20, 21, 22, 23, 24, 25, 26, 27, 28, 29,
    30, 31, 32, 33, 34, 35, 36, 37, 38], db); // everything else, in order

  const match = await db.collection("battleMatches").doc("m1").get();
  for (let r = 0; r < TOTAL_ROUNDS; r++) {
    assert.strictEqual(match.data().scoredRounds[String(r)], true);
  }
  assert.strictEqual(match.data().status, "active"); // still stuck
  assert.strictEqual(match.data().result, null);
});

// ---------------------------------------------------------------------
// 6. Explicit "all 40 answers exist, is the match ever left active" check
// ---------------------------------------------------------------------

test("every ordering that processes round 39 last concludes; every ordering that processes it before full contiguity does not", async () => {
  const orderings = {
    ascending: Array.from({length: 20}, (_, i) => i + MAIN_PHASE_ROUNDS),
    // Reversed *except* 39, which is moved to the end — every ordering
    // that happens to leave round 39 for last, however scrambled
    // otherwise, converges correctly. (A literal `TOTAL_ROUNDS-1-i`
    // descending sweep puts 39 *first*, which is the failing case
    // already covered by its own dedicated test above, not this one.)
    reversedButLast: [
      ...Array.from({length: 19}, (_, i) => TOTAL_ROUNDS - 2 - i),
      TOTAL_ROUNDS - 1,
    ],
    reviewScramble: [25, 20, 24, 21, 23, 22, ...Array.from({length: 14}, (_, i) => i + 26)],
  };
  for (const [name, order] of Object.entries(orderings)) {
    const db = new FakeFirestore();
    seedPostStage2Writes(db, "m1");
    await scoreInOrder("m1", order, db);
    const match = await db.collection("battleMatches").doc("m1").get();
    assert.strictEqual(
        match.data().status, "finished",
        `ordering "${name}" (round 39 processed last) should conclude`,
    );
  }

  // The one ordering that does NOT conclude: round 39 anywhere but last.
  const db = new FakeFirestore();
  seedPostStage2Writes(db, "m1");
  await scoreInOrder(
      "m1",
      [TOTAL_ROUNDS - 1, ...Array.from({length: 19}, (_, i) => i + MAIN_PHASE_ROUNDS)],
      db,
  );
  const stuck = await db.collection("battleMatches").doc("m1").get();
  assert.strictEqual(stuck.data().status, "active");
});

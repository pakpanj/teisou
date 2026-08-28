/**
 * Coverage for the rank-skip exam's decisions — which cards a tier is
 * examined on, what counts as a right answer, and which tiers a player
 * may aim at — plus, below (Rank-Skip Fix Phase, 2026-08-29), permanent
 * coverage for `startRankSkipExamFor`/`submitRankSkipExamFor` themselves:
 * the TOCTOU/cooldown race (BUG #1) and the submit/promotion atomicity
 * gap (BUG #2) found by the 2026-08-29 audit and fixed the same day.
 *
 * The ladder arithmetic `promoteToTierFloor` itself stands on already
 * has its own coverage in battle_stars.test.js and is not re-tested
 * here — the tests below inject a controllable stand-in for it
 * (`options.promoteToTierFloor`) specifically so they can prove how
 * `rank_skip.js` REACTS to a promotion succeeding/failing, without
 * needing `battle_stars.js`'s own transaction machinery at all.
 *
 * Run from functions/: `node --test`
 */

const {test} = require("node:test");
const assert = require("node:assert/strict");

const kanaData = require("./data/kana_data.json");
const {resolveCorrectRomaji} = require("./battle_scoring")._internal;
const {FakeFirestore} = require("./test_helpers/fake_firestore");
const {
  QUESTIONS,
  PASS_MARK,
  COOLDOWN_HOURS,
  SKIPPABLE,
  poolFor,
  sample,
  isCorrect,
  tiersAbove,
  startRankSkipExamFor,
  submitRankSkipExamFor,
} = require("./rank_skip")._internal;

test("every tier is examined on cards the grader can actually score", () => {
  // The failure this catches is silent and total: a pool holding ids
  // resolveCorrectRomaji returns null for would mark every answer
  // wrong, and the player would fail an exam nobody could pass.
  for (const tier of SKIPPABLE) {
    const pool = poolFor(tier);
    assert.ok(pool.length >= QUESTIONS,
        `${tier} has only ${pool.length} cards, needs ${QUESTIONS}`);
    for (const id of pool) {
      assert.ok(resolveCorrectRomaji(id), `${tier}: ${id} does not resolve`);
    }
  }
});

test("the pools match the tiers the app plays those cards at", () => {
  // Mirrors `_poolFor` in battle_deck_builder.dart. Two copies of this
  // mapping exist because the server cannot import Dart; this is the
  // check that keeps them the same, so examining a tier on cards it
  // never deals fails here rather than confusing a player.
  const silver = new Set(poolFor("silver"));
  const bronzeKana = kanaData
      .filter((k) => k.type === "hiragana" && (k.row || 0) <= 10)
      .map((k) => k.id);

  assert.ok(bronzeKana.length > 0);
  for (const id of bronzeKana) {
    assert.ok(!silver.has(id),
        `${id} is Bronze's own hiragana and must not be in Silver's exam`);
  }
  for (const id of silver) {
    const kana = kanaData.find((k) => k.id === id);
    assert.ok(kana, `${id} is not kana at all`);
    assert.ok(kana.type === "katakana" || (kana.row || 0) > 10);
  }

  // Gold and up are kanji words, which are the ids carrying a "|".
  for (const tier of ["gold", "diamond", "emerald"]) {
    for (const id of poolFor(tier)) {
      assert.ok(id.includes("|"), `${tier}: ${id} is not a kanji word card`);
    }
  }
});

test("kanji tiers are answered in hiragana, the way their battles are", () => {
  // Gold and up use KanaKeyboard in a match (`answersWithKanaKeyboard`).
  // An exam that accepted romaji there would be an easier test than the
  // tier it admits you to.
  for (const tier of ["gold", "diamond", "emerald"]) {
    const id = poolFor(tier)[0];
    assert.strictEqual(resolveCorrectRomaji(id).answerInHiragana, true);
  }
  const silverId = poolFor("silver")[0];
  assert.strictEqual(resolveCorrectRomaji(silverId).answerInHiragana, false);
});

test("an answer is marked by the same rule a match uses", () => {
  const kana = kanaData.find((k) => k.type === "katakana" && k.romaji === "a");
  assert.ok(kana, "expected a katakana card reading 'a'");

  assert.ok(isCorrect(kana.id, kana.romaji));
  assert.ok(isCorrect(kana.id, ` ${kana.romaji.toUpperCase()} `),
      "case and surrounding space must not decide a rank");
  assert.ok(!isCorrect(kana.id, "zzz"));
  assert.ok(!isCorrect(kana.id, ""));
  assert.ok(!isCorrect(kana.id, null), "an unanswered card is not correct");
  assert.ok(!isCorrect("no_such_card", "a"));
});

test("only tiers above the one held can be aimed at", () => {
  // Both halves matter. Skipping down would erase a climb; re-taking
  // the tier already held would spend a cooldown on nothing.
  assert.deepStrictEqual(tiersAbove("bronze"),
      ["silver", "gold", "diamond", "emerald"]);
  assert.deepStrictEqual(tiersAbove("gold"), ["diamond", "emerald"]);
  assert.deepStrictEqual(tiersAbove("emerald"), []);
  assert.ok(!tiersAbove("silver").includes("silver"));
  assert.ok(!tiersAbove("silver").includes("bronze"));
});

test("the pass mark is reachable and not a formality", () => {
  assert.ok(PASS_MARK <= QUESTIONS);
  assert.ok(PASS_MARK / QUESTIONS >= 0.8,
      "a mark a lucky run could reach would make the ladder pointless");
});

test("a drawn exam has no repeats", () => {
  // Twenty questions, one of them asked three times, is a seventeen
  // question exam — and an easier one, since a card seen once is a card
  // already worked out.
  const drawn = sample(poolFor("gold"), QUESTIONS);
  assert.strictEqual(drawn.length, QUESTIONS);
  assert.strictEqual(new Set(drawn).size, QUESTIONS);
});

// ---------------------------------------------------------------------
// Rank-Skip Fix Phase (2026-08-29) — startRankSkipExamFor/
// submitRankSkipExamFor, BUG #1 (TOCTOU/cooldown race) and BUG #2
// (submit/promotion atomicity), plus the ordinary paths around them.
// ---------------------------------------------------------------------

const UID = "player-uid";
const EXAM_PATH = `rankSkipExams/${UID}`;

function seedBronzeUser(fake, uid = UID) {
  fake.seed(`users/${uid}`, {cardGameRank: {tier: "bronze"}});
}

function correctAnswersFor(cardIds) {
  return cardIds.map((id) => resolveCorrectRomaji(id).correctRomaji);
}

function wrongAnswersFor(cardIds) {
  return cardIds.map(() => "definitely-wrong");
}

/** A controllable stand-in for `battleStars.promoteToTierFloor` — never
 * touches real Firestore or `battle_stars.js` at all, since these tests
 * are about how `rank_skip.js` reacts to that call succeeding/failing,
 * not about the ladder arithmetic inside it (already covered by
 * `battle_stars.test.js`). `outcomes` is consumed one entry per call —
 * a `throw` for a simulated transient failure, or a `{changed}` result
 * for a simulated success — and every call is recorded in `.calls` for
 * assertions on how many times, and with what arguments, it was
 * invoked. */
function fakePromote(outcomes) {
  const calls = [];
  const queue = outcomes.slice();
  const fn = async (uid, tier) => {
    calls.push({uid, tier});
    const next = queue.length > 1 ? queue.shift() : queue[0];
    if (next instanceof Error) throw next;
    return next;
  };
  fn.calls = calls;
  return fn;
}

test("(1) an ordinary successful exam: passes, promotes, and clears "
    + "the session", async () => {
  const fake = new FakeFirestore();
  seedBronzeUser(fake);

  const started = await startRankSkipExamFor(UID, "silver", {firestore: fake});
  assert.strictEqual(started.cardIds.length, QUESTIONS);

  const promote = fakePromote([{changed: true}]);
  const result = await submitRankSkipExamFor(
      UID, started.sessionId, correctAnswersFor(started.cardIds),
      {firestore: fake, promoteToTierFloor: promote},
  );

  assert.strictEqual(result.passed, true);
  assert.strictEqual(result.promoted, true);
  assert.strictEqual(result.correct, QUESTIONS);
  assert.strictEqual(result.targetTier, "silver");
  assert.strictEqual(result.lockedUntil, null);
  assert.deepStrictEqual(promote.calls, [{uid: UID, tier: "silver"}]);

  const finalDoc = (await fake.collection("rankSkipExams").doc(UID).get()).data();
  assert.strictEqual(finalDoc.session, undefined,
      "the session must be cleared once promotion has actually committed");
});

test("(2) an ordinary failed exam: fails, sets the 24h cooldown, and a "
    + "sequential retry is correctly rejected", async () => {
  const fake = new FakeFirestore();
  seedBronzeUser(fake);

  const started = await startRankSkipExamFor(UID, "silver", {firestore: fake});
  const promote = fakePromote([{changed: true}]); // must never be called

  const before = Date.now();
  const result = await submitRankSkipExamFor(
      UID, started.sessionId, wrongAnswersFor(started.cardIds),
      {firestore: fake, promoteToTierFloor: promote},
  );

  assert.strictEqual(result.passed, false);
  assert.strictEqual(result.promoted, false);
  assert.strictEqual(promote.calls.length, 0,
      "a failed exam must never attempt a promotion");
  assert.ok(result.lockedUntil, "a failed exam must report a lockedUntil");
  const lockedMs = new Date(result.lockedUntil).getTime();
  assert.ok(
      lockedMs >= before + COOLDOWN_HOURS * 60 * 60 * 1000 - 1000 &&
      lockedMs <= Date.now() + COOLDOWN_HOURS * 60 * 60 * 1000 + 1000,
      "lockedUntil must be roughly COOLDOWN_HOURS from now",
  );

  const finalDoc = (await fake.collection("rankSkipExams").doc(UID).get()).data();
  assert.strictEqual(finalDoc.session, undefined);
  assert.ok(finalDoc.lockedUntil, "the cooldown must actually be stored");

  await assert.rejects(
      () => startRankSkipExamFor(UID, "silver", {firestore: fake}),
      (err) => err.code === "resource-exhausted",
      "a genuinely sequential start-after-fail must stay rejected — " +
      "confirms the cooldown mechanism itself still works",
  );
});

test("(3, BUG #1 fix) a start racing a failing submit on the SAME uid "
    + "never leaves a fresh exam coexisting with a freshly-established "
    + "cooldown", async () => {
  const fake = new FakeFirestore({
    beforeCommit: async (transaction) => {
      // Only armed once the setup call below has already committed —
      // otherwise THAT call (also a start-transaction, also matching
      // the predicate below) would be the one paused instead of the
      // race's own second call.
      if (!fake._armed) return;
      // Target START's own commit specifically (identifiable by its
      // write carrying a `session` but never touching `lockedUntil` —
      // submit's fail-write always carries both), regardless of which
      // of the two calls happens to reach `beforeCommit` first — a
      // deterministic target beats relying on incidental scheduling
      // order between two structurally different async call chains.
      const write = transaction._writes.get(EXAM_PATH);
      const isStartWrite = write && write.data && write.data.session &&
          !("lockedUntil" in write.data);
      if (isStartWrite && !fake._startPaused) {
        fake._startPaused = true;
        await new Promise((resolve) => {
          fake._releaseStart = resolve;
        });
      }
    },
  });
  seedBronzeUser(fake);

  const started = await startRankSkipExamFor(UID, "silver", {firestore: fake});
  fake._armed = true;
  const promote = fakePromote([{changed: true}]);

  // Race a SECOND startRankSkipExamFor (paused mid-commit by the hook
  // above) against submitRankSkipExamFor's failing submission of the
  // FIRST exam — both read the pre-fail, unlocked state; submit is free
  // to commit its failure while start sits paused; start is then
  // released and must retry against submit's already-committed result.
  const raceStart = startRankSkipExamFor(UID, "silver", {firestore: fake});
  // Let the race's own transaction reach the paused commit point.
  await new Promise((resolve) => setTimeout(resolve, 10));

  const submitResult = await submitRankSkipExamFor(
      UID, started.sessionId, wrongAnswersFor(started.cardIds),
      {firestore: fake, promoteToTierFloor: promote},
  );
  assert.strictEqual(submitResult.passed, false);

  fake._releaseStart();
  await assert.rejects(
      () => raceStart,
      (err) => err.code === "resource-exhausted",
      "BUG (would fail without the fix): the racing start must observe " +
      "the fresh cooldown submit just committed and correctly refuse " +
      "to start — not silently overwrite it with a fresh, unlocked " +
      "session",
  );

  const finalDoc = (await fake.collection("rankSkipExams").doc(UID).get()).data();
  assert.ok(
      finalDoc.lockedUntil,
      "BUG (would fail without the fix): lockedUntil must still be set " +
      "after the race — this is the exact field the old implementation " +
      "silently wiped back to null",
  );
  assert.strictEqual(
      finalDoc.session, undefined,
      "no fresh exam may survive together with a newly established " +
      "cooldown — the racing start must not have left a live session " +
      "behind despite being refused",
  );
});

test("(3b, control) two genuinely different users racing on their own "
    + "exams never interfere with each other", async () => {
  const fake = new FakeFirestore();
  seedBronzeUser(fake, "uid-a");
  seedBronzeUser(fake, "uid-b");

  const [a, b] = await Promise.all([
    startRankSkipExamFor("uid-a", "silver", {firestore: fake}),
    startRankSkipExamFor("uid-b", "silver", {firestore: fake}),
  ]);
  assert.strictEqual(a.cardIds.length, QUESTIONS);
  assert.strictEqual(b.cardIds.length, QUESTIONS);
  assert.notStrictEqual(a.sessionId, b.sessionId);
});

test("(4, BUG #2 fix) a promotion failure after a genuine PASS keeps "
    + "the session retryable — the attempt is not silently destroyed",
async () => {
  const fake = new FakeFirestore();
  seedBronzeUser(fake);

  const started = await startRankSkipExamFor(UID, "silver", {firestore: fake});
  const answers = correctAnswersFor(started.cardIds);
  const failingPromote = fakePromote([
    new Error("simulated transient Firestore failure"),
  ]);

  await assert.rejects(
      () => submitRankSkipExamFor(UID, started.sessionId, answers,
          {firestore: fake, promoteToTierFloor: failingPromote}),
      /simulated transient Firestore failure/,
  );

  const afterFailure =
      (await fake.collection("rankSkipExams").doc(UID).get()).data();
  assert.notStrictEqual(
      afterFailure.session, undefined,
      "BUG (would fail without the fix): the session must survive a " +
      "promotion failure — deleting it beforehand would strand a " +
      "genuinely passed attempt with no way to retry it",
  );
  assert.strictEqual(afterFailure.session.sessionId, started.sessionId);
});

test("(5) retrying after a transient promotion failure succeeds and "
    + "does not double-promote", async () => {
  const fake = new FakeFirestore();
  seedBronzeUser(fake);

  const started = await startRankSkipExamFor(UID, "silver", {firestore: fake});
  const answers = correctAnswersFor(started.cardIds);
  const promote = fakePromote([
    new Error("simulated transient Firestore failure"),
    {changed: true},
  ]);

  await assert.rejects(
      () => submitRankSkipExamFor(UID, started.sessionId, answers,
          {firestore: fake, promoteToTierFloor: promote}),
  );
  const retryResult = await submitRankSkipExamFor(
      UID, started.sessionId, answers,
      {firestore: fake, promoteToTierFloor: promote},
  );

  assert.strictEqual(retryResult.passed, true);
  assert.strictEqual(retryResult.promoted, true);
  assert.strictEqual(promote.calls.length, 2,
      "exactly one failing call and one successful retry");
  assert.deepStrictEqual(promote.calls[0], promote.calls[1],
      "both calls must target the same (uid, tier) — a real retry of " +
      "the same attempt, not a different one");

  const finalDoc = (await fake.collection("rankSkipExams").doc(UID).get()).data();
  assert.strictEqual(finalDoc.session, undefined,
      "the session is finalized only once the retry actually succeeds");
});

test("(6) concurrent submissions of the SAME passing session converge "
    + "safely — no crash, no inconsistent final state", async () => {
  const fake = new FakeFirestore();
  seedBronzeUser(fake);

  const started = await startRankSkipExamFor(UID, "silver", {firestore: fake});
  const answers = correctAnswersFor(started.cardIds);
  const promote = fakePromote([{changed: true}]);

  const [r1, r2] = await Promise.all([
    submitRankSkipExamFor(UID, started.sessionId, answers,
        {firestore: fake, promoteToTierFloor: promote}),
    submitRankSkipExamFor(UID, started.sessionId, answers,
        {firestore: fake, promoteToTierFloor: promote}),
  ]);

  assert.strictEqual(r1.passed, true);
  assert.strictEqual(r2.passed, true);
  assert.ok(promote.calls.length >= 1,
      "at least one concurrent call must reach promotion");

  const finalDoc = (await fake.collection("rankSkipExams").doc(UID).get()).data();
  assert.strictEqual(finalDoc.session, undefined,
      "the session must end up cleared, not left in a half-finalized " +
      "state by two racing finalize attempts");
});

test("(7) the target tier at promotion time always comes from the "
    + "server-stored session, never a client-supplied value", async () => {
  const fake = new FakeFirestore();
  seedBronzeUser(fake);

  const started = await startRankSkipExamFor(UID, "silver", {firestore: fake});
  // submitRankSkipExamFor's own signature has no tier parameter at
  // all — there is no argument position a modified client could use to
  // claim a different tier at submit time. This test pins that
  // contract: only (uid, sessionId, answers, options) exist (`.length`
  // is 3, not 4 — `options`'s default value excludes it from the count,
  // a plain JS quirk, not a fourth meaningful position).
  assert.strictEqual(submitRankSkipExamFor.length, 3);

  const promote = fakePromote([{changed: true}]);
  await submitRankSkipExamFor(
      UID, started.sessionId, correctAnswersFor(started.cardIds),
      {firestore: fake, promoteToTierFloor: promote},
  );
  assert.strictEqual(promote.calls[0].tier, "silver",
      "promotion must use the tier startRankSkipExamFor itself stored");
});

test("(8) authorization/eligibility invariants still hold through the "
    + "DI seam", async () => {
  const fake = new FakeFirestore();
  seedBronzeUser(fake);

  await assert.rejects(
      () => startRankSkipExamFor(UID, "not-a-real-tier", {firestore: fake}),
      (err) => err.code === "invalid-argument",
  );
  await assert.rejects(
      () => startRankSkipExamFor(UID, "bronze", {firestore: fake}),
      (err) => err.code === "invalid-argument",
      "bronze is not a skippable target at all",
  );

  fake.seed(`users/${UID}`, {cardGameRank: {tier: "gold"}});
  await assert.rejects(
      () => startRankSkipExamFor(UID, "silver", {firestore: fake}),
      (err) => err.code === "failed-precondition",
      "cannot aim at a tier at or below the one already held",
  );

  await assert.rejects(
      () => submitRankSkipExamFor(UID, "no-such-session", ["a"],
          {firestore: fake}),
      (err) => err.code === "failed-precondition",
      "an unknown/forged sessionId must be refused",
  );
});

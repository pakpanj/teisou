const {test} = require("node:test");
const assert = require("node:assert/strict");

const {FakeFirestore} = require("./test_helpers/fake_firestore");
const {
  awardPointsForHistoryDoc,
  handleHistoryDocCreated,
  isRetryableError,
} = require("./global_points");
const {backfillUser} = require("./backfill_global_points");

/**
 * Reliability/idempotency proof, following the explicit review request:
 * these tests exercise the REAL transaction-shaped code paths
 * (`awardPointsForHistoryDoc`/`handleHistoryDocCreated`/`backfillUser`)
 * against `FakeFirestore` — a Firestore double with genuine optimistic-
 * concurrency conflict detection, not a simplification down to pure-
 * function calls. See `test_helpers/fake_firestore.js`'s own doc comment
 * for exactly what this does and does not prove.
 */

const uid = "uReliability";

// Real kana ids/romaji (mirrors `functions/data/kana_data.json`) — 9
// correctly-answered + 1 wrong, so `gradeAttempt("kana", ...)` derives
// `serverScore: 9, serverTotal: 10` independently of the (now purely
// display-only) `score`/`total` fields alongside it. See
// `exam_grading.js`/the Exam-History Authority fix in
// `TEISOU_ROADMAP_MASTER.md` for why grading is now answers-derived,
// not trusted from `score`/`total` directly.
const kanaAnswers = [
  {contentId: "hiragana_a", submittedText: "a"},
  {contentId: "hiragana_i", submittedText: "i"},
  {contentId: "hiragana_u", submittedText: "u"},
  {contentId: "hiragana_e", submittedText: "e"},
  {contentId: "hiragana_o", submittedText: "o"},
  {contentId: "hiragana_ka", submittedText: "ka"},
  {contentId: "hiragana_ki", submittedText: "ki"},
  {contentId: "hiragana_ku", submittedText: "ku"},
  {contentId: "hiragana_ke", submittedText: "ke"},
  {contentId: "hiragana_ko", submittedText: "wrong"}, // 9 correct, 1 wrong
];
const kanaDoc = {
  type: "hiragana", score: 9, total: 10, completedAt: 0,
  answers: kanaAnswers,
};

async function leaderboardPoints(fake, forUid) {
  const snap = await fake.collection("leaderboard").doc(forUid).get();
  return snap.exists ? (snap.data().globalPoints || 0) : 0;
}

async function markerExists(fake, forUid, historyDocId) {
  const snap = await fake
    .collection("globalPointsState").doc(forUid)
    .collection("pointsAwarded").doc(historyDocId)
    .get();
  return snap.exists;
}

// 1. History yang sama diproses dua kali -> 1 award.
test("1. the same historyDocId processed twice through the real "
    + "transaction yields exactly one award, not a pure-function stand-in",
    async () => {
  const fake = new FakeFirestore();

  const first = await awardPointsForHistoryDoc(uid, "kana", "h1", kanaDoc, {firestore: fake});
  const second = await awardPointsForHistoryDoc(uid, "kana", "h1", kanaDoc, {firestore: fake});

  assert.equal(first.awarded, true);
  assert.equal(first.points, 90);
  assert.equal(second.awarded, false);
  assert.equal(second.points, 0);
  assert.equal(await leaderboardPoints(fake, uid), 90);
});

// 2. Live trigger + backfill concurrency model -> 1 award.
test("2. a live trigger and a backfill run racing on the same "
    + "historyDocId, via genuine Node event-loop interleaving on shared "
    + "state (not two independent invocations checked separately), "
    + "converge to exactly one award", async () => {
  const fake = new FakeFirestore();
  // backfillUser discovers records by reading the exam-history
  // collection itself, unlike awardPointsForHistoryDoc which is handed
  // docData directly — seed the doc so backfillUser's own fetch sees it.
  fake.seed(`users/${uid}/examHistory/h1`, kanaDoc);

  const live = handleHistoryDocCreated("kana", uid, "h1", kanaDoc, "evt-live", {firestore: fake});
  const backfill = backfillUser(uid, 1000, {firestore: fake});

  const [liveResult, backfillResult] = await Promise.all([live, backfill]);

  // Whichever actually reached Firestore first wins the award; the
  // other must observe the marker and award nothing — never both.
  const awardedCount =
    (liveResult.awarded ? 1 : 0) + (backfillResult.attemptsAwarded);
  assert.equal(awardedCount, 1, "exactly one of the two paths must have awarded");
  assert.equal(await leaderboardPoints(fake, uid), 90);
  assert.equal(await markerExists(fake, uid, "h1"), true);
});

// 3. Marker sudah ada -> tidak ada increment.
test("3. a pre-existing marker (seeded, not written by this test) "
    + "blocks any increment at all", async () => {
  const fake = new FakeFirestore();
  fake.seed(
    `globalPointsState/${uid}/pointsAwarded/h1`,
    {awarded: true, points: 999, moduleType: "kana", source: "live"},
  );

  const result = await awardPointsForHistoryDoc(uid, "kana", "h1", kanaDoc, {firestore: fake});

  assert.equal(result.awarded, false);
  assert.equal(await leaderboardPoints(fake, uid), 0, "no leaderboard doc should be created at all");
});

// 4. Transaction error -> invocation gagal/retryable.
test("4. a genuine transaction-level fault propagates as a real "
    + "rejection, and is classified retryable/non-retryable by its "
    + "error code exactly as isRetryableError defines", async () => {
  const transient = new Error("simulated UNAVAILABLE");
  transient.code = 14; // UNAVAILABLE — in RETRYABLE_GRPC_CODES
  assert.equal(isRetryableError(transient), true);

  const permanent = new Error("simulated INVALID_ARGUMENT");
  permanent.code = 3; // not in RETRYABLE_GRPC_CODES
  assert.equal(isRetryableError(permanent), false);

  const fakeTransient = new FakeFirestore({faultInjector: () => transient});
  await assert.rejects(
    () => awardPointsForHistoryDoc(uid, "kana", "h1", kanaDoc, {firestore: fakeTransient}),
    (error) => error === transient,
  );

  // handleHistoryDocCreated must rethrow (reject) for a retryable
  // failure — that rejection is precisely the signal Eventarc's
  // `retry: true` registration needs in order to redeliver the event.
  const fakeForHandler = new FakeFirestore({faultInjector: () => transient});
  await assert.rejects(
    () => handleHistoryDocCreated("kana", uid, "h1", kanaDoc, "evt1", {firestore: fakeForHandler}),
  );

  // A non-retryable failure must NOT reject handleHistoryDocCreated —
  // it is swallowed on purpose (see global_points.js's own reasoning:
  // retrying a permanent bug for a full day cannot ever succeed).
  const fakePermanent = new FakeFirestore({faultInjector: () => permanent});
  const swallowed = await handleHistoryDocCreated(
    "kana", uid, "h1", kanaDoc, "evt2", {firestore: fakePermanent},
  );
  assert.equal(swallowed.awarded, false);
});

// 5. Retry setelah failure -> eventual 1 award.
test("5. the first delivery fails transiently, a simulated platform "
    + "redelivery (a second, independent call — exactly what Eventarc's "
    + "retry does) then succeeds, and the net result is exactly one "
    + "award, not zero and not two", async () => {
  const transient = new Error("simulated ABORTED on first delivery only");
  transient.code = 10;

  const fake = new FakeFirestore({
    // Only the very first top-level runTransaction call ever made on
    // this instance fails — every call after that (the "redelivery")
    // proceeds normally.
    faultInjector: (callNumber) => (callNumber === 1 ? transient : null),
  });

  await assert.rejects(
    () => handleHistoryDocCreated("kana", uid, "h1", kanaDoc, "evt1", {firestore: fake}),
  );
  // Nothing committed on the failed first delivery — Firestore
  // transactions are all-or-nothing, so a thrown transaction is
  // guaranteed to have written nothing.
  assert.equal(await leaderboardPoints(fake, uid), 0);
  assert.equal(await markerExists(fake, uid, "h1"), false);

  // Simulated redelivery: same event, called again.
  const redelivered = await handleHistoryDocCreated(
    "kana", uid, "h1", kanaDoc, "evt1", {firestore: fake},
  );
  assert.equal(redelivered.awarded, true);
  assert.equal(await leaderboardPoints(fake, uid), 90, "exactly one award's worth, not zero, not doubled");
});

// 6. Backfill tetap bisa dipanggil ulang tanpa menggandakan poin.
test("6. calling backfillUser twice for the same user/window never "
    + "doubles the total — the second run finds every marker already "
    + "set and awards nothing new", async () => {
  const fake = new FakeFirestore();
  fake.seed(`users/${uid}/examHistory/h1`, kanaDoc);
  fake.seed(`users/${uid}/dokkaiExamHistory/d1`, {
    itemId: "sess1", jlptLevel: "N4", score: 45, total: 50, completedAt: 500,
    // One genuinely-correct real answer is enough here — this test only
    // asserts `attemptsAwarded`/`totalPoints > 0`, not an exact figure.
    answers: [
      {
        contentId: "dokkai_surat_sahabat_pena|dokkai_surat_sahabat_pena_q0",
        submittedText: "アメリカ",
      },
    ],
  });

  const first = await backfillUser(uid, 1000, {firestore: fake});
  assert.equal(first.attemptsAwarded, 2);
  const totalAfterFirst = await leaderboardPoints(fake, uid);
  assert.ok(totalAfterFirst > 0);

  const second = await backfillUser(uid, 1000, {firestore: fake});
  assert.equal(second.attemptsAwarded, 0);
  assert.equal(second.totalPoints, 0);
  assert.equal(
    await leaderboardPoints(fake, uid),
    totalAfterFirst,
    "re-running backfill must not change the already-awarded total at all",
  );
});

// 7. Repeat cycle tetap benar, melalui jalur transaksi nyata (bukan
// hanya decideAward murni).
test("7. the repeat cycle still decays correctly end-to-end through "
    + "the real per-record transaction path — two different "
    + "historyDocIds on the same repeatKey, processed via "
    + "awardPointsForHistoryDoc directly", async () => {
  const fake = new FakeFirestore();

  const attempt1 = await awardPointsForHistoryDoc(uid, "kana", "h1", kanaDoc, {firestore: fake});
  const attempt2 = await awardPointsForHistoryDoc(
    uid, "kana", "h2",
    {...kanaDoc, completedAt: 24 * 60 * 60 * 1000}, // one day later, same repeatKey (kana:hiragana)
    {firestore: fake},
  );

  assert.equal(attempt1.points, 90); // n=1
  assert.equal(Math.abs(attempt2.points - 54) < 0.001, true); // n=2, 90*0.6
  assert.equal(await leaderboardPoints(fake, uid), 144);

  const cycleSnap = await fake
    .collection("globalPointsState").doc(uid)
    .collection("repeatCycles").doc("kana:hiragana")
    .get();
  assert.equal(cycleSnap.data().attemptCountInCycle, 2);
});

// Deterministic proof of the retry-on-conflict mechanism itself, forced
// via FakeFirestore's `beforeCommit` pause hook rather than hoping
// Node's own scheduling happens to interleave two calls usefully.
test("a genuine mid-transaction conflict (not just 'ran later and saw "
    + "the marker') forces Firestore's own abort-and-retry, and still "
    + "converges to exactly one award", async () => {
  let releaseA;
  const gate = new Promise((resolve) => {
    releaseA = resolve;
  });
  let notifyPaused;
  const reachedPause = new Promise((resolve) => {
    notifyPaused = resolve;
  });
  let pausedOnce = false;

  const fake = new FakeFirestore({
    beforeCommit: async () => {
      if (!pausedOnce) {
        pausedOnce = true;
        notifyPaused();
        await gate;
      }
    },
  });

  // Transaction A reads the (nonexistent) marker/cycle, computes its
  // award, then pauses right before its conflict check/commit.
  const txA = awardPointsForHistoryDoc(uid, "kana", "h1", kanaDoc, {firestore: fake});
  await reachedPause;

  // Transaction B runs to full, uninterrupted completion while A is
  // paused — it sees no marker, awards, and commits.
  const txB = await awardPointsForHistoryDoc(uid, "kana", "h1", kanaDoc, {firestore: fake});
  assert.equal(txB.awarded, true);

  // Release A: it resumes, its conflict check now finds the marker/
  // cycle it read have changed version since — Firestore's own
  // documented behavior is to abort and re-run the transaction
  // function fresh, which this time reads the marker as existing and
  // awards nothing.
  releaseA();
  const txAResult = await txA;
  assert.equal(txAResult.awarded, false);

  assert.equal(await leaderboardPoints(fake, uid), 90, "still exactly one award despite the forced conflict");
});

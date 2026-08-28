// Permanent regression coverage for the Exam-History Authority fix (see
// TEISOU_ROADMAP_MASTER.md's P0 audit + design + implementation
// sections). Exercises the REAL server-trigger logic
// (awardPointsForHistoryDoc, the same function globalPointsTriggerFor
// invokes in production) against FakeFirestore, proving the former P0
// exploit — a client-controlled `score`/`total` on a directly-written
// exam-history document — no longer has any path into Global Points or
// the Weekly Global Ranking payout.
//
// This file is the permanent replacement for the now-removed temporary
// `_audit_exam_history_authority.test.js` — same scenario letters (A-G)
// kept for traceability against that earlier audit, but every assertion
// below proves the FIXED (safe) behaviour, not the vulnerable one.
"use strict";

const {test} = require("node:test");
const assert = require("node:assert/strict");

const {FakeFirestore} = require("./test_helpers/fake_firestore");
const {awardPointsForHistoryDoc} = require("./global_points");
const {wibWeekId} = require("./wib_week");

async function leaderboardPoints(fake, uid) {
  const snap = await fake.collection("leaderboard").doc(uid).get();
  return snap.exists ? (snap.data().globalPoints || 0) : 0;
}

async function periodPoints(fake, periodId, uid) {
  const snap = await fake
      .collection("globalScorePeriods").doc(periodId)
      .collection("users").doc(uid).get();
  return snap.exists ? (snap.data().points || 0) : 0;
}

async function gradedDoc(fake, historyDocId) {
  return fake.collection("examHistoryGraded").doc(historyDocId).get();
}

const EVENT_TIME_MS = Date.parse("2026-08-31T00:05:00.000Z"); // Mon 07:05 WIB
const PERIOD_ID = wibWeekId(new Date(EVENT_TIME_MS));

// Real kana ids/romaji (mirrors functions/data/kana_data.json) — 9
// correct + 1 wrong, the same fixture shape used elsewhere in this
// project's Global Points tests.
const REAL_KANA_ANSWERS = [
  {contentId: "hiragana_a", submittedText: "a"},
  {contentId: "hiragana_i", submittedText: "i"},
  {contentId: "hiragana_u", submittedText: "u"},
  {contentId: "hiragana_e", submittedText: "e"},
  {contentId: "hiragana_o", submittedText: "o"},
  {contentId: "hiragana_ka", submittedText: "ka"},
  {contentId: "hiragana_ki", submittedText: "ki"},
  {contentId: "hiragana_ku", submittedText: "ku"},
  {contentId: "hiragana_ke", submittedText: "ke"},
  {contentId: "hiragana_ko", submittedText: "wrong"},
];

// ---------------------------------------------------------------------
// A. Legitimate history (real answers) -> real, server-graded points.
// ---------------------------------------------------------------------
test("A. a legitimate kana attempt (9/10 correct, real answers) is " +
    "awarded real, server-derived points, the weekly period is " +
    "credited, and a trusted grading result is recorded", async () => {
  const fake = new FakeFirestore();
  const uid = "legit-user";
  const result = await awardPointsForHistoryDoc(
      uid, "kana", "legit-doc-1",
      {
        score: 9, total: 10, type: "hiragana",
        completedAt: "2026-08-31T07:05:00.000Z",
        answers: REAL_KANA_ANSWERS,
      },
      {firestore: fake, eventTimeMs: EVENT_TIME_MS},
  );
  assert.strictEqual(result.awarded, true);
  // serverScore=9, difficulty(hiragana)=1.0, K=10, n=1 -> 9*1*10*0.6^0 = 90
  assert.strictEqual(result.points, 90);
  assert.strictEqual(await leaderboardPoints(fake, uid), 90);
  assert.strictEqual(await periodPoints(fake, PERIOD_ID, uid), 90);

  const graded = await gradedDoc(fake, "legit-doc-1");
  assert.strictEqual(graded.exists, true,
      "a trusted grading result must be recorded for every awarded attempt");
  assert.strictEqual(graded.data().serverScore, 9);
  assert.strictEqual(graded.data().serverTotal, 10);
});

// ---------------------------------------------------------------------
// B. A forged score/total on an otherwise-empty (no real answers)
//    document — the former exploit's exact shape — is now worth 0.
// ---------------------------------------------------------------------
test("B. FORGERY DEFEATED: a fabricated document claiming score=999999 " +
    "but carrying no real answers is awarded ZERO points — the server " +
    "no longer trusts docData.score at all", async () => {
  const fake = new FakeFirestore();
  const uid = "attacker-1";
  const result = await awardPointsForHistoryDoc(
      uid, "kana", "forged-doc-1",
      {
        score: 999999, total: 1, type: "mixed",
        completedAt: "1999-01-01T00:00:00.000Z",
        // no `answers` field at all — exactly the P0 audit's shape.
      },
      {firestore: fake, eventTimeMs: EVENT_TIME_MS},
  );
  assert.strictEqual(result.awarded, true); // still processed...
  assert.strictEqual(result.points, 0, // ...but worth nothing.
      "a forged score with no real answers behind it must be worth 0, " +
      "not 9999990");
  assert.strictEqual(await leaderboardPoints(fake, uid), 0);
  assert.strictEqual(await periodPoints(fake, PERIOD_ID, uid), 0,
      "the forged document has zero effect on the weekly-ranking " +
      "collection award_top_coins.js's real payout reads from");
});

test("B2. FORGERY DEFEATED: score=999999/total=1 with real answers " +
    "attached is still graded from the real answers, not from the " +
    "claimed score/total pair", async () => {
  const fake = new FakeFirestore();
  const uid = "attacker-2";
  const result = await awardPointsForHistoryDoc(
      uid, "kana", "forged-doc-2",
      {
        score: 999999, total: 1, type: "hiragana",
        completedAt: "2026-01-01T00:00:00.000Z",
        answers: [{contentId: "hiragana_a", submittedText: "a"}], // 1 real correct
      },
      {firestore: fake, eventTimeMs: EVENT_TIME_MS},
  );
  // serverScore=1, difficulty=1.0, K=10 -> 10, not 9999990.
  assert.strictEqual(result.points, 10);
});

// ---------------------------------------------------------------------
// C. Farming via many distinct fabricated documents no longer pays —
//    each document with no real answers grades to 0 regardless of how
//    many are created.
// ---------------------------------------------------------------------
test("C. FARMING DEFEATED: 10 separate fabricated documents (10 " +
    "distinct historyDocIds), none carrying real answers, are each " +
    "awarded ZERO points — creating more fake documents no longer buys " +
    "anything", async () => {
  const fake = new FakeFirestore();
  const uid = "farmer-1";
  let total = 0;
  for (let i = 0; i < 10; i++) {
    const result = await awardPointsForHistoryDoc(
        uid, "kana", `farmed-doc-${i}`,
        {
          score: 1000, total: 1, type: "hiragana",
          completedAt: "2026-01-01T00:00:00.000Z",
        },
        {firestore: fake, eventTimeMs: EVENT_TIME_MS},
    );
    total += result.points;
  }
  assert.strictEqual(total, 0);
  assert.strictEqual(await periodPoints(fake, PERIOD_ID, uid), 0);
});

test("C2. FARMING STILL BOUNDED for REAL content: repeatedly submitting " +
    "the SAME real, correct answer set across many distinct documents " +
    "is exactly what the pre-existing repeat-cycle decay already " +
    "governs — not a new gap, and the decay still applies to the now-" +
    "honest score", async () => {
  const fake = new FakeFirestore();
  const uid = "farmer-2";
  const attempt1 = await awardPointsForHistoryDoc(
      uid, "kana", "real-doc-1",
      {type: "hiragana", completedAt: "2026-01-01T00:00:00.000Z", answers: REAL_KANA_ANSWERS},
      {firestore: fake, eventTimeMs: EVENT_TIME_MS},
  );
  const attempt2 = await awardPointsForHistoryDoc(
      uid, "kana", "real-doc-2",
      {type: "hiragana", completedAt: "2026-01-01T00:00:00.000Z", answers: REAL_KANA_ANSWERS},
      {firestore: fake, eventTimeMs: EVENT_TIME_MS + 1000},
  );
  assert.strictEqual(attempt1.points, 90); // n=1
  assert.ok(Math.abs(attempt2.points - 54) < 0.001); // n=2, 90*0.6, unchanged mechanic
});

// ---------------------------------------------------------------------
// D. Points no longer scale with a client-chosen score value at all —
//    only the real, independently-graded answer count matters.
// ---------------------------------------------------------------------
test("D. points do NOT scale with an arbitrary client-chosen score " +
    "value anymore — varying the claimed score while the real answers " +
    "stay fixed has zero effect on the award", async () => {
  const fake = new FakeFirestore();
  const claimedScores = [10, 100, 1000, 100000];
  const points = [];
  for (const score of claimedScores) {
    const result = await awardPointsForHistoryDoc(
        `linear-${score}`, "kana", `doc-${score}`,
        {
          score, total: score, type: "hiragana",
          completedAt: "2026-01-01T00:00:00.000Z",
          answers: [{contentId: "hiragana_a", submittedText: "a"}], // always 1 real correct
        },
        {firestore: fake, eventTimeMs: EVENT_TIME_MS},
    );
    points.push(result.points);
  }
  assert.deepStrictEqual(points, claimedScores.map(() => 10),
      "every attempt scores identically (1 real correct answer -> 10 " +
      "points), regardless of the wildly different score values claimed");
});

// ---------------------------------------------------------------------
// E. Timestamp authority — unchanged by this fix, re-confirmed.
// ---------------------------------------------------------------------
test("E. TIMESTAMP AUTHORITY STILL HOLDS: a forged completedAt (year " +
    "1999) has ZERO effect on which weekly period real, server-graded " +
    "points land in — only eventTimeMs decides this", async () => {
  const fake = new FakeFirestore();
  const uid = "attacker-timeforge";
  const result = await awardPointsForHistoryDoc(
      uid, "kana", "forged-timestamp-doc",
      {
        score: 500, total: 1, type: "hiragana",
        completedAt: "1999-01-01T00:00:00.000Z",
        answers: [{contentId: "hiragana_a", submittedText: "a"}],
      },
      {firestore: fake, eventTimeMs: EVENT_TIME_MS},
  );
  assert.strictEqual(result.periodId, PERIOD_ID);
  assert.strictEqual(await periodPoints(fake, PERIOD_ID, uid), 10);
});

// ---------------------------------------------------------------------
// F. Replay vs. new-document idempotency.
// ---------------------------------------------------------------------
test("F1. SAME historyDocId replayed (Eventarc redelivery) does NOT " +
    "award, grade, or record twice", async () => {
  const fake = new FakeFirestore();
  const uid = "replay-user";
  const docData = {
    type: "hiragana", completedAt: "2026-01-01T00:00:00.000Z",
    answers: REAL_KANA_ANSWERS,
  };
  const first = await awardPointsForHistoryDoc(
      uid, "kana", "same-doc-id", docData, {firestore: fake, eventTimeMs: EVENT_TIME_MS});
  const second = await awardPointsForHistoryDoc(
      uid, "kana", "same-doc-id", docData, {firestore: fake, eventTimeMs: EVENT_TIME_MS});
  assert.strictEqual(first.awarded, true);
  assert.strictEqual(second.awarded, false);
  assert.strictEqual(await leaderboardPoints(fake, uid), 90,
      "only the first call's points are present, not doubled");
});

test("F2. a NEW fabricated history document (different historyDocId) " +
    "is still processed independently by the idempotency marker (per-" +
    "document, unchanged mechanic) — but since it now carries no real " +
    "answers, being 'a new document' no longer manufactures any points " +
    "by itself, unlike the pre-fix exploit", async () => {
  const fake = new FakeFirestore();
  const uid = "distinguish-user";
  const fakeDocData = {
    score: 9, total: 10, type: "hiragana",
    completedAt: "2026-01-01T00:00:00.000Z",
    // no real answers — a document fabricated to look legitimate on its
    // score/total fields alone.
  };
  const first = await awardPointsForHistoryDoc(
      uid, "kana", "doc-A", fakeDocData, {firestore: fake, eventTimeMs: EVENT_TIME_MS});
  const second = await awardPointsForHistoryDoc(
      uid, "kana", "doc-B", fakeDocData, {firestore: fake, eventTimeMs: EVENT_TIME_MS});
  assert.strictEqual(first.awarded, true);
  assert.strictEqual(second.awarded, true); // still per-document, unchanged
  assert.strictEqual(first.points, 0);
  assert.strictEqual(second.points, 0,
      "a fresh fabricated document is no longer enough by itself to " +
      "become a trusted monetary score");
});

// ---------------------------------------------------------------------
// G. Weekly-ranking end-to-end: a forger can no longer outrank honest
//    learners, and honest learners with real answers correctly rank by
//    their real performance.
// ---------------------------------------------------------------------
test("G. END-TO-END: honest learners (real answers) correctly outrank " +
    "a forger (score=999999, no real answers) in the exact ranking " +
    "award_top_coins.js's real payout query reads from", async () => {
  const {awardTopGlobalCoinsOnce, REWARDS} = require("./award_top_coins");
  const fake = new FakeFirestore();
  // Three honest learners, each with a genuinely different real,
  // correct answer count out of the same real kana ids.
  const allTenCorrect = [
    {contentId: "hiragana_a", submittedText: "a"},
    {contentId: "hiragana_i", submittedText: "i"},
    {contentId: "hiragana_u", submittedText: "u"},
    {contentId: "hiragana_e", submittedText: "e"},
    {contentId: "hiragana_o", submittedText: "o"},
    {contentId: "hiragana_ka", submittedText: "ka"},
    {contentId: "hiragana_ki", submittedText: "ki"},
    {contentId: "hiragana_ku", submittedText: "ku"},
    {contentId: "hiragana_ke", submittedText: "ke"},
    {contentId: "hiragana_ko", submittedText: "ko"},
  ];
  const honestAnswerSets = {
    "honest-1": allTenCorrect, // 10 real correct
    "honest-2": allTenCorrect.slice(0, 7), // 7 real correct
    "honest-3": allTenCorrect.slice(0, 4), // 4 real correct
  };
  for (const [uid, answers] of Object.entries(honestAnswerSets)) {
    await awardPointsForHistoryDoc(
        uid, "kana", `${uid}-doc`,
        {type: "hiragana", completedAt: "2026-01-01T00:00:00.000Z", answers},
        {firestore: fake, eventTimeMs: EVENT_TIME_MS},
    );
  }
  // One attacker, one forged document with no real answers behind it.
  await awardPointsForHistoryDoc(
      "attacker-final", "kana", "attacker-final-doc",
      {score: 999999, total: 1, type: "mixed", completedAt: "2026-01-01T00:00:00.000Z"},
      {firestore: fake, eventTimeMs: EVENT_TIME_MS},
  );
  for (const uid of ["honest-1", "honest-2", "honest-3", "attacker-final"]) {
    fake.seed(`users/${uid}`, {coins: 0});
  }
  const winners = await awardTopGlobalCoinsOnce(fake, PERIOD_ID);
  assert.strictEqual(winners[0].uid, "honest-1",
      "the honest learner with the most REAL correct answers wins 1st " +
      "place — the forger's claimed score=999999 has no effect at all");
  assert.notStrictEqual(winners.find((w) => w.uid === "attacker-final")?.rank, 1,
      "the forger must never rank 1st");
  assert.strictEqual(winners[0].reward, REWARDS[0]);
});

// ---------------------------------------------------------------------
// H. Deterministic concurrency — the trusted grading result, the
//    points marker, and the leaderboard/period increments are all
//    written in the SAME transaction, so a genuine mid-transaction
//    conflict (forced via FakeFirestore's beforeCommit pause hook, not
//    hoped for from Node's own scheduling — same proof shape already
//    established by global_points_reliability.test.js's own "genuine
//    mid-transaction conflict" test) can only ever converge to exactly
//    one grading result, never a duplicate or a partial one.
// ---------------------------------------------------------------------
test("H. a genuine mid-transaction conflict on the SAME historyDocId " +
    "still converges to exactly ONE trusted grading result and ONE " +
    "points award — the graded doc can never be written twice, or " +
    "written without the points award (or vice versa)", async () => {
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
  const uid = "concurrent-user";
  const docData = {
    type: "hiragana", completedAt: "2026-01-01T00:00:00.000Z",
    answers: REAL_KANA_ANSWERS,
  };

  const txA = awardPointsForHistoryDoc(uid, "kana", "h1", docData, {firestore: fake, eventTimeMs: EVENT_TIME_MS});
  await reachedPause;

  const txB = await awardPointsForHistoryDoc(uid, "kana", "h1", docData, {firestore: fake, eventTimeMs: EVENT_TIME_MS});
  assert.strictEqual(txB.awarded, true);

  releaseA();
  const txAResult = await txA;
  assert.strictEqual(txAResult.awarded, false,
      "the forced-conflicting retry must see the marker/grading already " +
      "committed by B and award nothing a second time");

  assert.strictEqual(await leaderboardPoints(fake, uid), 90);
  const graded = await gradedDoc(fake, "h1");
  assert.strictEqual(graded.exists, true);
  assert.strictEqual(graded.data().serverScore, 9,
      "exactly one, correctly-graded trusted result — not two, not " +
      "zero, not a half-written one");
});

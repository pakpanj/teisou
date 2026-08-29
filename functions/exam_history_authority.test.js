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

// ---------------------------------------------------------------------
// I/J/K. Compatibility with the OLD (pre-03e879f) app build — see
// TEISOU_ROADMAP_MASTER.md's "Exam-History Authority — P0 FIX
// IMPLEMENTED" and the follow-up "AUDIT + DESIGN — P0 Exam-History
// Deployment Compatibility" sections. Old `ExamResult.toMap()`/
// `SimpleExamResult.toMap()` (pre-fix) never wrote an `answers` key at
// all — everything else (score/total/type/completedAt/etc.) is
// byte-identical to the current format. These tests name that exact
// shape explicitly, rather than leaving it implicit in the generic
// "missing answers" cases scenario B already covers, since the
// compatibility audit found this specific scenario had no permanent
// test asserting it by name.
// ---------------------------------------------------------------------

/** The exact document shape an app build predating 03e879f writes for
 * a completed kana exam — every field `ExamResult.toMap()` used to
 * emit, and nothing more; no `answers` key exists in this shape at
 * all (it did not exist in the model before this fix). */
function oldFormatKanaDoc(overrides = {}) {
  return {
    type: "hiragana",
    score: 9,
    total: 10,
    percentage: 90,
    correctCount: 9,
    wrongCount: 1,
    completedAt: "2026-01-01T00:00:00.000Z",
    ...overrides,
    // deliberately no `answers` field anywhere in this shape
  };
}

test("I. OLD CLIENT (pre-03e879f format, no `answers` field at all): " +
    "raw processing does not crash, a trusted graded document IS " +
    "still created, serverScore/serverTotal are both 0, and the " +
    "client-reported score=9/total=10 has zero effect on the award", async () => {
  const fake = new FakeFirestore();
  const uid = "old-client-user";
  const result = await awardPointsForHistoryDoc(
      uid, "kana", "old-format-doc-1", oldFormatKanaDoc(),
      {firestore: fake, eventTimeMs: EVENT_TIME_MS},
  );

  // 1. does not crash — reaching this line at all proves it.
  assert.strictEqual(result.awarded, true);

  // 2/3/4. a trusted graded document is created, and BOTH serverScore
  // and serverTotal reflect the established secure default: 0.
  const graded = await gradedDoc(fake, "old-format-doc-1");
  assert.strictEqual(graded.exists, true,
      "a trusted result must still be recorded even for an old-format " +
      "document — 'ungraded' is not a valid outcome, 'graded as 0' is");
  assert.strictEqual(graded.data().serverScore, 0);
  assert.strictEqual(graded.data().serverTotal, 0);

  // 5. Global Points awarded for this document are 0.
  assert.strictEqual(result.points, 0);
  assert.strictEqual(await leaderboardPoints(fake, uid), 0);
  assert.strictEqual(await periodPoints(fake, PERIOD_ID, uid), 0,
      "the weekly-ranking collection award_top_coins.js's real payout " +
      "reads from is also unaffected by the old client's self-reported " +
      "score=9/total=10");

  // 6. client-provided score must not affect the result — re-run the
  // identical old-format shape but with an implausible score, and
  // confirm the award is byte-identical (still 0), not merely "low".
  const fakeB = new FakeFirestore();
  const inflatedOldFormat = await awardPointsForHistoryDoc(
      "old-client-user-2", "kana", "old-format-doc-2",
      oldFormatKanaDoc({score: 999999, total: 1}),
      {firestore: fakeB, eventTimeMs: EVENT_TIME_MS},
  );
  assert.strictEqual(inflatedOldFormat.points, 0,
      "an old-format document with an inflated self-reported score " +
      "earns exactly as much as one with an honest score — zero, " +
      "because neither is ever consulted");
});

test("J. MIXED OLD + NEW submissions from the SAME user: the " +
    "old-format document (no answers) and the current-format " +
    "document (real answers) are graded completely independently — " +
    "one earns 0, the other earns its real, correct points, with no " +
    "cross-document contamination in either direction", async () => {
  const fake = new FakeFirestore();
  const uid = "mixed-format-user";

  const oldResult = await awardPointsForHistoryDoc(
      uid, "kana", "mixed-old-doc", oldFormatKanaDoc(),
      {firestore: fake, eventTimeMs: EVENT_TIME_MS},
  );
  const newResult = await awardPointsForHistoryDoc(
      uid, "kana", "mixed-new-doc",
      {
        type: "hiragana", completedAt: "2026-01-01T00:00:00.000Z",
        answers: REAL_KANA_ANSWERS, // 9 correct, 1 wrong — see top of file
      },
      {firestore: fake, eventTimeMs: EVENT_TIME_MS + 1000},
  );

  // Old document graded to 0, exactly as test I proves in isolation.
  assert.strictEqual(oldResult.points, 0);
  const oldGraded = await gradedDoc(fake, "mixed-old-doc");
  assert.strictEqual(oldGraded.data().serverScore, 0);

  // New document graded correctly from its own real answers — this is
  // this SAME user's second attempt, so the repeat-cycle decay applies
  // (n=2, same "kana:hiragana" repeatKey) exactly as it would for two
  // consecutive real attempts; the old document's zero score does not
  // pull the new one down any further than normal decay already would.
  assert.ok(Math.abs(newResult.points - 54) < 0.001, // 90 * 0.6, n=2
      "the new document's own real answers (9/10 correct) still earn " +
      "the normal decayed amount for a 2nd attempt in the cycle — not " +
      "reduced further, and not contaminated by the old document's 0");

  // No cross-document contamination: the leaderboard total is exactly
  // the sum of the two independent awards, and the old document's own
  // graded result was never touched by processing the new one.
  assert.strictEqual(
      await leaderboardPoints(fake, uid), oldResult.points + newResult.points);
  const oldGradedAfter = await gradedDoc(fake, "mixed-old-doc");
  assert.strictEqual(oldGradedAfter.data().serverScore, 0,
      "processing the new document must not retroactively change the " +
      "old document's already-recorded trusted result");
});

test("K. CLIENT UPDATE AFTER AN OLD SUBMISSION: an old-format exam " +
    "graded under current secure rules stays permanently unchanged " +
    "— there is no retroactive re-grading — and a LATER, current-" +
    "format submission from the same user grades normally and is the " +
    "only one of the two that earns points", async () => {
  const fake = new FakeFirestore();
  const uid = "updated-client-user";

  // 1. User submits an old-format exam (pre-update).
  const oldResult = await awardPointsForHistoryDoc(
      uid, "kana", "before-update-doc", oldFormatKanaDoc(),
      {firestore: fake, eventTimeMs: EVENT_TIME_MS},
  );
  assert.strictEqual(oldResult.points, 0);
  const gradedBeforeUpdate = await gradedDoc(fake, "before-update-doc");
  const snapshotOfOldResult = {
    serverScore: gradedBeforeUpdate.data().serverScore,
    serverTotal: gradedBeforeUpdate.data().serverTotal,
    gradedAt: gradedBeforeUpdate.data().gradedAt,
  };

  // 2. (Simulated) the user updates their app — nothing in this
  // system re-processes the old document as a result; it is only
  // ever written once, by the original trigger invocation above.

  // 3. User later submits a current-format exam with valid answers.
  const newResult = await awardPointsForHistoryDoc(
      uid, "kana", "after-update-doc",
      {
        type: "hiragana", completedAt: "2026-02-01T00:00:00.000Z",
        answers: REAL_KANA_ANSWERS,
      },
      {firestore: fake, eventTimeMs: EVENT_TIME_MS + 7 * 24 * 60 * 60 * 1000},
  );

  // The old graded document remains unchanged at its original result —
  // explicitly re-read and compared field-by-field against the
  // snapshot taken right after it was first graded.
  const gradedAfterUpdate = await gradedDoc(fake, "before-update-doc");
  assert.strictEqual(
      gradedAfterUpdate.data().serverScore, snapshotOfOldResult.serverScore);
  assert.strictEqual(
      gradedAfterUpdate.data().serverTotal, snapshotOfOldResult.serverTotal);
  assert.strictEqual(
      gradedAfterUpdate.data().gradedAt, snapshotOfOldResult.gradedAt,
      "no retroactive re-grading — the old document's trusted result, " +
      "including its own gradedAt timestamp, is untouched by any later " +
      "activity from the same user");

  // Only the new submission earns points; the old one still earns 0.
  assert.strictEqual(oldResult.points, 0);
  assert.ok(newResult.points > 0,
      "the new, current-format submission grades normally from its " +
      "own real answers");
  assert.strictEqual(
      await leaderboardPoints(fake, uid), oldResult.points + newResult.points);
});

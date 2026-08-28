// Coverage for the weekly-period write [global_points.js's
// awardPointsForHistoryDoc] gained as part of the Weekly Global Ranking
// implementation (see TEISOU_ROADMAP_MASTER.md). This is deliberately a
// SEPARATE file from global_points_reliability.test.js — that file's own
// 8 tests already fully cover the pre-existing marker/cycle/leaderboard
// idempotency machinery (still green, unmodified, after this extension —
// confirmed by running it alongside this file) and this file is scoped
// purely to the new behaviour layered on top of it, so a future reader
// doesn't have to separate "old" vs "new" assertions inside one giant
// file.
"use strict";

const {test} = require("node:test");
const assert = require("node:assert/strict");

const {FakeFirestore} = require("./test_helpers/fake_firestore");
const {awardPointsForHistoryDoc} = require("./global_points");
const {wibWeekId} = require("./wib_week");

const uid = "uPeriod";

function kanaDoc(overrides = {}) {
  return {
    score: 9,
    total: 10,
    type: "hiragana",
    completedAt: "2020-01-01T00:00:00.000Z", // deliberately far from any
    // eventTimeMs used below — see the anti-forgery test, this value
    // must never influence which period a write lands in.
    ...overrides,
  };
}

async function periodDoc(fake, periodId, forUid = uid) {
  return fake
    .collection("globalScorePeriods")
    .doc(periodId)
    .collection("users")
    .doc(forUid)
    .get();
}

test("a live attempt (eventTimeMs supplied) writes a weekly-period " +
    "document under globalScorePeriods/{periodId}/users/{uid}", async () => {
  const fake = new FakeFirestore();
  const eventTimeMs = Date.parse("2026-08-31T01:00:00.000Z"); // Mon 08:00 WIB
  const expectedPeriodId = wibWeekId(new Date(eventTimeMs));

  const result = await awardPointsForHistoryDoc(
    uid, "kana", "h1", kanaDoc(), {firestore: fake, eventTimeMs},
  );

  assert.strictEqual(result.awarded, true);
  assert.strictEqual(result.periodId, expectedPeriodId);

  const snap = await periodDoc(fake, expectedPeriodId);
  assert.ok(snap.exists, "the period document must have been created");
  assert.strictEqual(snap.data().points, result.points);
  assert.strictEqual(snap.data().attempts, 1);
  assert.strictEqual(snap.data().uid, uid);
  assert.strictEqual(snap.data().periodId, expectedPeriodId);
});

test("a backfill replay (no eventTimeMs) writes NO weekly-period " +
    "document at all — a historical replay must never inject itself " +
    "into a live competition period", async () => {
  const fake = new FakeFirestore();

  const result = await awardPointsForHistoryDoc(
    uid, "kana", "h1", kanaDoc(), {firestore: fake, source: "backfill"},
  );

  assert.strictEqual(result.awarded, true);
  assert.strictEqual(result.periodId, null,
      "no eventTimeMs means no period assignment at all");

  // There is no periodId to look a document up by — the real proof is
  // that no globalScorePeriods document was ever created anywhere.
  // Assert this by directly inspecting the fake's own flat `docs` store
  // (`path -> {data, version}`, see fake_firestore.js's own
  // `FakeFirestore` constructor) rather than guessing a periodId that
  // shouldn't exist.
  const anyPeriodDocs = [...fake.docs.keys()]
    .some((path) => path.startsWith("globalScorePeriods/"));
  assert.strictEqual(anyPeriodDocs, false,
      "backfill must never create any globalScorePeriods document");
});

test("ANTI-FORGERY: the period a live attempt lands in is derived " +
    "SOLELY from eventTimeMs, never from docData.completedAt — a " +
    "client cannot backdate/forward-date completedAt to move its own " +
    "score into a different (e.g. still-open, or already-favorable) " +
    "week", async () => {
  const fake = new FakeFirestore();
  // completedAt claims a wildly different week than the real trigger
  // time — if the implementation ever regresses to reading
  // docData.completedAt instead of options.eventTimeMs, this test must
  // fail by landing the write in the wrong (attacker-chosen) period.
  const forgedCompletedAt = "2019-01-01T00:00:00.000Z";
  const realEventTimeMs = Date.parse("2026-09-07T01:00:00.000Z"); // a later Monday, WIB
  const realPeriodId = wibWeekId(new Date(realEventTimeMs));
  const forgedPeriodId = wibWeekId(new Date(Date.parse(forgedCompletedAt)));

  assert.notStrictEqual(realPeriodId, forgedPeriodId,
      "test setup sanity: the two dates must actually be different weeks");

  const result = await awardPointsForHistoryDoc(
    uid, "kana", "h1", kanaDoc({completedAt: forgedCompletedAt}),
    {firestore: fake, eventTimeMs: realEventTimeMs},
  );

  assert.strictEqual(result.periodId, realPeriodId,
      "the write must land in the REAL (event-time) period");

  const realSnap = await periodDoc(fake, realPeriodId);
  assert.ok(realSnap.exists);

  const forgedSnap = await periodDoc(fake, forgedPeriodId);
  assert.strictEqual(forgedSnap.exists, false,
      "the forged (completedAt-derived) period must receive NOTHING");
});

test("two attempts in the SAME period accumulate points and attempts, " +
    "not overwrite", async () => {
  const fake = new FakeFirestore();
  const weekMs = Date.parse("2026-08-31T01:00:00.000Z");
  const periodId = wibWeekId(new Date(weekMs));

  const first = await awardPointsForHistoryDoc(
    uid, "kana", "h1", kanaDoc(), {firestore: fake, eventTimeMs: weekMs},
  );
  const second = await awardPointsForHistoryDoc(
    uid, "kana", "h2", kanaDoc(),
    {firestore: fake, eventTimeMs: weekMs + 60000},
  );

  const snap = await periodDoc(fake, periodId);
  assert.strictEqual(snap.data().attempts, 2);
  assert.strictEqual(
    snap.data().points, first.points + second.points,
    "points must accumulate across both attempts within the period",
  );
});

test("a replay of the SAME historyDocId (Eventarc redelivery) does " +
    "NOT double-count into the period — idempotency reuses the exact " +
    "same marker gate as the leaderboard write", async () => {
  const fake = new FakeFirestore();
  const weekMs = Date.parse("2026-08-31T01:00:00.000Z");
  const periodId = wibWeekId(new Date(weekMs));

  await awardPointsForHistoryDoc(
    uid, "kana", "h1", kanaDoc(), {firestore: fake, eventTimeMs: weekMs},
  );
  const replay = await awardPointsForHistoryDoc(
    uid, "kana", "h1", kanaDoc(),
    {firestore: fake, eventTimeMs: weekMs + 60000},
  );

  assert.strictEqual(replay.awarded, false,
      "the marker gate must reject the replay before any period write");
  assert.strictEqual(replay.periodId, null);

  const snap = await periodDoc(fake, periodId);
  assert.strictEqual(snap.data().attempts, 1,
      "the replay must not have incremented attempts a second time");
});

test("two attempts in DIFFERENT weekly periods each get their own, " +
    "independently-accumulating period document", async () => {
  const fake = new FakeFirestore();
  const weekOneMs = Date.parse("2026-08-31T01:00:00.000Z");
  const weekTwoMs = Date.parse("2026-09-07T01:00:00.000Z");
  const periodOne = wibWeekId(new Date(weekOneMs));
  const periodTwo = wibWeekId(new Date(weekTwoMs));
  assert.notStrictEqual(periodOne, periodTwo);

  await awardPointsForHistoryDoc(
    uid, "kana", "h1", kanaDoc(), {firestore: fake, eventTimeMs: weekOneMs},
  );
  await awardPointsForHistoryDoc(
    uid, "kana", "h2", kanaDoc(), {firestore: fake, eventTimeMs: weekTwoMs},
  );

  const snapOne = await periodDoc(fake, periodOne);
  const snapTwo = await periodDoc(fake, periodTwo);
  assert.strictEqual(snapOne.data().attempts, 1);
  assert.strictEqual(snapTwo.data().attempts, 1);
});

test("the existing leaderboard.globalPoints write is completely " +
    "unaffected by whether a period write also happens — the two are " +
    "additive, not a replacement", async () => {
  const fakeWithPeriod = new FakeFirestore();
  const fakeWithoutPeriod = new FakeFirestore();

  const withPeriod = await awardPointsForHistoryDoc(
    uid, "kana", "h1", kanaDoc(),
    {firestore: fakeWithPeriod, eventTimeMs: Date.parse("2026-08-31T01:00:00.000Z")},
  );
  const withoutPeriod = await awardPointsForHistoryDoc(
    uid, "kana", "h1", kanaDoc(), {firestore: fakeWithoutPeriod},
  );

  assert.strictEqual(withPeriod.points, withoutPeriod.points,
      "the Formula C points value itself must not depend on whether " +
      "eventTimeMs was supplied");

  const lbWith = await fakeWithPeriod.collection("leaderboard").doc(uid).get();
  const lbWithout =
    await fakeWithoutPeriod.collection("leaderboard").doc(uid).get();
  assert.strictEqual(lbWith.data().globalPoints, lbWithout.data().globalPoints);
});

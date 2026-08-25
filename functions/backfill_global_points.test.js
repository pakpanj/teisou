const {test, describe} = require("node:test");
const assert = require("node:assert/strict");

const {BACKFILL_WINDOW_MS, replayForBackfill} = require("./backfill_global_points");

const DAY_MS = 24 * 60 * 60 * 1000;

/** Fixture-data tests for the pure replay core — no Firestore/emulator
 * involved, per this file's own doc comment on why [replayForBackfill]
 * is deliberately Firestore-free. */
describe("backfill: replayForBackfill with fixture data", () => {
  test("90-day window constant matches the approved Final Decision Memo "
      + "(3x the 30-day repeat-cycle window)", () => {
    assert.equal(BACKFILL_WINDOW_MS, 90 * DAY_MS);
  });

  test("a single historical kana attempt replays to the same points a "
      + "live first-attempt trigger would produce", () => {
    const records = [{
      moduleType: "kana",
      historyDocId: "h1",
      data: {type: "hiragana", score: 9, total: 10, completedAt: 0},
    }];
    const {totalPoints, markers} = replayForBackfill(records);
    assert.equal(totalPoints, 90); // 9 * 1.0 * 10
    assert.equal(markers.length, 1);
    assert.equal(markers[0].historyDocId, "h1");
    assert.equal(markers[0].points, 90);
  });

  test("multiple attempts on the same repeat key, in chronological "
      + "order, decay exactly like the live trigger's sequential "
      + "processing would", () => {
    const records = [
      {moduleType: "kana", historyDocId: "h1", data: {type: "hiragana", score: 9, total: 10, completedAt: 0}},
      {moduleType: "kana", historyDocId: "h2", data: {type: "hiragana", score: 9, total: 10, completedAt: DAY_MS}},
      {moduleType: "kana", historyDocId: "h3", data: {type: "hiragana", score: 9, total: 10, completedAt: 2 * DAY_MS}},
    ];
    const {totalPoints, markers} = replayForBackfill(records);
    // 90 + 90*0.6 + 90*0.36 = 90 + 54 + 32.4 = 176.4
    assert.ok(Math.abs(totalPoints - 176.4) < 0.001, `expected ~176.4, got ${totalPoints}`);
    assert.equal(markers[0].points, 90);
    assert.equal(markers[1].points, 54);
    assert.ok(Math.abs(markers[2].points - 32.4) < 0.001);
  });

  test("out-of-order input is NOT tolerated silently — the caller "
      + "(backfillUser) is responsible for sorting chronologically first, "
      + "since decay/reset math is order-dependent; this test documents "
      + "that feeding unsorted records produces a DIFFERENT (wrong) "
      + "result than sorted input, as a guard against ever removing the "
      + "sort in backfillUser", () => {
    const sorted = [
      {moduleType: "kana", historyDocId: "h1", data: {type: "hiragana", score: 9, total: 10, completedAt: 0}},
      {moduleType: "kana", historyDocId: "h2", data: {type: "hiragana", score: 9, total: 10, completedAt: DAY_MS}},
    ];
    const reversed = [sorted[1], sorted[0]];

    const sortedResult = replayForBackfill(sorted);
    const reversedResult = replayForBackfill(reversed);

    // Same total either way here (both attempts are within the 30-day
    // cycle regardless of processing order), but the PER-ATTEMPT points
    // assigned to h1 vs h2 differ depending on which is treated as
    // "first" — proving order genuinely matters to the marker output,
    // not just the total.
    assert.equal(sortedResult.totalPoints, reversedResult.totalPoints);
    const sortedH1 = sortedResult.markers.find((m) => m.historyDocId === "h1");
    const reversedH1 = reversedResult.markers.find((m) => m.historyDocId === "h1");
    assert.notEqual(sortedH1.points, reversedH1.points);
  });

  test("different repeat keys never share a decay chain — an N5 Dokkai "
      + "attempt and an N3 Dokkai attempt each start fresh at n=1", () => {
    const records = [
      {moduleType: "dokkai", historyDocId: "d1", data: {jlptLevel: "N5", score: 45, total: 50, completedAt: 0}},
      {moduleType: "dokkai", historyDocId: "d2", data: {jlptLevel: "N3", score: 40, total: 50, completedAt: DAY_MS}},
    ];
    const {markers} = replayForBackfill(records);
    // N5: 45*1.0*10 = 450 (n=1); N3: 40*1.5*10 = 600 (n=1, different key)
    assert.equal(markers[0].points, 450);
    assert.equal(markers[1].points, 600);
  });

  test("a gap longer than 30 days between two attempts on the same key "
      + "resets the cycle during replay, exactly as a live trigger "
      + "would for a genuine returning learner", () => {
    const thirtyOneDaysMs = 31 * DAY_MS;
    const records = [
      {moduleType: "kana", historyDocId: "h1", data: {type: "hiragana", score: 9, total: 10, completedAt: 0}},
      {moduleType: "kana", historyDocId: "h2", data: {type: "hiragana", score: 9, total: 10, completedAt: thirtyOneDaysMs}},
    ];
    const {markers} = replayForBackfill(records);
    assert.equal(markers[0].points, 90);
    assert.equal(markers[1].points, 90, "the gap should have reset the cycle back to full value");
  });

  test("records for an unrecognised module type are silently skipped, "
      + "not thrown — a schema drift in old history data must not abort "
      + "the whole user's backfill", () => {
    const records = [
      {moduleType: "kana", historyDocId: "h1", data: {type: "hiragana", score: 9, total: 10, completedAt: 0}},
      {moduleType: "not-a-real-module", historyDocId: "h2", data: {score: 5, total: 5, completedAt: DAY_MS}},
    ];
    const {totalPoints, markers} = replayForBackfill(records);
    assert.equal(totalPoints, 90);
    assert.equal(markers.length, 1);
  });

  test("realistic mixed-module fixture: a user with kana, dokkai, "
      + "choukai and kanji-kombo history across several days produces a "
      + "total that is the sum of each module's own independent replay",
      () => {
    const records = [
      {moduleType: "kana", historyDocId: "k1", data: {type: "hiragana", score: 10, total: 10, completedAt: 0}},
      {moduleType: "dokkai", historyDocId: "d1", data: {jlptLevel: "N4", score: 45, total: 50, completedAt: DAY_MS}},
      {moduleType: "choukai", historyDocId: "c1", data: {itemId: "clip_a", jlptLevel: "N1", score: 8, total: 10, completedAt: 2 * DAY_MS}},
      {moduleType: "kanjiCombo", historyDocId: "j1", data: {itemId: "single_n2", jlptLevel: "N2", score: 42, total: 50, completedAt: 3 * DAY_MS}},
    ];
    const {totalPoints, markers} = replayForBackfill(records);
    const expected =
      10 * 1.0 * 10 + // kana, pre-JLPT tier
      45 * 1.2 * 10 + // dokkai N4
      8 * 2.2 * 10 + // choukai N1 — difficulty reads the doc's own jlptLevel field, distinct from itemId
      42 * 1.8 * 10; // kanjiCombo N2 — same: jlptLevel, not the "single_n2"-shaped itemId
    assert.ok(Math.abs(totalPoints - expected) < 0.001, `expected ${expected}, got ${totalPoints}`);
    assert.equal(markers.length, 4);
  });

  test("empty input produces an empty, harmless result", () => {
    const {totalPoints, markers, finalCycles} = replayForBackfill([]);
    assert.equal(totalPoints, 0);
    assert.deepEqual(markers, []);
    assert.equal(finalCycles.size, 0);
  });
});

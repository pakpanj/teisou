"use strict";

const {test} = require("node:test");
const assert = require("node:assert/strict");

const {wibWeekId, wibWeekStart, WIB_OFFSET_MS} = require("./wib_week");

test("WIB_OFFSET_MS is exactly +7 hours", () => {
  assert.strictEqual(WIB_OFFSET_MS, 7 * 60 * 60 * 1000);
});

test("Sunday 23:59:59.999 WIB is still the CLOSING week, not the new one", () => {
  // 2026-08-30 is a Sunday. 23:59:59.999 WIB == 2026-08-30T16:59:59.999Z.
  const justBeforeMidnightWib = new Date("2026-08-30T16:59:59.999Z");
  // Earlier the same Sunday (still well inside the closing week's WIB day).
  const earlierSameSundayWib = new Date("2026-08-30T05:00:00.000Z"); // 2026-08-30 12:00 WIB
  const idOfExactMonday = wibWeekId(new Date("2026-08-30T17:00:00.000Z")); // exactly 2026-08-31T00:00 WIB

  assert.strictEqual(
      wibWeekId(justBeforeMidnightWib), wibWeekId(earlierSameSundayWib),
      "one millisecond before WIB midnight must still belong to the " +
      "same week as earlier that same Sunday");
  assert.notStrictEqual(wibWeekId(justBeforeMidnightWib), idOfExactMonday,
      "one millisecond before WIB midnight must NOT belong to the " +
      "week that is about to start at midnight");
});

test("Monday 00:00:00.000 WIB starts a NEW week id, distinct from the " +
    "previous week", () => {
  const sundayNight = new Date("2026-08-30T16:59:59.999Z"); // 2026-08-30 23:59:59.999 WIB
  const mondayMidnight = new Date("2026-08-30T17:00:00.000Z"); // 2026-08-31 00:00:00.000 WIB
  assert.notStrictEqual(wibWeekId(sundayNight), wibWeekId(mondayMidnight),
      "the instant exactly at WIB midnight must roll over to a new " +
      "period id");
});

test("a UTC instant that is still Sunday in UTC but already Monday in " +
    "WIB resolves to the NEW week — this is the whole point of using " +
    "WIB rather than raw UTC boundaries", () => {
  // 2026-08-30 (Sun) 23:00 UTC == 2026-08-31 (Mon) 06:00 WIB.
  const stillSundayUtcButMondayWib = new Date("2026-08-30T23:00:00.000Z");
  const deepIntoMondayWib = new Date("2026-08-31T10:00:00.000Z"); // 2026-08-31 17:00 WIB
  assert.strictEqual(
      wibWeekId(stillSundayUtcButMondayWib), wibWeekId(deepIntoMondayWib),
      "6am WIB Monday and 5pm WIB Monday must be the same WIB week, " +
      "even though the first instant is still Sunday by raw UTC clock");
});

test("a UTC instant that is already Monday in UTC but still Sunday in " +
    "WIB resolves to the OLD (closing) week", () => {
  // 2026-08-31 (Mon) 00:00 UTC == 2026-08-31 07:00 WIB — already Monday
  // in WIB too in this specific case; use an earlier UTC instant that is
  // Monday UTC but still Sunday WIB: 2026-08-31 00:00 UTC is 07:00 WIB
  // Monday, so that's not a counter-example. The genuine "UTC already
  // rolled, WIB hasn't" window doesn't exist for a +7 shift landing on a
  // later local day — instead verify the mirror case explicitly: an
  // instant that is Sunday UTC AND Sunday WIB must match the closing
  // week, not accidentally read as new.
  const sundayBothClocks = new Date("2026-08-30T10:00:00.000Z"); // 2026-08-30 17:00 WIB, Sunday both ways
  const sundayNightWib = new Date("2026-08-30T16:59:59.999Z");
  assert.strictEqual(
      wibWeekId(sundayBothClocks), wibWeekId(sundayNightWib),
      "two instants both still Sunday in WIB must share the same " +
      "week id regardless of their raw UTC day");
});

test("wibWeekId format matches award_top_coins.js's isoWeekId " +
    "convention exactly (YYYY-Www, zero-padded)", () => {
  const id = wibWeekId(new Date("2026-08-31T00:00:00.000Z"));
  assert.match(id, /^\d{4}-W\d{2}$/);
});

test("a year boundary correctly rolls the WIB week's ISO year forward " +
    "(late-December WIB dates can belong to week 1 of the next year, " +
    "same edge case isoWeekId already handles for raw UTC)", () => {
  // 2026-12-31 is a Thursday — ISO week rules put Dec 28 2026 (Mon) as
  // the start of the week containing both Dec 31 2026 and Jan 1 2027;
  // that week's Thursday (Dec 31) is in ISO year 2026, so the id must
  // read 2026-W53, not roll to 2027-W01 early.
  const dec31Wib = new Date("2026-12-31T10:00:00.000Z"); // Dec 31 2026, 17:00 WIB
  assert.strictEqual(wibWeekId(dec31Wib), "2026-W53");

  // Jan 5 2027 is a Tuesday, safely inside the following week (Mon Jan 4
  // 2027 - Sun Jan 10 2027), which IS ISO week 1 of 2027.
  const jan5_2027Wib = new Date("2027-01-05T10:00:00.000Z"); // Jan 5 2027, 17:00 WIB
  assert.strictEqual(wibWeekId(jan5_2027Wib), "2027-W01");
});

test("wibWeekStart returns the real UTC instant of Monday 00:00:00.000 " +
    "WIB for the week containing the given date", () => {
  const midWeek = new Date("2026-09-02T05:00:00.000Z"); // Wed 2026-09-02 12:00 WIB
  const start = wibWeekStart(midWeek);
  // Monday 2026-08-31 00:00:00 WIB == 2026-08-30T17:00:00.000Z
  assert.strictEqual(start.toISOString(), "2026-08-30T17:00:00.000Z");
});

test("wibWeekStart(x) and x itself always share the same wibWeekId " +
    "(the start instant is a self-consistent anchor for its own week)", () => {
  const samples = [
    new Date("2026-08-30T16:59:59.999Z"),
    new Date("2026-08-30T17:00:00.000Z"),
    new Date("2026-09-05T23:59:59.999Z"),
    new Date("2027-01-01T00:00:00.000Z"),
  ];
  for (const sample of samples) {
    const start = wibWeekStart(sample);
    assert.strictEqual(wibWeekId(start), wibWeekId(sample),
        `wibWeekStart(${sample.toISOString()}) must resolve to the ` +
        "same period id as the sample itself");
  }
});

test("wibWeekStart is idempotent: calling it again on its own result " +
    "returns the same instant", () => {
  const midWeek = new Date("2026-09-02T05:00:00.000Z");
  const start = wibWeekStart(midWeek);
  const startOfStart = wibWeekStart(start);
  assert.strictEqual(start.getTime(), startOfStart.getTime());
});

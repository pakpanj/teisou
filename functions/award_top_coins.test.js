const test = require("node:test");
const assert = require("node:assert");

const {isoWeekId, REWARDS} = require("./award_top_coins");

/**
 * `isoWeekId` is what makes the weekly payout idempotent — a retry or a
 * cold-start re-trigger on the same week must resolve to the same id as
 * the first run, or `weeklyCoinAwards/{isoWeek}`'s own dedup check pays
 * the same week out twice. The Firestore-touching half
 * (`awardTopGlobalCoinsOnce`) isn't unit-tested here for the same reason
 * `iap.js`'s `verifyPurchase` itself isn't — it needs a live Firestore
 * instance, and the part actually worth testing without one is this pure
 * date math.
 */

// Derived rather than hardcoded from a guessed calendar date — the
// point of this test is the week-boundary math, not memorising which
// day of the week August 24th 2026 happens to fall on.
const aMonday = new Date("2026-08-24T00:00:00Z");
while (aMonday.getUTCDay() !== 1) aMonday.setUTCDate(aMonday.getUTCDate() + 1);

test("two dates in the same ISO week resolve to the same id", () => {
  // The Monday found above and the Sunday that follows it are the same
  // ISO week.
  const sunday = new Date(aMonday);
  sunday.setUTCDate(sunday.getUTCDate() + 6);
  sunday.setUTCHours(23, 59, 0, 0);
  assert.strictEqual(isoWeekId(aMonday), isoWeekId(sunday));
});

test("the Monday after rolls to the next week's id", () => {
  const nextMonday = new Date(aMonday);
  nextMonday.setUTCDate(nextMonday.getUTCDate() + 7);
  assert.notStrictEqual(isoWeekId(aMonday), isoWeekId(nextMonday));
});

test("a year boundary doesn't collide with the same week number a year "
    + "earlier", () => {
  const week1of2026 = isoWeekId(new Date("2026-01-05T00:00:00Z"));
  const week1of2027 = isoWeekId(new Date("2027-01-04T00:00:00Z"));
  assert.notStrictEqual(week1of2026, week1of2027);
  assert.match(week1of2026, /^2026-W\d{2}$/);
  assert.match(week1of2027, /^2027-W\d{2}$/);
});

test("rewards are highest-first, one per placed rank", () => {
  assert.deepStrictEqual(REWARDS, [500, 300, 100]);
  for (let i = 1; i < REWARDS.length; i++) {
    assert.ok(REWARDS[i] < REWARDS[i - 1], "rewards must strictly decrease");
  }
});

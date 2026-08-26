/**
 * Regression coverage for award_xp.js — Security & Monetization
 * Remediation Plan, Blocker #2 / Phase 1 (XP authority).
 *
 * Run from functions/: `node --test`
 *
 * Uses `FakeFirestore` (test_helpers/fake_firestore.js) so the tests
 * exercise the real transaction-shaped code path, not a pure-function
 * stand-in — same reasoning `global_points_reliability.test.js` already
 * documents for this project. This is what actually proves the
 * idempotency/race requirement: a pure-function call twice would prove
 * the *decision* is idempotent without proving the *transaction* that
 * reaches it is race-safe.
 */

const {test} = require("node:test");
const assert = require("node:assert/strict");

const {FakeFirestore} = require("./test_helpers/fake_firestore");
const {
  XP_PER_LEVEL,
  XP_AMOUNTS,
  REWARD_POOL,
  levelFor,
  pendingRewardsFor,
  awardXpFor,
  claimXpRewardFor,
} = require("./award_xp");

const uid = "uXpTest";

async function xpOf(fake, forUid) {
  const snap = await fake.collection("users").doc(forUid).get();
  return (snap.exists && snap.data().xp) || {};
}

// --- Amounts are fixed and server-side, not client-supplied ---

test("legitimate actions grant exactly the amount the table says", async () => {
  const fake = new FakeFirestore();

  const result = await awardXpFor(uid, "wordLearned", {firestore: fake});

  assert.equal(result.granted, XP_AMOUNTS.wordLearned);
  assert.equal((await xpOf(fake, uid)).totalXp, XP_AMOUNTS.wordLearned);
});

test("every documented action type grants its own real amount, additively", async () => {
  const fake = new FakeFirestore();

  await awardXpFor(uid, "wordLearned", {firestore: fake});
  await awardXpFor(uid, "examCompleted", {firestore: fake});
  await awardXpFor(uid, "babGatePassed", {firestore: fake});
  await awardXpFor(uid, "dailyActive", {firestore: fake});

  const expected = XP_AMOUNTS.wordLearned + XP_AMOUNTS.examCompleted +
    XP_AMOUNTS.babGatePassed + XP_AMOUNTS.dailyActive;
  assert.equal((await xpOf(fake, uid)).totalXp, expected);
});

test("an unrecognized action is refused, not defaulted to any amount", async () => {
  const fake = new FakeFirestore();

  await assert.rejects(
      () => awardXpFor(uid, "somethingMadeUp", {firestore: fake}),
      /Unknown XP action/,
  );
  // Nothing was written — a rejected call must not still touch xp.
  assert.deepEqual(await xpOf(fake, uid), {});
});

test("a client-supplied amount has nowhere to go in — awardXpFor takes "
    + "an action name, not a number, so there is no argument position "
    + "left for one", async () => {
  // This is a type-level guarantee more than a runtime one, but confirms
  // passing a raw number as the action is rejected exactly like any
  // other unrecognized string would be, rather than being coerced into
  // an amount.
  const fake = new FakeFirestore();
  await assert.rejects(() => awardXpFor(uid, 999999, {firestore: fake}));
});

// --- Legitimate reward claims still work ---

test("claiming with a pending reward grants one from the pool and "
    + "advances claimedLevel", async () => {
  const fake = new FakeFirestore();
  fake.seed(`users/${uid}`, {xp: {totalXp: XP_PER_LEVEL, claimedLevel: 0}});

  const result = await claimXpRewardFor(uid, {firestore: fake});

  assert.ok(result.reward, "expected a reward, got null");
  assert.ok(["avatar", "frame", "cover"].includes(result.reward.kind));
  const xp = await xpOf(fake, uid);
  assert.equal(xp.claimedLevel, 1);
  const field = REWARD_POOL[result.reward.kind].field;
  assert.ok(xp[field].includes(result.reward.id));
});

test("claiming with nothing pending grants nothing and leaves state "
    + "untouched", async () => {
  const fake = new FakeFirestore();
  fake.seed(`users/${uid}`, {xp: {totalXp: 0, claimedLevel: 0}});

  const result = await claimXpRewardFor(uid, {firestore: fake});

  assert.equal(result.reward, null);
  assert.equal((await xpOf(fake, uid)).claimedLevel, 0);
});

test("an exhausted pool still consumes the pending reward instead of "
    + "staying stuck offering one forever", async () => {
  const fake = new FakeFirestore();
  const everyAdCoinId = [
    ...REWARD_POOL.avatar.ids,
    ...REWARD_POOL.frame.ids,
    ...REWARD_POOL.cover.ids,
  ];
  fake.seed(`users/${uid}`, {
    xp: {
      totalXp: XP_PER_LEVEL,
      claimedLevel: 0,
      unlockedAvatarIds: REWARD_POOL.avatar.ids,
      unlockedFrameIds: REWARD_POOL.frame.ids,
      unlockedCoverIds: REWARD_POOL.cover.ids,
    },
  });
  assert.ok(everyAdCoinId.length > 0, "sanity: pool ids actually exist");

  const result = await claimXpRewardFor(uid, {firestore: fake});

  assert.equal(result.reward, null);
  assert.equal((await xpOf(fake, uid)).claimedLevel, 1);
});

// --- Idempotency / race: duplicate claim must not double-grant ---

test("two claim calls racing on the same pending reward converge to "
    + "exactly one grant, via genuine transaction conflict retry — not "
    + "two independent calls checked separately", async () => {
  const fake = new FakeFirestore();
  fake.seed(`users/${uid}`, {xp: {totalXp: XP_PER_LEVEL, claimedLevel: 0}});

  const [first, second] = await Promise.all([
    claimXpRewardFor(uid, {firestore: fake}),
    claimXpRewardFor(uid, {firestore: fake}),
  ]);

  const grantedCount =
    (first.reward ? 1 : 0) + (second.reward ? 1 : 0);
  assert.equal(grantedCount, 1, "exactly one of the two racing calls must grant a reward");
  assert.equal((await xpOf(fake, uid)).claimedLevel, 1,
      "claimedLevel must advance exactly once, not twice");
});

test("calling claim again after a successful claim, with nothing new "
    + "pending, grants nothing a second time", async () => {
  const fake = new FakeFirestore();
  fake.seed(`users/${uid}`, {xp: {totalXp: XP_PER_LEVEL, claimedLevel: 0}});

  const first = await claimXpRewardFor(uid, {firestore: fake});
  const second = await claimXpRewardFor(uid, {firestore: fake});

  assert.ok(first.reward);
  assert.equal(second.reward, null);
  assert.equal((await xpOf(fake, uid)).claimedLevel, 1);
});

// --- Option A — Premium Exclusive: never granted by the level reward ---

const PREMIUM_ONLY_IDS = [
  // avatars.dart's isPremiumOnly() bucket
  "neko_astronaut", "neko_gamer", "neko_lion",
  // frames.dart's isPremiumOnly() bucket
  "frame_steampunk", "frame_space", "frame_gaming", "frame_moon_crystal",
  // covers.dart's isPremiumOnly() bucket
  "sacred_geometry", "cyber_neon", "outer_space",
];

test("REWARD_POOL never contains a single subscription-exclusive id, "
    + "for any of the three kinds", () => {
  const allPoolIds = [
    ...REWARD_POOL.avatar.ids,
    ...REWARD_POOL.frame.ids,
    ...REWARD_POOL.cover.ids,
  ];
  for (const premiumOnlyId of PREMIUM_ONLY_IDS) {
    assert.ok(
        !allPoolIds.includes(premiumOnlyId),
        `${premiumOnlyId} is subscription-exclusive and must never be `
        + "reachable through the level-up reward pool (Option A)",
    );
  }
});

test("claiming many times in a row, exhausting the entire ad/coin pool, "
    + "never once grants a premium-only id", async () => {
  const fake = new FakeFirestore();
  const totalPoolSize = REWARD_POOL.avatar.ids.length +
    REWARD_POOL.frame.ids.length + REWARD_POOL.cover.ids.length;
  // High enough level to have that many pending rewards.
  fake.seed(`users/${uid}`, {
    xp: {totalXp: (totalPoolSize + 5) * XP_PER_LEVEL, claimedLevel: 0},
  });

  const granted = [];
  for (let i = 0; i < totalPoolSize + 3; i++) {
    // eslint-disable-next-line no-await-in-loop
    const result = await claimXpRewardFor(uid, {firestore: fake});
    if (result.reward) granted.push(result.reward.id);
  }

  assert.equal(granted.length, totalPoolSize,
      "every ad/coin-tier item should have been granted exactly once");
  for (const id of granted) {
    assert.ok(!PREMIUM_ONLY_IDS.includes(id),
        `${id} should never have been grantable`);
  }
});

// --- Ad-tier / coin-tier still work (the pool includes both, not just one) ---

test("the reward pool includes real ad-tier ids", () => {
  // A spot check against the actual catalog ids from
  // lib/core/constants/{avatars,frames,covers}.dart's adIds sets, not
  // invented ones — confirms ad-tier reachability wasn't accidentally
  // dropped while excluding premium-only ids.
  assert.ok(REWARD_POOL.avatar.ids.includes("neko_chef"));
  assert.ok(REWARD_POOL.frame.ids.includes("frame_ocean"));
  assert.ok(REWARD_POOL.cover.ids.includes("coral_reef"));
});

test("the reward pool includes real coin-tier ids", () => {
  assert.ok(REWARD_POOL.avatar.ids.includes("neko_matcha"));
  assert.ok(REWARD_POOL.frame.ids.includes("frame_witch"));
  assert.ok(REWARD_POOL.cover.ids.includes("sumi_ink"));
});

// --- globalPoints stays untouched — a separate, unrelated system ---

test("awarding XP never reads or writes leaderboard/{uid}.globalPoints",
    async () => {
      const fake = new FakeFirestore();
      fake.seed(`leaderboard/${uid}`, {globalPoints: 42});

      await awardXpFor(uid, "examCompleted", {firestore: fake});
      await claimXpRewardFor(uid, {firestore: fake});

      const leaderboardSnap = await fake.collection("leaderboard").doc(uid).get();
      assert.equal(leaderboardSnap.data().globalPoints, 42,
          "globalPoints must be exactly what it was seeded as — untouched");
    });

// --- Formula sanity, matching XpProgress's own Dart-side getters ---

test("levelFor/pendingRewardsFor mirror XpProgress.level/pendingRewards' "
    + "flat-curve formula", () => {
  assert.equal(levelFor(0), 1);
  assert.equal(levelFor(XP_PER_LEVEL - 1), 1);
  assert.equal(levelFor(XP_PER_LEVEL), 2);
  assert.equal(pendingRewardsFor(0, 0), 0);
  assert.equal(pendingRewardsFor(XP_PER_LEVEL, 0), 1);
  assert.equal(pendingRewardsFor(XP_PER_LEVEL, 1), 0);
  assert.equal(pendingRewardsFor(XP_PER_LEVEL * 3, 0), 3);
});

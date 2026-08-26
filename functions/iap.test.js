/**
 * Coverage for `iap.js`'s pure decision functions — `entitlementFor` and
 * `applyExpiry`, the two pieces `verifyPurchase` composes to build the
 * Firestore patch it writes — plus, further down, real behavioral
 * coverage of `claimAndGrant`, the ownership/ledger transaction the
 * Subscription Recovery Architecture added.
 *
 * `verifyPurchase` itself (the `onCall` handler) is still not tested
 * directly: it needs a real Android Publisher response, the same reason
 * `promoteToTierFloor` in `battle_stars.js` has no direct test either —
 * see `rank_skip.test.js`'s own doc comment for the precedent. But
 * `claimAndGrant` — the one piece of `verifyPurchase` that actually
 * touches Firestore — was deliberately split out and given an injectable
 * `options.firestore` seam specifically so it *could* be tested this way,
 * against `test_helpers/fake_firestore.js`'s real optimistic-concurrency
 * double (the same one `global_points_reliability.test.js` already
 * proved this style of test on). First-claim-wins and the two-uid-race
 * guarantee are the two things about the recovery design that source-
 * inspection genuinely cannot prove — only a transaction-shaped test can.
 *
 * Run from functions/: `node --test`
 */

const test = require("node:test");
const assert = require("node:assert");

const {entitlementFor, applyExpiry, claimAndGrant} = require("./iap");
const {FakeFirestore} = require("./test_helpers/fake_firestore");

const PREMIUM = "teisou_premium_monthly";

test("a premium purchase patch carries tier and purchasedAt", () => {
  const patch = entitlementFor(PREMIUM);
  assert.strictEqual(patch.subscription.tier, "premium");
  assert.ok(patch.subscription.purchasedAt, "purchasedAt must be set");
  assert.strictEqual(
      patch.subscription.expiresAt,
      undefined,
      "entitlementFor alone must never set expiresAt — that is applyExpiry's job",
  );
});

test("a skin purchase patch is unrelated to subscription/expiry", () => {
  const patch = entitlementFor("skin_cloud_white");
  assert.ok(patch.entitlements.skins, "arrayUnion sentinel must be set");
  assert.strictEqual(patch.subscription, undefined);
});

test("an unknown product id returns null, not a guess", () => {
  assert.strictEqual(entitlementFor("something_nobody_sells"), null);
});

test("applyExpiry adds a real expiry to a premium patch", () => {
  const patch = entitlementFor(PREMIUM);
  const playResponse = {
    lineItems: [{expiryTime: "2026-09-24T10:00:00.000Z"}],
  };
  const result = applyExpiry(patch, PREMIUM, playResponse);
  assert.strictEqual(result, patch, "mutates and returns the same object");
  assert.ok(patch.subscription.expiresAt instanceof Date);
  assert.strictEqual(
      patch.subscription.expiresAt.toISOString(),
      "2026-09-24T10:00:00.000Z",
  );
  // tier/purchasedAt must survive untouched alongside the new expiresAt.
  assert.strictEqual(patch.subscription.tier, "premium");
  assert.ok(patch.subscription.purchasedAt);
});

test("applyExpiry never writes expiresAt: null when Play's response has "
    + "no parseable expiry", () => {
  const patch = entitlementFor(PREMIUM);
  applyExpiry(patch, PREMIUM, {lineItems: []});
  assert.strictEqual(
      Object.prototype.hasOwnProperty.call(patch.subscription, "expiresAt"),
      false,
      "the key must be absent, not present-and-null — a downstream " +
      "set(..., {merge: true}) must never clobber a previously-known " +
      "expiresAt with nothing",
  );
});

test("applyExpiry is a no-op for a malformed Play response", () => {
  const patch = entitlementFor(PREMIUM);
  for (const bad of [null, undefined, {}, {lineItems: "nope"}]) {
    applyExpiry(patch, PREMIUM, bad);
    assert.strictEqual(
        Object.prototype.hasOwnProperty.call(patch.subscription, "expiresAt"),
        false,
    );
  }
});

test("applyExpiry never touches a non-subscription patch", () => {
  const skinPatch = entitlementFor("skin_neon_city");
  const before = JSON.stringify(skinPatch);
  applyExpiry(skinPatch, "skin_neon_city", {
    lineItems: [{expiryTime: "2026-09-24T10:00:00.000Z"}],
  });
  assert.strictEqual(JSON.stringify(skinPatch), before);
});

/**
 * `claimAndGrant` — the Subscription Recovery Architecture's ownership
 * ledger, tested against `FakeFirestore`'s real transaction semantics
 * rather than just the decision logic. See this test's own file-level
 * doc comment for why this specific function gets a behavioral test
 * where `verifyPurchase` itself still doesn't.
 */
const UID_A = "uid-first-claimant";
const UID_B = "uid-second-claimant";
const TOKEN = "token-xyz";

test("claimAndGrant: a Play-vouched purchase (bindingStatus 'granted') "
    + "grants and writes the entitlement patch — scenario 3, active + "
    + "current UID", async () => {
  const fake = new FakeFirestore();
  const patch = entitlementFor(PREMIUM);
  const result = await claimAndGrant({
    uid: UID_A, productId: PREMIUM, purchaseToken: TOKEN, patch,
    bindingStatus: "granted",
  }, {firestore: fake});

  assert.strictEqual(result.granted, true);
  assert.strictEqual(result.firstGrant, true);
  assert.strictEqual(result.deniedReason, null);
  const userDoc = fake.docs.get(`users/${UID_A}`);
  assert.strictEqual(userDoc.data.subscription.tier, "premium");
  const tokenDoc = fake.docs.get(`processedPurchaseTokens/${TOKEN}`);
  assert.strictEqual(tokenDoc.data.uid, UID_A);
  assert.strictEqual(tokenDoc.data.claimedVia, "account-match");
});

// Scenario 1: active + missing binding → first claimant gets Premium.
test("claimAndGrant: an unbound token grants to whichever uid claims it "
    + "first, recorded as 'first-claim'", async () => {
  const fake = new FakeFirestore();
  const patch = entitlementFor(PREMIUM);
  const result = await claimAndGrant({
    uid: UID_A, productId: PREMIUM, purchaseToken: TOKEN, patch,
    bindingStatus: "unbound",
  }, {firestore: fake});

  assert.strictEqual(result.granted, true);
  assert.strictEqual(result.firstGrant, true);
  const tokenDoc = fake.docs.get(`processedPurchaseTokens/${TOKEN}`);
  assert.strictEqual(tokenDoc.data.uid, UID_A);
  assert.strictEqual(tokenDoc.data.claimedVia, "first-claim");
  assert.strictEqual(
      fake.docs.get(`users/${UID_A}`).data.subscription.tier,
      "premium",
  );
});

// Scenario 2: active + old UID. A second, different uid must never be
// able to take over a token someone else already claimed — this is the
// exact rule that keeps first-claim-wins from becoming a cloning bug.
test("claimAndGrant: a SECOND uid claiming the SAME already-claimed "
    + "unbound token is denied, and its own user doc is left untouched",
    async () => {
  const fake = new FakeFirestore();
  const patchA = entitlementFor(PREMIUM);
  await claimAndGrant({
    uid: UID_A, productId: PREMIUM, purchaseToken: TOKEN, patch: patchA,
    bindingStatus: "unbound",
  }, {firestore: fake});

  const patchB = entitlementFor(PREMIUM);
  const result = await claimAndGrant({
    uid: UID_B, productId: PREMIUM, purchaseToken: TOKEN, patch: patchB,
    bindingStatus: "unbound",
  }, {firestore: fake});

  assert.strictEqual(result.granted, false);
  assert.strictEqual(result.firstGrant, false);
  assert.strictEqual(result.deniedReason, "account_mismatch");
  assert.strictEqual(
      fake.docs.has(`users/${UID_B}`),
      false,
      "a denied claim must never write anything to the denied uid's own document",
  );
  // The original claimant's grant must survive the second uid's attempt
  // completely untouched.
  assert.strictEqual(
      fake.docs.get(`users/${UID_A}`).data.subscription.tier,
      "premium",
  );
  assert.strictEqual(
      fake.docs.get(`processedPurchaseTokens/${TOKEN}`).data.uid,
      UID_A,
  );
});

test("claimAndGrant: the SAME uid re-verifying an already-claimed token "
    + "is idempotent — granted again, but not a second firstGrant",
    async () => {
  const fake = new FakeFirestore();
  await claimAndGrant({
    uid: UID_A, productId: PREMIUM, purchaseToken: TOKEN,
    patch: entitlementFor(PREMIUM), bindingStatus: "unbound",
  }, {firestore: fake});

  const second = await claimAndGrant({
    uid: UID_A, productId: PREMIUM, purchaseToken: TOKEN,
    patch: entitlementFor(PREMIUM), bindingStatus: "unbound",
  }, {firestore: fake});

  assert.strictEqual(second.granted, true);
  assert.strictEqual(
      second.firstGrant,
      false,
      "re-verifying an already-owned token must not report a fresh grant",
  );
});

// Scenario 7: concurrent first-claim → exactly one winner. Two different
// uids race to claim the SAME unbound token — forced into a genuine
// mid-transaction interleaving via FakeFirestore's beforeCommit hook
// (the same technique global_points_reliability.test.js already proved
// this style of test on), rather than hoping Node's own scheduling
// happens to interleave two plain `await`ed calls usefully.
test("claimAndGrant: two concurrent first-claims on the same unbound "
    + "token — exactly one wins, the other is denied, no double-grant",
    async () => {
      let firstTransactionStarted = false;
      const fake = new FakeFirestore({
        beforeCommit: async () => {
          // Let transaction A's read-then-decide run, pause exactly once
          // right before either commits, and give transaction B a chance
          // to run its OWN read (which — because A hasn't committed yet
          // — still sees no token) before A actually commits. This is
          // what forces a genuine conflict rather than two transactions
          // that just happen to run back-to-back.
          if (!firstTransactionStarted) {
            firstTransactionStarted = true;
            await new Promise((resolve) => setTimeout(resolve, 5));
          }
        },
      });

      const [resultA, resultB] = await Promise.all([
        claimAndGrant({
          uid: UID_A, productId: PREMIUM, purchaseToken: TOKEN,
          patch: entitlementFor(PREMIUM), bindingStatus: "unbound",
        }, {firestore: fake}),
        claimAndGrant({
          uid: UID_B, productId: PREMIUM, purchaseToken: TOKEN,
          patch: entitlementFor(PREMIUM), bindingStatus: "unbound",
        }, {firestore: fake}),
      ]);

      const outcomes = [resultA, resultB];
      const winners = outcomes.filter((r) => r.granted);
      const losers = outcomes.filter((r) => !r.granted);
      assert.strictEqual(
          winners.length,
          1,
          "exactly one of the two concurrent claims must win",
      );
      assert.strictEqual(losers.length, 1);
      assert.strictEqual(losers[0].deniedReason, "account_mismatch");

      // Firestore's own ledger must agree with whichever result object
      // says it won — the two must never disagree.
      const tokenDoc = fake.docs.get(`processedPurchaseTokens/${TOKEN}`);
      const winnerUid = winners[0] === resultA ? UID_A : UID_B;
      assert.strictEqual(tokenDoc.data.uid, winnerUid);
      assert.strictEqual(
          fake.docs.get(`users/${winnerUid}`).data.subscription.tier,
          "premium",
      );
      const loserUid = winnerUid === UID_A ? UID_B : UID_A;
      assert.strictEqual(
          fake.docs.has(`users/${loserUid}`),
          false,
          "the losing claim must never have written the loser's own document",
      );
    });

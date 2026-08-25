/**
 * Coverage for `iap.js`'s pure decision functions — `entitlementFor` and
 * `applyExpiry`, the two pieces `verifyPurchase` composes to build the
 * Firestore patch it writes. `verifyPurchase` itself (the `onCall`
 * handler) is not tested here: it needs a live Firestore transaction and
 * a real Android Publisher response, the same reason `promoteToTierFloor`
 * in `battle_stars.js` has no direct test either — see
 * `rank_skip.test.js`'s own doc comment for the precedent. What's tested
 * here is exactly the part that decides what `tier`/`purchasedAt`/
 * `expiresAt` end up being, which is where a real mistake would actually
 * hide.
 *
 * Run from functions/: `node --test`
 */

const test = require("node:test");
const assert = require("node:assert");

const {entitlementFor, applyExpiry} = require("./iap");

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

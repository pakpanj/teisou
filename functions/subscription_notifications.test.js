const test = require("node:test");
const assert = require("node:assert");

const {
  extractSubscriptionToken,
  buildSubscriptionPatch,
} = require("./subscription_notifications");

/**
 * `extractSubscriptionToken` and `buildSubscriptionPatch` are the parts
 * of the RTDN handler worth unit testing without a Pub/Sub emulator and
 * a live Android Publisher API — the decision of *whether* a token is
 * still active is "ask Play, trust `subscriptionGrants`", already
 * covered by `iap_states.test.js`; `buildSubscriptionPatch` only ever
 * gets a plain `active` boolean plus Play's raw response and turns that
 * into the exact object written to Firestore.
 */

test("a real subscription notification yields its purchase token", () => {
  const message = {
    version: "1.0",
    packageName: "com.teisou.kanamaster",
    eventTimeMillis: "1700000000000",
    subscriptionNotification: {
      version: "1.0",
      notificationType: 3,
      purchaseToken: "a-real-token",
      subscriptionId: "teisou_premium_monthly",
    },
  };
  assert.strictEqual(extractSubscriptionToken(message), "a-real-token");
});

test("Play's own \"send test notification\" button carries no token", () => {
  const message = {
    version: "1.0",
    packageName: "com.teisou.kanamaster",
    eventTimeMillis: "1700000000000",
    testNotification: {version: "1.0"},
  };
  assert.strictEqual(extractSubscriptionToken(message), null);
});

test("a one-time-product notification is not mistaken for a subscription "
    + "one", () => {
  const message = {
    version: "1.0",
    packageName: "com.teisou.kanamaster",
    eventTimeMillis: "1700000000000",
    oneTimeProductNotification: {
      version: "1.0",
      notificationType: 1,
      purchaseToken: "coin-pack-token",
      sku: "teisou_coins_100",
    },
  };
  assert.strictEqual(extractSubscriptionToken(message), null);
});

test("a malformed or empty message never throws", () => {
  assert.strictEqual(extractSubscriptionToken(null), null);
  assert.strictEqual(extractSubscriptionToken(undefined), null);
  assert.strictEqual(extractSubscriptionToken({}), null);
  assert.strictEqual(
    extractSubscriptionToken({subscriptionNotification: {}}),
    null,
  );
});

test("an active subscription's patch carries tier, updatedAt, and expiresAt",
    () => {
      const patch = buildSubscriptionPatch(true, {
        lineItems: [{expiryTime: "2026-09-24T10:00:00.000Z"}],
      });
      assert.strictEqual(patch.tier, "premium");
      assert.ok(patch.updatedAt, "updatedAt must be set");
      assert.ok(patch.expiresAt instanceof Date);
      assert.strictEqual(
          patch.expiresAt.toISOString(),
          "2026-09-24T10:00:00.000Z",
      );
    });

test("a lapsed subscription's patch still carries whatever expiry Play "
    + "reports — the date itself is honest either way", () => {
  const patch = buildSubscriptionPatch(false, {
    lineItems: [{expiryTime: "2026-09-24T10:00:00.000Z"}],
  });
  assert.strictEqual(patch.tier, "free");
  assert.ok(patch.expiresAt instanceof Date);
});

test("buildSubscriptionPatch never writes expiresAt: null when Play's "
    + "response has no parseable expiry", () => {
  for (const response of [null, undefined, {}, {lineItems: []}]) {
    const patch = buildSubscriptionPatch(true, response);
    assert.strictEqual(patch.tier, "premium");
    assert.ok(patch.updatedAt);
    assert.strictEqual(
        Object.prototype.hasOwnProperty.call(patch, "expiresAt"),
        false,
        "the key must be absent, not present-and-null — a downstream " +
        "set(..., {merge: true}) must never clobber a previously-known " +
        "expiresAt with nothing",
    );
  }
});

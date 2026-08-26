const test = require("node:test");
const assert = require("node:assert");

const {
  extractSubscriptionToken,
  buildSubscriptionPatch,
  isStillActive,
} = require("./subscription_notifications");

const UID = "uid-abc";

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

/**
 * `isStillActive` — the Subscription Recovery Architecture's fix for a
 * real bug caught while wiring first-claimed (unbound) subscriptions
 * into this RTDN handler: naively reusing `subscriptionGrants` for that
 * case always reads `false` (Play's own record has no account id to
 * match against for an unbound token, by definition), which would have
 * silently downgraded a first-claimed subscriber to `tier: "free"` on
 * their very first renewal notification. These tests exist specifically
 * to keep that regression from coming back.
 */
test("isStillActive: firstClaimed + a granting state reads active, even "
    + "though Play's own record has no account id at all", () => {
  assert.strictEqual(
      isStillActive({subscriptionState: "SUBSCRIPTION_STATE_ACTIVE"}, {
        firstClaimed: true, uid: UID,
      }),
      true,
  );
  assert.strictEqual(
      isStillActive(
          {subscriptionState: "SUBSCRIPTION_STATE_IN_GRACE_PERIOD"},
          {firstClaimed: true, uid: UID},
      ),
      true,
  );
});

test("isStillActive: firstClaimed + a non-granting state reads inactive",
    () => {
      for (const subscriptionState of [
        "SUBSCRIPTION_STATE_CANCELED",
        "SUBSCRIPTION_STATE_EXPIRED",
        "SUBSCRIPTION_STATE_ON_HOLD",
        "SUBSCRIPTION_STATE_PAUSED",
      ]) {
        assert.strictEqual(
            isStillActive({subscriptionState}, {firstClaimed: true, uid: UID}),
            false,
            subscriptionState,
        );
      }
    });

test("isStillActive: NOT firstClaimed delegates to subscriptionGrants "
    + "unchanged — an account id that matches still grants, one that "
    + "doesn't still refuses", () => {
  assert.strictEqual(
      isStillActive({
        subscriptionState: "SUBSCRIPTION_STATE_ACTIVE",
        externalAccountIdentifiers: {obfuscatedExternalAccountId: UID},
      }, {firstClaimed: false, uid: UID}),
      true,
  );
  assert.strictEqual(
      isStillActive({
        subscriptionState: "SUBSCRIPTION_STATE_ACTIVE",
        externalAccountIdentifiers: {obfuscatedExternalAccountId: "someone-else"},
      }, {firstClaimed: false, uid: UID}),
      false,
  );
});

test("isStillActive: the regression this exists to catch — firstClaimed "
    + "must never be routed through subscriptionGrants, or an active "
    + "first-claimed subscriber reads as inactive on every renewal",
    () => {
      // Same response, same uid, only `firstClaimed` differs — proves the
      // branch itself is what matters, not some other input.
      const response = {subscriptionState: "SUBSCRIPTION_STATE_ACTIVE"};
      assert.strictEqual(
          isStillActive(response, {firstClaimed: true, uid: UID}),
          true,
          "firstClaimed must read active from subscriptionState alone",
      );
      assert.strictEqual(
          isStillActive(response, {firstClaimed: false, uid: UID}),
          false,
          "the non-firstClaimed path is correctly false here — no account " +
          "id on this response at all — confirming the two paths really " +
          "do disagree, and firstClaimed is what's picking the right one",
      );
    });

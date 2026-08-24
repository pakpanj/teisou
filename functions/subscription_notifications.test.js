const test = require("node:test");
const assert = require("node:assert");

const {extractSubscriptionToken} = require("./subscription_notifications");

/**
 * `extractSubscriptionToken` is the only part of the RTDN handler worth
 * unit testing without a Pub/Sub emulator and a live Android Publisher
 * API — everything past it is "ask Play, trust `subscriptionGrants`",
 * already covered by `iap_states.test.js`.
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

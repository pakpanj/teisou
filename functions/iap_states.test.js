const test = require("node:test");
const assert = require("node:assert");

const {subscriptionGrants, productGrants} = require("./iap_states");

const UID = "uid-abc";
const other = "uid-someone-else";

test("an active subscription bought by this account grants", () => {
  assert.strictEqual(
      subscriptionGrants({
        subscriptionState: "SUBSCRIPTION_STATE_ACTIVE",
        externalAccountIdentifiers: {obfuscatedExternalAccountId: UID},
      }, UID),
      true,
  );
});

test("a grace-period subscription still grants", () => {
  // Google is retrying a failed payment. Locking someone out over a card
  // that will probably go through is the worse of the two errors.
  assert.strictEqual(
      subscriptionGrants({
        subscriptionState: "SUBSCRIPTION_STATE_IN_GRACE_PERIOD",
        externalAccountIdentifiers: {obfuscatedExternalAccountId: UID},
      }, UID),
      true,
  );
});

test("expired, on hold, paused and canceled do not grant", () => {
  for (const state of [
    "SUBSCRIPTION_STATE_EXPIRED",
    "SUBSCRIPTION_STATE_ON_HOLD",
    "SUBSCRIPTION_STATE_PAUSED",
    "SUBSCRIPTION_STATE_CANCELED",
    "SUBSCRIPTION_STATE_PENDING",
    "SUBSCRIPTION_STATE_UNSPECIFIED",
  ]) {
    assert.strictEqual(
        subscriptionGrants({
          subscriptionState: state,
          externalAccountIdentifiers: {obfuscatedExternalAccountId: UID},
        }, UID),
        false,
        state,
    );
  }
});

/**
 * The replay hole. Without the account check a single real purchase
 * token works for every account that sends it — one payment, unlimited
 * premium — and nothing about that looks wrong from either side.
 */
test("another account's token does not grant, however valid it is", () => {
  assert.strictEqual(
      subscriptionGrants({
        subscriptionState: "SUBSCRIPTION_STATE_ACTIVE",
        externalAccountIdentifiers: {obfuscatedExternalAccountId: other},
      }, UID),
      false,
  );
});

test("a token with no account attached is refused, not trusted", () => {
  // These exist — anything bought before the app started sending an
  // account id. "Unknown buyer" must never read as "this buyer".
  assert.strictEqual(
      subscriptionGrants({
        subscriptionState: "SUBSCRIPTION_STATE_ACTIVE",
      }, UID),
      false,
  );
  assert.strictEqual(
      subscriptionGrants({
        subscriptionState: "SUBSCRIPTION_STATE_ACTIVE",
        externalAccountIdentifiers: {},
      }, UID),
      false,
  );
});

test("a malformed or empty response never grants", () => {
  for (const response of [null, undefined, "", 0, []]) {
    assert.strictEqual(subscriptionGrants(response, UID), false);
    assert.strictEqual(productGrants(response, UID), false);
  }
});

test("a purchased, unconsumed product bought by this account grants", () => {
  assert.strictEqual(
      productGrants({
        purchaseState: 0,
        consumptionState: 0,
        obfuscatedExternalAccountId: UID,
      }, UID),
      true,
  );
});

test("a pending or cancelled product does not grant", () => {
  for (const purchaseState of [1, 2]) {
    assert.strictEqual(
        productGrants({
          purchaseState,
          obfuscatedExternalAccountId: UID,
        }, UID),
        false,
        `purchaseState ${purchaseState}`,
    );
  }
});

test("a consumed product does not grant", () => {
  // Nothing here is consumable, so this state means something is wrong
  // and "no" is the safe reading.
  assert.strictEqual(
      productGrants({
        purchaseState: 0,
        consumptionState: 1,
        obfuscatedExternalAccountId: UID,
      }, UID),
      false,
  );
});

test("a product token from another account does not grant", () => {
  assert.strictEqual(
      productGrants({
        purchaseState: 0,
        obfuscatedExternalAccountId: other,
      }, UID),
      false,
  );
});

/**
 * When Google's answer about a purchase means "give them the thing".
 *
 * Split out from `iap.js` so the decision is testable without a network
 * call, a service account, or a Play Console. **This is the part that
 * decides whether money turns into an entitlement**, and it is a set of
 * string comparisons — exactly the kind of code that is easy to get
 * subtly wrong and impossible to notice, because both mistakes look like
 * the app working: too permissive grants for free, too strict tells a
 * paying customer their purchase failed.
 */

/**
 * Subscription states Google reports, and which of them entitle.
 *
 * `IN_GRACE_PERIOD` grants deliberately: the subscription is still
 * active, Google is retrying a failed payment, and locking someone out
 * mid-renewal over a card that will probably go through is a worse
 * error than a few days of access. `ON_HOLD`, `PAUSED`, `EXPIRED` and
 * `CANCELED` do not — note that Google reports a subscription the user
 * has cancelled but not yet reached the end of as ACTIVE, so a
 * cancellation does not cut anyone off early.
 */
const GRANTING_SUBSCRIPTION_STATES = new Set([
  "SUBSCRIPTION_STATE_ACTIVE",
  "SUBSCRIPTION_STATE_IN_GRACE_PERIOD",
]);

/** `purchaseState` on a one-time product: 0 purchased, 2 pending. */
const PRODUCT_PURCHASED = 0;

/**
 * Whether a `purchases.subscriptionsv2.get` response entitles [uid].
 *
 * The account check is not paranoia: without it one real purchase token
 * could be replayed by any number of accounts, each getting premium from
 * a single payment. The client sends its uid as the obfuscated account
 * id when buying, and this is where that promise is actually kept.
 *
 * A token that carries **no** account id is refused rather than trusted.
 * Those exist — purchases made before this app started sending one — and
 * treating "unknown buyer" as "this buyer" is the whole hole again.
 */
function subscriptionGrants(response, uid) {
  if (!response || typeof response !== "object") return false;
  if (!GRANTING_SUBSCRIPTION_STATES.has(response.subscriptionState)) {
    return false;
  }
  // Boolean(), not a bare `&&` chain: with no identifiers block this
  // returned `undefined`, which is falsy enough for an `if` and is not
  // `false` to a caller that compares. Caught by the test that feeds it
  // a token with no account attached.
  return Boolean(
      response.externalAccountIdentifiers &&
      response.externalAccountIdentifiers.obfuscatedExternalAccountId === uid,
  );
}

/**
 * Whether a `purchases.products.get` response entitles [uid].
 *
 * Same account rule, plus one more: a product Google reports as consumed
 * is not owned any more. Nothing this app sells is consumable, so seeing
 * that means something is wrong and the safe reading is "no".
 */
function productGrants(response, uid) {
  if (!response || typeof response !== "object") return false;
  if (response.purchaseState !== PRODUCT_PURCHASED) return false;
  if (response.consumptionState === 1) return false;
  return response.obfuscatedExternalAccountId === uid;
}

module.exports = {
  GRANTING_SUBSCRIPTION_STATES,
  PRODUCT_PURCHASED,
  subscriptionGrants,
  productGrants,
};

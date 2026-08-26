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

/**
 * The subscription's own expiry, read from a `purchases.subscriptionsv2.get`
 * response — pure metadata, never consulted by [subscriptionGrants] to
 * decide entitlement. `subscriptionState` alone stays the only source of
 * truth for whether a purchase grants; this exists only so
 * `subscription.expiresAt` has something honest to show a learner
 * ("renews on..."/"expired on...").
 *
 * `lineItems` is an array because Play's API supports multi-line
 * subscriptions (add-ons); this app sells exactly one base plan with no
 * add-ons, so `lineItems[0]` is assumed to be the only entry — worth
 * re-checking here if that ever changes.
 *
 * Returns `null` for anything that isn't a real, parseable date —
 * missing `lineItems`, a missing/non-string `expiryTime`, or a string
 * that parses to `Invalid Date` — so a caller can tell "no expiry known"
 * apart from "expiry is right now", and is never tempted to write a
 * bogus date over a previously-known-good one. Callers must not write
 * this value into Firestore when it's `null`; see `iap.js`/
 * `subscription_notifications.js`'s own comments at their write sites
 * for why a missing expiry must never overwrite one already stored.
 */
function expiryFromResponse(response) {
  const item = response && Array.isArray(response.lineItems) ?
    response.lineItems[0] : null;
  const raw = item && item.expiryTime;
  if (typeof raw !== "string") return null;
  const date = new Date(raw);
  return Number.isNaN(date.getTime()) ? null : date;
}

/**
 * Whether a subscription response that did **not** grant looks like Play
 * still catching up on a purchase that just happened, rather than a real
 * rejection — the propagation race documented on `verifyWithPlay` in
 * `iap.js`: `subscriptionsv2.get`, asked seconds after checkout, can
 * briefly report no state at all, `PENDING`, or a granting state with no
 * `externalAccountIdentifiers` attached yet.
 *
 * **This never feeds back into [subscriptionGrants] and never changes what
 * it decides.** It answers a different question — "is it worth asking
 * Play again in a moment" — not "does this grant". A subscription Play
 * has definitively reported `CANCELED`/`EXPIRED`/`ON_HOLD`/`PAUSED`, or an
 * `ACTIVE` one bought by a different account, is not retryable: asking
 * again cannot change either answer, and retrying an account mismatch
 * would just give a replayed token more chances to be accepted.
 */
const RETRYABLE_SUBSCRIPTION_STATES = new Set([
  undefined,
  null,
  "",
  "SUBSCRIPTION_STATE_UNSPECIFIED",
  "SUBSCRIPTION_STATE_PENDING",
]);

function isRetryablePlayState(response) {
  if (!response || typeof response !== "object" || Array.isArray(response)) {
    return false;
  }
  const state = response.subscriptionState;
  if (RETRYABLE_SUBSCRIPTION_STATES.has(state)) return true;
  if (GRANTING_SUBSCRIPTION_STATES.has(state)) {
    // A state that would otherwise grant, but the account link hasn't
    // landed yet — the purchase itself is real, Play just hasn't
    // attached the buyer identity to this record yet.
    const hasAccountId = Boolean(
        response.externalAccountIdentifiers &&
        response.externalAccountIdentifiers.obfuscatedExternalAccountId,
    );
    return !hasAccountId;
  }
  return false;
}

/**
 * The three ways a subscription's Play-side account binding can relate
 * to the account asking to verify it — see [classifyAccountBinding].
 * Kept as a plain string enum (matching this file's existing style
 * elsewhere, e.g. the subscription-state set above) rather than a class,
 * since the only thing a caller ever does with one is compare it.
 */
const AccountBinding = Object.freeze({
  /** Play's own `obfuscatedExternalAccountId` equals the asking uid —
   * exactly [subscriptionGrants]'s existing check. Always safe to grant;
   * Play itself is the authority here. */
  MATCHED: "matched",
  /** Play has no account id on this token at all — a purchase made
   * before this app started sending one (or a Play Console test
   * purchase that never went through this app's own buy flow), OR a
   * brand-new purchase Play hasn't propagated the id to yet. The two
   * cannot be told apart from a single response; see `iap.js`'s
   * `verifyWithPlay` for how the short retry window (genuine propagation
   * lag) is separated from the permanent case (first-claim resolution,
   * `iap.js`'s `claimAndGrant`). */
  UNBOUND: "unbound",
  /** Play's own account id is present and belongs to someone else. This
   * is Play's own record, set once at the original purchase and never
   * rewritable by this app afterwards — a **permanent, definitive**
   * answer, never eligible for a retry or a first-claim. Restoring a
   * purchase can never re-bind it to a new uid; only Firebase Auth
   * identity (linking the same Google account back) can get the asking
   * party back to the uid Play already vouches for. */
  MISMATCHED: "mismatched",
});

/**
 * Classifies a `purchases.subscriptionsv2.get` response's account
 * binding against [uid] — the decision [subscriptionGrants] already
 * makes internally, exposed as its own three-way verdict so callers
 * that need to react differently to "never bound" vs. "bound to someone
 * else" (rather than collapsing both into a plain `false`) can.
 *
 * Deliberately does **not** look at `subscriptionState` at all — that is
 * an orthogonal question ([GRANTING_SUBSCRIPTION_STATES]/
 * [subscriptionGrants] already answer it) and mixing the two here would
 * make this impossible to reason about independently. A caller that
 * needs "does this grant, accounting for both facts" should keep using
 * [subscriptionGrants]; this function answers "whose token is this",
 * nothing else.
 */
function classifyAccountBinding(response, uid) {
  const accountId = response && response.externalAccountIdentifiers &&
      response.externalAccountIdentifiers.obfuscatedExternalAccountId;
  if (!accountId) return AccountBinding.UNBOUND;
  return accountId === uid ? AccountBinding.MATCHED : AccountBinding.MISMATCHED;
}

module.exports = {
  GRANTING_SUBSCRIPTION_STATES,
  PRODUCT_PURCHASED,
  AccountBinding,
  subscriptionGrants,
  productGrants,
  expiryFromResponse,
  isRetryablePlayState,
  classifyAccountBinding,
};

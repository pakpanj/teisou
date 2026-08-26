const {onMessagePublished} = require("firebase-functions/v2/pubsub");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");

const {
  subscriptionGrants,
  expiryFromResponse,
  GRANTING_SUBSCRIPTION_STATES,
} = require("./iap_states");
const {publisher, ANDROID_PACKAGE, playConfigured} = require("./iap");

/**
 * Keeping `subscription.tier` honest after the sale.
 *
 * **The gap this closes**: `verifyPurchase` only ever checks Play once,
 * at the moment of purchase, and then never again. A learner who cancels,
 * or whose card fails to renew, stays `tier: "premium"` in Firestore
 * forever — nothing was watching for either to happen. Play's answer is
 * Real-time Developer Notifications (RTDN): a Pub/Sub message the moment
 * a subscription's state changes, which this function listens for.
 *
 * **Deliberately does not switch on the notification's `notificationType`
 * (SUBSCRIPTION_CANCELED, _EXPIRED, _RENEWED, ...).** That enum is long,
 * easy to get subtly wrong, and duplicates a decision this codebase
 * already has one true answer for. Instead the notification is treated
 * as nothing more than a prompt to re-ask Play "is this purchase token
 * still active right now?" via the exact same `subscriptions.get` call
 * and the exact same [subscriptionGrants] boolean `verifyPurchase`
 * itself trusts — so a cancellation, an expiry, a failed renewal, a
 * recovered payment, a plan change, all converge on one code path
 * instead of needing their own case.
 *
 * **The topic name (`play-store-rtdn`) has to match Play Console.**
 * Firebase creates the Pub/Sub topic automatically on deploy (an
 * `onMessagePublished` trigger provisions it if missing), but Play only
 * ever publishes to it once Play Console → Monetize → Monetization
 * setup → Real-time developer notifications is pointed at this exact
 * topic name, and Play's own publisher service account is granted
 * permission to publish to it — both console-side steps, not something
 * this file can do. See the setup guide handed to the user alongside
 * this file.
 */

const RTDN_TOPIC = "play-store-rtdn";

/**
 * The subscription purchase token inside a raw RTDN message, or null for
 * every message shape that isn't a subscription state change — Play's
 * "send test notification" button posts `{testNotification: {...}}`
 * with no token at all, and a one-time product uses
 * `oneTimeProductNotification` instead (irrelevant here: nothing this
 * app sells as a one-time product is a subscription). Split out as its
 * own pure function so the parsing is testable without a Pub/Sub
 * emulator — same reasoning `iap_states.js` already documents for
 * keeping decision logic out of the HTTP/event plumbing.
 */
function extractSubscriptionToken(messageJson) {
  const sub = messageJson && messageJson.subscriptionNotification;
  return sub && typeof sub.purchaseToken === "string"
    ? sub.purchaseToken
    : null;
}

/**
 * The `subscription` patch this handler writes, given whether the token
 * is still active and Play's own response to re-derive an expiry from.
 * Split out as its own pure function — same reasoning as
 * [extractSubscriptionToken] above — so `tier`/`updatedAt`/`expiresAt`
 * consistency is testable without a live Firestore or Pub/Sub emulator.
 *
 * **Never sets `expiresAt: null`.** When [expiryFromResponse] can't find
 * a valid one, the key is left out of the patch entirely — the
 * downstream `set(..., {merge: true})` then leaves whatever
 * `subscription.expiresAt` was already stored completely untouched,
 * rather than clobbering a previously-known-good date with nothing. This
 * mirrors `iap.js`'s [applyExpiry] exactly, for the same reason.
 */
function buildSubscriptionPatch(active, response) {
  const patch = {
    tier: active ? "premium" : "free",
    updatedAt: FieldValue.serverTimestamp(),
  };
  const expiresAt = expiryFromResponse(response);
  if (expiresAt) patch.expiresAt = expiresAt;
  return patch;
}

/**
 * Whether a subscription Play just reported should still read as active,
 * for the specific `externalId` this notification is about to write to.
 * Split out as its own pure function — same reasoning as
 * [extractSubscriptionToken]/[buildSubscriptionPatch] above.
 *
 * **`firstClaimed: true` is the one case that must NOT delegate to
 * [subscriptionGrants].** That function re-checks Play's own account id
 * against the uid it's given — correct when `externalId` came straight
 * off Play's response (`firstClaimed: false`, it trivially matches
 * itself), but for a token this app first-claimed via `iap.js`'s
 * `claimAndGrant` (see that function's own doc comment), Play's record
 * has **no** account id at all, so `subscriptionGrants` would always
 * read `false` there and silently write `tier: "free"` on every renewal
 * of a subscription this app itself already granted — a real bug caught
 * while building this, not a hypothetical one. For that case, whether it
 * still grants is answered by `subscriptionState` alone; ownership was
 * already decided once, at claim time, and is not re-litigated here.
 */
function isStillActive(response, {firstClaimed, uid}) {
  return firstClaimed
    ? GRANTING_SUBSCRIPTION_STATES.has(response && response.subscriptionState)
    : subscriptionGrants(response, uid);
}

exports.onPlayRtdn = onMessagePublished(RTDN_TOPIC, async (event) => {
  if (!playConfigured()) {
    // Same fail-closed posture as verifyPurchase, mirrored the other
    // direction: if Play verification was never switched on for this
    // project, there is no Android Publisher access to re-check with,
    // so this must not guess either way.
    return;
  }

  let messageJson;
  try {
    messageJson = event.data.message.json;
  } catch (_) {
    // Not valid JSON — nothing to act on.
    return;
  }

  const purchaseToken = extractSubscriptionToken(messageJson);
  if (!purchaseToken) return;

  const api = publisher();
  let response;
  try {
    response = await api.purchases.subscriptionsv2.get({
      packageName: ANDROID_PACKAGE,
      token: purchaseToken,
    });
  } catch (_) {
    // An unrecognised or expired token — nothing in Firestore to
    // reconcile against it.
    return;
  }

  const boundId = response.data
    && response.data.externalAccountIdentifiers
    && response.data.externalAccountIdentifiers.obfuscatedExternalAccountId;

  let externalId = boundId;
  let firstClaimed = false;

  if (!externalId) {
    // No uid attached on Play's own record means this purchase predates
    // the app sending one (see `subscriptionGrants`'s own doc comment) —
    // Play itself has no opinion on whose it is. This handler never
    // *creates* a first-claim binding on its own (it has no notion of
    // "who is asking right now" the way `verifyPurchase` does when a
    // learner taps restore) — it only ever *consults* one that a prior
    // `verifyPurchase` call already recorded in `processedPurchaseTokens`
    // (see `iap.js`'s `claimAndGrant`), so a token nobody has ever
    // claimed yet is still correctly left alone rather than guessed.
    const claim = await getFirestore()
        .collection("processedPurchaseTokens")
        .doc(purchaseToken)
        .get();
    if (!claim.exists) return;
    externalId = claim.data().uid;
    firstClaimed = true;
  }

  const active = isStillActive(response.data, {firstClaimed, uid: externalId});
  await getFirestore().collection("users").doc(externalId).set({
    subscription: buildSubscriptionPatch(active, response.data),
  }, {merge: true});
});

module.exports.extractSubscriptionToken = extractSubscriptionToken;
module.exports.isStillActive = isStillActive;
module.exports.buildSubscriptionPatch = buildSubscriptionPatch;
module.exports.RTDN_TOPIC = RTDN_TOPIC;

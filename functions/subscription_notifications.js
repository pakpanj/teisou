const {onMessagePublished} = require("firebase-functions/v2/pubsub");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");

const {subscriptionGrants} = require("./iap_states");
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

  const externalId = response.data
    && response.data.externalAccountIdentifiers
    && response.data.externalAccountIdentifiers.obfuscatedExternalAccountId;
  // No uid attached means this purchase predates the app sending one
  // (see `subscriptionGrants`'s own doc comment) — there is no account
  // to safely act on, so this is left alone rather than guessed.
  if (!externalId) return;

  const active = subscriptionGrants(response.data, externalId);
  await getFirestore().collection("users").doc(externalId).set({
    subscription: {
      tier: active ? "premium" : "free",
      updatedAt: FieldValue.serverTimestamp(),
    },
  }, {merge: true});
});

module.exports.extractSubscriptionToken = extractSubscriptionToken;
module.exports.RTDN_TOPIC = RTDN_TOPIC;

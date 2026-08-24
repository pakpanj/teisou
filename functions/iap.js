const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");

const {subscriptionGrants, productGrants} = require("./iap_states");

/**
 * Turning a store purchase into an entitlement.
 *
 * **This exists because the client must not be trusted with it.** Until
 * now `users/{uid}.subscription` was writable by its owner, which was
 * harmless while nothing was for sale and is not harmless now: anyone
 * running a modified client would simply write `tier: premium`.
 * `firestore.rules` now refuses every client write to `subscription` and
 * `entitlements`, so this function — running with Admin privileges,
 * which bypass rules — is the only way either field can change.
 *
 * **It fails closed.** If the Play Developer API is not configured yet,
 * this refuses rather than granting on the client's say-so. A paywall
 * that opens for everyone during setup is worse than one that opens for
 * nobody: the second is obvious the first time it is tested, the first
 * is discovered in the revenue figures months later.
 */

const PREMIUM_PRODUCT = "teisou_premium_monthly";
const SKIN_PREFIX = "skin_";

/**
 * Coin top-up packs — **mirrors** `IapProducts.coinPackAmounts` in
 * `lib/core/constants/iap_products.dart`. Node can't import Dart, so
 * this map has to be kept in sync by hand; the Dart side's own doc
 * comment says the same thing pointing back here. If a pack is ever
 * added or resized, both sides need the edit.
 */
const COIN_PACKS = {
  "teisou_coins_100": 100,
  "teisou_coins_200": 200,
  "teisou_coins_350": 350,
  "teisou_coins_500": 500,
  "teisou_coins_700": 700,
  "teisou_coins_1000": 1000,
};

/** Android package name — must match `applicationId` in build.gradle.kts. */
const ANDROID_PACKAGE = "com.teisou.kanamaster";

/**
 * Whether Play verification can run at all.
 *
 * Needs a service account with the Android Publisher scope, granted
 * access in Play Console under Users and permissions. Without it there
 * is no way to ask Google whether a token is real.
 */
function playConfigured() {
  return Boolean(process.env.PLAY_VERIFICATION_ENABLED === "true");
}

/**
 * The Android Publisher client, built once and reused.
 *
 * Authenticates with the function's own service account, so there is no
 * key file anywhere in this repo — the account is granted access in Play
 * Console instead. Built lazily so that merely *loading* this module in
 * a test or a project without the API enabled does not reach out to
 * anything.
 */
let androidPublisher = null;
function publisher() {
  if (!androidPublisher) {
    // Required here, not at the top of the file. `googleapis` takes well
    // over a second to load, and the deploy step gives the whole module
    // ten seconds to reveal its exports before giving up — which it did:
    // "Cannot determine backend specification". Nothing outside this
    // function needs the library, so nothing else should wait for it.
    const {google} = require("googleapis");
    const auth = new google.auth.GoogleAuth({
      scopes: ["https://www.googleapis.com/auth/androidpublisher"],
    });
    androidPublisher = google.androidpublisher({version: "v3", auth});
  }
  return androidPublisher;
}

/**
 * Asks Google whether this purchase token is real, still valid, and
 * bought by this account.
 *
 * Throws rather than returning false, so the caller cannot accidentally
 * treat a lookup failure as a refusal and a refusal as a grant — the two
 * need different answers to the app, and the difference is money.
 *
 * The decision itself lives in `iap_states.js`, away from the HTTP
 * plumbing, because it is the part worth testing.
 */
async function verifyWithPlay({productId, purchaseToken, packageName, uid}) {
  const api = publisher();
  let response;
  try {
    response = productId === PREMIUM_PRODUCT
      ? await api.purchases.subscriptionsv2.get({packageName, token: purchaseToken})
      : await api.purchases.products.get({
        packageName,
        productId,
        token: purchaseToken,
      });
  } catch (error) {
    // A 404 from Play means the token is not a real purchase — that is
    // an answer, and the answer is no. Anything else (a quota, an
    // outage, a misconfigured service account) is *not* an answer, and
    // must not be reported to the client as a refusal: the purchase is
    // real and will be granted when restore asks again.
    const status = error && error.code;
    if (status === 404 || status === 400) {
      throw new HttpsError("permission-denied", "Purchase not recognised.");
    }
    throw new HttpsError("unavailable", "Could not reach the store.");
  }

  const grants = productId === PREMIUM_PRODUCT
    ? subscriptionGrants(response.data, uid)
    : productGrants(response.data, uid);
  if (!grants) {
    throw new HttpsError("permission-denied", "Purchase is not active.");
  }
}

/**
 * What a product entitles its buyer to.
 *
 * Returns the Firestore patch, or null for an id this app does not sell
 * — an unrecognised product is refused rather than ignored, since it
 * means either an attack or a console entry nobody told the app about.
 */
function entitlementFor(productId) {
  if (productId === PREMIUM_PRODUCT) {
    return {
      subscription: {
        tier: "premium",
        purchasedAt: FieldValue.serverTimestamp(),
      },
    };
  }
  if (productId.startsWith(SKIN_PREFIX)) {
    const skinId = productId.slice(SKIN_PREFIX.length);
    return {
      entitlements: {
        skins: FieldValue.arrayUnion(skinId),
      },
    };
  }
  if (Object.prototype.hasOwnProperty.call(COIN_PACKS, productId)) {
    // Unlike a subscription patch (set-merge of the same values) or a
    // skin (arrayUnion), `increment` is **not** idempotent — verifying
    // the same token twice would grant coins twice. The processed-token
    // ledger in `verifyPurchase` below is what actually makes this safe
    // to call more than once, not anything about this patch itself.
    return {coins: FieldValue.increment(COIN_PACKS[productId])};
  }
  return null;
}

exports.verifyPurchase = onCall(async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in first.");
  }

  const {productId, purchaseToken, platform} = request.data || {};
  if (typeof productId !== "string" || typeof purchaseToken !== "string") {
    throw new HttpsError("invalid-argument", "productId and purchaseToken.");
  }

  const patch = entitlementFor(productId);
  if (!patch) {
    throw new HttpsError("invalid-argument", `Unknown product ${productId}`);
  }

  if (platform !== "android") {
    // iOS receipt validation is a different API against a different
    // endpoint, and this project has never had an iOS build. Refusing is
    // honest; pretending to verify would grant on nothing.
    throw new HttpsError(
        "unimplemented",
        "Only Android purchases can be verified yet.",
    );
  }

  if (!playConfigured()) {
    throw new HttpsError(
        "failed-precondition",
        "Purchase verification is not switched on for this project yet.",
    );
  }

  await verifyWithPlay({
    productId,
    purchaseToken,
    packageName: ANDROID_PACKAGE,
    uid,
  });

  const db = getFirestore();
  const userRef = db.collection("users").doc(uid);

  // Subscription/skin patches are idempotent by construction (set-merge
  // of the same values / arrayUnion), so verifying one token twice —
  // which `restore()` does routinely — has always safely granted the
  // same thing once. A coin pack's `increment` patch is **not**
  // idempotent that way, so every purchase now goes through this
  // processed-token ledger regardless of product: the transaction reads
  // `processedPurchaseTokens/{token}` and only applies the patch if this
  // exact token has never been recorded before, so a retried or replayed
  // verification of the same token can never double-grant.
  const tokenRef = db.collection("processedPurchaseTokens").doc(purchaseToken);
  let firstGrant = false;
  await db.runTransaction(async (tx) => {
    const tokenSnap = await tx.get(tokenRef);
    if (tokenSnap.exists) return;
    firstGrant = true;
    tx.set(tokenRef, {
      uid,
      productId,
      grantedAt: FieldValue.serverTimestamp(),
    });
    tx.set(userRef, patch, {merge: true});
  });

  // A coin pack is consumable: Play refuses to sell the same product id
  // again while a purchase of it sits unconsumed. This is called after
  // the grant (not before) — see `IapService.buyCoinPack`'s doc comment
  // for why the client deliberately leaves this to the server instead of
  // auto-consuming locally. Best-effort: a failure here does not undo the
  // coins already granted above, and the purchase can still be consumed
  // by a later restore/retry against the same token.
  if (Object.prototype.hasOwnProperty.call(COIN_PACKS, productId)) {
    try {
      await publisher().purchases.products.consume({
        packageName: ANDROID_PACKAGE,
        productId,
        token: purchaseToken,
      });
    } catch (_) {
      // Already consumed, or a transient API error — either way the
      // coins are already on the ledger above.
    }
  }

  return {granted: true, firstGrant};
});

module.exports.entitlementFor = entitlementFor;
module.exports.playConfigured = playConfigured;
// Reused by subscription_notifications.js so the RTDN handler talks to
// the same lazily-built Android Publisher client and the same package
// name constant, instead of a second copy that could drift.
module.exports.publisher = publisher;
module.exports.ANDROID_PACKAGE = ANDROID_PACKAGE;

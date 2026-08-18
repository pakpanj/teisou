const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");

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
 * Asks Google whether this purchase token is real and still valid.
 *
 * Split out so the shape of the answer is one thing to change when the
 * googleapis client is wired in, and so the caller below reads as the
 * policy it is rather than as HTTP plumbing.
 */
async function verifyWithPlay({productId, purchaseToken}) {
  // Deliberately not implemented against a half-configured project.
  // When the service account exists, this becomes a
  // `androidpublisher.purchases.subscriptionsv2.get` (or
  // `.products.get` for a skin) and returns whether the purchase is in
  // a granting state. Until then nothing is granted at all.
  void productId;
  void purchaseToken;
  throw new HttpsError(
      "failed-precondition",
      "Play verification is not configured on this project yet.",
  );
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
  });

  // Idempotent by construction: the subscription patch is a set-merge of
  // the same values, and a skin is an arrayUnion. Verifying one token
  // twice — which restore does routinely — grants the same thing once.
  await getFirestore().collection("users").doc(uid).set(patch, {merge: true});

  return {granted: true};
});

module.exports.entitlementFor = entitlementFor;
module.exports.playConfigured = playConfigured;

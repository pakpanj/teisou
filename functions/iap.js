const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const logger = require("firebase-functions/logger");

const {
  subscriptionGrants,
  productGrants,
  expiryFromResponse,
  isRetryablePlayState,
} = require("./iap_states");

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
 * Delay before each retry of a subscription check that looked like Play
 * propagation lag rather than a real rejection — see [isRetryablePlayState]
 * in `iap_states.js`. Two entries means up to 3 attempts total (the first
 * try, plus one retry after each delay). Scoped to the subscription
 * product only (see [verifyWithPlay]) — a one-time product (skin/coin
 * pack) has no equivalent propagation-lag failure mode observed in
 * practice, so retrying it would just be blind delay for no reason.
 */
const SUBSCRIPTION_RETRY_DELAYS_MS = [1500, 3000];

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

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
 * One lookup at Google — a helper [verifyWithPlay] calls once per attempt,
 * split out so the retry loop below reads as attempts around one call
 * rather than a loop with the whole request/response/decision inlined.
 * Throws for a genuinely unreachable/unrecognised token, exactly like
 * [verifyWithPlay] itself used to; a *reachable* response that simply
 * does not grant is returned, not thrown, so the caller can inspect it
 * for retryability.
 */
async function checkOnce({productId, purchaseToken, packageName, uid, requestId}) {
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
    logger.warn("verifyPurchase: Play API call failed", {
      requestId, uid, productId, status: status || "unknown",
    });
    if (status === 404 || status === 400) {
      throw new HttpsError("permission-denied", "Purchase not recognised.");
    }
    throw new HttpsError("unavailable", "Could not reach the store.");
  }

  logger.info("verifyPurchase: Play responded", {
    requestId,
    uid,
    productId,
    subscriptionState: response.data && response.data.subscriptionState,
  });

  const grants = productId === PREMIUM_PRODUCT
    ? subscriptionGrants(response.data, uid)
    : productGrants(response.data, uid);
  return {data: response.data, grants};
}

/**
 * Asks Google whether this purchase token is real, still valid, and
 * bought by this account.
 *
 * Throws rather than returning false, so the caller cannot accidentally
 * treat a lookup failure as a refusal and a refusal as a grant — the two
 * need different answers to the app, and the difference is money.
 *
 * The grant decision itself lives in `iap_states.js`, away from the HTTP
 * plumbing, because it is the part worth testing — **unchanged by the
 * retry loop added here**: this function still only ever asks
 * `subscriptionGrants`/`productGrants` for the answer, the same call as
 * before, just possibly more than once.
 *
 * **Retries only the subscription product**, and only when the specific
 * non-grant looks like Play propagation lag (see [isRetryablePlayState])
 * — a definitive rejection (cancelled, expired, wrong account) is thrown
 * immediately on the first attempt, exactly as it always was. A one-time
 * product (skin/coin pack) never retries: nothing about its failure mode
 * has ever been observed to be a propagation race the way the
 * subscription's `externalAccountIdentifiers` timing is.
 *
 * A final non-grant throws with `details: {retryable}` — `true` when
 * every attempt still looked like lag, letting the client show "still
 * verifying" instead of a flat failure; `false` for a definitive
 * rejection, on the first attempt already.
 *
 * **Returns the raw Play response on success** (`response.data`) so the
 * caller can read metadata off it — today that's just [applyExpiry]
 * reading `lineItems[0].expiryTime` — without this function needing to
 * know anything about what that metadata is used for.
 */
async function verifyWithPlay({
  productId, purchaseToken, packageName, uid, requestId,
}) {
  const delays = productId === PREMIUM_PRODUCT ? SUBSCRIPTION_RETRY_DELAYS_MS : [];
  let last = null;

  for (let attempt = 0; attempt <= delays.length; attempt++) {
    last = await checkOnce({productId, purchaseToken, packageName, uid, requestId});
    if (last.grants) {
      logger.info("verifyPurchase: granted", {requestId, uid, productId, attempt});
      return last.data;
    }
    if (attempt === delays.length || !isRetryablePlayState(last.data)) break;
    await sleep(delays[attempt]);
  }

  const retryable = productId === PREMIUM_PRODUCT && isRetryablePlayState(last.data);
  logger.warn("verifyPurchase: not granted", {
    requestId,
    uid,
    productId,
    subscriptionState: last.data && last.data.subscriptionState,
    retryable,
  });
  throw new HttpsError("permission-denied", "Purchase is not active.", {retryable});
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

/**
 * Folds a subscription purchase's expiry, if Play reported one that
 * parses, into an already-built [patch] — mutates and returns the same
 * object, mirroring [entitlementFor]'s own plain-object-patch style.
 *
 * Kept separate from [entitlementFor] rather than merged into it: that
 * function only ever needs `productId` and is called once, early,
 * purely to validate the id and shape the base patch — before
 * `verifyWithPlay` has even run, so there is no Play response yet to
 * read an expiry off of. This runs after, once one exists.
 *
 * A no-op for anything but the premium product, and a no-op when
 * [expiryFromResponse] returns `null` — **deliberately never writes
 * `expiresAt: null`**. `entitlementFor`'s premium patch never sets the
 * key at all unless this adds it, so an unset key here means the
 * Firestore `set(..., {merge: true})` call downstream leaves whatever
 * `subscription.expiresAt` was already stored completely untouched,
 * rather than clobbering a previously-known-good date with nothing —
 * exactly the failure this function exists to avoid.
 */
function applyExpiry(patch, productId, playResponse) {
  if (productId !== PREMIUM_PRODUCT) return patch;
  const expiresAt = expiryFromResponse(playResponse);
  if (expiresAt) patch.subscription.expiresAt = expiresAt;
  return patch;
}

exports.verifyPurchase = onCall(async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in first.");
  }

  const {productId, purchaseToken, platform, requestId: clientRequestId} =
      request.data || {};
  if (typeof productId !== "string" || typeof purchaseToken !== "string") {
    throw new HttpsError("invalid-argument", "productId and purchaseToken.");
  }
  // Correlates this invocation's log lines with the client's own —
  // never the token itself, which must never appear in logs at all (see
  // every log call in this file and `checkOnce` above). Falls back to a
  // server-generated id for an older client that never sent one, so a
  // mixed rollout still produces a usable, if self-only, log trail.
  const requestId = typeof clientRequestId === "string" && clientRequestId
    ? clientRequestId
    : `srv_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;

  logger.info("verifyPurchase: started", {requestId, uid, productId, platform});

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

  const playResponse = await verifyWithPlay({
    productId,
    purchaseToken,
    packageName: ANDROID_PACKAGE,
    uid,
    requestId,
  });
  applyExpiry(patch, productId, playResponse);

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
module.exports.applyExpiry = applyExpiry;
module.exports.playConfigured = playConfigured;
// Reused by subscription_notifications.js so the RTDN handler talks to
// the same lazily-built Android Publisher client and the same package
// name constant, instead of a second copy that could drift.
module.exports.publisher = publisher;
module.exports.ANDROID_PACKAGE = ANDROID_PACKAGE;

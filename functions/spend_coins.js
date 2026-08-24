const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");

/**
 * Buying a cosmetic with coins.
 *
 * **Why this has to be a Cloud Function and not a client write.** `coins`
 * is frozen against every client write in `firestore.rules` — the same
 * reasoning `verifyPurchase` documents for `subscription`/`entitlements`
 * applies here: coins are backed by real money (the top-up packs) or a
 * competitive reward (the weekly Skor Global payout), so "spend" has to
 * be a transaction nobody can fake. `xp.unlockedAvatarIds` (and its
 * frame/cover siblings) is **not** frozen — level-up rewards have always
 * written there straight from the client, since a free, earned-by-
 * playing cosmetic was never worth protecting — but a coin-bought one
 * shares that same field, so if this function only decremented `coins`
 * and left the client to write the unlock id afterwards, a modified
 * client could just skip paying and write the id anyway. Both have to
 * happen in one transaction, which is what this does.
 *
 * **Card skins are a fourth kind, added 2026-08-24, that writes
 * somewhere different.** Avatar/frame/cover unlocks land in
 * `xp.{field}`; a card skin instead writes into `entitlements.skins` —
 * the exact same array `verifyPurchase`'s real-money grant
 * (`entitlementFor` in `iap.js`) already `arrayUnion`s into. That reuse
 * is deliberate: it means `ownedSkinsProvider` (which watches
 * `entitlements.skins`) sees a coin-bought skin exactly the same way it
 * already sees a money-bought one, with no second "how did I get this"
 * concept anywhere else in the app. [KIND_PATH] is what makes each
 * kind's write target a `[group, field]` pair instead of assuming every
 * kind lives under `xp`.
 *
 * **Prices are mirrored, same pattern as `COIN_PACKS` in `iap.js`.**
 * `AvatarPresets.coinPrice`/`FramePresets.coinPrice`/
 * `CoverPresets.coinPrice`/`CardSkinPresets.coinPrice` in the Dart
 * source are the ones actually shown in the shop; [KIND_PRICE] here has
 * to agree or a learner could be charged a different amount than what
 * the UI showed them.
 */

const COIN_PRICE = 150;
const SKIN_COIN_PRICE = 300;

/** `[group, field]` under `users/{uid}` that each kind's owned-ids array
 * lives at. Avatar/frame/cover share the `xp` group; `skin` deliberately
 * doesn't — see the file doc comment above.
 */
const KIND_PATH = {
  avatar: ["xp", "unlockedAvatarIds"],
  frame: ["xp", "unlockedFrameIds"],
  cover: ["xp", "unlockedCoverIds"],
  skin: ["entitlements", "skins"],
};

const KIND_PRICE = {
  avatar: COIN_PRICE,
  frame: COIN_PRICE,
  cover: COIN_PRICE,
  skin: SKIN_COIN_PRICE,
};

/**
 * Which ids are actually coin-buyable per kind — **mirrors**
 * `AvatarPresets.coinIds` / `FramePresets.coinIds` / `CoverPresets
 * .coinIds` / `CardSkinPresets.ofSource(paid)` in
 * `lib/core/constants/{avatars,frames,covers,card_skins}.dart`. An id
 * not in the matching set here is refused even if the client thinks it
 * is coin-tier — this is what actually enforces the tier split
 * server-side; the Dart-side `isCoinUnlockable` check is only what
 * decides whether the *button* is shown.
 */
const COIN_IDS = {
  avatar: new Set([
    "neko_artist",
    "neko_graduate",
    "neko_ninja",
    "neko_samurai",
    "neko_kimono",
    "neko_matcha",
    "neko_sailor",
    "neko_detective",
    "neko_musician",
    "neko_winter",
    "neko_forest",
  ]),
  frame: new Set([
    "frame_halloween",
    "frame_night_sky",
    "frame_mushroom_fairy",
    "frame_fairytale",
    "frame_witch",
    "frame_music",
    "frame_retro_pc",
    "frame_calligraphy",
  ]),
  cover: new Set([
    "jungle_canopy",
    "enchanted_forest",
    "art_studio",
    "sumi_ink",
    "pixel_game",
    "steampunk_brass",
    "zodiac_night",
    "magic_castle",
  ]),
  // The paid card-skin family (`CardSkinSource.paid`) — real money still
  // works once its own Play Console products exist, and now this does
  // too, whichever the learner has to hand.
  skin: new Set([
    "cloud_white",
    "neon_city",
    "sakura_gold",
  ]),
};

exports.spendCoins = onCall(async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in first.");
  }

  const {kind, id} = request.data || {};
  const path = KIND_PATH[kind];
  if (!path || typeof id !== "string") {
    throw new HttpsError("invalid-argument", "kind and id.");
  }
  if (!COIN_IDS[kind].has(id)) {
    throw new HttpsError(
        "invalid-argument",
        `${id} is not coin-buyable for kind ${kind}`,
    );
  }

  const [group, field] = path;
  const price = KIND_PRICE[kind];
  const userRef = getFirestore().collection("users").doc(uid);

  const alreadyOwned = await getFirestore().runTransaction(async (tx) => {
    const snap = await tx.get(userRef);
    const data = snap.data() || {};
    const balance = typeof data.coins === "number" ? data.coins : 0;
    const owned = (data[group] && Array.isArray(data[group][field]))
      ? data[group][field]
      : [];

    if (owned.includes(id)) return true;

    if (balance < price) {
      throw new HttpsError(
          "failed-precondition",
          `Not enough coins: have ${balance}, need ${price}.`,
      );
    }

    tx.set(userRef, {
      coins: FieldValue.increment(-price),
      [group]: {[field]: FieldValue.arrayUnion(id)},
    }, {merge: true});
    return false;
  });

  return {granted: true, alreadyOwned, price};
});

module.exports.COIN_PRICE = COIN_PRICE;
module.exports.SKIN_COIN_PRICE = SKIN_COIN_PRICE;
module.exports.COIN_IDS = COIN_IDS;

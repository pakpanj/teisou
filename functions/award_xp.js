const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");

/**
 * XP — per-account learning progress, and the level-up cosmetic reward
 * loop built on top of it. Deliberately unrelated to Global Points
 * (`leaderboard/{uid}.globalPoints`, see global_points.js): that field is
 * the "Top Global" ranking metric, computed independently by its own
 * triggers, and nothing in this file ever reads or writes it. `xp` lives
 * on `users/{uid}.xp`; `globalPoints` lives on a different document
 * entirely. Keep them that way.
 *
 * **Why this has to be a Cloud Function and not a client write.**
 * `xp.totalXp` used to be incremented directly by the client
 * (`ProgressRepository.addXp`), by whatever amount the caller passed —
 * nothing checked it was plausible. `xp.claimedLevel` and
 * `xp.unlockedAvatarIds`/`unlockedFrameIds`/`unlockedCoverIds` (which
 * level-up reward landed where) were computed and written client-side
 * too, including the random pick of which cosmetic to grant. Security &
 * Monetization Master Access Audit found both exploitable: forge
 * `totalXp` high, then drain the entire reward pool for free. See
 * `TEISOU_Master_Access_Monetization_Audit.md` Section 11 and
 * `TEISOU_Security_Monetization_Remediation_Plan.md` Finding 1 for the
 * full write-up.
 *
 * **Option A — Premium Exclusive (locked product decision).** A
 * subscription-exclusive avatar/frame/cover
 * (`AvatarPresets`/`FramePresets`/`CoverPresets.isPremiumOnly`) may
 * *only* ever be obtained through an active Premium subscription — never
 * through this reward pool, regardless of level. [REWARD_POOL] below is
 * therefore built from each catalog's ad-tier ∪ coin-tier ids only,
 * mirroring `adIds`/`coinIds` from `lib/core/constants/{avatars,frames,
 * covers}.dart` — never the broader `AvatarPresets.premium`/
 * `FramePresets.isLocked`/`CoverPresets.isLocked` sets, which include
 * the premium-only bucket too. This is the one detail that actually
 * enforces the policy: since premium-only ids are simply never *in* the
 * pool, there is no filter to bypass and no id to accidentally leak in
 * later — see `TEISOU_Premium_Cosmetic_Ownership_Product_Decision.md`
 * for the full A-vs-B comparison this locks in.
 *
 * **Card Skin is untouched, on purpose.** It was never part of
 * `claimLevelReward`'s pool — `XpRewardKind` (the Dart model) has no
 * `skin` value — and keeps its own, already-correct `stars threshold AND
 * live Premium` mechanism (`card_skins.dart`'s `isCardSkinUnlocked`,
 * `functions/battle_stars.js`). Nothing here changes that.
 *
 * **Amounts are a fixed, server-side table, not client-supplied.**
 * [XP_AMOUNTS] mirrors the exact amount each learning action already
 * granted client-side (confirmed by reading every `addXp` call site
 * before writing this table) — a legitimate action grants exactly what
 * it always did; what changes is that the *type* of action is what the
 * client asserts, not the amount.
 *
 * **Idempotency/race safety on claim.** `claimXpReward` reads
 * `totalXp`/`claimedLevel` and writes the result inside one Firestore
 * transaction. Two concurrent calls (a double-tap, a retried request)
 * serialize through Firestore's transaction conflict retry: the second
 * one re-reads the already-incremented `claimedLevel`, recomputes
 * `pendingRewards` from that fresh value, and finds nothing left to
 * claim rather than granting a second reward for the same level-up.
 */

// Mirrors `XpProgress.xpPerLevel` in
// lib/data/models/xp_progress.dart — kept in sync by hand, same
// accepted cost this codebase already carries for `COIN_PRICE`/
// `SKIN_COIN_PRICE` in spend_coins.js and `COIN_PACKS` in iap.js.
const XP_PER_LEVEL = 150;

// Mirrors every `addXp(uid, amount)` call site's amount as of this
// change (lib/features/bab/bab_gate_quiz_screen.dart,
// lib/features/{bunpou,kaiwa,kanji,kotoba,particle}/*_detail_screen.dart
// or *_dialogue_screen.dart, lib/features/{choukai,dokkai,exam,
// kanji_combo}/*_exam_screen.dart, and
// ProgressRepository.recordDailyActivity's own internal call) —
// unrecognized action types are refused rather than defaulting to any
// amount, so a client can never assert its own number.
const XP_AMOUNTS = {
  dailyActive: 5,
  wordLearned: 2,
  examCompleted: 10,
  babGatePassed: 15,
};

// Reward-pool eligibility per kind — ad-tier ∪ coin-tier ids only,
// mirroring `AvatarPresets.adIds`/`.coinIds`,
// `FramePresets.adIds`/`.coinIds`, `CoverPresets.adIds`/`.coinIds` in
// lib/core/constants/{avatars,frames,covers}.dart. Deliberately excludes
// every `isPremiumOnly()` id — see the file doc comment above.
const REWARD_POOL = {
  avatar: {
    field: "unlockedAvatarIds",
    ids: [
      // adIds
      "neko_chef", "neko_sleepy", "neko_traveler",
      // coinIds
      "neko_artist", "neko_graduate", "neko_ninja", "neko_samurai",
      "neko_kimono", "neko_matcha", "neko_sailor", "neko_detective",
      "neko_musician", "neko_winter", "neko_forest",
    ],
  },
  frame: {
    field: "unlockedFrameIds",
    ids: [
      // adIds
      "frame_spring_garden", "frame_ocean", "frame_jungle", "frame_cat",
      // coinIds
      "frame_halloween", "frame_night_sky", "frame_mushroom_fairy",
      "frame_fairytale", "frame_witch", "frame_music", "frame_retro_pc",
      "frame_calligraphy",
    ],
  },
  cover: {
    field: "unlockedCoverIds",
    ids: [
      // adIds
      "coral_reef", "sunflower_field", "library_books", "cat_lover",
      // coinIds
      "jungle_canopy", "enchanted_forest", "art_studio", "sumi_ink",
      "pixel_game", "steampunk_brass", "zodiac_night", "magic_castle",
    ],
  },
};

function levelFor(totalXp) {
  return Math.floor(totalXp / XP_PER_LEVEL) + 1;
}

function pendingRewardsFor(totalXp, claimedLevel) {
  return Math.max(0, levelFor(totalXp) - 1 - claimedLevel);
}

function db() {
  return getFirestore();
}

/**
 * Core logic behind the `awardXp` callable, pulled out so tests can pass
 * a `FakeFirestore` in `options.firestore` — the same injection shape
 * `global_points.js`'s `awardPointsForHistoryDoc` already established in
 * this codebase — instead of exercising the real Admin SDK.
 *
 * @param {string} uid
 * @param {string} action one of [XP_AMOUNTS]'s keys
 * @param {{firestore?: object}} [options]
 * @return {Promise<{granted: number}>}
 */
async function awardXpFor(uid, action, options = {}) {
  const amount = XP_AMOUNTS[action];
  if (typeof amount !== "number") {
    throw new HttpsError("invalid-argument", `Unknown XP action: ${action}`);
  }

  const firestore = options.firestore || db();
  const userRef = firestore.collection("users").doc(uid);
  await userRef.set({
    xp: {totalXp: FieldValue.increment(amount)},
  }, {merge: true});

  return {granted: amount};
}

/**
 * Core logic behind the `claimXpReward` callable, same injection shape
 * as [awardXpFor]. Runs entirely inside one Firestore transaction, which
 * is what makes two concurrent claims converge to exactly one grant —
 * see the file doc comment's "Idempotency/race safety on claim" section.
 *
 * @param {string} uid
 * @param {{firestore?: object}} [options]
 * @return {Promise<{reward: {kind: string, id: string}|null}>}
 */
async function claimXpRewardFor(uid, options = {}) {
  const firestore = options.firestore || db();
  const userRef = firestore.collection("users").doc(uid);

  return firestore.runTransaction(async (tx) => {
    const snap = await tx.get(userRef);
    const data = snap.data() || {};
    const xp = data.xp || {};
    const totalXp = typeof xp.totalXp === "number" ? xp.totalXp : 0;
    const claimedLevel = typeof xp.claimedLevel === "number" ?
      xp.claimedLevel : 0;

    if (pendingRewardsFor(totalXp, claimedLevel) <= 0) {
      return {reward: null};
    }

    const pool = [];
    for (const [kind, spec] of Object.entries(REWARD_POOL)) {
      const owned = Array.isArray(xp[spec.field]) ? xp[spec.field] : [];
      for (const id of spec.ids) {
        if (!owned.includes(id)) pool.push({kind, id});
      }
    }

    if (pool.length === 0) {
      // Pool exhausted (every ad/coin-tier item already owned) — the
      // pending reward still has to be consumed, same as the original
      // client-side behaviour, or a claim that can't be filled stays
      // stuck offering one forever.
      tx.set(userRef, {
        xp: {claimedLevel: claimedLevel + 1},
      }, {merge: true});
      return {reward: null};
    }

    const pick = pool[Math.floor(Math.random() * pool.length)];
    const field = REWARD_POOL[pick.kind].field;
    tx.set(userRef, {
      xp: {
        claimedLevel: claimedLevel + 1,
        [field]: FieldValue.arrayUnion(pick.id),
      },
    }, {merge: true});

    return {reward: {kind: pick.kind, id: pick.id}};
  });
}

exports.awardXp = onCall(async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in first.");
  }
  return awardXpFor(uid, (request.data || {}).action);
});

exports.claimXpReward = onCall(async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in first.");
  }
  return claimXpRewardFor(uid);
});

module.exports.XP_PER_LEVEL = XP_PER_LEVEL;
module.exports.XP_AMOUNTS = XP_AMOUNTS;
module.exports.REWARD_POOL = REWARD_POOL;
module.exports.levelFor = levelFor;
module.exports.pendingRewardsFor = pendingRewardsFor;
module.exports.awardXpFor = awardXpFor;
module.exports.claimXpRewardFor = claimXpRewardFor;

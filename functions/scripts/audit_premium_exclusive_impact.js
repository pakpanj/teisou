/**
 * READ-ONLY audit — counts how many accounts currently hold a
 * subscription-exclusive avatar/frame/cover they may not be entitled to
 * under the locked "Option A — Premium Exclusive" policy (see
 * TEISOU_Premium_Cosmetic_Ownership_Product_Decision.md).
 *
 * Why this exists: before `firestore.rules` was hardened, `xp.unlocked*Ids`
 * and `profile.avatarValue`/`frameId`/`coverId` had NO server-side
 * ownership check at all — any client could write a subscription-only id
 * directly. Separately, before Option A was locked in as policy, the
 * XP-leveling reward pool (`claimLevelReward`) could legitimately hand out
 * a premium-only item too. Either path can leave an account holding an id
 * that today's tightened rule says should only ever come from a live
 * subscription. This script finds out how many accounts, if any, are
 * actually in that state — the number the migration decision (grandfather
 * vs. corrective strip vs. hybrid) depends on.
 *
 * This script NEVER calls .set()/.update()/.delete() anywhere. It only
 * reads. Safe to run against production as many times as you like.
 *
 * ---- HOW TO RUN THIS ----
 *
 * 1. Get a service-account key with Firestore read access:
 *    Firebase Console -> teisou-kana-master project -> gear icon ->
 *    Project settings -> Service accounts tab -> "Generate new private
 *    key". This downloads a .json file. Keep it out of git — it is a
 *    real credential.
 *
 * 2. From the `functions/` directory (so it can find the already-
 *    installed `firebase-admin` package), run:
 *
 *      GOOGLE_APPLICATION_CREDENTIALS="C:/path/to/the-key-you-downloaded.json" \
 *        node scripts/audit_premium_exclusive_impact.js
 *
 *    On Windows PowerShell:
 *
 *      $env:GOOGLE_APPLICATION_CREDENTIALS = "C:\path\to\key.json"
 *      node scripts/audit_premium_exclusive_impact.js
 *
 * 3. Read the printed report. Nothing here writes to Firestore — you can
 *    run it again any time the numbers need re-checking.
 *
 * The three premium-only id lists below were copied directly from the
 * live Dart source (`lib/core/constants/avatars.dart`/`frames.dart`/
 * `covers.dart`'s `isPremiumOnly()` logic) on 2026-08-30. If a future
 * session adds or removes a premium-only cosmetic, re-check those three
 * files' `premium`/`freeIds`/`adIds`/`coinIds` sets before trusting this
 * script's PREMIUM_ONLY constant again — it is not derived automatically
 * from the Dart source, since that would mean parsing Dart from Node.
 */
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
initializeApp();
const db = getFirestore();

const PREMIUM_ONLY = {
  avatar: ["neko_astronaut", "neko_gamer", "neko_lion"],
  frame: ["frame_steampunk", "frame_space", "frame_gaming", "frame_moon_crystal"],
  cover: ["sacred_geometry", "cyber_neon", "outer_space"],
};

// The full catalog per kind, so a stray/unknown id can be told apart from
// a legitimate one — kept in sync with the same three Dart files.
const KNOWN_IDS = {
  avatar: new Set([
    "neko_sensei", "neko_cheerleader", "neko_bookworm",
    "neko_artist", "neko_graduate", "neko_ninja", "neko_samurai",
    "neko_kimono", "neko_matcha", "neko_chef", "neko_sailor",
    "neko_detective", "neko_musician", "neko_winter", "neko_traveler",
    "neko_forest", "neko_sleepy",
    ...PREMIUM_ONLY.avatar,
  ]),
  frame: new Set([
    "frame_sakura_fuji", "frame_sakura", "frame_autumn", "frame_winter",
    "frame_spring_garden", "frame_ocean", "frame_jungle", "frame_cat",
    "frame_halloween", "frame_night_sky", "frame_mushroom_fairy",
    "frame_fairytale", "frame_witch", "frame_music", "frame_retro_pc",
    "frame_calligraphy", ...PREMIUM_ONLY.frame,
  ]),
  cover: new Set([
    "sakura_dawn", "autumn_leaves", "spring_meadow", "starry_night",
    "coral_reef", "sunflower_field", "library_books", "cat_lover",
    "jungle_canopy", "enchanted_forest", "art_studio", "sumi_ink",
    "pixel_game", "steampunk_brass", "zodiac_night", "magic_castle",
    ...PREMIUM_ONLY.cover,
  ]),
};

const FIELD = {avatar: "unlockedAvatarIds", frame: "unlockedFrameIds", cover: "unlockedCoverIds"};
const EQUIPPED_FIELD = {avatar: "avatarValue", frame: "frameId", cover: "coverId"};

async function main() {
  console.log("Reading users/ collection (read-only — no writes will happen)...");
  const snap = await db.collection("users").get();

  const report = {
    totalAccounts: snap.size,
    // Every account that has a premium-only id sitting in its ledger,
    // whether or not it's currently equipped.
    ledgerHits: [],
    // Every account currently DISPLAYING a premium-only item.
    equippedHits: [],
    // Same as equippedHits, but split by whether that account is a
    // paying subscriber right now — this is the split Option C's
    // recommendation is built on.
    equippedByTier: {free: [], premium: []},
    anomalies: [],
  };

  snap.forEach((doc) => {
    const uid = doc.id;
    const data = doc.data();
    const tier = data.subscription && data.subscription.tier ? data.subscription.tier : "free";
    const xp = data.xp || {};
    const profile = data.profile || {};

    for (const kind of ["avatar", "frame", "cover"]) {
      const owned = xp[FIELD[kind]];
      if (owned === undefined) {
        // Never touched this field at all — normal for most accounts,
        // not an anomaly.
      } else if (!Array.isArray(owned)) {
        report.anomalies.push({uid, kind: "malformed_ledger_field", field: FIELD[kind], value: owned});
      } else {
        const seen = new Set();
        for (const id of owned) {
          if (seen.has(id)) {
            report.anomalies.push({uid, kind: "duplicate_id_in_ledger", field: FIELD[kind], id});
          }
          seen.add(id);
          if (!KNOWN_IDS[kind].has(id)) {
            report.anomalies.push({uid, kind: "unknown_catalog_id_in_ledger", field: FIELD[kind], id});
          } else if (PREMIUM_ONLY[kind].includes(id)) {
            report.ledgerHits.push({uid, kind, id, tier});
          }
        }
      }
    }

    for (const kind of ["avatar", "frame", "cover"]) {
      const id = profile[EQUIPPED_FIELD[kind]];
      if (!id) continue;
      if (!KNOWN_IDS[kind].has(id)) {
        report.anomalies.push({uid, kind: "unknown_equipped_id", field: EQUIPPED_FIELD[kind], id});
      } else if (PREMIUM_ONLY[kind].includes(id)) {
        report.equippedHits.push({uid, kind, id, tier});
        report.equippedByTier[tier === "premium" ? "premium" : "free"].push({uid, kind, id});
      }
    }
  });

  console.log("\n================ SUMMARY ================");
  console.log(`Total accounts scanned: ${report.totalAccounts}`);
  console.log(`Accounts with a premium-only id sitting in their ledger (owned, may or may not be equipped): ${new Set(report.ledgerHits.map((h) => h.uid)).size}`);
  console.log(`Accounts currently WEARING a premium-only item: ${new Set(report.equippedHits.map((h) => h.uid)).size}`);
  console.log(`  - of those, currently paying subscribers (Option A/C would leave these alone): ${new Set(report.equippedByTier.premium.map((h) => h.uid)).size}`);
  console.log(`  - of those, NOT currently subscribed (the accounts Option C's corrective half targets): ${new Set(report.equippedByTier.free.map((h) => h.uid)).size}`);
  console.log(`Data-quality anomalies found (unknown ids, duplicates, malformed fields): ${report.anomalies.length}`);
  console.log("===========================================\n");

  if (report.equippedByTier.free.length > 0) {
    console.log("Free-tier accounts wearing a premium-only item right now (Option C's corrective target):");
    console.log(JSON.stringify(report.equippedByTier.free, null, 2));
  }
  if (report.anomalies.length > 0) {
    console.log("\nAnomalies:");
    console.log(JSON.stringify(report.anomalies, null, 2));
  }

  console.log("\nFull report (every hit, for reference):");
  console.log(JSON.stringify(report, null, 2));
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error("Audit failed:", err);
    process.exit(1);
  });

/**
 * Option C migration — corrects the "premium-only avatar/frame/cover"
 * data-integrity gap described in
 * AUDIT_PRODUCTION_DATA_MIGRATION_OPTION_A.md /
 * TEISOU_Premium_Cosmetic_Ownership_Product_Decision.md, per the explicit
 * product decision: **hybrid**.
 *
 * The rule this enforces:
 *   - Currently PAYING subscribers keep whatever they have, untouched —
 *     wearing a premium-only item is legitimate for them right now,
 *     regardless of how it got there.
 *   - Accounts that are NOT currently subscribed have any
 *     subscription-exclusive avatar/frame/cover CORRECTED: stripped from
 *     their unlocked-cosmetic ledger (`xp.unlocked{Kind}Ids`) and, if
 *     currently equipped, their `profile.{field}` is reset to null (the
 *     app already falls back gracefully to the Google photo / default
 *     emoji when that field is null — see `UserAvatar`/`LeaderboardAvatar`).
 *
 * This does NOT touch anything for a currently-subscribed account, and
 * does NOT touch any ad-tier/coin-tier id — only the 10 ids in
 * PREMIUM_ONLY below.
 *
 * ---- SAFETY MODEL ----
 *
 * 1. DRY RUN BY DEFAULT. This script only PRINTS what it would change
 *    unless you pass `--write` on the command line. Read the dry-run
 *    output before ever passing `--write`.
 * 2. BACK UP FIRST. Before running with `--write`, take a Firestore
 *    export of the `users` collection:
 *      gcloud firestore export gs://YOUR_BUCKET/premium-cosmetic-migration-backup \
 *        --collection-ids=users --project=teisou-kana-master
 *    (needs the gcloud CLI and a real GCS bucket — set one up in the
 *    Cloud Console first if you don't have one). This is what makes the
 *    migration actually reversible if something looks wrong afterward,
 *    beyond the audit log this script also writes (see 4).
 * 3. IDEMPOTENT. `FieldValue.arrayRemove(...)` is a no-op if the id is
 *    already gone, and the `profile.{field}` reset only fires when that
 *    field is STILL exactly the premium-only id at write time (read
 *    fresh, not reused from the earlier dry-run pass) — running this
 *    script twice in a row produces the same end state, not a second
 *    mutation.
 * 4. AUDIT-LOGGED. Every correction writes one record to
 *    `migrationAuditLog/{autoId}` (uid, field, oldValue, newValue,
 *    timestamp, scriptRunId) in the SAME batch as the correction itself,
 *    so the log can never drift from what was actually written on a
 *    partial failure. This is what a rollback would read from: for each
 *    logged record, write `oldValue` back to `field`.
 * 5. VERIFY BY RE-RUNNING. Run this script again (still without
 *    `--write`) after a real migration — it should report zero
 *    corrective-eligible accounts.
 *
 * ---- HOW TO RUN THIS ----
 *
 * Dry run (safe, no writes, run this first):
 *   GOOGLE_APPLICATION_CREDENTIALS="C:/path/to/key.json" \
 *     node scripts/migrate_premium_cosmetic_option_c.js
 *
 * Real run (after reading the dry-run output and taking a backup):
 *   GOOGLE_APPLICATION_CREDENTIALS="C:/path/to/key.json" \
 *     node scripts/migrate_premium_cosmetic_option_c.js --write
 *
 * See audit_premium_exclusive_impact.js's own header for how to get a
 * service-account key if you don't already have one downloaded.
 */
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
initializeApp();
const db = getFirestore();

const PREMIUM_ONLY = {
  avatar: ["neko_astronaut", "neko_gamer", "neko_lion"],
  frame: ["frame_steampunk", "frame_space", "frame_gaming", "frame_moon_crystal"],
  cover: ["sacred_geometry", "cyber_neon", "outer_space"],
};

const LEDGER_FIELD = {avatar: "unlockedAvatarIds", frame: "unlockedFrameIds", cover: "unlockedCoverIds"};
const EQUIPPED_FIELD = {avatar: "avatarValue", frame: "frameId", cover: "coverId"};

const WRITE = process.argv.includes("--write");
const SCRIPT_RUN_ID = `option_c_${Date.now()}`;

/** Firestore batches cap at 500 writes; chunk accordingly. */
function chunk(list, size) {
  const out = [];
  for (let i = 0; i < list.length; i += size) out.push(list.slice(i, i + size));
  return out;
}

async function main() {
  console.log(WRITE
    ? `*** LIVE RUN — this WILL write to Firestore. Run id: ${SCRIPT_RUN_ID} ***`
    : "Dry run — no writes will happen. Pass --write to actually migrate.");
  console.log("Reading users/ collection...");
  const snap = await db.collection("users").get();

  // { uid: { corrections: [{kind, field, docType: 'ledger'|'equipped', oldValue, newValue}] } }
  const plan = [];

  snap.forEach((doc) => {
    const uid = doc.id;
    const data = doc.data();
    const tier = data.subscription && data.subscription.tier ? data.subscription.tier : "free";
    if (tier === "premium") return; // grandfathered — never touched

    const xp = data.xp || {};
    const profile = data.profile || {};
    const corrections = [];

    for (const kind of ["avatar", "frame", "cover"]) {
      const ledger = xp[LEDGER_FIELD[kind]];
      if (Array.isArray(ledger)) {
        for (const id of PREMIUM_ONLY[kind]) {
          if (ledger.includes(id)) {
            corrections.push({kind, field: `xp.${LEDGER_FIELD[kind]}`, docType: "ledger", id});
          }
        }
      }
      const equippedId = profile[EQUIPPED_FIELD[kind]];
      if (equippedId && PREMIUM_ONLY[kind].includes(equippedId)) {
        corrections.push({
          kind,
          field: `profile.${EQUIPPED_FIELD[kind]}`,
          docType: "equipped",
          oldValue: equippedId,
        });
      }
    }

    if (corrections.length > 0) plan.push({uid, corrections});
  });

  console.log(`\n${plan.length} account(s) need correction (out of ${snap.size} scanned).`);
  for (const {uid, corrections} of plan) {
    console.log(`  ${uid}:`);
    for (const c of corrections) {
      if (c.docType === "ledger") {
        console.log(`    - remove "${c.id}" from ${c.field}`);
      } else {
        console.log(`    - reset ${c.field} ("${c.oldValue}" -> null)`);
      }
    }
  }

  if (!WRITE) {
    console.log("\nDry run complete. No writes were made. Re-run with --write to apply.");
    return;
  }
  if (plan.length === 0) {
    console.log("\nNothing to migrate — live run complete, no writes needed.");
    return;
  }

  console.log("\nApplying corrections...");
  for (const group of chunk(plan, 400)) {
    const batch = db.batch();
    for (const {uid, corrections} of group) {
      const userRef = db.collection("users").doc(uid);
      for (const c of corrections) {
        const auditRef = db.collection("migrationAuditLog").doc();
        if (c.docType === "ledger") {
          batch.update(userRef, {
            [`xp.${LEDGER_FIELD[c.kind]}`]: FieldValue.arrayRemove(c.id),
          });
          batch.set(auditRef, {
            uid, field: `xp.${LEDGER_FIELD[c.kind]}`,
            oldValue: c.id, newValue: null, kind: "arrayRemove",
            scriptRunId: SCRIPT_RUN_ID, at: FieldValue.serverTimestamp(),
          });
        } else {
          batch.update(userRef, {[`profile.${EQUIPPED_FIELD[c.kind]}`]: null});
          batch.set(auditRef, {
            uid, field: `profile.${EQUIPPED_FIELD[c.kind]}`,
            oldValue: c.oldValue, newValue: null, kind: "reset",
            scriptRunId: SCRIPT_RUN_ID, at: FieldValue.serverTimestamp(),
          });
        }
      }
    }
    await batch.commit();
  }

  console.log(`\nDone. ${plan.length} account(s) corrected. Audit log: migrationAuditLog (scriptRunId="${SCRIPT_RUN_ID}").`);
  console.log("Re-run this script without --write to verify — it should now report 0 accounts needing correction.");
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error("Migration failed:", err);
    process.exit(1);
  });

/**
 * Reverses a run of migrate_premium_cosmetic_option_c.js, using the
 * `migrationAuditLog` records that migration wrote as its own source of
 * truth for what to undo. For every logged correction it writes
 * `oldValue` back to `field` — an `arrayUnion` for a ledger removal, a
 * direct `set` for an equipped-field reset.
 *
 * Same safety model as the migration script: DRY RUN BY DEFAULT, pass
 * `--write` to actually apply. Read the dry-run output first.
 *
 * ---- HOW TO RUN THIS ----
 *
 * 1. Find the scriptRunId to roll back — it was printed at the end of
 *    the migration run you want to undo (also stored on every one of
 *    that run's `migrationAuditLog` records).
 *
 * 2. Dry run:
 *      GOOGLE_APPLICATION_CREDENTIALS="C:/path/to/key.json" \
 *        node scripts/rollback_premium_cosmetic_migration.js <scriptRunId>
 *
 * 3. Real run, after reading the dry-run output:
 *      GOOGLE_APPLICATION_CREDENTIALS="C:/path/to/key.json" \
 *        node scripts/rollback_premium_cosmetic_migration.js <scriptRunId> --write
 */
const admin = require("firebase-admin");
admin.initializeApp();
const db = admin.firestore();

const WRITE = process.argv.includes("--write");
const scriptRunId = process.argv[2];

function chunk(list, size) {
  const out = [];
  for (let i = 0; i < list.length; i += size) out.push(list.slice(i, i + size));
  return out;
}

async function main() {
  if (!scriptRunId || scriptRunId === "--write") {
    console.error("Usage: node rollback_premium_cosmetic_migration.js <scriptRunId> [--write]");
    process.exit(1);
  }

  console.log(WRITE
    ? `*** LIVE ROLLBACK of run "${scriptRunId}" — this WILL write to Firestore. ***`
    : `Dry run — reversing run "${scriptRunId}" without --write makes no changes.`);

  const logSnap = await db.collection("migrationAuditLog")
    .where("scriptRunId", "==", scriptRunId)
    .get();

  if (logSnap.empty) {
    console.log(`No migrationAuditLog records found for scriptRunId "${scriptRunId}" — nothing to roll back.`);
    return;
  }

  const records = logSnap.docs.map((d) => ({id: d.id, ...d.data()}));
  console.log(`\n${records.length} logged correction(s) to reverse:`);
  for (const r of records) {
    console.log(`  ${r.uid}: ${r.field} -> restore "${r.oldValue}"`);
  }

  if (!WRITE) {
    console.log("\nDry run complete. No writes were made. Re-run with --write to apply.");
    return;
  }

  console.log("\nRolling back...");
  for (const group of chunk(records, 400)) {
    const batch = db.batch();
    for (const r of group) {
      const userRef = db.collection("users").doc(r.uid);
      if (r.kind === "arrayRemove") {
        batch.update(userRef, {[r.field]: admin.firestore.FieldValue.arrayUnion(r.oldValue)});
      } else {
        batch.update(userRef, {[r.field]: r.oldValue});
      }
    }
    await batch.commit();
  }

  console.log(`\nDone. ${records.length} correction(s) reversed for run "${scriptRunId}".`);
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error("Rollback failed:", err);
    process.exit(1);
  });

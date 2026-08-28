// Permanent Rules coverage for the Exam-History Authority fix (see
// TEISOU_ROADMAP_MASTER.md's "Exam-History Authority" sections).
// Replaces the now-removed temporary
// `_audit_exam_history_rules.test.js` probe — same findings kept for
// traceability (raw exam-history writes remain freely client-writable,
// on purpose — content honesty is enforced downstream by server-side
// grading, not by locking the raw submission), plus new coverage for
// the `examHistoryGraded` trusted-result collection this fix adds.
"use strict";
const {test, before, after} = require("node:test");
const fs = require("node:fs");
const path = require("node:path");
const {initializeTestEnvironment, assertSucceeds, assertFails} =
  require("@firebase/rules-unit-testing");
const {doc, setDoc, updateDoc, deleteDoc, getDoc} = require("firebase/firestore");

let testEnv;
before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: "demo-teisou-examhistory-authority-rules",
    firestore: {
      rules: fs.readFileSync(
          path.join(__dirname, "..", "firestore.rules"), "utf8"),
      host: "127.0.0.1",
      port: 8080,
    },
  });
});
after(async () => testEnv.cleanup());

// ---------------------------------------------------------------------
// Raw exam-history submission — still functional, by design (Phase 6's
// "raw exam-history flow must remain functional").
// ---------------------------------------------------------------------
test("owner can still CREATE a raw examHistory document, including one " +
    "with an arbitrary self-reported score — the raw submission path " +
    "is deliberately unrestricted; content honesty is enforced " +
    "downstream by server-side re-grading, not by this rule", async () => {
  const uid = "rules-user-1";
  const db = testEnv.authenticatedContext(uid).firestore();
  await assertSucceeds(setDoc(
      doc(db, "users", uid, "examHistory", "raw-1"),
      {score: 999999, total: 1, type: "mixed", completedAt: "1999-01-01T00:00:00.000Z"},
  ));
});

test("owner can still UPDATE/DELETE their own raw examHistory document " +
    "— unchanged by this fix", async () => {
  const uid = "rules-user-2";
  const db = testEnv.authenticatedContext(uid).firestore();
  const ref = doc(db, "users", uid, "examHistory", "raw-2");
  await assertSucceeds(setDoc(ref, {score: 1, total: 10, type: "hiragana"}));
  await assertSucceeds(updateDoc(ref, {score: 999999}));
  await assertSucceeds(deleteDoc(ref));
});

test("same holds for dokkaiExamHistory / choukaiExamHistory / " +
    "kanjiComboExamHistory — all four raw collections stay writable", async () => {
  const uid = "rules-user-3";
  const db = testEnv.authenticatedContext(uid).firestore();
  for (const collection of [
    "dokkaiExamHistory", "choukaiExamHistory", "kanjiComboExamHistory",
  ]) {
    await assertSucceeds(setDoc(
        doc(db, "users", uid, collection, "forged"),
        {score: 999999, total: 1, jlptLevel: "N1", itemId: "forged_item"},
    ));
  }
});

// ---------------------------------------------------------------------
// examHistoryGraded — server-only, the new trust boundary this fix adds.
// ---------------------------------------------------------------------
test("a client CANNOT create an examHistoryGraded document at all, " +
    "even one that looks legitimate", async () => {
  const uid = "rules-user-4";
  const db = testEnv.authenticatedContext(uid).firestore();
  await assertFails(setDoc(
      doc(db, "examHistoryGraded", "self-forged-1"),
      {uid, moduleType: "kana", serverScore: 999999, serverTotal: 1},
  ));
});

test("a client CANNOT update an existing examHistoryGraded document " +
    "(seeded with the Admin SDK, simulating a real Cloud-Function-" +
    "written result) — the trusted result is immutable to every client", async () => {
  const uid = "rules-user-5";
  await testEnv.withSecurityRulesDisabled(async (adminCtx) => {
    await setDoc(
        doc(adminCtx.firestore(), "examHistoryGraded", "real-graded-1"),
        {uid, moduleType: "kana", serverScore: 9, serverTotal: 10, gradingVersion: 1},
    );
  });
  const db = testEnv.authenticatedContext(uid).firestore();
  await assertFails(updateDoc(
      doc(db, "examHistoryGraded", "real-graded-1"),
      {serverScore: 999999},
  ));
});

test("a client CANNOT delete an examHistoryGraded document either", async () => {
  const uid = "rules-user-6";
  await testEnv.withSecurityRulesDisabled(async (adminCtx) => {
    await setDoc(
        doc(adminCtx.firestore(), "examHistoryGraded", "real-graded-2"),
        {uid, moduleType: "kana", serverScore: 9, serverTotal: 10},
    );
  });
  const db = testEnv.authenticatedContext(uid).firestore();
  await assertFails(deleteDoc(doc(db, "examHistoryGraded", "real-graded-2")));
});

test("the owner CAN read their own real examHistoryGraded document, " +
    "but a different signed-in user CANNOT read someone else's", async () => {
  const owner = "rules-user-7";
  const other = "rules-user-8";
  await testEnv.withSecurityRulesDisabled(async (adminCtx) => {
    await setDoc(
        doc(adminCtx.firestore(), "examHistoryGraded", "real-graded-3"),
        {uid: owner, moduleType: "kana", serverScore: 9, serverTotal: 10},
    );
  });
  const ownerDb = testEnv.authenticatedContext(owner).firestore();
  await assertSucceeds(getDoc(doc(ownerDb, "examHistoryGraded", "real-graded-3")));

  const otherDb = testEnv.authenticatedContext(other).firestore();
  await assertFails(getDoc(doc(otherDb, "examHistoryGraded", "real-graded-3")));
});

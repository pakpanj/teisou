// Isolated, single-scenario regression guard, kept separate from the
// main rules.test.js suite specifically so this one bug class has a
// standalone, minimal repro that stays readable on its own.
//
// History: this test originally PROVED the hypothesis that
// `match /users/{uid} { match /{document=**} { allow write: if owner }
// } }` grants write access to `/users/{uid}` itself, not just its
// subcollections, via Firestore's zero-or-more recursive wildcard
// semantics union-ing with the specific rule above it — at the time,
// this write genuinely SUCCEEDED, which was the critical finding that
// blocked the whole Security & Monetization Remediation from actually
// working. Fixed by requiring a named `{subcollection}` path segment
// before the recursive wildcard (see firestore.rules' own comment on
// `match /users/{uid} { match /{subcollection}/{document=**} { ... } }
// }` for the full writeup), so the wildcard can no longer match the
// parent document with zero remaining segments.
//
// Now runs as a permanent regression guard in the OPPOSITE direction:
// this exact write must always be DENIED. If this test ever starts
// failing (the write starts succeeding again), the wildcard bypass has
// come back — check whether `match /{subcollection}/{document=**}`
// under `users/{uid}` was ever changed back to a bare
// `match /{document=**}`.
"use strict";
const {test, before, after} = require("node:test");
const fs = require("node:fs");
const path = require("node:path");
const {initializeTestEnvironment, assertFails} =
  require("@firebase/rules-unit-testing");
const {doc, setDoc, updateDoc} = require("firebase/firestore");

let testEnv;
before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: "demo-teisou-wildcard-probe",
    firestore: {
      rules: fs.readFileSync(
          path.join(__dirname, "..", "firestore.rules"), "utf8"),
      host: "127.0.0.1",
      port: 8080,
    },
  });
});
after(async () => testEnv.cleanup());

test("owner CANNOT write cardGameRank directly on their own users/{uid} " +
    "doc — the specific allow update rule's freeze must be the only " +
    "thing deciding this, never a broader wildcard grant reaching the " +
    "parent document with zero remaining path segments", async () => {
  const uid = "probe1";
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), "users", uid), {
      profile: {}, cardGameRank: {tier: "bronze"},
    });
  });
  const db = testEnv.authenticatedContext(uid).firestore();
  await assertFails(
      updateDoc(doc(db, "users", uid), {cardGameRank: {tier: "emerald"}}),
  );
});

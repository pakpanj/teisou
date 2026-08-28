// Permanent Rules Emulator coverage for the Weekly Global Ranking P0 fix
// — REPLACES `_audit_award_top_coins_globalScore.test.js` (deleted as
// part of this implementation), which only proved the OLD vulnerability
// existed. This file proves both halves: the old exploit path is closed,
// and the new collections (`globalScorePeriods`, `globalScorePeriodAwards`)
// are genuinely server-only — real Firestore Rules CEL-engine evaluation,
// not source-inspection.
"use strict";

const {test, before, after, beforeEach} = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const {initializeTestEnvironment, assertSucceeds, assertFails} =
  require("@firebase/rules-unit-testing");
const {doc, setDoc, updateDoc} = require("firebase/firestore");

const RULES_PATH = path.join(__dirname, "..", "firestore.rules");

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: "demo-teisou-rules-test",
    firestore: {
      rules: fs.readFileSync(RULES_PATH, "utf8"),
      host: "127.0.0.1",
      port: 8080,
    },
  });
});

after(async () => {
  if (testEnv) await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

function asUser(uid) {
  return testEnv.authenticatedContext(uid).firestore();
}

function unauthed() {
  return testEnv.unauthenticatedContext().firestore();
}

async function seedUserProfile(uid) {
  // mirrorsOwnCosmetics() (consulted by the leaderboard create/update
  // rules) reads users/{uid}.profile — throws inside the rules
  // evaluator if missing, unrelated to what this file tests. Bypasses
  // rules to seed, same as every other test in this project's suite.
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc(`users/${uid}`).set({profile: {}});
  });
}

async function seedPeriodDoc(periodId, uid, data) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore()
        .doc(`globalScorePeriods/${periodId}/users/${uid}`)
        .set(data);
  });
}

async function seedAwardDoc(periodId, data) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc(`globalScorePeriodAwards/${periodId}`).set(data);
  });
}

// ---------------------------------------------------------------------
// globalScorePeriods/{periodId}/users/{uid} — server-only, no client
// write path of any kind.
// ---------------------------------------------------------------------

test("a client CANNOT create their OWN globalScorePeriods entry — this " +
    "is the exact field the new payout ranks by, and it must have no " +
    "client write path at all, unlike the old globalScore gap", async () => {
  await seedUserProfile("player-uid");
  const db = asUser("player-uid");
  const ref = doc(db, "globalScorePeriods/2026-W36/users/player-uid");

  await assertFails(setDoc(ref, {points: 999999, attempts: 1}));
});

test("a client CANNOT update an EXISTING globalScorePeriods entry, " +
    "even their own — points/attempts must only ever move via the " +
    "server transaction", async () => {
  await seedUserProfile("player-uid");
  await seedPeriodDoc("2026-W36", "player-uid", {
    points: 50, attempts: 1, uid: "player-uid", periodId: "2026-W36",
  });
  const db = asUser("player-uid");
  const ref = doc(db, "globalScorePeriods/2026-W36/users/player-uid");

  await assertFails(updateDoc(ref, {points: 999999}));
  await assertFails(updateDoc(ref, {attempts: 999}));
});

test("a client CANNOT write into ANOTHER user's globalScorePeriods " +
    "entry either — not just an own-uid restriction, a blanket deny", async () => {
  await seedUserProfile("attacker-uid");
  const db = asUser("attacker-uid");
  const ref = doc(db, "globalScorePeriods/2026-W36/users/victim-uid");

  await assertFails(setDoc(ref, {points: 999999, attempts: 1}));
});

test("a client CANNOT forge an entry into a DIFFERENT (e.g. future, " +
    "not-yet-closed) period id — periodId itself is not a meaningful " +
    "gate here since every write to this collection is denied " +
    "regardless of periodId", async () => {
  await seedUserProfile("player-uid");
  const db = asUser("player-uid");
  const ref = doc(db, "globalScorePeriods/2099-W01/users/player-uid");

  await assertFails(setDoc(ref, {points: 1, attempts: 1}));
});

test("a signed-in client CAN read globalScorePeriods entries — public " +
    "ranking data, same trust level as the rest of the leaderboard", async () => {
  await seedPeriodDoc("2026-W36", "someone", {
    points: 500, attempts: 5, uid: "someone", periodId: "2026-W36",
  });
  await seedUserProfile("reader-uid");
  const db = asUser("reader-uid");
  const ref = doc(db, "globalScorePeriods/2026-W36/users/someone");

  await assertSucceeds(require("firebase/firestore").getDoc(ref));
});

test("an UNAUTHENTICATED client cannot even read globalScorePeriods", async () => {
  await seedPeriodDoc("2026-W36", "someone", {points: 500, attempts: 5});
  const db = unauthed();
  const ref = doc(db, "globalScorePeriods/2026-W36/users/someone");

  await assertFails(require("firebase/firestore").getDoc(ref));
});

// ---------------------------------------------------------------------
// globalScorePeriodAwards/{periodId} — server-only payout markers.
// ---------------------------------------------------------------------

test("a client CANNOT create a globalScorePeriodAwards document — this " +
    "would be the exact self-award-coins forgery shape (fabricate a " +
    "winners list naming yourself) the payout marker exists to " +
    "prevent", async () => {
  await seedUserProfile("attacker-uid");
  const db = asUser("attacker-uid");
  const ref = doc(db, "globalScorePeriodAwards/2026-W36");

  await assertFails(setDoc(ref, {
    periodId: "2026-W36",
    winners: [{uid: "attacker-uid", rank: 1, points: 1, attempts: 1, reward: 500}],
  }));
});

test("a client CANNOT update an EXISTING globalScorePeriodAwards " +
    "document — e.g. cannot rewrite the winners list after the fact " +
    "to add themselves", async () => {
  await seedAwardDoc("2026-W36", {
    periodId: "2026-W36",
    winners: [{uid: "real-winner", rank: 1, points: 900, attempts: 5, reward: 500}],
  });
  await seedUserProfile("attacker-uid");
  const db = asUser("attacker-uid");
  const ref = doc(db, "globalScorePeriodAwards/2026-W36");

  await assertFails(updateDoc(ref, {
    winners: [
      {uid: "real-winner", rank: 1, points: 900, attempts: 5, reward: 500},
      {uid: "attacker-uid", rank: 2, points: 1, attempts: 1, reward: 300},
    ],
  }));
});

test("a signed-in client CAN read a globalScorePeriodAwards document — " +
    "past winners are public information, same as the rest of the " +
    "leaderboard/profile surfaces", async () => {
  await seedAwardDoc("2026-W36", {
    periodId: "2026-W36",
    winners: [{uid: "real-winner", rank: 1, points: 900, attempts: 5, reward: 500}],
  });
  await seedUserProfile("reader-uid");
  const db = asUser("reader-uid");
  const ref = doc(db, "globalScorePeriodAwards/2026-W36");

  await assertSucceeds(require("firebase/firestore").getDoc(ref));
});

// ---------------------------------------------------------------------
// CONTRAST / regression proof — the OLD exploit path.
// ---------------------------------------------------------------------

test("CONTRAST — leaderboard.globalScore remains freely writable by " +
    "its own owner (a DELIBERATE, documented decision — see " +
    "firestore.rules' own comment on this), proving the fix is a " +
    "ranking-SOURCE change, not a globalScore lockdown that would " +
    "otherwise make this contrast test meaningless", async () => {
  await seedUserProfile("attacker-uid");
  const db = asUser("attacker-uid");
  const ref = doc(db, "leaderboard/attacker-uid");

  await assertSucceeds(setDoc(ref, {
    displayName: "Attacker",
    globalScore: 999999999,
  }));
});

test("...BUT that same forged globalScore has NO Rules-level path into " +
    "either new collection — an attacker who successfully sets a huge " +
    "globalScore (proven possible above) still cannot use it to write " +
    "themselves into globalScorePeriods or globalScorePeriodAwards; " +
    "the two systems are provably disconnected at the security-rule " +
    "level, and the actual disconnection at the ranking-LOGIC level is " +
    "separately proven by functions/award_top_coins_period.test.js's " +
    "own 'a stale/unprotected leaderboard.globalScore value... has " +
    "ZERO influence on ranking' test", async () => {
  await seedUserProfile("attacker-uid");
  const db = asUser("attacker-uid");

  await assertSucceeds(setDoc(doc(db, "leaderboard/attacker-uid"), {
    displayName: "Attacker",
    globalScore: 999999999,
  }));
  await assertFails(setDoc(
      doc(db, "globalScorePeriods/2026-W36/users/attacker-uid"),
      {points: 999999999, attempts: 1},
  ));
  await assertFails(setDoc(doc(db, "globalScorePeriodAwards/2026-W36"), {
    periodId: "2026-W36",
    winners: [{uid: "attacker-uid", rank: 1, points: 999999999, attempts: 1, reward: 500}],
  }));
});

test("CONTRAST — users/{uid}.coins remains locked against direct " +
    "client writes (pre-existing protection via isAllowedPurchaseWrite, " +
    "unaffected by and unrelated to this change) — even IF an attacker " +
    "could somehow forge a globalScorePeriodAwards doc naming " +
    "themselves (proven impossible above), the actual coin balance " +
    "still has its own, separate, independent lock", async () => {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc("users/attacker-uid").set({coins: 0, profile: {}});
  });
  const db = asUser("attacker-uid");
  await assertFails(updateDoc(doc(db, "users/attacker-uid"), {coins: 999999}));
});

// PERMANENT regression test — Core Clan Mechanics audit (2026-08-28),
// BUG #2 fix. Proves, against the REAL Firestore Rules CEL engine (not
// source-inspection), that clan leadership authority is derived from the
// clan's authoritative `hostUid`, never from the mutable, client-writable
// `role` field stored on a member's own roster row.
//
// Before this fix, `actorRole()` trusted a stored `role` value first and
// only fell back to `hostUid` when `role` was absent — so (1) a genuine
// leader could write `role: 'leader'` onto ANOTHER member's own row via
// the `members/{memberUid}` `allow update` rule (it only checked that
// `role` was the sole changed KEY, never the value), and (2) any member
// could write a forged `role: 'leader'` onto their OWN row via the
// `allow write` rule (no restriction on `role`'s value at all). Either
// path handed the recipient real leader authority — including the power
// to kick the genuine leader out of their own clan.
"use strict";

const {test, before, after, beforeEach} = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const {initializeTestEnvironment, assertSucceeds, assertFails} =
  require("@firebase/rules-unit-testing");
const {doc, updateDoc, deleteDoc} = require("firebase/firestore");

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

async function seed(fn) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await fn(ctx.firestore());
  });
}

async function seedClan(code, {hostUid, members}) {
  await seed(async (db) => {
    await db.doc(`clans/${code}`).set({
      name: "Test Clan", hostUid, memberCount: Object.keys(members).length,
    });
    for (const [uid, role] of Object.entries(members)) {
      await db.doc(`clans/${code}/members/${uid}`).set({
        displayName: uid, role,
      });
    }
  });
}

// (a) The real, authoritative leader can still legitimately promote an
// ordinary member to co-leader — the fix must not break real
// promote/demote functionality.
test("(a) the real leader can legitimately promote a member to coLeader",
    async () => {
      const code = "ABC001";
      await seedClan(code, {hostUid: "leaderUid",
        members: {leaderUid: "leader", memberUid: "member"}});

      const leaderDb = asUser("leaderUid");
      await assertSucceeds(updateDoc(
          doc(leaderDb, `clans/${code}/members/memberUid`),
          {role: "coLeader"}));

      await seed(async (db) => {
        const snap = await db.doc(`clans/${code}/members/memberUid`).get();
        assert.equal(snap.data().role, "coLeader");
      });
    });

// (b) An ordinary member cannot promote themself — neither by writing a
// forged role onto their own row (the `allow write` path) nor by any
// other path, since they are never the target of `allow update` (that
// rule only fires when `auth.uid != memberUid`).
test("(b) an ordinary member cannot promote themself by editing their " +
    "own roster row", async () => {
  const code = "ABC002";
  await seedClan(code, {hostUid: "leaderUid",
    members: {leaderUid: "leader", memberUid: "member"}});

  const memberDb = asUser("memberUid");
  await assertFails(updateDoc(
      doc(memberDb, `clans/${code}/members/memberUid`),
      {role: "leader"}));

  await seed(async (db) => {
    const snap = await db.doc(`clans/${code}/members/memberUid`).get();
    assert.equal(snap.data().role, "member",
        "a member's own self-write must never be able to change their " +
        "own stored role");
  });
});

// (c) Even if a non-host row somehow already carries a forged
// `role: 'leader'` value (e.g. a legacy/corrupted document, seeded here
// bypassing rules to simulate that state directly, independent of
// whether the write-time restrictions above would have allowed it to be
// written that way in the first place), `actorRole()` must never honor
// it as real leadership for a uid that isn't the clan's `hostUid` — a
// leader-gated action attempted by that uid must still be denied.
test("(c) a forged stored role:'leader' on a non-host row grants no " +
    "real leader privileges", async () => {
  const code = "ABC003";
  // allyUid's row is seeded directly with role:'leader' even though
  // hostUid is leaderUid — simulating a forged/corrupted value.
  await seedClan(code, {hostUid: "leaderUid",
    members: {leaderUid: "leader", allyUid: "leader", targetUid: "member"}});

  const allyDb = asUser("allyUid");
  // A real leader-only action: promoting another member to coLeader.
  await assertFails(updateDoc(
      doc(allyDb, `clans/${code}/members/targetUid`),
      {role: "coLeader"}));

  await seed(async (db) => {
    const snap = await db.doc(`clans/${code}/members/targetUid`).get();
    assert.equal(snap.data().role, "member",
        "a forged non-host 'leader' row must not be able to promote " +
        "anyone else");
  });
});

// (d) The same forged non-host 'leader' row must not be able to kick the
// clan's real owner out of their own clan — this is the exact
// escalation chain the original audit proved end-to-end.
test("(d) a forged stored role:'leader' on a non-host row cannot kick " +
    "the real clan owner", async () => {
  const code = "ABC004";
  await seedClan(code, {hostUid: "leaderUid",
    members: {leaderUid: "leader", allyUid: "leader"}});

  const allyDb = asUser("allyUid");
  await assertFails(deleteDoc(doc(allyDb, `clans/${code}/members/leaderUid`)));

  await seed(async (db) => {
    const snap = await db.doc(`clans/${code}/members/leaderUid`).get();
    assert.equal(snap.exists, true,
        "the real owner's own roster row must survive an attempted " +
        "kick from a forged non-host 'leader'");
  });
});

// (e) Legitimate leader/co-leader kick policy still works exactly as
// before this fix — the real leader can kick an ordinary member, and a
// real co-leader can kick an ordinary member but not another
// leader/co-leader.
test("(e) legitimate kick policy for the real leader and a real " +
    "coLeader still works unchanged", async () => {
  const code = "ABC005";
  await seedClan(code, {hostUid: "leaderUid", members: {
    leaderUid: "leader",
    coLeaderUid: "coLeader",
    memberUid: "member",
  }});

  const leaderDb = asUser("leaderUid");
  await assertSucceeds(
      deleteDoc(doc(leaderDb, `clans/${code}/members/memberUid`)));

  await seedClan(code, {hostUid: "leaderUid", members: {
    leaderUid: "leader",
    coLeaderUid: "coLeader",
    memberUid2: "member",
  }});
  const coLeaderDb = asUser("coLeaderUid");
  await assertSucceeds(
      deleteDoc(doc(coLeaderDb, `clans/${code}/members/memberUid2`)));
  // A co-leader still cannot kick the real leader.
  await assertFails(
      deleteDoc(doc(coLeaderDb, `clans/${code}/members/leaderUid`)));
});

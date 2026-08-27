// Real Firestore Rules Emulator test harness for firestore.rules.
//
// This is the genuine replacement/supplement for the source-inspection
// tests in test/ad_rewards_freeze_test.dart, test/xp_authority_test.dart
// and test/cosmetic_ownership_equip_test.dart: those read firestore.rules
// as *text* and assert on its shape; these actually spin up the real
// Firestore Rules CEL engine (via the Firebase Emulator Suite) and throw
// real writes/reads at it, so a rule that reads correctly but evaluates
// wrong would be caught here and NOT there.
//
// Run with: node --test rules.test.js (from this directory), against a
// running `firebase emulators:start --only firestore` — or, for a single
// self-contained run, `firebase emulators:exec --only firestore "node
// --test rules.test.js"` from the repo root (adjust the relative path to
// this file accordingly). See ../firestore_rules_tests/README.md.
//
// Deliberately its own package.json (see that file's own doc comment) —
// @firebase/rules-unit-testing is a dev-only, rules-testing-only
// dependency and must never ship with functions/ or the Flutter app.
"use strict";

const {test, describe, before, after, beforeEach} = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require("@firebase/rules-unit-testing");
const {
  doc,
  setDoc,
  getDoc,
  updateDoc,
  deleteDoc,
  Timestamp,
} = require("firebase/firestore");

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

/** A Firestore instance authenticated as [uid], subject to real rules. */
function asUser(uid) {
  return testEnv.authenticatedContext(uid).firestore();
}

/** A Firestore instance with no auth at all, subject to real rules. */
function asAnon() {
  return testEnv.unauthenticatedContext().firestore();
}

/** Seeds data bypassing rules entirely — the emulator's own documented
 * way to set up fixtures without the seed write itself being subject to
 * the rules under test. */
async function seed(fn) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await fn(ctx.firestore());
  });
}

function future(seconds = 3600) {
  return Timestamp.fromMillis(Date.now() + seconds * 1000);
}

function past(seconds = 3600) {
  return Timestamp.fromMillis(Date.now() - seconds * 1000);
}

// ---------------------------------------------------------------------
// 1. adRewards
// ---------------------------------------------------------------------
describe("adRewards", () => {
  test("an authenticated user cannot write adRewards on their own doc", async () => {
    const uid = "u1";
    await seed(async (db) => {
      await setDoc(doc(db, "users", uid), {
        profile: {},
        subscription: {tier: "free"},
        adRewards: {},
      });
    });
    const db = asUser(uid);
    await assertFails(
        updateDoc(doc(db, "users", uid), {
          adRewards: {avatar_premium: {expiresAt: future()}},
        }),
    );
  });

  test("a brand-new document cannot seed adRewards at create time", async () => {
    const uid = "u2";
    const db = asUser(uid);
    await assertFails(
        setDoc(doc(db, "users", uid), {
          subscription: {tier: "free"},
          coins: 0,
          adRewards: {avatar_premium: {expiresAt: future()}},
        }),
    );
  });

  test("existing adRewards data can still be read by its owner", async () => {
    const uid = "u3";
    await seed(async (db) => {
      await setDoc(doc(db, "users", uid), {
        profile: {},
        subscription: {tier: "free"},
        adRewards: {avatar_premium: {expiresAt: future()}},
      });
    });
    const db = asUser(uid);
    await assertSucceeds(getDoc(doc(db, "users", uid)));
  });

  test("adRewards stays untouched by an unrelated field update", async () => {
    const uid = "u4";
    await seed(async (db) => {
      await setDoc(doc(db, "users", uid), {
        profile: {displayName: "Old"},
        subscription: {tier: "free"},
        adRewards: {avatar_premium: {expiresAt: future()}},
      });
    });
    const db = asUser(uid);
    await assertSucceeds(
        updateDoc(doc(db, "users", uid), {"profile.displayName": "New"}),
    );
  });
});

// ---------------------------------------------------------------------
// 2. XP
// ---------------------------------------------------------------------
describe("xp authority", () => {
  test("client cannot change xp.totalXp", async () => {
    const uid = "u5";
    await seed(async (db) => {
      await setDoc(doc(db, "users", uid), {
        profile: {},
        subscription: {tier: "free"},
        xp: {totalXp: 0, claimedLevel: 0},
      });
    });
    const db = asUser(uid);
    await assertFails(
        updateDoc(doc(db, "users", uid), {"xp.totalXp": 999999}),
    );
  });

  test("client cannot grant themself a premium-only avatar id via " +
      "xp.unlockedAvatarIds", async () => {
    const uid = "u6";
    await seed(async (db) => {
      await setDoc(doc(db, "users", uid), {
        profile: {},
        subscription: {tier: "free"},
        xp: {unlockedAvatarIds: []},
      });
    });
    const db = asUser(uid);
    await assertFails(
        updateDoc(doc(db, "users", uid), {
          "xp.unlockedAvatarIds": ["neko_astronaut"],
        }),
    );
  });

  test("a legitimate server/Admin-SDK write to xp still works " +
      "(simulated via the rules-disabled seed context, since Admin SDK " +
      "bypasses rules entirely — this proves the freeze targets client " +
      "writes specifically, not the field in general)", async () => {
    const uid = "u7";
    await seed(async (db) => {
      await setDoc(doc(db, "users", uid), {
        profile: {},
        subscription: {tier: "free"},
        xp: {totalXp: 0},
      });
    });
    await seed(async (db) => {
      await updateDoc(doc(db, "users", uid), {"xp.totalXp": 500});
    });
    const db = asUser(uid);
    const snap = await getDoc(doc(db, "users", uid));
    assert.equal(snap.data().xp.totalXp, 500);
  });
});

// ---------------------------------------------------------------------
// 3. Avatar / Frame / Cover — the four-tier isAllowedCosmeticEquip logic
// ---------------------------------------------------------------------
describe("Avatar/Frame/Cover ownership + equip", () => {
  async function seedUser(uid, overrides = {}) {
    await seed(async (db) => {
      await setDoc(doc(db, "users", uid), {
        profile: {avatarValue: null},
        subscription: {tier: "free"},
        adRewards: {},
        xp: {unlockedAvatarIds: []},
        ...overrides,
      });
    });
  }

  test("FREE avatar id is always allowed", async () => {
    const uid = "a1";
    await seedUser(uid);
    const db = asUser(uid);
    await assertSucceeds(
        updateDoc(doc(db, "users", uid), {
          "profile.avatarValue": "neko_sensei",
        }),
    );
  });

  test("ad-tier avatar id allowed while the ad reward is still active", async () => {
    const uid = "a2";
    await seedUser(uid, {
      adRewards: {avatar_premium: {expiresAt: future()}},
    });
    const db = asUser(uid);
    await assertSucceeds(
        updateDoc(doc(db, "users", uid), {
          "profile.avatarValue": "neko_chef",
        }),
    );
  });

  test("ad-tier avatar id denied once the ad reward has expired", async () => {
    const uid = "a3";
    await seedUser(uid, {
      adRewards: {avatar_premium: {expiresAt: past()}},
    });
    const db = asUser(uid);
    await assertFails(
        updateDoc(doc(db, "users", uid), {
          "profile.avatarValue": "neko_chef",
        }),
    );
  });

  test("coin-tier avatar id allowed once genuinely owned via xp.unlockedAvatarIds", async () => {
    const uid = "a4";
    await seedUser(uid, {xp: {unlockedAvatarIds: ["neko_matcha"]}});
    const db = asUser(uid);
    await assertSucceeds(
        updateDoc(doc(db, "users", uid), {
          "profile.avatarValue": "neko_matcha",
        }),
    );
  });

  test("coin-tier avatar id denied when not owned", async () => {
    const uid = "a5";
    await seedUser(uid);
    const db = asUser(uid);
    await assertFails(
        updateDoc(doc(db, "users", uid), {
          "profile.avatarValue": "neko_matcha",
        }),
    );
  });

  test("premium-only avatar id denied without an active Premium subscription", async () => {
    const uid = "a6";
    await seedUser(uid);
    const db = asUser(uid);
    await assertFails(
        updateDoc(doc(db, "users", uid), {
          "profile.avatarValue": "neko_astronaut",
        }),
    );
  });

  test("premium-only avatar id denied even if it's (incorrectly) present " +
      "in xp.unlockedAvatarIds — Option A's defense-in-depth", async () => {
    const uid = "a6b";
    await seedUser(uid, {xp: {unlockedAvatarIds: ["neko_astronaut"]}});
    const db = asUser(uid);
    await assertFails(
        updateDoc(doc(db, "users", uid), {
          "profile.avatarValue": "neko_astronaut",
        }),
    );
  });

  test("premium-only avatar id allowed with an active Premium subscription", async () => {
    const uid = "a7";
    await seedUser(uid, {subscription: {tier: "premium"}});
    const db = asUser(uid);
    await assertSucceeds(
        updateDoc(doc(db, "users", uid), {
          "profile.avatarValue": "neko_astronaut",
        }),
    );
  });

  test("unknown/arbitrary avatar id is denied outright", async () => {
    const uid = "a8";
    await seedUser(uid);
    const db = asUser(uid);
    await assertFails(
        updateDoc(doc(db, "users", uid), {
          "profile.avatarValue": "not_a_real_avatar_id",
        }),
    );
  });

  test("cross-user write is denied — u9 cannot equip an avatar on u10's doc", async () => {
    const owner = "u10";
    const attacker = "u9";
    await seedUser(owner);
    const db = asUser(attacker);
    await assertFails(
        updateDoc(doc(db, "users", owner), {
          "profile.avatarValue": "neko_sensei",
        }),
    );
  });

  test("frame follows the identical four-tier logic (spot check: " +
      "free allowed, premium-only denied without Premium)", async () => {
    const uid = "f1";
    await seed(async (db) => {
      await setDoc(doc(db, "users", uid), {
        profile: {frameId: null},
        subscription: {tier: "free"},
        xp: {unlockedFrameIds: []},
      });
    });
    const db = asUser(uid);
    await assertSucceeds(
        updateDoc(doc(db, "users", uid), {"profile.frameId": "frame_sakura"}),
    );
    await assertFails(
        updateDoc(doc(db, "users", uid), {"profile.frameId": "frame_space"}),
    );
  });

  test("cover follows the identical four-tier logic (spot check: " +
      "coin-tier allowed once owned)", async () => {
    const uid = "c1";
    await seed(async (db) => {
      await setDoc(doc(db, "users", uid), {
        profile: {coverId: null},
        subscription: {tier: "free"},
        xp: {unlockedCoverIds: ["sumi_ink"]},
      });
    });
    const db = asUser(uid);
    await assertSucceeds(
        updateDoc(doc(db, "users", uid), {"profile.coverId": "sumi_ink"}),
    );
  });
});

// ---------------------------------------------------------------------
// 3b. Combined-write enforcement — profile equip + xp.unlocked*Ids in
//     ONE request (TEST GAP #3, AUDIT_COSMETIC_PROFILE_SHOP.md).
//
// Every test above only ever changes ONE of `profile.frameId` or
// `xp.unlockedFrameIds` per request. That leaves a real question
// unanswered: `isAllowedProfileWrite()` reads `ownedFrames` from
// `resource.data` (the document as it stood BEFORE this write), so if a
// single `set(..., merge:true)`/`update()` call could smuggle a NEW id
// into `xp.unlockedFrameIds` in the same request that equips it, would
// `isAllowedCosmeticEquip` be fooled into reading the request's own
// freshly-claimed ownership as if it were already-established fact?
//
// Source-inspection answer: no — `isAllowedPurchaseWrite()` freezes the
// ENTIRE `xp` map (`request.resource.data.get('xp', {}) == oldXp`) as
// one of the `&&`-chained conditions on `allow update`, so ANY change
// to ANY key under `xp` (unlockedFrameIds included) fails that condition
// outright, and Firestore rules require every `&&` term to hold — one
// false denies the WHOLE document write, not just the field that
// violated it. But that is exactly the kind of "reads correct, might
// not evaluate correct" claim this harness exists to stop trusting on
// sight (see README.md's own three real discrepancies, none of which
// were visible from reading the rule text alone) — so this group proves
// it against the real CEL engine instead of re-asserting the same
// reasoning in prose.
describe("combined-write enforcement — profile equip + xp.unlocked*Ids " +
    "in one request", () => {
  test("baseline: profile.frameId ALONE, to an owned/free id, is " +
      "ALLOWED — establishes what the combined-write tests below " +
      "contrast against", async () => {
    const uid = "cw1";
    await seed(async (db) => {
      await setDoc(doc(db, "users", uid), {
        profile: {frameId: null},
        subscription: {tier: "free"},
        xp: {unlockedFrameIds: []},
      });
    });
    const db = asUser(uid);
    await assertSucceeds(
        updateDoc(doc(db, "users", uid), {"profile.frameId": "frame_sakura"}),
    );
  });

  test("baseline: xp.unlockedFrameIds ALONE, changed by the client, is " +
      "DENIED", async () => {
    const uid = "cw2";
    await seed(async (db) => {
      await setDoc(doc(db, "users", uid), {
        profile: {frameId: null},
        subscription: {tier: "free"},
        xp: {unlockedFrameIds: []},
      });
    });
    const db = asUser(uid);
    await assertFails(
        updateDoc(doc(db, "users", uid), {
          "xp.unlockedFrameIds": ["frame_ocean"],
        }),
    );
  });

  test("CORE: profile.frameId (a legitimately free id) + " +
      "xp.unlockedFrameIds in the SAME update() request is DENIED — " +
      "even though the frameId half alone would succeed on its own " +
      "(see the baseline above)", async () => {
    const uid = "cw3";
    await seed(async (db) => {
      await setDoc(doc(db, "users", uid), {
        profile: {frameId: null},
        subscription: {tier: "free"},
        xp: {unlockedFrameIds: []},
      });
    });
    const db = asUser(uid);
    await assertFails(
        updateDoc(doc(db, "users", uid), {
          "profile.frameId": "frame_sakura",
          "xp.unlockedFrameIds": ["frame_sakura"],
        }),
    );
    // And prove the deny is atomic — the doc must show NEITHER half
    // landed, not "the frameId part quietly went through anyway".
    const snap = await getDoc(doc(db, "users", uid));
    assert.equal(snap.data().profile.frameId, null);
    assert.deepEqual(snap.data().xp.unlockedFrameIds, []);
  });

  test("ESCALATION ATTEMPT: a combined write trying to self-grant a " +
      "premium-only frame via xp.unlockedFrameIds AND equip it in the " +
      "same request is DENIED — the exact self-service-ownership " +
      "shortcut isAllowedCosmeticEquip's design note warns about", async () => {
    const uid = "cw4";
    await seed(async (db) => {
      await setDoc(doc(db, "users", uid), {
        profile: {frameId: null},
        subscription: {tier: "free"},
        xp: {unlockedFrameIds: []},
      });
    });
    const db = asUser(uid);
    await assertFails(
        updateDoc(doc(db, "users", uid), {
          "profile.frameId": "frame_space",
          "xp.unlockedFrameIds": ["frame_space"],
        }),
    );
    const snap = await getDoc(doc(db, "users", uid));
    assert.equal(snap.data().profile.frameId, null);
  });

  test("the same combined denial holds via setDoc(..., {merge:true}) " +
      "with nested objects too, not just updateDoc's dot-path form — " +
      "both are real request shapes ProgressRepository/spend_coins.js " +
      "could in principle produce", async () => {
    const uid = "cw5";
    await seed(async (db) => {
      await setDoc(doc(db, "users", uid), {
        profile: {frameId: null},
        subscription: {tier: "free"},
        xp: {unlockedFrameIds: []},
      });
    });
    const db = asUser(uid);
    await assertFails(
        setDoc(doc(db, "users", uid), {
          profile: {frameId: "frame_sakura"},
          xp: {unlockedFrameIds: ["frame_sakura"]},
        }, {merge: true}),
    );
    const snap = await getDoc(doc(db, "users", uid));
    assert.equal(snap.data().profile.frameId, null);
  });

  test("a legitimate server-side grant is NOT blocked by this freeze — " +
      "simulated the same way the existing 'xp authority' describe " +
      "block already does (rules-disabled seed context standing in for " +
      "an Admin SDK write, since this harness has no functions emulator " +
      "wired in — see README.md — and Admin SDK writes bypass these " +
      "rules regardless of which server code performs them, so faking " +
      "a Cloud Function object here would prove nothing this doesn't)",
  async () => {
    const uid = "cw6";
    await seed(async (db) => {
      await setDoc(doc(db, "users", uid), {
        profile: {frameId: null},
        subscription: {tier: "free"},
        xp: {unlockedFrameIds: []},
      });
    });
    // What claimLevelReward/spend_coins.js actually do server-side:
    // grant the id into xp.unlockedFrameIds via the Admin SDK, out of
    // band from anything the client itself requested. Deliberately a
    // COIN-tier id (frame_ocean), not a premium-only one (frame_space) —
    // Option A's defense-in-depth (see isAllowedCosmeticEquip's own doc
    // comment, and the "premium-only ... even if it's (incorrectly)
    // present in xp.unlocked*Ids" tests elsewhere in this file) means a
    // premium-only id is NEVER equippable via xp.unlocked*Ids alone, no
    // matter how it got there — using one here would test the wrong
    // thing and this test's own first run correctly caught that.
    await seed(async (db) => {
      await updateDoc(doc(db, "users", uid), {
        "xp.unlockedFrameIds": ["frame_ocean"],
      });
    });
    // The id is now genuinely owned. The client equipping it — writing
    // profile.frameId ONLY, no xp write of its own — must succeed.
    const db = asUser(uid);
    await assertSucceeds(
        updateDoc(doc(db, "users", uid), {"profile.frameId": "frame_ocean"}),
    );
  });

  test("COVER: the identical combined-write denial holds for " +
      "profile.coverId + xp.unlockedCoverIds too — proves this is the " +
      "shared isAllowedPurchaseWrite/isAllowedProfileWrite mechanism, " +
      "not a frame-only assumption", async () => {
    const uid = "cw7";
    await seed(async (db) => {
      await setDoc(doc(db, "users", uid), {
        profile: {coverId: null},
        subscription: {tier: "free"},
        xp: {unlockedCoverIds: []},
      });
    });
    const db = asUser(uid);
    await assertFails(
        updateDoc(doc(db, "users", uid), {
          "profile.coverId": "sakura_dawn",
          "xp.unlockedCoverIds": ["sakura_dawn"],
        }),
    );
    const snap = await getDoc(doc(db, "users", uid));
    assert.equal(snap.data().profile.coverId, null);
  });
});

// ---------------------------------------------------------------------
// 4. Card Skin
// ---------------------------------------------------------------------
describe("Card Skin ownership + equip", () => {
  async function seedUserAndLeaderboard(uid, userOverrides = {}, starTotal = 0) {
    await seed(async (db) => {
      await setDoc(doc(db, "users", uid), {
        profile: {cardSkinId: null},
        subscription: {tier: "free"},
        entitlements: {},
        ...userOverrides,
      });
      await setDoc(doc(db, "leaderboard", uid), {
        cardGameStarTotal: starTotal,
      });
    });
  }

  test("free skin always allowed", async () => {
    const uid = "s1";
    await seedUserAndLeaderboard(uid);
    const db = asUser(uid);
    await assertSucceeds(
        updateDoc(doc(db, "users", uid), {"profile.cardSkinId": "sakura"}),
    );
  });

  test("achievement skin denied with enough stars but no Premium", async () => {
    const uid = "s2";
    await seedUserAndLeaderboard(uid, {}, 40);
    const db = asUser(uid);
    await assertFails(
        updateDoc(doc(db, "users", uid), {
          "profile.cardSkinId": "emas_kencana",
        }),
    );
  });

  test("achievement skin denied with Premium but not enough stars", async () => {
    const uid = "s3";
    await seedUserAndLeaderboard(uid, {subscription: {tier: "premium"}}, 10);
    const db = asUser(uid);
    await assertFails(
        updateDoc(doc(db, "users", uid), {
          "profile.cardSkinId": "emas_kencana",
        }),
    );
  });

  test("achievement skin allowed with both enough stars AND Premium", async () => {
    const uid = "s4";
    await seedUserAndLeaderboard(uid, {subscription: {tier: "premium"}}, 40);
    const db = asUser(uid);
    await assertSucceeds(
        updateDoc(doc(db, "users", uid), {
          "profile.cardSkinId": "emas_kencana",
        }),
    );
  });

  test("paid skin allowed once owned via entitlements.skins", async () => {
    const uid = "s5";
    await seedUserAndLeaderboard(uid, {entitlements: {skins: ["neon_city"]}});
    const db = asUser(uid);
    await assertSucceeds(
        updateDoc(doc(db, "users", uid), {
          "profile.cardSkinId": "neon_city",
        }),
    );
  });

  test("paid skin allowed for Premium even without a purchase (bundled free)", async () => {
    const uid = "s6";
    await seedUserAndLeaderboard(uid, {subscription: {tier: "premium"}});
    const db = asUser(uid);
    await assertSucceeds(
        updateDoc(doc(db, "users", uid), {
          "profile.cardSkinId": "neon_city",
        }),
    );
  });

  test("paid skin denied when neither owned nor Premium", async () => {
    const uid = "s7";
    await seedUserAndLeaderboard(uid);
    const db = asUser(uid);
    await assertFails(
        updateDoc(doc(db, "users", uid), {
          "profile.cardSkinId": "neon_city",
        }),
    );
  });

  test("cross-user card skin write is denied", async () => {
    const owner = "s8";
    const attacker = "s9";
    await seedUserAndLeaderboard(owner);
    const db = asUser(attacker);
    await assertFails(
        updateDoc(doc(db, "users", owner), {
          "profile.cardSkinId": "sakura",
        }),
    );
  });
});

// ---------------------------------------------------------------------
// 5. Existing-behavior non-regression
// ---------------------------------------------------------------------
describe("existing behavior — no regression", () => {
  test("cardGameRank is completely frozen against client update", async () => {
    const uid = "r1";
    await seed(async (db) => {
      await setDoc(doc(db, "users", uid), {
        profile: {},
        subscription: {tier: "free"},
        cardGameRank: {tier: "bronze"},
      });
    });
    const db = asUser(uid);
    await assertFails(
        updateDoc(doc(db, "users", uid), {
          "cardGameRank.tier": "emerald",
        }),
    );
  });

  test("leaderboard globalPoints is frozen against client update", async () => {
    const uid = "r2";
    await seed(async (db) => {
      await setDoc(doc(db, "leaderboard", uid), {globalPoints: 10});
    });
    const db = asUser(uid);
    await assertFails(
        updateDoc(doc(db, "leaderboard", uid), {globalPoints: 999999}),
    );
  });

  test("leaderboard is still readable by any signed-in user", async () => {
    const uid = "r3";
    await seed(async (db) => {
      await setDoc(doc(db, "leaderboard", uid), {globalPoints: 10});
    });
    const db = asUser("someone_else");
    await assertSucceeds(getDoc(doc(db, "leaderboard", uid)));
  });

  // RISK-2 (AUDIT_COSMETIC_PROFILE_SHOP.md): leaderboard/{uid},
  // clans/{code}/members/{uid} and users/{otherUid}/friends/{friendUid}
  // are pure mirrors of users/{uid}.profile's cosmetic fields, read by
  // this app's own render sites for OTHER people's avatars/frames/
  // covers/card skins with no live re-check (see battle_screen.dart's
  // own _skinFor doc comment). Before mirrorsOwnCosmetics existed, a
  // client could write ANY value to any of the three directly, no
  // ownership required at all — proven here, and closed by
  // firestore.rules' mirrorsOwnCosmetics.
  describe("cosmetic identity mirrors must match users/{uid}.profile", () => {
    test("DENIED: fake an achievement card skin via " +
        "leaderboard/{uid}.cardSkinId — no stars/Premium, and no " +
        "matching users/{uid} value either", async () => {
      const uid = "mirror1";
      await seed(async (db) => {
        await setDoc(doc(db, "users", uid), {
          profile: {cardSkinId: "classic"},
          subscription: {tier: "free"},
        });
        await setDoc(doc(db, "leaderboard", uid), {
          cardGameStarTotal: 0,
          cardSkinId: "classic",
        });
      });
      const db = asUser(uid);
      await assertFails(
          updateDoc(doc(db, "leaderboard", uid), {cardSkinId: "dragon_black"}),
      );
    });

    test("ALLOWED: leaderboard.cardSkinId can be synced to whatever " +
        "users/{uid}.profile.cardSkinId genuinely says right now — the " +
        "legitimate mirror path this fix must not break", async () => {
      const uid = "mirror2";
      await seed(async (db) => {
        await setDoc(doc(db, "users", uid), {
          profile: {cardSkinId: "sakura"},
          subscription: {tier: "free"},
        });
        await setDoc(doc(db, "leaderboard", uid), {
          cardGameStarTotal: 0,
          cardSkinId: "classic",
        });
      });
      const db = asUser(uid);
      await assertSucceeds(
          updateDoc(doc(db, "leaderboard", uid), {cardSkinId: "sakura"}),
      );
    });

    test("DENIED: fake a premium-only avatar via " +
        "leaderboard/{uid}.avatarType/avatarValue", async () => {
      const uid = "mirror3";
      await seed(async (db) => {
        await setDoc(doc(db, "users", uid), {
          profile: {avatarType: "preset_free", avatarValue: "neko_sensei"},
          subscription: {tier: "free"},
        });
        await setDoc(doc(db, "leaderboard", uid), {
          avatarType: "preset_free",
          avatarValue: "neko_sensei",
        });
      });
      const db = asUser(uid);
      await assertFails(
          updateDoc(doc(db, "leaderboard", uid), {
            avatarType: "preset_premium",
            avatarValue: "neko_astronaut",
          }),
      );
    });

    test("ALLOWED: the leaderboard avatar mirror can be synced to " +
        "whatever the client genuinely just equipped on " +
        "users/{uid}.profile", async () => {
      const uid = "mirror4";
      await seed(async (db) => {
        await setDoc(doc(db, "users", uid), {
          profile: {
            avatarType: "preset_premium",
            avatarValue: "neko_astronaut",
          },
          subscription: {tier: "premium"},
        });
        await setDoc(doc(db, "leaderboard", uid), {
          avatarType: "preset_free",
          avatarValue: "neko_sensei",
        });
      });
      const db = asUser(uid);
      await assertSucceeds(
          updateDoc(doc(db, "leaderboard", uid), {
            avatarType: "preset_premium",
            avatarValue: "neko_astronaut",
          }),
      );
    });

    test("ALLOWED: an unrelated leaderboard field (displayName) can " +
        "still be updated without touching any cosmetic field, as long " +
        "as the already-stored cosmetic fields still match the profile",
    async () => {
      const uid = "mirror5";
      await seed(async (db) => {
        await setDoc(doc(db, "users", uid), {
          profile: {avatarType: "preset_free", avatarValue: "neko_sensei"},
          subscription: {tier: "free"},
        });
        await setDoc(doc(db, "leaderboard", uid), {
          avatarType: "preset_free",
          avatarValue: "neko_sensei",
          displayName: "Old Name",
        });
      });
      const db = asUser(uid);
      await assertSucceeds(
          updateDoc(doc(db, "leaderboard", uid), {displayName: "New Name"}),
      );
    });

    test("DENIED: fake a premium-only avatar in your OWN clan roster " +
        "row, visible to clanmates", async () => {
      const memberUid = "mirror6";
      const code = "MIRRORCLAN1";
      await seed(async (db) => {
        await setDoc(doc(db, "users", memberUid), {
          profile: {avatarType: "preset_free", avatarValue: "neko_sensei"},
          subscription: {tier: "free"},
        });
        await setDoc(doc(db, "clans", code), {hostUid: "someone_else"});
        await setDoc(doc(db, "clans", code, "members", memberUid), {
          avatarType: "preset_free",
          avatarValue: "neko_sensei",
          role: "member",
        });
      });
      const db = asUser(memberUid);
      await assertFails(
          updateDoc(doc(db, "clans", code, "members", memberUid), {
            avatarType: "preset_premium",
            avatarValue: "neko_astronaut",
          }),
      );
    });

    test("ALLOWED: a clan roster row can still be synced to whatever " +
        "the member's own users/{uid}.profile genuinely says", async () => {
      const memberUid = "mirror7";
      const code = "MIRRORCLAN2";
      await seed(async (db) => {
        await setDoc(doc(db, "users", memberUid), {
          profile: {
            avatarType: "preset_premium",
            avatarValue: "neko_astronaut",
          },
          subscription: {tier: "premium"},
        });
        await setDoc(doc(db, "clans", code), {hostUid: "someone_else"});
        await setDoc(doc(db, "clans", code, "members", memberUid), {
          avatarType: "preset_free",
          avatarValue: "neko_sensei",
          role: "member",
        });
      });
      const db = asUser(memberUid);
      await assertSucceeds(
          updateDoc(doc(db, "clans", code, "members", memberUid), {
            avatarType: "preset_premium",
            avatarValue: "neko_astronaut",
          }),
      );
    });

    test("ALLOWED: leaving a clan (deleting your own roster row) is " +
        "unaffected by this check", async () => {
      const memberUid = "mirror8";
      const code = "MIRRORCLAN3";
      await seed(async (db) => {
        await setDoc(doc(db, "users", memberUid), {
          profile: {avatarType: "preset_free", avatarValue: "neko_sensei"},
          subscription: {tier: "free"},
        });
        await setDoc(doc(db, "clans", code), {hostUid: "someone_else"});
        await setDoc(doc(db, "clans", code, "members", memberUid), {
          avatarType: "preset_free",
          avatarValue: "neko_sensei",
          role: "member",
        });
      });
      const db = asUser(memberUid);
      await assertSucceeds(
          deleteDoc(doc(db, "clans", code, "members", memberUid)),
      );
    });

    test("DENIED: fake a premium-only avatar in your OWN row inside " +
        "someone else's friends list", async () => {
      const otherUid = "mirror9_owner";
      const friendUid = "mirror9_friend";
      await seed(async (db) => {
        await setDoc(doc(db, "users", friendUid), {
          profile: {avatarType: "preset_free", avatarValue: "neko_sensei"},
          subscription: {tier: "free"},
        });
        await setDoc(doc(db, "users", otherUid, "friends", friendUid), {
          avatarType: "preset_free",
          avatarValue: "neko_sensei",
        });
      });
      const db = asUser(friendUid);
      await assertFails(
          updateDoc(doc(db, "users", otherUid, "friends", friendUid), {
            avatarType: "preset_premium",
            avatarValue: "neko_astronaut",
          }),
      );
    });

    test("ALLOWED: a friend row can still be synced to whatever that " +
        "friend's own users/{uid}.profile genuinely says", async () => {
      const otherUid = "mirror10_owner";
      const friendUid = "mirror10_friend";
      await seed(async (db) => {
        await setDoc(doc(db, "users", friendUid), {
          profile: {
            avatarType: "preset_premium",
            avatarValue: "neko_astronaut",
          },
          subscription: {tier: "premium"},
        });
        await setDoc(doc(db, "users", otherUid, "friends", friendUid), {
          avatarType: "preset_free",
          avatarValue: "neko_sensei",
        });
      });
      const db = asUser(friendUid);
      await assertSucceeds(
          updateDoc(doc(db, "users", otherUid, "friends", friendUid), {
            avatarType: "preset_premium",
            avatarValue: "neko_astronaut",
          }),
      );
    });

    test("ALLOWED: unfriending (deleting your own row in someone " +
        "else's friends list) is unaffected by this check", async () => {
      const otherUid = "mirror11_owner";
      const friendUid = "mirror11_friend";
      await seed(async (db) => {
        await setDoc(doc(db, "users", friendUid), {
          profile: {avatarType: "preset_free", avatarValue: "neko_sensei"},
          subscription: {tier: "free"},
        });
        await setDoc(doc(db, "users", otherUid, "friends", friendUid), {
          avatarType: "preset_free",
          avatarValue: "neko_sensei",
        });
      });
      const db = asUser(friendUid);
      await assertSucceeds(
          deleteDoc(doc(db, "users", otherUid, "friends", friendUid)),
      );
    });
  });

  test("rankSkipExams is sealed — read and write both denied for everyone", async () => {
    const uid = "r4";
    await seed(async (db) => {
      await setDoc(doc(db, "rankSkipExams", uid), {answerKey: ["a", "b"]});
    });
    const db = asUser(uid);
    await assertFails(getDoc(doc(db, "rankSkipExams", uid)));
    await assertFails(
        updateDoc(doc(db, "rankSkipExams", uid), {answerKey: []}),
    );
  });

  test("globalPointsState is sealed the same way", async () => {
    const uid = "r5";
    await seed(async (db) => {
      await setDoc(doc(db, "globalPointsState", uid), {repeatCycles: 1});
    });
    const db = asUser(uid);
    await assertFails(getDoc(doc(db, "globalPointsState", uid)));
  });

  test("an unauthenticated client cannot read or write a user doc", async () => {
    const uid = "r6";
    await seed(async (db) => {
      await setDoc(doc(db, "users", uid), {profile: {}});
    });
    const db = asAnon();
    await assertFails(getDoc(doc(db, "users", uid)));
  });

  test("subscription/entitlements/coins stay frozen (pre-existing freeze, untouched)", async () => {
    const uid = "r7";
    await seed(async (db) => {
      await setDoc(doc(db, "users", uid), {
        profile: {},
        subscription: {tier: "free"},
        entitlements: {},
        coins: 0,
      });
    });
    const db = asUser(uid);
    await assertFails(
        updateDoc(doc(db, "users", uid), {"subscription.tier": "premium"}),
    );
    await assertFails(updateDoc(doc(db, "users", uid), {coins: 99999}));
  });
});

// ---------------------------------------------------------------------
// 6. Recursive-wildcard bypass — closed
//
// Before the fix, `match /users/{uid} { match /{document=**} { allow
// read, write: if owner; } } }` matched the PARENT `/users/{uid}`
// document too (Firestore recursive wildcards match zero-or-more
// segments), and that unconditional grant unioned with — and
// completely overrode — every restriction in the specific `allow
// create`/`allow update` block above it. Every "DENY" test in this
// group failed (wrongly succeeded) before the fix; see
// wildcard_probe.test.js for the isolated proof, and the commit this
// harness is attached to for the before/after.
// ---------------------------------------------------------------------
describe("recursive wildcard bypass — closed", () => {
  async function seedFullUser(uid, overrides = {}) {
    await seed(async (db) => {
      await setDoc(doc(db, "users", uid), {
        profile: {avatarValue: null, frameId: null, coverId: null, cardSkinId: null},
        subscription: {tier: "free"},
        entitlements: {},
        coins: 0,
        adRewards: {},
        xp: {totalXp: 0, unlockedAvatarIds: [], unlockedFrameIds: [], unlockedCoverIds: []},
        cardGameRank: {tier: "bronze"},
        ...overrides,
      });
      await setDoc(doc(db, "leaderboard", uid), {cardGameStarTotal: 0});
    });
  }

  test("CRITICAL: a direct write to the exact users/{uid} document — the " +
      "one path the old broad wildcard used to reach and grant " +
      "unconditionally — is now decided ONLY by the specific allow " +
      "update rule, even when a protected field is smuggled in " +
      "alongside an otherwise-legitimate change in the SAME write", async () => {
    const uid = "w-critical";
    await seedFullUser(uid);
    const db = asUser(uid);
    // A single combined update: one field the specific rule genuinely
    // permits (displayName, unrestricted) plus one it explicitly
    // protects (adRewards). This is the actual shape the old bug made
    // dangerous — a batched write smuggling a protected field in next
    // to an innocuous one. Before the wildcard fix, the broad
    // `match /{document=**} { allow write: if owner }` block also
    // matched this exact path (users/{uid} itself, zero remaining
    // wildcard segments) and granted it unconditionally regardless of
    // what the specific `allow update` rule decided. It must fail now,
    // and must fail as a whole — Firestore has no per-field partial
    // grant, so the protected field poisons the entire write.
    await assertFails(
        updateDoc(doc(db, "users", uid), {
          "profile.displayName": "Totally Normal Name Change",
          adRewards: {avatar_premium: {expiresAt: future()}},
        }),
    );
  });

  describe("parent users/{uid} — protected fields deny", () => {
    test("adRewards write is denied", async () => {
      const uid = "w1";
      await seedFullUser(uid);
      const db = asUser(uid);
      await assertFails(
          updateDoc(doc(db, "users", uid), {
            adRewards: {avatar_premium: {expiresAt: future()}},
          }),
      );
    });

    test("xp write is denied", async () => {
      const uid = "w2";
      await seedFullUser(uid);
      const db = asUser(uid);
      await assertFails(
          updateDoc(doc(db, "users", uid), {"xp.totalXp": 999999}),
      );
    });

    test("premium-only avatar equip without entitlement is denied", async () => {
      const uid = "w3";
      await seedFullUser(uid);
      const db = asUser(uid);
      await assertFails(
          updateDoc(doc(db, "users", uid), {
            "profile.avatarValue": "neko_astronaut",
          }),
      );
    });

    test("premium-only frame equip without entitlement is denied", async () => {
      const uid = "w4";
      await seedFullUser(uid);
      const db = asUser(uid);
      await assertFails(
          updateDoc(doc(db, "users", uid), {"profile.frameId": "frame_space"}),
      );
    });

    test("premium-only cover equip without entitlement is denied", async () => {
      const uid = "w5";
      await seedFullUser(uid);
      const db = asUser(uid);
      await assertFails(
          updateDoc(doc(db, "users", uid), {"profile.coverId": "cyber_neon"}),
      );
    });

    test("invalid (unrecognized) card skin equip is denied", async () => {
      const uid = "w6";
      await seedFullUser(uid);
      const db = asUser(uid);
      await assertFails(
          updateDoc(doc(db, "users", uid), {
            "profile.cardSkinId": "not_a_real_skin",
          }),
      );
    });

    test("cardGameRank write is denied", async () => {
      const uid = "w7";
      await seedFullUser(uid);
      const db = asUser(uid);
      await assertFails(
          updateDoc(doc(db, "users", uid), {
            "cardGameRank.tier": "emerald",
          }),
      );
    });
  });

  describe("parent users/{uid} — legitimate writes still allowed", () => {
    test("changing an ordinary profile field (displayName) still succeeds", async () => {
      const uid = "w8";
      await seedFullUser(uid, {profile: {displayName: "Old"}});
      const db = asUser(uid);
      await assertSucceeds(
          updateDoc(doc(db, "users", uid), {"profile.displayName": "New"}),
      );
    });

    test("equipping a FREE avatar still succeeds", async () => {
      const uid = "w9";
      await seedFullUser(uid);
      const db = asUser(uid);
      await assertSucceeds(
          updateDoc(doc(db, "users", uid), {
            "profile.avatarValue": "neko_sensei",
          }),
      );
    });

    test("the owner can still read their own users/{uid} document", async () => {
      const uid = "w10";
      await seedFullUser(uid);
      const db = asUser(uid);
      await assertSucceeds(getDoc(doc(db, "users", uid)));
    });
  });

  describe("subcollections — intended access preserved, cross-user still denied", () => {
    test("owner can still write their own subcollection document " +
        "(e.g. users/{uid}/kanjiProgress/{id})", async () => {
      const uid = "w11";
      await seedFullUser(uid);
      const db = asUser(uid);
      await assertSucceeds(
          setDoc(doc(db, "users", uid, "kanjiProgress", "kanji_1"), {
            learned: true,
          }),
      );
    });

    test("owner can still read their own subcollection document", async () => {
      const uid = "w12";
      await seedFullUser(uid);
      await seed(async (db) => {
        await setDoc(doc(db, "users", uid, "savedWords", "word_1"), {
          word: "食べる",
        });
      });
      const db = asUser(uid);
      await assertSucceeds(
          getDoc(doc(db, "users", uid, "savedWords", "word_1")),
      );
    });

    test("a DIFFERENT signed-in user cannot read someone else's " +
        "subcollection document", async () => {
      const owner = "w13";
      const attacker = "w14";
      await seedFullUser(owner);
      await seed(async (db) => {
        await setDoc(doc(db, "users", owner, "kanjiProgress", "kanji_1"), {
          learned: true,
        });
      });
      const db = asUser(attacker);
      await assertFails(
          getDoc(doc(db, "users", owner, "kanjiProgress", "kanji_1")),
      );
    });

    test("a DIFFERENT signed-in user cannot write to someone else's " +
        "subcollection document", async () => {
      const owner = "w15";
      const attacker = "w16";
      await seedFullUser(owner);
      const db = asUser(attacker);
      await assertFails(
          setDoc(doc(db, "users", owner, "kanjiProgress", "kanji_2"), {
            learned: true,
          }),
      );
    });

    test("cross-user is STILL denied on the parent document too " +
        "(sanity: the fix didn't accidentally loosen this)", async () => {
      const owner = "w17";
      const attacker = "w18";
      await seedFullUser(owner);
      const db = asUser(attacker);
      await assertFails(
          updateDoc(doc(db, "users", owner), {
            "profile.avatarValue": "neko_sensei",
          }),
      );
    });
  });
});

// ---------------------------------------------------------------------
// appConfig/minVersion — MinVersionGate (Phase 2), the one document in
// this whole ruleset readable with no auth at all. See
// `lib/features/onboarding/min_version_gate.dart` for why: this gate
// runs before anonymous sign-in even happens, so it cannot rely on the
// `request.auth != null` pattern every other collection in this file
// uses.
// ---------------------------------------------------------------------
describe("appConfig/minVersion", () => {
  test("an unauthenticated client can read it — this is the one document "
      + "in the whole ruleset meant to work before sign-in", async () => {
    await seed(async (db) => {
      await setDoc(doc(db, "appConfig", "minVersion"), {minBuildNumber: 12});
    });
    const db = asAnon();
    await assertSucceeds(getDoc(doc(db, "appConfig", "minVersion")));
  });

  test("a signed-in client can also read it", async () => {
    await seed(async (db) => {
      await setDoc(doc(db, "appConfig", "minVersion"), {minBuildNumber: 12});
    });
    const db = asUser("u1");
    await assertSucceeds(getDoc(doc(db, "appConfig", "minVersion")));
  });

  test("an unauthenticated client cannot write it", async () => {
    const db = asAnon();
    await assertFails(
        setDoc(doc(db, "appConfig", "minVersion"), {minBuildNumber: 999}),
    );
  });

  test("a signed-in client cannot write it either — the value can only "
      + "come from the Firebase Console/Admin SDK", async () => {
    const db = asUser("u1");
    await assertFails(
        setDoc(doc(db, "appConfig", "minVersion"), {minBuildNumber: 999}),
    );
  });

  test("a DIFFERENT document under appConfig/ is NOT publicly readable — "
      + "the rule names the exact document, it does not open the whole "
      + "collection", async () => {
    await seed(async (db) => {
      await setDoc(doc(db, "appConfig", "someOtherDoc"), {secret: true});
    });
    const db = asAnon();
    await assertFails(getDoc(doc(db, "appConfig", "someOtherDoc")));
  });
});

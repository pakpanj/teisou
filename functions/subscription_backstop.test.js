/**
 * Regression coverage for `subscription_backstop.js` — RISK-3's
 * self-healing backstop for a stale `subscription.tier` when
 * `onPlayRtdn` (the only downgrade path) never fires. Follows the same
 * pattern `iap.test.js`/`battle_abandonment_sweep.js`'s own tests
 * already use: real decision functions (imported, never reimplemented),
 * `FakeFirestore` for anything that touches Firestore, and a small fake
 * Play client injected the same way `claimAndGrant` already accepts an
 * injected `options.firestore`.
 *
 * Run from functions/: `node --test`
 */

const test = require("node:test");
const assert = require("node:assert");

const {FakeFirestore} = require("./test_helpers/fake_firestore");
const {PREMIUM_PRODUCT} = require("./iap");
const backstop = require("./subscription_backstop")._internal;

const {
  isRecentlyUpdated,
  pickCurrentToken,
  processCandidate,
  findNearExpiryCandidates,
  findAllPremiumCandidates,
  processAll,
  runDailySweep,
  runWeeklySweep,
  NEAR_EXPIRY_WINDOW_MS,
} = backstop;

const UID = "uid-backstop-1";
const TOKEN = "token-backstop-1";

function fakePlayClient(handler) {
  return {
    purchases: {
      subscriptionsv2: {
        get: async (args) => handler(args),
      },
    },
  };
}

function activeResponse({uid, expiryTime} = {}) {
  return {
    data: {
      subscriptionState: "SUBSCRIPTION_STATE_ACTIVE",
      externalAccountIdentifiers: uid ?
        {obfuscatedExternalAccountId: uid} : undefined,
      lineItems: expiryTime ? [{expiryTime}] : [],
    },
  };
}

function expiredResponse() {
  return {
    data: {
      subscriptionState: "SUBSCRIPTION_STATE_EXPIRED",
      lineItems: [],
    },
  };
}

function seedPremiumUser(fake, uid, {
  expiresAt,
  updatedAt,
  hasExpiresAtKey = true,
} = {}) {
  const subscription = {tier: "premium"};
  if (hasExpiresAtKey) subscription.expiresAt = expiresAt;
  if (updatedAt) subscription.updatedAt = updatedAt;
  fake.seed(`users/${uid}`, {profile: {}, subscription});
}

function seedToken(fake, {
  uid,
  token = TOKEN,
  productId = PREMIUM_PRODUCT,
  grantedAt,
  claimedVia = "account-match",
}) {
  fake.seed(`processedPurchaseTokens/${token}`, {
    uid, productId, grantedAt, claimedVia,
  });
}

// ---------------------------------------------------------------------
// 1. expired premium + valid token -> downgrade to free
// ---------------------------------------------------------------------
test("expired premium subscription with a valid token downgrades to free",
    async () => {
      const now = Date.now();
      const fake = new FakeFirestore();
      seedPremiumUser(fake, UID, {
        expiresAt: new Date(now - 10 * 24 * 60 * 60 * 1000),
        updatedAt: new Date(now - 30 * 24 * 60 * 60 * 1000),
      });
      seedToken(fake, {uid: UID, grantedAt: new Date(now - 30 * 24 * 60 * 60 * 1000)});

      const result = await processCandidate({
        uid: UID,
        subscriptionData: (await fake.collection("users").doc(UID).get())
            .data().subscription,
        firestore: fake,
        playClient: fakePlayClient(() => expiredResponse()),
        now,
        dryRun: false,
      });

      assert.strictEqual(result.outcome, "downgraded");
      const userDoc = fake.docs.get(`users/${UID}`);
      assert.strictEqual(userDoc.data.subscription.tier, "free");
    });

// ---------------------------------------------------------------------
// 2. premium far from expiry -> not in the daily query
// ---------------------------------------------------------------------
test("a premium account far from expiry is excluded from the daily " +
    "near-expiry query", async () => {
  const now = Date.now();
  const fake = new FakeFirestore();
  seedPremiumUser(fake, "near-expiry", {
    expiresAt: new Date(now + 1 * 24 * 60 * 60 * 1000), // 1 day out
  });
  seedPremiumUser(fake, "far-from-expiry", {
    expiresAt: new Date(now + 60 * 24 * 60 * 60 * 1000), // 60 days out
  });

  const candidates = await findNearExpiryCandidates(fake, now);
  const uids = candidates.map((c) => c.uid);

  assert.ok(uids.includes("near-expiry"));
  assert.ok(
      !uids.includes("far-from-expiry"),
      "an account nowhere near its renewal window must not be a daily " +
      "sweep candidate — the whole point of scoping the query",
  );
});

// ---------------------------------------------------------------------
// 3. Play still ACTIVE + new expiry -> stays premium, expiresAt updated
// ---------------------------------------------------------------------
test("Play still reports ACTIVE with a new expiry — stays premium and " +
    "expiresAt is updated (a missed-renewal self-heal, not just a " +
    "missed-cancellation one)", async () => {
  const now = Date.now();
  const fake = new FakeFirestore();
  const oldExpiry = new Date(now - 1000);
  seedPremiumUser(fake, UID, {
    expiresAt: oldExpiry,
    updatedAt: new Date(now - 24 * 60 * 60 * 1000),
  });
  seedToken(fake, {uid: UID, grantedAt: new Date(now - 60 * 24 * 60 * 60 * 1000)});

  const newExpiryIso = new Date(now + 30 * 24 * 60 * 60 * 1000).toISOString();
  const result = await processCandidate({
    uid: UID,
    subscriptionData: {tier: "premium", expiresAt: oldExpiry},
    firestore: fake,
    playClient: fakePlayClient(
        () => activeResponse({uid: UID, expiryTime: newExpiryIso}),
    ),
    now,
    dryRun: false,
  });

  assert.strictEqual(result.outcome, "reconfirmed");
  const userDoc = fake.docs.get(`users/${UID}`);
  assert.strictEqual(userDoc.data.subscription.tier, "premium");
  assert.strictEqual(
      userDoc.data.subscription.expiresAt.toISOString(),
      newExpiryIso,
  );
});

// ---------------------------------------------------------------------
// 4. Play API error -> skip, never downgrade
// ---------------------------------------------------------------------
test("a Play API error is skipped, never read as a denial", async () => {
  const now = Date.now();
  const fake = new FakeFirestore();
  seedPremiumUser(fake, UID, {expiresAt: new Date(now - 1000)});
  seedToken(fake, {uid: UID, grantedAt: new Date(now - 1000)});

  const result = await processCandidate({
    uid: UID,
    subscriptionData: {tier: "premium", expiresAt: new Date(now - 1000)},
    firestore: fake,
    playClient: fakePlayClient(() => {
      throw Object.assign(new Error("quota exceeded"), {code: 429});
    }),
    now,
    dryRun: false,
  });

  assert.strictEqual(result.outcome, "skipped_play_error");
  const userDoc = fake.docs.get(`users/${UID}`);
  assert.strictEqual(
      userDoc.data.subscription.tier,
      "premium",
      "an unreachable Play API must never cause a downgrade",
  );
});

// ---------------------------------------------------------------------
// 5. one candidate errors -> the rest still get processed
// ---------------------------------------------------------------------
test("one candidate throwing an unexpected error does not stop the " +
    "rest of the batch", async () => {
  const now = Date.now();
  const fake = new FakeFirestore();
  seedPremiumUser(fake, "broken-candidate", {expiresAt: new Date(now - 1000)});
  seedPremiumUser(fake, "healthy-candidate", {expiresAt: new Date(now - 1000)});
  seedToken(fake, {
    uid: "healthy-candidate",
    token: "token-healthy",
    grantedAt: new Date(now - 1000),
  });
  // Deliberately no token seeded for "broken-candidate" — instead we
  // make ONLY its own Firestore query throw (scoped by the uid it
  // queries for), simulating a genuine unexpected failure for that one
  // candidate specifically, never the "no token" case and never the
  // other candidate.
  const throwingFirestore = {
    collection: (name) => {
      if (name !== "processedPurchaseTokens") return fake.collection(name);
      return {
        where: (field, op, value) => {
          if (field === "uid" && value === "broken-candidate") {
            return {get: async () => {
              throw new Error("simulated Firestore outage");
            }};
          }
          return fake.collection(name).where(field, op, value);
        },
      };
    },
  };

  const results = await processAll(
      [
        {uid: "broken-candidate", subscriptionData: {tier: "premium"}},
        {uid: "healthy-candidate", subscriptionData: {tier: "premium"}},
      ],
      {
        firestore: throwingFirestore,
        now,
        dryRun: false,
        // Without this, "healthy-candidate" would fall through to
        // processCandidate's own default (a real publisher() client),
        // hitting the real network for no reason and making this test
        // slow/flaky.
        playClient: fakePlayClient(
            () => activeResponse({uid: "healthy-candidate"}),
        ),
      },
  );

  const byUid = Object.fromEntries(results.map((r) => [r.uid, r]));
  assert.strictEqual(byUid["broken-candidate"].outcome, "unexpected_error");
  // The healthy candidate still gets processed despite the other one's
  // Firestore call throwing — this proves the try/catch is per-candidate.
  assert.notStrictEqual(byUid["healthy-candidate"].outcome, "unexpected_error");
});

// ---------------------------------------------------------------------
// 6. no processed token -> skip safely
// ---------------------------------------------------------------------
test("a premium account with no processedPurchaseTokens entry is " +
    "skipped safely, never a crash", async () => {
  const now = Date.now();
  const fake = new FakeFirestore();
  seedPremiumUser(fake, UID, {expiresAt: new Date(now - 1000)});
  // No token seeded at all.

  const result = await processCandidate({
    uid: UID,
    subscriptionData: {tier: "premium", expiresAt: new Date(now - 1000)},
    firestore: fake,
    playClient: fakePlayClient(() => {
      throw new Error("must never be called — no token to check");
    }),
    now,
    dryRun: false,
  });

  assert.strictEqual(result.outcome, "skipped_missing_token");
});

// ---------------------------------------------------------------------
// 7. claimedVia/firstClaimed produces the same decision RTDN would
// ---------------------------------------------------------------------
test("a first-claimed (unbound) token still reconfirms premium via " +
    "state alone, matching onPlayRtdn's own isStillActive behavior",
async () => {
  const now = Date.now();
  const fake = new FakeFirestore();
  seedPremiumUser(fake, UID, {expiresAt: new Date(now - 1000)});
  seedToken(fake, {
    uid: UID,
    grantedAt: new Date(now - 1000),
    claimedVia: "first-claim",
  });

  // Play reports ACTIVE but with NO externalAccountIdentifiers at all —
  // exactly the "legacy unbound token" shape. subscriptionGrants alone
  // would read this as false; isStillActive must still say active here
  // because firstClaimed bypasses the account check (see
  // subscription_notifications.js's own doc comment on isStillActive).
  const result = await processCandidate({
    uid: UID,
    subscriptionData: {tier: "premium", expiresAt: new Date(now - 1000)},
    firestore: fake,
    playClient: fakePlayClient(() => activeResponse({})), // no uid attached
    now,
    dryRun: false,
  });

  assert.strictEqual(
      result.outcome,
      "reconfirmed",
      "firstClaimed must be correctly read from claimedVia and change " +
      "the decision the same way it changes onPlayRtdn's own",
  );
});

// ---------------------------------------------------------------------
// 8. weekly legacy premium with no expiresAt -> processed
// ---------------------------------------------------------------------
test("a legacy premium account with no expiresAt at all is found by " +
    "the weekly sweep's query but NOT the daily one", async () => {
  const now = Date.now();
  const fake = new FakeFirestore();
  seedPremiumUser(fake, "legacy-no-expiry", {hasExpiresAtKey: false});

  const daily = await findNearExpiryCandidates(fake, now);
  assert.ok(
      !daily.map((c) => c.uid).includes("legacy-no-expiry"),
      "a Firestore inequality filter excludes a document missing the " +
      "filtered field entirely — this is exactly why the weekly sweep " +
      "has to exist",
  );

  const weekly = await findAllPremiumCandidates(fake);
  assert.ok(weekly.map((c) => c.uid).includes("legacy-no-expiry"));
});

// ---------------------------------------------------------------------
// 9. idempotent repeat processing
// ---------------------------------------------------------------------
test("processing the same still-active candidate twice (clock advanced " +
    "past the recently-updated guard) converges, does not drift",
async () => {
  const now = Date.now();
  const fake = new FakeFirestore();
  seedPremiumUser(fake, UID, {
    expiresAt: new Date(now - 1000),
    updatedAt: new Date(now - 24 * 60 * 60 * 1000),
  });
  seedToken(fake, {uid: UID, grantedAt: new Date(now - 1000)});

  const expiryIso = new Date(now + 30 * 24 * 60 * 60 * 1000).toISOString();
  const playClient = fakePlayClient(
      () => activeResponse({uid: UID, expiryTime: expiryIso}),
  );

  const first = await processCandidate({
    uid: UID,
    subscriptionData: (await fake.collection("users").doc(UID).get())
        .data().subscription,
    firestore: fake, playClient, now, dryRun: false,
  });
  assert.strictEqual(first.outcome, "reconfirmed");

  // Advance well past the 10-minute recently-updated guard before
  // reprocessing, so this genuinely re-runs the decision rather than
  // being skipped by the guard (that's test #10, separately).
  const laterNow = now + 20 * 60 * 1000;
  const second = await processCandidate({
    uid: UID,
    subscriptionData: fake.docs.get(`users/${UID}`).data.subscription,
    firestore: fake, playClient, now: laterNow, dryRun: false,
  });

  assert.strictEqual(second.outcome, "reconfirmed");
  const userDoc = fake.docs.get(`users/${UID}`);
  assert.strictEqual(userDoc.data.subscription.tier, "premium");
  assert.strictEqual(userDoc.data.subscription.expiresAt.toISOString(), expiryIso);
});

// ---------------------------------------------------------------------
// 10. recently-updated candidate -> skip
// ---------------------------------------------------------------------
test("a candidate updated moments ago is skipped without even being " +
    "queried further", async () => {
  const now = Date.now();
  assert.strictEqual(
      isRecentlyUpdated({updatedAt: new Date(now - 2 * 60 * 1000)}, now),
      true,
  );
  assert.strictEqual(
      isRecentlyUpdated({updatedAt: new Date(now - 20 * 60 * 1000)}, now),
      false,
  );

  const result = await processCandidate({
    uid: UID,
    subscriptionData: {tier: "premium", updatedAt: new Date(now - 2 * 60 * 1000)},
    firestore: {collection: () => {
      throw new Error("must never be reached — the guard must short-circuit");
    }},
    playClient: fakePlayClient(() => {
      throw new Error("must never be called");
    }),
    now,
    dryRun: false,
  });

  assert.strictEqual(result.outcome, "skipped_recently_updated");
});

// ---------------------------------------------------------------------
// 11. RTDN/backstop race — final state follows the latest Play data
// ---------------------------------------------------------------------
test("RTDN and the backstop racing on the same account: whichever " +
    "write actually lands last reflects Play's true state, no " +
    "corruption either way", async () => {
  const now = Date.now();
  const fake = new FakeFirestore();
  seedPremiumUser(fake, UID, {
    expiresAt: new Date(now - 1000),
    updatedAt: new Date(now - 24 * 60 * 60 * 1000),
  });
  seedToken(fake, {uid: UID, grantedAt: new Date(now - 1000)});

  // The backstop runs first and (correctly, per Play at that moment)
  // downgrades.
  await processCandidate({
    uid: UID,
    subscriptionData: fake.docs.get(`users/${UID}`).data.subscription,
    firestore: fake,
    playClient: fakePlayClient(() => expiredResponse()),
    now,
    dryRun: false,
  });
  assert.strictEqual(fake.docs.get(`users/${UID}`).data.subscription.tier, "free");

  // "RTDN" fires moments later — the learner actually renewed in
  // between. Simulated the same way onPlayRtdn itself writes: reusing
  // buildSubscriptionPatch directly against the same document.
  const {buildSubscriptionPatch} = require("./subscription_notifications");
  const renewedResponse = activeResponse({
    uid: UID,
    expiryTime: new Date(now + 30 * 24 * 60 * 60 * 1000).toISOString(),
  }).data;
  await fake.collection("users").doc(UID).set(
      {subscription: buildSubscriptionPatch(true, renewedResponse)},
      {merge: true},
  );

  const finalDoc = fake.docs.get(`users/${UID}`);
  assert.strictEqual(
      finalDoc.data.subscription.tier,
      "premium",
      "the LAST write (RTDN's, reflecting the real renewal) must win — " +
      "not the backstop's earlier, now-stale downgrade",
  );
});

// ---------------------------------------------------------------------
// 12. never downgrade a genuinely active subscription
// ---------------------------------------------------------------------
test("a genuinely active subscription is never downgraded", async () => {
  const now = Date.now();
  const fake = new FakeFirestore();
  seedPremiumUser(fake, UID, {
    expiresAt: new Date(now + 10 * 24 * 60 * 60 * 1000),
    updatedAt: new Date(now - 24 * 60 * 60 * 1000),
  });
  seedToken(fake, {uid: UID, grantedAt: new Date(now - 1000)});

  const result = await processCandidate({
    uid: UID,
    subscriptionData: fake.docs.get(`users/${UID}`).data.subscription,
    firestore: fake,
    playClient: fakePlayClient(
        () => activeResponse({
          uid: UID,
          expiryTime: new Date(now + 10 * 24 * 60 * 60 * 1000).toISOString(),
        }),
    ),
    now,
    dryRun: false,
  });

  assert.notStrictEqual(result.outcome, "downgraded");
  assert.strictEqual(fake.docs.get(`users/${UID}`).data.subscription.tier, "premium");
});

// ---------------------------------------------------------------------
// Extra: dry-run never writes, even when it would downgrade
// ---------------------------------------------------------------------
test("dry run (the default, SUBSCRIPTION_BACKSTOP_ENABLED unset) never " +
    "writes to Firestore, even for a candidate that would downgrade",
async () => {
  const now = Date.now();
  const fake = new FakeFirestore();
  seedPremiumUser(fake, UID, {expiresAt: new Date(now - 1000)});
  seedToken(fake, {uid: UID, grantedAt: new Date(now - 1000)});
  delete process.env.SUBSCRIPTION_BACKSTOP_ENABLED;

  const result = await processCandidate({
    uid: UID,
    subscriptionData: {tier: "premium", expiresAt: new Date(now - 1000)},
    firestore: fake,
    playClient: fakePlayClient(() => expiredResponse()),
    now,
    // dryRun intentionally omitted — must default from the env flag.
  });

  assert.strictEqual(result.outcome, "would_downgrade");
  assert.strictEqual(
      fake.docs.get(`users/${UID}`).data.subscription.tier,
      "premium",
      "dry run must never actually write",
  );
});

// ---------------------------------------------------------------------
// Extra: pure helper coverage
// ---------------------------------------------------------------------
test("pickCurrentToken picks the newest matching-product token, " +
    "ignores other products, and returns null when none match", () => {
  const now = Date.now();
  const docs = [
    {id: "old", data: {productId: PREMIUM_PRODUCT, grantedAt: new Date(now - 90 * 24 * 60 * 60 * 1000)}},
    {id: "newest", data: {productId: PREMIUM_PRODUCT, grantedAt: new Date(now - 1000)}},
    {id: "middle", data: {productId: PREMIUM_PRODUCT, grantedAt: new Date(now - 30 * 24 * 60 * 60 * 1000)}},
    {id: "unrelated-skin", data: {productId: "skin_cloud_white", grantedAt: new Date(now)}},
  ];
  const picked = pickCurrentToken(docs, PREMIUM_PRODUCT);
  assert.strictEqual(picked.id, "newest");

  assert.strictEqual(pickCurrentToken([], PREMIUM_PRODUCT), null);
  assert.strictEqual(
      pickCurrentToken(
          [{id: "a", data: {productId: "skin_cloud_white", grantedAt: new Date()}}],
          PREMIUM_PRODUCT,
      ),
      null,
  );
});

// ---------------------------------------------------------------------
// Extra: playConfigured() gate on the sweep orchestrators themselves
// ---------------------------------------------------------------------
test("runDailySweep/runWeeklySweep skip entirely (no candidates even " +
    "queried) when Play verification is not configured", async () => {
  const originalEnv = process.env.PLAY_VERIFICATION_ENABLED;
  delete process.env.PLAY_VERIFICATION_ENABLED;
  try {
    const throwingFirestore = {
      collection: () => {
        throw new Error("must never be queried while unconfigured");
      },
    };
    const dailyResult = await runDailySweep({firestore: throwingFirestore});
    assert.strictEqual(dailyResult.skipped, "play_not_configured");
    const weeklyResult = await runWeeklySweep({firestore: throwingFirestore});
    assert.strictEqual(weeklyResult.skipped, "play_not_configured");
  } finally {
    if (originalEnv === undefined) {
      delete process.env.PLAY_VERIFICATION_ENABLED;
    } else {
      process.env.PLAY_VERIFICATION_ENABLED = originalEnv;
    }
  }
});

test("runDailySweep end-to-end against FakeFirestore: finds, processes, " +
    "and summarizes candidates when configured and enabled", async () => {
  const originalPlay = process.env.PLAY_VERIFICATION_ENABLED;
  const originalBackstop = process.env.SUBSCRIPTION_BACKSTOP_ENABLED;
  process.env.PLAY_VERIFICATION_ENABLED = "true";
  process.env.SUBSCRIPTION_BACKSTOP_ENABLED = "true";
  try {
    const now = Date.now();
    const fake = new FakeFirestore();
    seedPremiumUser(fake, UID, {expiresAt: new Date(now - 1000)});
    seedToken(fake, {uid: UID, grantedAt: new Date(now - 1000)});

    // playClient is threaded through runDailySweep -> processAll ->
    // processCandidate the same way firestore already is — without this,
    // processCandidate's own default (`publisher()`) would build a real
    // Android Publisher client and this test would depend on network
    // access and real credentials.
    const result = await runDailySweep({
      firestore: fake,
      now,
      playClient: fakePlayClient(() => expiredResponse()),
    });
    assert.strictEqual(result.candidates, 1);
    assert.strictEqual(result.dryRun, false);
    assert.deepStrictEqual(result.summary, {downgraded: 1});
    assert.strictEqual(fake.docs.get(`users/${UID}`).data.subscription.tier, "free");
  } finally {
    if (originalPlay === undefined) {
      delete process.env.PLAY_VERIFICATION_ENABLED;
    } else {
      process.env.PLAY_VERIFICATION_ENABLED = originalPlay;
    }
    if (originalBackstop === undefined) {
      delete process.env.SUBSCRIPTION_BACKSTOP_ENABLED;
    } else {
      process.env.SUBSCRIPTION_BACKSTOP_ENABLED = originalBackstop;
    }
  }
});

// RISK-5 regression coverage for functions/spend_coins.js.
//
// Concurrency is forced into a genuine interleaving via FakeFirestore's
// `beforeCommit` hook — the same technique `iap.test.js`'s
// "claimAndGrant: two concurrent first-claims" test and
// `global_points_reliability.test.js` already established for this
// codebase — rather than hoping Node's own scheduling happens to
// interleave two plain `await`ed calls usefully.
//
// spend_coins.js's own `spendCoinsFor(uid, kind, id, options)` is tested
// directly via `options.firestore` dependency injection (RISK-5 added
// this seam; every business-logic assertion below exercises the exact
// same code the real `spendCoins` callable runs — no logic was changed
// by extracting it). The one thing `spendCoinsFor` does NOT cover —
// the `onCall` wrapper's own auth check — is tested separately below via
// `spendCoins.run(...)`, `onCall`'s direct-invoke entry point (confirmed
// against the installed firebase-functions v7.3.2), so the wiring between
// the callable and the extracted function is exercised too, not just the
// extracted function in isolation.
const assert = require("node:assert/strict");
const {test} = require("node:test");
const {FakeFirestore} = require("./test_helpers/fake_firestore");
const {spendCoins, spendCoinsFor} = require("./spend_coins");

// ---------------------------------------------------------------------
// Concurrency / atomicity — the core of the RISK-5 audit's server-side
// questions (double-spend, negative balance, lost update).
// ---------------------------------------------------------------------

test("two concurrent spends on the SAME (uid, kind, id) — exactly one "
    + "charge, no double-spend, second call sees it already owned",
async () => {
  let firstStarted = false;
  const fake = new FakeFirestore({
    beforeCommit: async () => {
      // Let transaction A's read-then-decide finish, pause right before
      // it commits, and give transaction B a chance to run its OWN fresh
      // read (which, since A hasn't committed yet, still sees "not
      // owned") before A actually commits — forces a genuine conflict
      // rather than two transactions that just happen to run back-to-back.
      if (!firstStarted) {
        firstStarted = true;
        await new Promise((resolve) => setTimeout(resolve, 5));
      }
    },
  });
  fake.seed("users/u1", {coins: 500});

  const [a, b] = await Promise.all([
    spendCoinsFor("u1", "avatar", "neko_artist", {firestore: fake}),
    spendCoinsFor("u1", "avatar", "neko_artist", {firestore: fake}),
  ]);

  const results = [a, b];
  const freshGrants = results.filter((r) => r.alreadyOwned === false);
  const alreadyOwnedHits = results.filter((r) => r.alreadyOwned === true);
  assert.strictEqual(
      freshGrants.length,
      1,
      "exactly one of the two concurrent calls must be the actual charge",
  );
  assert.strictEqual(
      alreadyOwnedHits.length,
      1,
      "the other must resolve as alreadyOwned, not a second charge",
  );

  const doc = fake.docs.get("users/u1").data;
  assert.strictEqual(
      doc.coins,
      350,
      "coins must be decremented exactly once (500 - 150), never twice",
  );
  assert.deepStrictEqual(doc.xp.unlockedAvatarIds, ["neko_artist"]);
});

test("two concurrent spends on DIFFERENT ids, balance enough for only "
    + "ONE — exactly one succeeds, the other is refused, balance never "
    + "goes negative",
async () => {
  let firstStarted = false;
  const fake = new FakeFirestore({
    beforeCommit: async () => {
      if (!firstStarted) {
        firstStarted = true;
        await new Promise((resolve) => setTimeout(resolve, 5));
      }
    },
  });
  fake.seed("users/u1", {coins: 150}); // exactly enough for ONE 150-coin item

  const outcomes = await Promise.allSettled([
    spendCoinsFor("u1", "avatar", "neko_artist", {firestore: fake}),
    spendCoinsFor("u1", "frame", "frame_halloween", {firestore: fake}),
  ]);

  const fulfilled = outcomes.filter((o) => o.status === "fulfilled");
  const rejected = outcomes.filter((o) => o.status === "rejected");
  assert.strictEqual(
      fulfilled.length,
      1,
      "exactly one of the two concurrent different-item purchases must "
      + "succeed when the balance can only cover one",
  );
  assert.strictEqual(rejected.length, 1);
  assert.strictEqual(rejected[0].reason.code, "failed-precondition");

  const doc = fake.docs.get("users/u1").data;
  assert.strictEqual(
      doc.coins,
      0,
      "balance must land at exactly 0, never negative",
  );
  assert.ok(
      doc.coins >= 0,
      "CRITICAL: balance must never go negative under concurrency",
  );
  const avatarGranted = (doc.xp && doc.xp.unlockedAvatarIds || [])
      .includes("neko_artist");
  const frameGranted = (doc.xp && doc.xp.unlockedFrameIds || [])
      .includes("frame_halloween");
  assert.strictEqual(avatarGranted !== frameGranted, true,
      "exactly one grant must have landed, not zero and not both");
});

// ---------------------------------------------------------------------
// Atomicity of (coin deduction) + (ownership grant) as ONE unit.
// ---------------------------------------------------------------------

test("a rejected purchase (insufficient balance) leaves BOTH coins and "
    + "ownership completely untouched — no partial state",
async () => {
  const fake = new FakeFirestore();
  fake.seed("users/u1", {coins: 10});

  await assert.rejects(
      () => spendCoinsFor("u1", "avatar", "neko_artist", {firestore: fake}),
      (err) => err.code === "failed-precondition",
  );

  const doc = fake.docs.get("users/u1").data;
  assert.strictEqual(doc.coins, 10, "coins must be untouched on refusal");
  assert.strictEqual(
      doc.xp,
      undefined,
      "no ownership field should ever be written on a refused purchase",
  );
});

// ---------------------------------------------------------------------
// Retry-after-timeout idempotency (sequential, not concurrent).
// ---------------------------------------------------------------------

test("the exact same request repeated sequentially (simulating a client "
    + "retry after a network timeout) charges only once",
async () => {
  const fake = new FakeFirestore();
  fake.seed("users/u1", {coins: 500});

  const first = await spendCoinsFor("u1", "cover", "jungle_canopy", {firestore: fake});
  const second = await spendCoinsFor("u1", "cover", "jungle_canopy", {firestore: fake});

  assert.strictEqual(first.alreadyOwned, false);
  assert.strictEqual(second.alreadyOwned, true, "the retry must not charge again");
  assert.strictEqual(fake.docs.get("users/u1").data.coins, 350);
});

// ---------------------------------------------------------------------
// Client cannot control price/reward; server re-validates against its
// own locked catalog regardless of what the client sends.
// ---------------------------------------------------------------------

test("a client-supplied price is completely ignored — the server always "
    + "charges its own KIND_PRICE regardless of what a caller passes",
async () => {
  const fake = new FakeFirestore();
  fake.seed("users/u1", {coins: 500});

  // spendCoinsFor's signature has no price parameter at all — there is
  // nothing a caller (or, transitively, a client) could even pass that
  // would change the charged amount. This is the strongest form of proof
  // available: the field genuinely doesn't exist on the code path, not
  // just "ignored if present".
  await spendCoinsFor("u1", "avatar", "neko_artist", {firestore: fake});

  assert.strictEqual(
      fake.docs.get("users/u1").data.coins,
      350,
      "the real 150-coin price must be charged, from KIND_PRICE alone",
  );
});

test("an id that is not in the server's own coin-buyable catalog is "
    + "refused, even if it is a real preset id (e.g. premium-only)",
async () => {
  const fake = new FakeFirestore();
  fake.seed("users/u1", {coins: 500});

  await assert.rejects(
      () => spendCoinsFor("u1", "avatar", "neko_astronaut", {firestore: fake}),
      (err) => err.code === "invalid-argument",
  );
  assert.strictEqual(
      fake.docs.get("users/u1").data.coins,
      500,
      "a refused, catalog-invalid id must never charge anything",
  );
});

test("an unknown kind is refused outright", async () => {
  const fake = new FakeFirestore();
  fake.seed("users/u1", {coins: 500});

  await assert.rejects(
      () => spendCoinsFor("u1", "mascot_skin", "whatever", {firestore: fake}),
      (err) => err.code === "invalid-argument",
  );
});

// ---------------------------------------------------------------------
// Already-owned path — a legitimate re-buy attempt (e.g. the same id
// already granted through a level-up reward), not a race — must still be
// free, since it's the exact mechanism idempotency relies on.
// ---------------------------------------------------------------------

test("spending on an already-owned id (owned via ANY path, not just a "
    + "prior spend — e.g. a level-up reward) is free and does not "
    + "double-charge", async () => {
  const fake = new FakeFirestore();
  fake.seed("users/u1", {coins: 500, xp: {unlockedAvatarIds: ["neko_artist"]}});

  const result = await spendCoinsFor("u1", "avatar", "neko_artist", {firestore: fake});

  assert.strictEqual(result.alreadyOwned, true);
  assert.strictEqual(
      fake.docs.get("users/u1").data.coins,
      500,
      "an id already owned through a different mechanism (e.g. XP reward) "
      + "must never be charged for again",
  );
});

// ---------------------------------------------------------------------
// The onCall wrapper's own auth check — spendCoinsFor alone can't cover
// this, since it lives only in the callable wrapper, not in the
// extracted function. Safe to call `spendCoins.run()` directly against
// the real (unmocked) firebase-admin/firestore module here: an
// unauthenticated request throws before the wrapper ever calls
// spendCoinsFor, so `getFirestore()` is never actually invoked — no DI
// substitution needed for this one case. Mirrors this codebase's own
// convention (award_xp.test.js tests `awardXpFor`/`claimXpRewardFor`
// directly and never exercises the `onCall` wrapper itself) by staying
// this minimal rather than re-testing business logic already covered
// above via direct injection.
// ---------------------------------------------------------------------

test("spendCoins (the real onCall callable) refuses an unauthenticated "
    + "request before ever calling spendCoinsFor", async () => {
  await assert.rejects(
      () => spendCoins.run({auth: undefined, data: {kind: "avatar", id: "neko_artist"}}),
      (err) => err.code === "unauthenticated",
  );
});

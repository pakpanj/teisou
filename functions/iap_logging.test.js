/**
 * Guards the logging discipline `iap.js` is supposed to follow — no
 * `purchaseToken` (not even a substring of it) ever reaches a `logger.*`
 * call, on pain of a real purchase token sitting in Cloud Logging where
 * anyone with log-read access could replay it.
 *
 * Read as source, the same way `test/iap_test.dart` already checks this
 * file's shape from the Dart side — there is no live Play API or
 * Firestore to run `verifyPurchase` against here, so the guarantee this
 * pins is "the code never passes the token to a logger call", not "no
 * token ever appears in a real log line" (which would need a live
 * invocation to prove).
 *
 * Run from functions/: `node --test`
 */

const test = require("node:test");
const assert = require("node:assert");
const fs = require("node:fs");

const source = fs.readFileSync(`${__dirname}/iap.js`, "utf8");
const rtdnSource = fs.readFileSync(
    `${__dirname}/subscription_notifications.js`, "utf8",
);

test("iap.js logs at every real decision point", () => {
  for (const marker of [
    "verifyPurchase: started",
    "verifyPurchase: Play responded",
    "verifyPurchase: granted",
    "verifyPurchase: not granted",
  ]) {
    assert.ok(source.includes(marker), `missing log line: ${marker}`);
  }
});

test("no logger.* call anywhere in iap.js mentions purchaseToken", () => {
  // A logger call spans from `logger.` to its closing `);` — checked as a
  // block rather than per-line, since several of these calls are
  // multi-line object literals.
  const calls = source.match(/logger\.(info|warn|error)\([\s\S]*?\}\);/g) || [];
  assert.ok(calls.length > 0, "no logger calls found at all — did logging get removed?");
  for (const call of calls) {
    assert.ok(
        !call.includes("purchaseToken") && !call.includes("token"),
        `a logger call mentions the token: ${call}`,
    );
  }
});

test("verifyWithPlay only retries the subscription product", () => {
  assert.ok(
      source.includes(
          "productId === PREMIUM_PRODUCT ? SUBSCRIPTION_RETRY_DELAYS_MS : []",
      ),
      "retry delays are not scoped to the subscription product alone",
  );
});

test("a final non-grant carries an explicit retryable flag, not a guess "
    + "the client has to make", () => {
  assert.ok(source.includes('throw new HttpsError("permission-denied", "Purchase is not active.", {retryable});'));
});

test("the RTDN handler still calls subscriptionsv2.get directly and does "
    + "not route through the retrying verifyWithPlay — the RTDN "
    + "architecture stays untouched", () => {
  assert.ok(rtdnSource.includes("api.purchases.subscriptionsv2.get"));
  assert.ok(!rtdnSource.includes("verifyWithPlay"));
});

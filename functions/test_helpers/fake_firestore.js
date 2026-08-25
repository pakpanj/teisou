/**
 * A minimal, in-memory Firestore double that implements just enough of
 * the Admin SDK surface `global_points.js`/`backfill_global_points.js`
 * actually use — `collection().doc().collection().doc()` chains, `.get()`,
 * `.getAll()`, and `.runTransaction()` — with **real optimistic-
 * concurrency conflict detection**, not a simplification of it.
 *
 * ## Why this exists instead of a pure-function-only test
 *
 * The reliability review this file supports asked for proof that a live
 * trigger and a backfill run racing on the same `historyDocId` still
 * produce exactly one award. That claim is entirely about Firestore's
 * own transaction semantics — whether a document a transaction never
 * `.get()`s is protected from concurrent writes (it is not), and whether
 * two transactions that DO both read the same document before writing it
 * are forced to serialize (they are, via abort-and-retry). A
 * pure-function test of [decideAward] alone cannot exercise either of
 * those — it never touches a transaction at all. Simplifying the proof
 * down to "call the pure function twice with `alreadyAwarded: true`"
 * would prove the *decision* is idempotent without proving the
 * *mechanism that reaches that decision* is race-safe, which is exactly
 * the bug this review found in the old `backfillUser`.
 *
 * ## What this fake does and does not prove
 *
 * **Does prove**: that two calls into the real transaction-shaped code
 * path (`awardPointsForHistoryDoc`, whether reached directly or via
 * `backfillUser`), racing via genuine Node event-loop interleaving on a
 * shared in-memory document store with the same conflict-detect-and-
 * retry contract real Firestore transactions have, converge to exactly
 * one committed award. This is the same class of proof a real Firestore
 * emulator would give for this specific question, built from Firestore's
 * own documented transaction contract (a transaction's read set is
 * checked for changes at commit time; on conflict, the whole transaction
 * function is re-run) rather than guessed.
 *
 * **Does not prove**: true multi-process/multi-machine concurrency (this
 * is still one Node process, one event loop — "concurrent" here means
 * "interleaved at `await` boundaries", which is the same concurrency
 * model Cloud Functions' own single execution environment has for a
 * given document anyway, since two separate Cloud Function instances
 * still ultimately serialize through the *same* real Firestore
 * transaction coordinator this fake is modeling), nor exact production
 * latency/retry-timing behavior, nor anything about Eventarc's own
 * at-least-once delivery machinery (that part is tested by directly
 * unit-testing `handleHistoryDocCreated`'s retry/rethrow decision, not by
 * this fake).
 *
 * If a future review needs a stronger guarantee than this (e.g. genuine
 * multi-process behavior, exact Firestore latency characteristics), that
 * needs the real `firebase-tools` Firestore emulator wired into this
 * project's test infrastructure — which does not exist here today (every
 * existing Cloud Function test in this project, before this file, is
 * pure-logic-only with zero Firestore dependency) — a real infrastructure
 * addition, not something to fake further around.
 */

class FakeSnapshot {
  constructor(path, doc) {
    this._path = path;
    this._exists = Boolean(doc);
    this._data = doc ? doc.data : undefined;
  }

  get id() {
    const parts = this._path.split("/");
    return parts[parts.length - 1];
  }

  get exists() {
    return this._exists;
  }

  data() {
    return this._data;
  }
}

class FakeDocRef {
  constructor(store, path) {
    this._store = store;
    this.path = path;
  }

  collection(name) {
    return new FakeCollectionRef(this._store, `${this.path}/${name}`);
  }

  async get() {
    const doc = this._store.docs.get(this.path);
    return new FakeSnapshot(this.path, doc);
  }
}

class FakeCollectionRef {
  constructor(store, path) {
    this._store = store;
    this.path = path;
  }

  doc(id) {
    return new FakeDocRef(this._store, `${this.path}/${id}`);
  }

  async get() {
    const prefix = `${this.path}/`;
    const docs = [];
    for (const [path, doc] of this._store.docs.entries()) {
      if (!path.startsWith(prefix)) continue;
      const rest = path.slice(prefix.length);
      if (rest.includes("/")) continue; // only direct children, like a real collection query
      docs.push({id: rest, data: () => doc.data});
    }
    return {docs};
  }
}

/** Applies Firestore's own `FieldValue.increment`/`serverTimestamp`
 * sentinels the same way a real `.set(data, {merge})` would, against an
 * `existing` plain-object document (or `undefined` if none). Detected by
 * constructor name rather than `instanceof` — these are internal
 * `@google-cloud/firestore` classes with no exported type to import and
 * check against directly; confirmed the exact shape via
 * `node -e "console.log(FieldValue.increment(5))"` against the real
 * installed package: `NumericIncrementTransform { operand: 5 }` and
 * `ServerTimestampTransform {}`. */
function applyWrite(existing, incomingData, merge) {
  const base = merge && existing ? {...existing} : {};
  for (const [key, value] of Object.entries(incomingData)) {
    if (value && value.constructor && value.constructor.name === "NumericIncrementTransform") {
      base[key] = (typeof base[key] === "number" ? base[key] : 0) + value.operand;
    } else if (value && value.constructor && value.constructor.name === "ServerTimestampTransform") {
      base[key] = new Date();
    } else {
      base[key] = value;
    }
  }
  return base;
}

class FakeTransaction {
  constructor(store) {
    this._store = store;
    this._reads = new Map(); // path -> version seen
    this._writes = new Map(); // path -> {data, merge}
  }

  async get(ref) {
    const doc = this._store.docs.get(ref.path);
    if (!this._reads.has(ref.path)) {
      this._reads.set(ref.path, doc ? doc.version : 0);
    }
    return new FakeSnapshot(ref.path, doc);
  }

  set(ref, data, opts) {
    this._writes.set(ref.path, {data, merge: Boolean(opts && opts.merge)});
    return this;
  }
}

class FakeFirestore {
  /**
   * @param {object} [options]
   * @param {(callNumber: number) => Error|null} [options.faultInjector]
   *   called once at the very start of every **top-level**
   *   `runTransaction()` call (`callNumber` is 1 for the first call this
   *   instance ever receives, 2 for the second, and so on — deliberately
   *   independent of the internal contention-retry loop below, which
   *   models a *different* failure class: `faultInjector` stands in for
   *   an outright infrastructure fault — a network blip, Firestore
   *   briefly unavailable — the kind of failure that reaches calling
   *   code directly rather than being silently retried by the SDK the
   *   way a contention-abort is. Return an Error (with a `.code`, e.g.
   *   `{code: 14}` for UNAVAILABLE, if the test wants it classified
   *   retryable) to make that call fail outright with no attempt at
   *   all; return `null`/`undefined` to let it proceed normally. Exists
   *   purely to test `global_points.js`'s retry/rethrow behavior
   *   without needing a real transient Firestore failure to occur, and
   *   to prove a later call (simulating a platform redelivery) still
   *   succeeds.
   * @param {(transaction: FakeTransaction) => Promise<void>} [options.beforeCommit]
   *   awaited once per attempt, after the update function resolves but
   *   before the conflict check/commit — a deliberate pause point a test
   *   can use to force two transactions into a specific, deterministic
   *   interleaving (see `global_points_reliability.test.js`'s "genuine
   *   mid-transaction conflict" test) rather than hoping Node's own
   *   scheduling happens to interleave them usefully.
   */
  constructor(options = {}) {
    this.docs = new Map(); // path -> {data, version}
    this._faultInjector = options.faultInjector || null;
    this._beforeCommit = options.beforeCommit || null;
    this._callCount = 0;
  }

  /** Test-only seam: write a document directly, bypassing any
   * transaction — used to seed fixture state before a test runs. */
  seed(path, data) {
    this.docs.set(path, {data, version: 1});
  }

  collection(name) {
    return new FakeCollectionRef(this, name);
  }

  async getAll(...refs) {
    return Promise.all(refs.map((ref) => ref.get()));
  }

  async runTransaction(updateFunction, {maxAttempts = 25} = {}) {
    this._callCount += 1;
    if (this._faultInjector) {
      const fault = this._faultInjector(this._callCount);
      if (fault) throw fault;
    }

    for (let attempt = 0; attempt < maxAttempts; attempt++) {
      const transaction = new FakeTransaction(this);
      // The transaction function itself throwing (a bug, or a
      // deliberate test error inside updateFunction) is NOT caught here
      // — it propagates straight out, exactly like a real Firestore
      // transaction rethrows a callback's own error without retrying it.
      const result = await updateFunction(transaction);

      if (this._beforeCommit) await this._beforeCommit(transaction);

      // Conflict check: has any document this transaction *read*
      // changed version since it was read? Deliberately only checks
      // `_reads` — a write to a path never read in this transaction is
      // NOT protected, matching real Firestore exactly (this is the
      // precise mechanism the old backfillUser's blind writes fell
      // through).
      let conflict = false;
      for (const [path, versionSeen] of transaction._reads.entries()) {
        const current = this.docs.get(path);
        const currentVersion = current ? current.version : 0;
        if (currentVersion !== versionSeen) {
          conflict = true;
          break;
        }
      }

      if (conflict) {
        if (attempt === maxAttempts - 1) {
          const err = new Error("transaction contention exceeded max attempts");
          err.code = 10; // ABORTED
          throw err;
        }
        continue; // retry: re-run updateFunction fresh, per real Firestore semantics
      }

      // Commit.
      for (const [path, write] of transaction._writes.entries()) {
        const existing = this.docs.get(path);
        const merged = applyWrite(existing ? existing.data : undefined, write.data, write.merge);
        this.docs.set(path, {
          data: merged,
          version: existing ? existing.version + 1 : 1,
        });
      }
      return result;
    }
    throw new Error("unreachable: runTransaction exhausted maxAttempts without returning");
  }
}

module.exports = {FakeFirestore};

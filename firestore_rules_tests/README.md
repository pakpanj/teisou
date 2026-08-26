# Firestore Rules Emulator Test Harness

Real Firestore Rules Emulator tests for `../firestore.rules` — genuine
CEL-engine evaluation, not source-inspection/logic-mirror. Built during
the Security & Monetization Remediation's Phase 3.

Kept as its own npm package, separate from `../functions/`, so the
dev-only `@firebase/rules-unit-testing`/`firebase` dependencies never
ship with Cloud Functions.

## Prerequisites

- Firebase CLI reachable via `npx firebase-tools@latest` (the bare
  `firebase` binary crashes in this environment on Node — see the
  project's own CLAUDE.md for the standing workaround).
- A JVM. This machine has no system `java`; Android Studio's bundled
  JetBrains Runtime works: prepend
  `C:\Program Files\Android\Android Studio\jbr\bin` to `PATH`.
- `npm install` in this directory once (installs
  `@firebase/rules-unit-testing` + `firebase`).

## Running

From the repo root:

```bash
export PATH="/c/Program Files/Android/Android Studio/jbr/bin:$PATH"
npx --yes firebase-tools@latest emulators:exec --only firestore \
  --project demo-teisou-rules-test \
  "node --test firestore_rules_tests/rules.test.js"
```

`emulators:exec` starts the Firestore emulator (per `firebase.json`'s
`emulators.firestore` block, port 8080), runs the given command, and
tears the emulator down afterward regardless of exit code. Any
`demo-*` project id works with no real GCP project/credentials.

`wildcard_probe.test.js` is a second, standalone file — a minimal,
single-scenario regression guard for the recursive-wildcard bypass
found the first time this harness ran (see the Phase 3 report). Run it
the same way, swapping the test file path and (optionally) the
`--project` id.

## Files

- `rules.test.js` — the main suite: adRewards freeze, XP authority,
  Avatar/Frame/Cover four-tier ownership+equip, Card Skin, and
  existing-behavior non-regression (cardGameRank, leaderboard
  globalPoints, rankSkipExams, globalPointsState, unauthenticated
  access, subscription/entitlements/coins).
- `wildcard_probe.test.js` — isolated proof that
  `match /users/{uid} { match /{document=**} { allow write: if owner
  } } }` also grants write access to the parent `/users/{uid}` document
  itself (Firestore recursive wildcards match zero-or-more segments),
  independent of every other rule in the file.

## Status

**34/34 (grown to 50/50 once the dedicated regression group was added)
real Firestore Rules tests pass.** Three real discrepancies were found
between the source-inspection tests elsewhere in `../test/` and the
actual CEL engine — every one reported to the user with the suite's
exact failure output before any rules-logic edit was made, none
silently patched:

1. **Compile error**, fixed: `isAllowedCosmeticEquip` originally took 8
   arguments, over Firestore's hard 7-argument-per-function limit.
2. **Recursive-wildcard bypass**, fixed: the pre-existing
   `match /{document=**} { allow write: if owner }` block nested under
   `users/{uid}` also matched the **parent** document (Firestore
   recursive wildcards match zero-or-more segments, not one-or-more),
   and Firestore unions all matching `allow` blocks — so it granted the
   owner unconditional write access to their own `users/{uid}` doc,
   bypassing every freeze/ownership restriction Phases 0-2 added
   (adRewards, xp, avatar/frame/cover/card-skin equip, cardGameRank).
   Fixed by requiring a named `{subcollection}` segment before the
   recursive wildcard — `match /{subcollection}/{document=**}` — so it
   can no longer match the parent document with zero remaining
   segments. Subcollection access (own and cross-user) is unchanged.
3. **Map-parameter evaluation bug**, fixed, found only once fix #2
   stopped masking it: fix #1's map-parameter redesign compiled fine
   but threw a "Null value error" at evaluation time the moment a field
   of the map was dereferenced inside the function — even though the
   map was never null. Maps cannot safely cross a Firestore Rules
   function-call boundary in this engine; lists can. Fixed by using
   three separate list parameters (`freeIds`/`adIds`/`premiumOnlyIds`)
   instead of one map, with `coinIds` dropped as a parameter entirely
   (still correct — see `isAllowedCosmeticEquip`'s own doc comment in
   `../firestore.rules` for why).

Not touched by any of this: Global Points formula, XP amounts, IAP,
Quiz/Tutorial. No commit, no deploy, no production migration.

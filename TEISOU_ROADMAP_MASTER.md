# Teisou — Security/Reliability Audit Roadmap (RISK-N series)

Tracks a sequential audit-then-fix engagement over async UI actions,
Cloud Function concurrency, and global error handling. Each phase
follows the same discipline: audit first (no production changes),
report findings, only fix with explicit instruction, add a permanent
regression test proving the fix actually closes the gap (not just that
the code compiles), then verify + commit.

This file did not exist before RISK-9 — created then, backfilling
RISK-1 through RISK-7 from git history and this repo's own commit
messages rather than guessing. If a fact below turns out wrong, fix it
in place rather than leaving two contradictory rows.

## Status

| Phase | Scope | Status |
|---|---|---|
| RISK-1 | Cosmetic equip reentrancy (avatar/frame/card-skin double-tap) | ✅ DONE (code+tests committed; live-app rollout status — see Production Readiness) |
| RISK-2 | Cosmetic identity spoofing via leaderboard/clan/friend mirrors (`firestore.rules`) | ✅ **CODE COMPLETE / DEPLOYED / PRODUCTION DEPLOYMENT CONFIRMED** — 2026-08-28 (see Production Readiness §A) |
| RISK-3 | Self-healing subscription backstop (`sweepNearExpirySubscriptions`/`sweepAllPremiumSubscriptions`) | 🔶 **INDEX + FUNCTIONS DEPLOYED 2026-08-28 — DEPLOYED / PRODUCTION EXECUTION NOT YET OBSERVED**, enforcement correctly still disabled (see Production Readiness §B) |
| RISK-4 | Premium purchase (IAP) reentrancy | ✅ DONE (client-side fix — ships with next app build/release, see Production Readiness §D) |
| RISK-5 | Coin-purchase reentrancy (Avatar/Frame/Cover pickers) + `spend_coins.js` DI seam | ✅ DONE |
| RISK-6 | Cross-function race audit (spendCoins vs claimXpReward vs verifyPurchase) | ✅ DONE (audit-only, no bug found) |
| RISK-7 | Global error handling (`main.dart` boundary + `fcm_service.dart` listeners) | ✅ DONE |
| RISK-8 | Global async-action/reentrancy audit (app-wide inventory) | ✅ DONE |
| RISK-9 | Fix RISK-8's 3 confirmed bugs (clan kick/leave/invite/friend-request reentrancy) | ✅ DONE |
| Q3 | Kanji defense-in-depth around `_invalidStartMora`/`isValidKotobaStart` | ✅ VERIFIED / CLOSED |
| **Production Readiness** | Firestore Rules / Functions / AdMob SSV / Play Purchase — code-vs-deployed-vs-verified audit | 🔶 **ACTIVE — Firestore Rules (RISK-2) + RISK-3 index + RISK-3 Functions all deployed 2026-08-28; RISK-3 dry-run invocation still pending; AdMob/verifyPurchase found already live (pre-existing); Play purchase still pending** (see §B for the fully current state — this row lagged one update, corrected here) |
| **Core Clan Mechanics Audit** | 13 mutation paths, authorization/atomicity/idempotency/capacity/role-transitions, against real code + real Rules emulator | 🔴 **AUDIT COMPLETE 2026-08-28 — 2 new P1 bugs PROVEN** (joinClan memberCount race; clan role escalation via unvalidated `role` value) — not fixed yet, no new RISK number assigned, awaiting a scheduled fix phase |

## RISK-2 and RISK-3 — corrected (this file's own earlier placeholder was wrong)

An earlier version of this file said "see git history — completed before
this file existed" for both, without pinning the actual commit or scope.
The Production Readiness audit (below) traced both precisely:

- **RISK-2** = commit `cb3fcf1` ("fix: close cosmetic identity spoofing
  via leaderboard/clan/friend mirrors", per `AUDIT_COSMETIC_PROFILE_SHOP.md`
  — a `firestore.rules` fix, 11 new emulator tests, confirmed via the
  real Firestore Rules Emulator). The commit message itself originally
  stated "Not deployed..." — **this is now stale: deployed to
  production 2026-08-28, see §A below for the full record.**
- **RISK-3** = commit `9260517` ("feat: add self-healing subscription
  backstop", per `AUDIT_SUBSCRIPTION_RECOVERY*.md`) — two new scheduled
  Cloud Functions + one new Firestore composite index, 12 new test
  scenarios. **Update 2026-08-28**: the composite index is now deployed
  to production; the two scheduled Functions are not — a real deploy
  attempt hit a network-egress failure in this environment, not a code
  or config problem. See §B below for the full record.

## RISK-1 (pre-dates this file)

Completed in earlier sessions — commit `f9e1078` (cosmetic equip
double-tap guard). Directly referenced by this file's own RISK-8/RISK-9
entries as an already-proven-safe baseline pattern. Not re-audited as
part of RISK-8/9/Production-Readiness per explicit instruction not to
re-touch an already-verified baseline without new regression evidence.

## RISK-4 — Premium Purchase Reentrancy

**Bug**: `PaywallScreen`/`PlanIntroScreen`'s buy button had no in-flight
guard — a double-tap during the IAP purchase flow could fire `.buy()`
twice.

**Fix**: `bool _buying` guard, set before the purchase flow starts,
reset in `finally`, button swapped to a spinner while busy.

**Files**: `lib/features/paywall/paywall_screen.dart`,
`lib/features/onboarding/plan_intro_screen.dart`.

**Tests**: `test/premium_purchase_reentrancy_test.dart` (7 cases,
Completer-gated).

**Commit**: `913347e` — "fix: prevent duplicate premium purchase attempts"

**Known carryover, not fixed here or in RISK-9 (out of scope both
times)**: `PaywallScreen._restore()` still has no in-flight guard on its
own button (`PremiumCard._restore()`, a different screen, does). Flagged
again in RISK-8's audit as a P2 (duplicate `restore()` call, not a
double-charge — IAP restore is idempotent by platform contract) —
still open.

## RISK-5 — Coin-Purchase Reentrancy + `spend_coins.js` DI

**Bug**: Avatar/Frame/Cover picker sheets' coin-buy confirm dialog only
guarded the window *before* the dialog opened — the window *after*
confirm, while `CoinSpendService.buy()` was in flight, was unguarded. A
tap-confirm, tap-confirm-again sequence opened a second dialog and fired
a second concurrent `buy()` call.

**Fix**: `bool _buyingWithCoins`, set before `showDialog` opens (not
just around the `buy()` call), `AbsorbPointer` over the picker grid
while busy. `functions/spend_coins.js` also got a DI seam
(`spendCoinsFor(uid, kind, id, {firestore})`) so its transaction logic
could be exercised by a permanent Node test without touching the
callable-wrapper contract.

**Server-side finding**: `spend_coins.js`'s own transaction was already
SAFE under concurrency (proven by test, not assumed) — this was a
client-only bug.

**Files**: `lib/features/profile/widgets/avatar_picker_sheet.dart`,
`cover_picker_sheet.dart`, `functions/spend_coins.js`.

**Tests**: `test/coin_buy_reentrancy_test.dart` (7 cases),
`functions/spend_coins.test.js` (9 cases).

**Commit**: `d0f5113` — "fix: harden coin purchase reentrancy and add spend tests"

## RISK-6 — Cross-Function Race Audit

**Scope**: proved, under forced `FakeFirestore` interleaving, that
`spendCoins` (avatar/frame/cover kind) racing against `claimXpReward`
racing against `verifyPurchase` (skin kind) on the same uid never loses
either grant — final state is always the correct union, never a
last-write-wins overwrite. Also audited every other writer of the same
`xp.unlockedAvatarIds`/`unlockedFrameIds`/`unlockedCoverIds`/
`entitlements.skins` fields (`award_top_coins.js`, `rank_skip.js`, etc.)
for a missed third writer.

**Result**: **SAFE** — no bug found. All three functions' writes are
either `FieldValue.arrayUnion` transforms (immune to blind-write races
by construction) or protected by their own transaction's read-then-
check logic. Audit-only, no production change, no permanent test added
(the temporary proof test `functions/_audit_cross_function_race.test.js`
was deleted in RISK-9's cleanup pass — nothing to regress-guard since
nothing was fixed).

## RISK-7 — Global Error Handling

**Finding**: `main.dart` had zero global error boundary
(`FlutterError.onError`/`PlatformDispatcher.instance.onError`/
`runZonedGuarded` all absent) — a prior session had deliberately decided
against one, reasoning "every stream already handles its own errors,"
which held for Battle's two listeners but not app-wide:
`fcm_service.dart`'s three `FirebaseMessaging` listeners
(`onTokenRefresh`/`onMessage`/`onMessageOpenedApp`) had neither `onError`
nor internal try/catch.

**Fix**: `installGlobalErrorHandlers()` in `main.dart`, called before
`runApp`, setting both handlers (logs + `FlutterError.presentError` so
visibility is unchanged, never silently swallows a framework error).

**What's provably untestable in `flutter_test`, documented rather than
faked**: `TestWidgetsFlutterBinding`'s own zone claims an uncaught async
error before `PlatformDispatcher.instance.onError` would ever see it —
confirmed empirically, not assumed. The test file covers what *can* be
proven: the wiring runs before `runApp`, and both handler functions
behave correctly when invoked directly with a synthetic error.

**Files**: `lib/main.dart`.

**Tests**: `test/global_error_handling_test.dart` (3 cases),
`test/battle_reliability_wiring_test.dart` (1 group updated — used to
assert the *opposite*, that no global handler existed).

**Commit**: `3e77956` — "fix: add global error boundary (main.dart), closing AUDIT_PHASE_C's C1"

## RISK-8 — Global Async-Action / Reentrancy Audit

Audit-only phase (explicit instruction: "STOP setelah laporan audit.
Jangan fix BUG apa pun pada fase ini.") — a comprehensive inventory of
every async UI action across the app that could double-fire before its
first invocation completes. 42 entry points surveyed across Paywall/IAP,
coin-buy, ad-reward, Clan (create/join/leave/kick/promote/invite),
Friend (send/accept/reject/remove), Battle (matchmaking/challenge/
submit-answer), Rank Skip exam, XP claim, Profile save, cosmetic equip,
and every UI-invoked callable Cloud Function.

**Result: 33 SAFE, 2 UNKNOWN, 3 BUG (all CLIENT BUG, all now closed by
RISK-9), 1 TEST GAP (latent server bug, not client-exploitable via any
existing UI path).**

### Confirmed bugs (closed in RISK-9)

1. **`ClanMembersScreen._MemberRow._kick`** — no in-flight guard on the
   kick icon after the confirm dialog closes; `ClanRepository.kickMember`
   was also a non-transactional batch with an unconditional
   `FieldValue.increment(-1)`. **P1** — a double-tap-then-double-confirm
   corrupted `memberCount` by 2 for a single kick. **PROVEN BY TEST**
   (temporary Completer-gated widget test, ported into RISK-9's permanent
   suite).
2. **`ClanTab._leaveClan`** — same shape as #1, on the "Keluar" action
   instead of kick. **P1**, confirmed from code (same mechanism as the
   already-test-proven #1).
3. **`SearchInviteScreen._invite` / `SearchFriendTab._sendRequest`** —
   both marked "already sent" only *after* success, not before the call
   starts, so a fast double-tap created two duplicate invite/request
   documents. **P2** (wasteful/duplicate documents, not state corruption
   — `sendInvite`/`sendFriendRequest` don't touch any counter).

### TEST GAP (not fixed — not client-exploitable today)

`ClanRepository.joinClan`'s own `.get()`-then-`increment` shape has the
same non-transactional pattern as kick/leave, but every current UI entry
point into it (`JoinClanDialog._join`, `clan_tab.dart`'s invite-accept
path) is already client-guarded — so it's a latent risk for a *future*
caller, not a live bug. Left open, documented, not fixed in RISK-9
(explicitly out of scope — RISK-9's instructions scoped fixes to the 3
confirmed BUGs only).

### UNKNOWN resolved during RISK-9

`EditNameDialog._saveDirectly` had no explicit in-flight guard on its
Save button. Investigated in RISK-9: `updateCustomDisplayName` and all
three `syncIdentityEverywhere` sub-calls
(`syncProfileInfo`/`syncMemberInfo`/`syncFriendInfo`) are pure
`.set(..., merge: true)` value overwrites with no increment/counter —
genuinely idempotent regardless of guard presence. **Determination:
SAFE, not a bug — no code change made**, per RISK-9's own instruction
not to "fix" something for tidiness alone.

## RISK-9 — Fix Clan Reentrancy & Atomicity

Closed all 3 confirmed RISK-8 bugs, both client and server layer.

**Client fixes**:
- `_MemberRow._kick` (kick icon → spinner-swap while `_kicking`,
  matching the strongest guard pattern already established in this
  codebase, e.g. `clan_tab.dart`'s `_InviteRow`).
- `_ClanTabState._leaveClan` ("Keluar" action disabled, `onTap: null`,
  while `_leaving`).
- `SearchInviteScreen._invite` / `SearchFriendTab._sendRequest` (button
  → spinner the instant a tap registers, before the async call starts,
  not after it succeeds).

**Server/repository fixes** (defense-in-depth, so a future client-guard
regression can't reintroduce the corruption):
- `ClanRepository.kickMember` and `.leaveClan` both rewritten from a
  plain batch (no existence check, unconditional
  `FieldValue.increment(-1)`) into a transaction that reads the member
  document first and only deletes + decrements if it still exists —
  mirroring `BattleRepository.submitAnswer`'s own self-guarding-
  transaction shape elsewhere in this codebase.

**Files changed**: `lib/data/repositories/clan_repository.dart`,
`lib/features/leaderboard/widgets/clan_members_screen.dart`,
`clan_tab.dart`, `search_invite_screen.dart`, `search_friend_tab.dart`.

**Tests**: `test/clan_reentrancy_test.dart` (8 permanent cases — 4
client-layer Completer-gated widget tests for kick/leave/invite/friend-
request, plus 2 backend-layer transaction-concurrency tests for kick and
1 for leave, using a purpose-built minimal fake of the `cloud_firestore`
transaction API since this project has no Dart-side Firestore emulator
and the Node `FakeFirestore` used by `functions/*.test.js` can't be
reused for pure-Dart client repository code). Every test was verified to
actually fail when its corresponding fix was reverted, not just pass
against the fixed code — see the commit's own verification notes for the
exact defect-injection results.

**Cleanup**: `test/_audit_risk8_kick_reentrancy_test.dart` and
`functions/_audit_cross_function_race.test.js` (RISK-8/RISK-6 temporary
audit scratch files) both deleted — their coverage is superseded by
`test/clan_reentrancy_test.dart`, and RISK-6 found no bug so had nothing
to permanently regress-guard.

**Commit**: see `git log` for the exact hash (recorded in the same
commit that made this file's RISK-9 row `DONE`).

## Q3 — Kanji Defense-in-Depth around `_invalidStartMora`

**Status: VERIFIED / CLOSED.** This is a **defense-in-depth gap, not a
live production bug** — the real bundled dataset has zero readings that
currently violate it. See below for why it still warranted a fix.

### Root cause

`KanjiComboRepository`'s reading-distractor pipeline
(`lib/data/repositories/kanji_combo_repository.dart`) has two
independent sources for a reading question's wrong-answer options:

1. `generateMutationDistractors` — mutates the correct reading itself
   (dakuten toggle / vowel shift / adjacent swap). Every candidate it
   produces is filtered through `isValidKotobaStart` before being
   returned — already fully guarded, confirmed by pre-existing tests.
2. `_pickCloseDistractors` — a pool-search fallback `_pickReadingDistractors`
   tops up with whenever (1) can't reach the target count on its own
   (e.g. single-mora わ has no dakuten pair and isn't in any vowel-row
   group, so it has zero valid mutations and needs 3/3 distractors from
   this fallback). **This path never called `isValidKotobaStart` at
   all** — it ranked/shuffled whatever was in the pool with no
   filtering. `isValidKotobaStart`'s own doc comment explicitly claims
   "a distractor starting with a lone small-y would be an immediately
   obvious fake to a learner... so it stays rejected here too", but
   that claim only held for path (1).

**Why this never surfaced as a real bug**: a reading can only reach
this pipeline via the bundled `kanji_data.json`/`kotoba/*.json`
datasets — there is no runtime/user-controlled input anywhere near
`_splitMora`/`isValidKotobaStart`/`generateMutationDistractors`. An
exhaustive scan of the real data (all 2425 kanji onyomi/kunyomi + all
1351 compound-eligible Kotoba readings) found **zero** entries that
start with an invalid mora — so path (2)'s missing filter had nothing
to leak, today. A future content-authoring typo (a genuine risk in this
codebase — see the many multi-thousand-word batch-authoring passes
documented elsewhere in `CLAUDE.md`) could introduce one with zero
runtime defense catching it before it reached a learner as a distractor
option.

### Reproduction (before any fix)

A temporary test built a controlled 3-kanji pool via a fake
`KanjiRepository`: one kanji with reading わ (structurally forces the
pool-search fallback), one deliberately "bad" kanji with onyomi んき (a
reading real Japanese never has — simulating a future authoring
mistake), one normal filler. Ran `generateQuestions` across 200 random
seeds and checked every DISTRACTOR option (excluding the correct
answer) for starting with ん.

- **Against the unfixed code: test FAILED** — a distractor starting
  with ん was observed.
- **After the one-line fix: test PASSED.**
- **Fix reverted again as a sanity check: test FAILED again**, exactly
  reproducing the original failure — confirms the test is genuinely
  load-bearing, not tautological.

### Exact fix

One line in `_pickReadingDistractors`
(`lib/data/repositories/kanji_combo_repository.dart`):

```dart
// before
final remainingPool = poolCandidates.where((c) => c != correctAnswer && !mutated.contains(c));
// after
final remainingPool = poolCandidates.where(
  (c) => c != correctAnswer && !mutated.contains(c) && isValidKotobaStart(c),
);
```

No architecture change, no data format change, no behavior change for
any currently-valid reading (since the real dataset has nothing this
filter would ever remove today).

### Defense-in-depth verdict

Two boundaries now both reject an invalid-start reading before it can
become a distractor (mutation path + pool-search path), matching the
module's own stated design intent. The CORRECT answer itself is
intentionally **not** given a runtime check — if a future kanji/kotoba
entry's own reading were ever bad, there is no sane runtime fallback
(skip the kanji? show it anyway?) without a larger design decision, and
that's explicitly out of scope for a minimal fix. Instead, the content
side of this boundary is enforced by two new **permanent
content-integrity tests** (below) that assert the real dataset itself
never contains such a reading — the correct layer for a data-quality
invariant, matching this project's own established pattern for content
integrity elsewhere (Dokkai/Choukai/Kaiwa/Bab content-integrity tests).

### Files changed

- `lib/data/repositories/kanji_combo_repository.dart` (1 line +
  doc comment).
- `test/kanji_combo_distractor_test.dart` (2 new groups).

### Tests added

- `Q3 defense-in-depth: pool-search fallback must also reject an
  invalid start mora` — the reproduction above, ported to a permanent
  regression test.
- `Q3 content integrity: the real bundled dataset never has an
  onyomi/kunyomi/compound reading that fails isValidKotobaStart` — two
  cases, scanning the real `KanjiRepository.getAll()` (2425 entries) and
  every compound-eligible Kotoba word across every available category
  (1351+ entries, cross-checked against an independent one-off Python
  scan of the same raw JSON files before any test was written — both
  agreed: 0 violations).

### Test results

- `test/kanji_combo_distractor_test.dart`: **22/22 PASS** (19
  pre-existing + 3 new).
- `test/kanjivg_parser_test.dart` (unrelated Kanji-area file, run for
  completeness): **10/10 PASS**, unaffected.
- Full Dart suite (`flutter test --concurrency=1`): **876/876 PASS**, 0
  failures.

### flutter analyze

**Clean** — "No issues found!" project-wide.

### On-device

**UNKNOWN** — no physical device connected this session. Not claimed as
verified on-device.

### Remaining UNKNOWN / follow-up

- None new. The correct-answer-side gap named above is a deliberate,
  documented scope decision (covered by content-integrity tests
  instead of a runtime code change), not an open unknown.

### Commit

`4c7ad1b` — "fix(kanji): close pool-fallback distractor leak past
isValidKotobaStart". Exactly 2 files changed
(`kanji_combo_repository.dart`, `kanji_combo_distractor_test.dart`).
`git status` after commit: only pre-existing `windows/flutter/*` and
`AUDIT_*.md`/`AUDIT_SUBSCRIPTION_*.md` remain — none touched.

## Production Readiness / Deployment Verification Audit

**Status: ACTIVE.** Read-only audit — no source changed, no commit, no
deploy, no Firestore Rules/Functions/AdMob/Play Console change, no
production data touched. Purpose: separate "fixed in code" from
"committed" from "deployed" from "production-verified", since this
project's own history has already shown these are NOT the same thing —
see the `firestore.indexes.json` file's own comment: *"the clan feature
already shipped once with rules that were right here and absent from
the live project, and every write silently permission-denied."* This
environment's bare `firebase` binary crashes on its own first-run
welcome script (confirmed again, reproducibly, when this was actually
attempted — see §A below); `npx firebase-tools@latest` is a working
workaround, already documented in `firestore_rules_tests/README.md`.
Every "Deployed"/"Production Verified" answer below is evidence-based,
not assumed from "the commit exists" — as of §A, one row now has a
genuine deployment confirmation from a live `firebase deploy` run, not
just a commit.

### A. Firestore Rules (RISK-2) — ✅ DEPLOYED 2026-08-28

**Update 2026-08-28**: deployed to production, per an explicit,
scoped user request ("PRODUCTION DEPLOYMENT — FIRESTORE RULES
(RISK-2)"). Full record:

- **Commit deployed**: `cb3fcf1` — confirmed still in `HEAD`'s ancestry
  (`git merge-base --is-ancestor cb3fcf1 HEAD`) immediately before
  deploying, and `git diff -- firestore.rules` against the working tree
  was empty (no uncommitted local changes) — the file deployed is
  exactly what `cb3fcf1` committed, nothing drifted since.
- **Pre-flight**: repo root `C:\Users\LENOVO\teisou`, branch `master`,
  HEAD `4f10e2d` at the time of deploy. `firebase.json` confirmed
  `firestore.rules` is the configured rules target for project
  `teisou-kana-master` (`.firebaserc`).
- **Tooling note, worth keeping**: the bare `firebase` command crashes
  immediately on this machine — `SyntaxError: Unexpected end of JSON
  input` inside its own bundled `welcome.js`, before reaching any real
  command, reproduced twice (plain and with `CI=true`). This matches
  `firestore_rules_tests/README.md`'s own documented note about this
  exact environment. **`npx --yes firebase-tools@latest`** is the
  working substitute — confirmed via `--version` (15.28.2) and
  `login:list` (already authenticated as the project owner,
  `gilanggarind1975@gmail.com`) before attempting the real deploy.
- **Deploy command run**: `npx --yes firebase-tools@latest deploy
  --only firestore:rules` (exactly this, nothing else in scope).
- **Deployment output** (verbatim, relevant lines):
  ```
  === Deploying to 'teisou-kana-master'...
  i  deploying firestore
  i  firestore: reading indexes from firestore.indexes.json...
  i  cloud.firestore: checking firestore.rules for compilation errors...
  +  cloud.firestore: rules file firestore.rules compiled successfully
  i  firestore: uploading rules firestore.rules...
  +  firestore: released rules firestore.rules to cloud.firestore
  +  Deploy complete!
  Project Console: https://console.firebase.google.com/project/teisou-kana-master/overview
  ```
  No warnings, no errors. Indexes were only *read* (a standard prep
  step for any `firestore` deploy target) — never uploaded/released;
  only the `rules` line shows an actual write action. No Functions, no
  Hosting, no Storage were touched — confirmed by the output itself
  only ever naming `firestore`/`cloud.firestore`.
- **Firebase project target**: `teisou-kana-master` (matches
  `.firebaserc`'s `default` project — no ambiguity, no wrong-project
  risk).
- **Deployment timestamp**: 2026-08-28 03:32:54 UTC (≈ 10:32:54 WIB).
- **Deployed = ✅ CONFIRMED BY FIREBASE DEPLOYMENT OUTPUT.** This is a
  stronger claim than "the command exited 0" — the CLI's own
  compile-success and release-success lines are the actual evidence.

**Emulator verification (Rules Emulator, real CEL engine — not
production, but the strongest same-day proof the deployed rules
content is behaviorally correct)**:
- `firestore_rules_tests/rules.test.js`: **73/73 PASS**, 0 failures —
  including the exact RISK-2 group, `"cosmetic identity mirrors must
  match users/{uid}.profile"`, covering all three fixed boundaries
  (leaderboard, clan roster, friend row): DENIED for a spoofed
  premium-only avatar/cardSkin, ALLOWED for a legitimate mirror sync
  matching `users/{uid}.profile`, ALLOWED for delete (leave clan /
  unfriend), unaffected.
- `firestore_rules_tests/wildcard_probe.test.js`: **1/1 PASS** —
  confirms the unrelated recursive-wildcard-bypass regression guard
  still holds.
- **Total: 74/74 emulator tests PASS.** Run via `npx --yes
  firebase-tools@latest emulators:exec --only firestore --project
  demo-teisou-rules-test "..."` — a `demo-*` project id, no real GCP
  project/credentials touched, no production data read or written by
  the test run itself.

- **Production behavior verified**: **still UNKNOWN, by design of what
  this check can prove.** The emulator confirms the *rules file's own
  logic* is correct against the real CEL engine — it does not, and
  cannot, confirm the *live* `teisou-kana-master` project is actually
  enforcing it post-deploy (that would require a real authenticated
  write attempt against production, which this audit deliberately did
  not do — "Jangan mencoba spoofing cosmetic pada akun production" was
  an explicit constraint). The Firebase deployment output's own
  `released rules ... to cloud.firestore` line is the evidence that the
  live project now has this exact ruleset; whether a real client write
  against it behaves as the emulator predicts has not been separately
  confirmed with a live probe.
- **Verdict: CODE COMPLETE / DEPLOYED / PRODUCTION DEPLOYMENT
  CONFIRMED.** Production *behavior* verification remains a distinct,
  separate, still-open item — do not conflate the two.
- **Remaining action**: none required to close RISK-2's deployment gap
  — it's closed. Optional follow-up, not requested this session: a
  single live read/write probe against `teisou-kana-master` (e.g. via
  the Firebase Console's Rules Playground, which can simulate a write
  against live rules without touching real data) would upgrade
  "deployed" to "production behavior verified" with zero risk to real
  user data.

### B. RISK-3 Subscription Backstop

Verified directly from `functions/subscription_backstop.js`,
`functions/index.js`, `functions/.env`, `firestore.indexes.json`:

| Item | Finding |
|---|---|
| `sweepNearExpirySubscriptions` | Exists, `onSchedule` (daily), exported from `functions/index.js:311-312` |
| `sweepAllPremiumSubscriptions` | Exists, `onSchedule` (weekly), exported from `functions/index.js:313-314` |
| `firestore.indexes.json` | Composite index present (`users`, `subscription.tier` ASC + `subscription.expiresAt` ASC), explicitly commented "RISK-3 subscription backstop's daily near-expiry sweep" |
| `SUBSCRIPTION_BACKSTOP_ENABLED` | **Absent from `functions/.env`** → `backstopWritesEnabled()` returns `false` → `dryRun = true` by default. **Safe default confirmed.** |
| `PLAY_VERIFICATION_ENABLED` | Present, `=true`, in `functions/.env` — gates the backstop too (fails closed if unset) |
| Purchase token logging | **Not logged** — confirmed by reading every `logger.*` call in the file (only candidate uid/productId/decision/counts) |
| Tests | `functions/subscription_backstop.test.js` — 12 new scenarios per the commit message, all passing (part of the 314/314 full Functions suite, re-run fresh during this audit) |

**Update 2026-08-28**: attempted, per an explicit, scoped user request
to bring RISK-3 from code-complete toward deployed/verified. Result is
**partial** — index deployed, Functions deployment failed on a genuine
environment limitation. Full record:

- **Pre-flight**: `9260517` confirmed still in `HEAD`'s ancestry; all 6
  RISK-3 files (`subscription_backstop.js`, `.test.js`, `iap.js`,
  `index.js`, `test_helpers/fake_firestore.js`, `firestore.indexes.json`)
  confirmed byte-identical to the working tree (`git diff` empty on all
  six). Both functions confirmed exported (`index.js:311-314`). Safe
  defaults reconfirmed: `SUBSCRIPTION_BACKSTOP_ENABLED` absent from
  `.env` → dry-run by default; `PLAY_VERIFICATION_ENABLED=true` present
  (gates the sweep, fails closed if unset); every Play-API-error path
  returns `outcome: "skipped_play_error"`, never a downgrade; no
  `logger.*` call anywhere in the file passes a purchase token (only
  `tokenDoc.id` reaches the Play API client directly, never a log line).
- **Tests before deployment**: `subscription_backstop.test.js`
  **16/16 PASS**; full Functions suite **314/314 PASS**; IAP-specific
  suites (`iap.test.js`/`iap_logging.test.js`/`iap_states.test.js`)
  **43/43 PASS** — `verifyPurchase`'s own logic confirmed untouched and
  intact. All re-run fresh this session, not assumed from an earlier
  pass.
- **Firebase project preflight**: `.firebaserc` confirms
  `teisou-kana-master`. `firebase functions:list` against the LIVE
  project (read-only) confirmed the Functions runtime is genuinely
  deployable — 20 functions already live (`adRewards`, `verifyPurchase`,
  `onPlayRtdn`, `sweepAbandonedBattleMatches` among them — this is also
  the first hard confirmation that **AdMob's `adRewards`/
  `consumeAdReward` are already deployed to production**, a fact the
  earlier Production-Readiness audit had marked "deployment UNKNOWN" —
  noted here for the record only, not acted on; out of this task's
  scope). **`sweepNearExpirySubscriptions`/`sweepAllPremiumSubscriptions`
  were confirmed ABSENT from that live list** before deploying — this
  was genuinely a new addition, not a redeploy.
- **Index deployment: ✅ SUCCESS.** Read the live indexes first
  (`firebase firestore:indexes`) — only the pre-existing `battleMatches`
  index was live, confirming the RISK-3 `users` composite index
  (`subscription.tier` ASC + `subscription.expiresAt` ASC) was genuinely
  missing and the diff was exactly the one expected addition, nothing
  unrelated. Ran `npx --yes firebase-tools@latest deploy --only
  firestore:indexes` — output: `firestore: deployed indexes in
  firestore.indexes.json successfully for (default) database` /
  `Deploy complete!`. Re-read the live indexes immediately after: the
  `users` composite index is now present, byte-for-byte matching the
  repo file. **Timestamp: 2026-08-28 03:48:52 UTC.** No Rules, Hosting,
  Storage, or unrelated Functions were touched (the deploy output only
  ever names `firestore`/indexes; rules were syntax-checked as a
  standard prep step, never re-released).
- **Functions deployment attempt #1 (this same day, earlier): ❌ FAILED**
  — kept as historical record. `npx --yes firebase-tools@latest deploy
  --only functions:sweepNearExpirySubscriptions,functions:sweepAllPremiumSubscriptions`
  failed twice, identically, with `Error: An unexpected error has
  occurred.` (exit code 2). `firebase-debug.log` traced the real cause
  both times: a `ConnectTimeoutError` (TCP connect timeout, 10s) to
  `iam.googleapis.com` and `firebase.googleapis.com`'s `adminSdkConfig`
  endpoint. `cloudresourcemanager.googleapis.com` and
  `firestore.googleapis.com` (used for the Rules/Indexes deploys) both
  worked fine in the same runs. No functions were created/updated/deleted
  by that attempt.

**Update 2026-08-28, same day, later — Functions deployment: ✅
SUCCESS.** A follow-up task explicitly asked to check network status
once (not retry blindly) before attempting again:
- **Connectivity check** (single lightweight probe, not a full deploy
  retry): `curl --connect-timeout 8` against
  `https://iam.googleapis.com/` and `https://firebase.googleapis.com/`
  — both returned `HTTP 404` (the expected response for hitting an API
  host's bare root with no valid request — the meaningful signal is a
  *fast TCP+TLS connection*, not the status code) in 0.08s/0.23s,
  a complete contrast to the earlier 10s hard timeout. **Network access
  to both previously-blocking hosts was confirmed available before
  attempting the deploy again** — this was not a blind retry.
- **Deploy command**: `npx --yes firebase-tools@latest deploy --only
  functions:sweepNearExpirySubscriptions,functions:sweepAllPremiumSubscriptions`
  (identical command to the failed attempt).
- **Deploy output** (relevant lines): `functions: Loaded environment
  variables from functions\.env` → `functions: functions source
  uploaded successfully` → `creating Node.js 22 (2nd Gen) function
  sweepNearExpirySubscriptions(us-central1)...` →
  `sweepAllPremiumSubscriptions(us-central1)...` →
  **`functions[sweepNearExpirySubscriptions(us-central1)] Successful
  create operation.`** → **`functions[sweepAllPremiumSubscriptions(us-central1)]
  Successful create operation.`**
- **A trailing, separate, non-fatal error was also printed** (worth
  recording honestly, not glossed over): `Functions successfully
  deployed but could not set up cleanup policy in location us-east1.`
  — an Artifact Registry container-image cleanup-policy warning for a
  *different* region (`us-east1`, not `us-central1` where these two
  functions actually deployed) — cosmetic/billing-lifecycle only, not a
  functional failure of either function. **Not acted on** (running
  `functions:artifacts:setpolicy` was outside this task's two-function
  scope) — flagged here as a real, still-open cosmetic item, not
  silently fixed or silently ignored.
- **Independent confirmation, not just trusting the deploy output**:
  `firebase functions:list` immediately after shows both
  `sweepNearExpirySubscriptions` and `sweepAllPremiumSubscriptions` live
  — `v2`, `scheduled`, `us-central1`, `nodejs22`, alongside the
  already-existing `sweepAbandonedBattleMatches`.
- **Timestamp**: deploy completed and independently re-confirmed
  ≈2026-08-28 04:19 UTC.
- **`.env` unchanged**: `git diff -- functions/.env` empty before and
  after — `SUBSCRIPTION_BACKSTOP_ENABLED` was never added,
  `PLAY_VERIFICATION_ENABLED=true` is the only flag present, exactly as
  before. The deploy output's own `Loaded environment variables from
  functions\.env` line confirms this exact file (dry-run default) is
  what shipped.
- **Enforcement**: **NOT enabled** — confirmed, per explicit
  instruction not to enable it in this task.
- **Production execution observed**: **NO.** Both functions are
  `scheduled` (Cloud Scheduler-triggered — daily/weekly per their own
  cron config), so they will not run again until their next scheduled
  time; no invocation has happened yet since this deploy. Marked
  **DEPLOYED — PRODUCTION EXECUTION NOT YET OBSERVED**, not "verified."
- **Production behavior verified**: **NO / UNKNOWN** — cannot be
  claimed until at least one real scheduled invocation's Cloud Functions
  logs have actually been read.
- **Verdict: CODE COMPLETE ✅ / TEST COMPLETE ✅ / INDEX DEPLOYED ✅ /
  FUNCTIONS DEPLOYED ✅ (2026-08-28) / ENFORCEMENT ENABLED ❌ (correctly,
  per instruction) / PRODUCTION EXECUTION OBSERVED ❌ (not yet — next
  scheduled run hasn't happened) / PRODUCTION BEHAVIOR VERIFIED ❌.**
- **Remaining action (user-owned)**: wait for (or manually trigger, via
  the Cloud Scheduler console/CLI, a user-owned action not attempted
  here) the next scheduled daily/weekly run, then read the Cloud
  Functions logs for `sweepNearExpirySubscriptions`/
  `sweepAllPremiumSubscriptions` to confirm: candidate counts look sane
  against real data, every outcome is a dry-run decision
  (`would_remain_premium`/`would_downgrade`, never an actual write),
  and no purchase token appears in any log line. Only after that
  observation looks correct should `SUBSCRIPTION_BACKSTOP_ENABLED="true"`
  be set and the functions redeployed. Optionally, close the separate
  `us-east1` cleanup-policy warning via `firebase
  functions:artifacts:setpolicy` (cosmetic, not blocking).

**Update 2026-08-28, later same day — dry-run observation pass.** An
explicit, read-only observation task: confirm both functions still
exist, check whether either has actually executed, inspect real Cloud
Functions logs for the backstop specifically. No source changed, no
manual sweep invoked (the implementation exposes no safe manual-trigger
path — `subscription_backstop.js` only exports the two `onSchedule`
functions plus an `_internal` object explicitly commented "Exported for
tests only," so none was invented per instruction).

- **Both functions confirmed still live**: `firebase functions:list`
  re-run — `sweepAllPremiumSubscriptions` and
  `sweepNearExpirySubscriptions`, both `v2`/`scheduled`/`us-central1`/
  `nodejs22`, unchanged since deploy.
- **Schedule, read directly from the deployed source**:
  `sweepNearExpirySubscriptions` = `"every day 03:00"` Asia/Jakarta;
  `sweepAllPremiumSubscriptions` = `"every monday 03:30"` Asia/Jakarta.
  Deploy landed 2026-08-28 ≈04:19 UTC (≈11:19 WIB) — **after** that
  day's 03:00 WIB daily slot, and 2026-08-28 is a Friday — so the
  earliest possible next runs are **2026-08-29 03:00 WIB** (daily) and
  **2026-08-31 (Monday) 03:30 WIB** (weekly). Neither had arrived yet at
  observation time.
- **Log inspection**: `firebase functions:log --only
  sweepNearExpirySubscriptions,sweepAllPremiumSubscriptions -n 500`.
  Every entry present is **deployment/infrastructure noise only** —
  Cloud Audit Log `CreateFunction` entries, container cold-start
  (`Starting new instance. Reason: DEPLOYMENT_ROLLOUT`), and the
  `STARTUP TCP probe succeeded` health check that Cloud Run performs on
  every new revision. **Zero occurrences** of this file's own
  application-level log lines
  (`"subscription_backstop: daily/weekly sweep starting/complete/
  skipped"` — grepped for directly, explicitly including `dry-run`/
  `downgrad`/`reconfirm`, nothing matched). This is conclusive,
  independent confirmation (not just schedule arithmetic) that
  `runDailySweep`/`runWeeklySweep`'s actual business logic has not run
  even once since deployment — no candidate query, no Play verification
  call, no dry-run decision, nothing to read yet.
- **No sensitive data found** — trivially true, since there is no
  application log output at all yet to check. (The code-level guarantee
  — no `logger.*` call anywhere in the file ever passes a purchase
  token — was already confirmed by direct source reading in the
  previous deployment task, not re-derived here since the source is
  unchanged.)
- **Cross-check against `subscription_backstop.test.js`**: unchanged
  since the previous task's pre-deploy run (16/16 PASS, source
  untouched) — the dry-run-safety/Play-verification-gating/fail-closed/
  no-token-logging guarantees this file tests are exactly the
  properties this observation pass was looking for live evidence of;
  none of that live evidence exists yet, so the test suite remains the
  only current evidence for those properties, not a live confirmation.
- **INVOCATION OBSERVED: NO** (both functions). **DRY-RUN BEHAVIOR
  VERIFIED: NOT APPLICABLE YET** (nothing to verify without an
  invocation — this is a state, not an "unknown due to insufficient
  access"). **ENFORCEMENT ENABLED: NO** — unchanged,
  `SUBSCRIPTION_BACKSTOP_ENABLED` still absent from `functions/.env`.
- **Verdict, unchanged from the deploy task**: **DEPLOYED — WAITING FOR
  SCHEDULED INVOCATION.** Next honest checkpoint: any time after
  2026-08-29 03:00 WIB, re-run the same log inspection and look for the
  `"daily sweep starting"`/`"daily sweep complete"` pair (or
  `"skipped — Play verification is not configured"` if
  `PLAY_VERIFICATION_ENABLED` somehow isn't live, which would itself be
  worth flagging) before drawing any conclusion about live behavior.

**Checkpoint 2026-08-28 04:47 UTC (≈11:47 WIB, still same day)**: an
explicit early re-check, requested ahead of the expected window. Time
math alone already ruled it out (2026-08-29 03:00 WIB = 2026-08-28
20:00 UTC — about 15 hours away at check time), but the same log grep
(`functions:log --only sweepNearExpirySubscriptions,
sweepAllPremiumSubscriptions -n 500`, searching for
`sweep (starting|complete|skipped)`/`dry.?run`/`downgrad`/`reconfirm`)
was re-run rather than trusting arithmetic alone — **zero matches,
same as before.** Nothing else checked or changed. **Still: DEPLOYED —
WAITING FOR SCHEDULED INVOCATION.** No PASS claimed. Next real
checkpoint remains any time after 2026-08-29 03:00 WIB.

### C. AdMob SSV / `adRewards`

Verified directly from `functions/ad_rewards.js` (full read) +
`AUDIT_PHASE_B1/B2/B3` (pre-existing, read for historical context):

| Item | Finding |
|---|---|
| `adRewards` exported | Yes — `onRequest` (plain HTTP, unauthenticated GET, correct for an AdMob→server callback), `functions/index.js:366` |
| `consumeAdReward` exported | Yes — `onCall`, scoped to `request.auth.uid` only, `functions/index.js:367` |
| Signature verification | ECDSA/SHA-256/DER against Google's own published verifier keys (`gstatic.com/admob/reward/verifier-keys.json`), fetched and cached in-memory (24h), matched by `key_id` — implemented exactly per Google's documented algorithm per the file's own header comment |
| Anti-duplicate grant | `processedAdRewardTransactions/{transaction_id}` ledger inside a Firestore transaction — same shape as `iap.js`'s `processedPurchaseTokens` ledger |
| Server-side `expiresAt` | Yes — `Timestamp.fromMillis(now + REWARD_DURATION_MS)`, 24h, written server-side only |
| Reward keys | Allowlisted (`KNOWN_REWARD_KEYS`, 9 keys) — an unlisted key is rejected |
| Ad units | Allowlisted (`KNOWN_AD_UNITS`, the 2 real Android/iOS unit ids) |
| HTTP status policy | 400 only for a genuinely malformed/unverifiable callback; 200 for every well-formed rejection (per AdMob's own documented retry contract); 500 only for this function's own unexpected failure |
| Tests | `functions/ad_rewards.test.js` — **22/22 PASS** (re-run fresh during this audit) |
| Token/signature logging | **Not logged in plaintext** — `log()` calls carry `transactionId`/`rewardKey`/`uid`/`reason`, never the raw signature or query string |

- **Deployed**: **UNKNOWN.** `AUDIT_PHASE_B3_SSV_IMPLEMENTATION_READINESS.md`'s
  own §8 "Deployment" section lists deploying `functions:ad_rewards` and
  registering the SSV URL in the AdMob console as **future**, numbered
  action items (steps 11-12) — written *before* the implementation
  commit (`796bf19`, the next day), and nothing found since confirms
  those steps were ever actually carried out.
- **SSV URL registered/active in AdMob console**: **NOT CONFIRMED —
  per the user's own instruction, this is marked BLOCKED rather than
  attempting any live verification.**
- **Production Verified**: **BLOCKED.** No test that consumes a real
  reward or touches a production user was run, per instruction.
- **Verdict**: **CODE READY / COMMITTED — DEPLOYMENT + SSV CONSOLE
  REGISTRATION UNKNOWN — PRODUCTION VERIFICATION BLOCKED.**
- **Remaining action (user-owned)**: deploy `functions:ad_rewards`
  alone (not a full functions redeploy); confirm/set the AdMob console's
  SSV URL to point at the deployed function's URL; confirm the reward
  amount configured on the live `.../3809909145` (Android) and
  `.../3939122841` (iOS) ad units is exactly `"1"` (B2's own audit
  flagged this specific value as **unverifiable from code** — it's an
  AdMob console setting); only then run one real, deliberate on-device
  end-to-end test (watch a real ad on the `particle` reward key, per the
  user's own scoping) — genuinely consuming that one reward is
  unavoidable to prove the endpoint works, but must be a single
  intentional test, not repeated/automated.

### D. Real Play Purchase Readiness

Verified from `lib/core/constants/iap_products.dart`, `functions/iap.js`,
`functions/subscription_notifications.js`, `functions/iap_states.js`,
plus `AUDIT_SUBSCRIPTION_RECOVERY.md`/`AUDIT_SUBSCRIPTION_RECOVERY_DESIGN.md`/
`AUDIT_PLAY_ITEM_UNAVAILABLE.md` (pre-existing):

| Item | Code-provable? | Finding |
|---|---|---|
| Premium product id | ✅ yes | `teisou_premium_monthly` — identical client (`iap_products.dart:47`) and server (`iap.js:33`) |
| Package name | ✅ yes | `com.teisou.kanamaster` — consistent across `build.gradle.kts`, `google-services.json`, `iap.js` |
| `verifyPurchase` | ✅ yes | Exists, gated on `PLAY_VERIFICATION_ENABLED` (fails closed if unset), decision logic in `iap_states.js` |
| `onPlayRtdn` | ✅ yes | Exists, Pub/Sub-triggered on topic `play-store-rtdn` — **the topic name must match Play Console exactly, and Play's publisher service account must be granted permission on it, both external/unverifiable from this repo** (the function's own doc comment says so) |
| Subscription backstop | ✅ yes | See §B — code ready, deployment unknown |
| Purchase reentrancy fix (RISK-4) | ✅ yes | Client-side `_buying` guard, 7/7 tests passing |
| Base plan / offer id | ✅ yes (confirmed absent) | App never names one, trusts Play's default resolution — ruled out as a mismatch cause by `AUDIT_PLAY_ITEM_UNAVAILABLE.md` |
| Base plan exists & active in Play Console | ❌ no | Play Console only |
| Tester/track eligibility | ❌ no | Play Console only (License testing, track rollout) |
| Installed build genuinely Play-signed | ❌ no | Device/Codemagic build log only — this app's own code comment (`iap_products.dart:32-37`) warns a sideloaded/debug build always reports every product unavailable |
| `PLAY_VERIFICATION_ENABLED` actually live on deployed Functions | ❌ no | `AUDIT_SUBSCRIPTION_RECOVERY.md`'s own conclusion: cannot be established from code alone |

- **Known real-world history**: `AUDIT_PLAY_ITEM_UNAVAILABLE.md`
  documents an actual production report of Play's native
  `ITEM_UNAVAILABLE` (billing code 4) — traced to a boundary Play itself
  rejects the purchase at, before this app's code ever runs, and every
  code-provable factor (product id, package name, base-plan-id absence)
  came back clean. Root cause narrowed to Play-Console-only facts this
  repo cannot see.
- **Verdict**: **CODE READY for a well-configured Play Console — real
  purchase verification is entirely blocked on**: (1) Play Console
  configuration (base plan active, correct track, tester list), (2) a
  genuinely Play-signed release build (not sideloaded/debug), (3) a
  physical device with that build installed from Play, (4) a real
  purchase attempt. None of these four are things this environment can
  do or verify.
- **No real purchase was made or attempted as part of this audit.**

### E. Production Deployment Matrix

| Component | Code | Tests | Committed | Deployed | Production Verified | Evidence | Remaining Action |
|---|---|---|---|---|---|---|---|
| `firestore.rules` (RISK-2 mirror-write fix) | ✅ | ✅ 74/74 emulator (2026-08-28) | ✅ `cb3fcf1` | ✅ **CONFIRMED 2026-08-28** | ❓ UNKNOWN (deployed, live behavior not separately probed) | Firebase deploy output + emulator re-run, this session | optional: a live Rules Playground probe to close the "behavior verified" gap |
| Subscription backstop Functions (RISK-3) | ✅ | ✅ 16 new / 314 total | ✅ `9260517` | ✅ **CONFIRMED 2026-08-28** (retried after confirming network access, `functions:list` re-verified) | ❌ **NOT YET** — deployed but no scheduled invocation observed yet | deploy output + `functions:list`, this session | wait for/trigger a scheduled run, read Cloud Functions logs, then decide on enabling enforcement |
| Firestore indexes (RISK-3's composite index) | ✅ | N/A | ✅ `9260517` | ✅ **CONFIRMED 2026-08-28** | N/A (an index has no "behavior" to verify beyond existing) | Firebase deploy output + live `firestore:indexes` re-read, this session | none |
| AdMob SSV (`adRewards`/`consumeAdReward`) | ✅ | ✅ 22/22 | ✅ `796bf19` | ✅ **CONFIRMED live** (`firebase functions:list`, this session — found incidentally while auditing RISK-3, not independently pursued) | 🚫 **BLOCKED** (no live-test per instruction) | `functions:list` output, this session | register/confirm SSV URL in AdMob console, confirm reward amount, one deliberate on-device test |
| `verifyPurchase` / `onPlayRtdn` | ✅ | ✅ (part of 314) | ✅ (pre-RISK-N) | ✅ **CONFIRMED live** (`firebase functions:list`, this session) | ❌ (last known real attempt failed at Play's own dialog, root cause Play-Console-only) | `functions:list` output; `AUDIT_SUBSCRIPTION_RECOVERY.md`, `AUDIT_PLAY_ITEM_UNAVAILABLE.md` | Play Console config + Play-signed build + device + real purchase |
| Premium purchase flow (client, incl. RISK-4 reentrancy fix) | ✅ | ✅ 7/7 | ✅ `913347e` | N/A (ships with next app build) | ❌ | this session's own verification | needs a released app build to reach any real user |

**Reading this matrix (updated 2026-08-28, second pass)**: every row is
"commit exists" ✅ and "tests pass" ✅. **`firestore.rules` and the
RISK-3 composite index are now confirmed Deployed by this session's own
actions; `adRewards`/`consumeAdReward`/`verifyPurchase`/`onPlayRtdn`
were found already deployed** (pre-existing, discovered incidentally via
`functions:list`, not deployed by this session). **The RISK-3 scheduled
Functions deploy attempt FAILED** — see §B — on a genuine network-egress
limit in this environment, not a code problem. **Zero rows are confirmed
"Production Verified"** in the stricter sense (a live, real-traffic
behavior probe) — deploying is not the same claim, and this file is
deliberately keeping the two separate. This is not a code-quality
problem — every fix audited across RISK-1 through Q3 this session is
well-tested and defensible on its own terms. **`npx --yes
firebase-tools@latest` works for Firestore Rules, Firestore Indexes,
AND Functions from this environment** — the earlier Functions failure
(two identical `ConnectTimeoutError`s to
`iam.googleapis.com`/`firebase.googleapis.com`) turned out to be a
**transient** network-egress gap in this sandbox, not a permanent one:
a same-day follow-up first confirmed those exact two hosts were
reachable again (a single lightweight connectivity probe, not a blind
retry), then deployed both scheduled Functions successfully. The
lesson worth keeping: this sandbox's network egress to the wider Google
API surface Functions deployment needs (beyond what Rules/Indexes
touch) is **not reliably available at all times** — check connectivity
before a deploy attempt and before assuming a prior failure is
permanent, rather than assuming either "always broken" or "always
fine." A Play-signed build and Play Console access remain genuinely
outside this environment either way. This project's own history (the
Clan-rules incident) is exactly why this file keeps insisting on
evidence over assumption for every row above.

### F. New findings from this audit (not previously tracked)

**Kept as the historical record of the read-only audit phase — see the
"Update 2026-08-28" note right after for what changed since.**

- **No new code bug found.** This phase was read-only by design and
  found none.
- **New test gap, worth tracking**: none of the 6 matrix rows above have
  ANY automated "is this actually live in production" check — by
  nature, since that requires live infrastructure access this
  environment doesn't have. If Firebase deploy access is ever available
  to a future session, a smoke-test script (e.g. attempt a rules-
  protected write and confirm it's denied against the LIVE project, not
  the emulator) would close this gap.
- **New deployment blocker, explicit**: RISK-2's `firestore.rules` fix
  (cosmetic identity spoofing via leaderboard/clan/friend mirrors) has
  been sitting committed-but-undeployed since Aug 27. Until deployed,
  the vulnerability it fixes is still live in production.
- **Requirement carried forward from RISK-2's own commit, restated
  here for visibility**: deploying `firestore.rules` is the single
  highest-value pending action in this whole matrix — it's the only
  row where the code fix is 100% code-complete/tested AND the
  deployment step is a single, well-understood command, not blocked on
  external Play/AdMob console configuration the way B/C/D are.

**Update 2026-08-28**: two of the above are now resolved, per an
explicit, scoped user request to deploy RISK-2's rules fix specifically.
1. **The "no live infrastructure access" premise above was wrong** — it
   assumed the bare `firebase` CLI's crash meant deployment was
   impossible from this environment. It wasn't: `npx --yes
   firebase-tools@latest` (already documented in
   `firestore_rules_tests/README.md`, just not connected to the deploy
   question until this session) works cleanly and was already
   authenticated as the project owner. Worth remembering for B/C/D too
   — their "deployment status UNKNOWN" verdicts were never blocked by
   environment access, only by not having been asked to deploy them.
2. **RISK-2's deployment blocker is closed** — see §A above for the
   full record (deploy output, timestamp, 74/74 emulator re-verification).
   The distinction between "deployed" and "production behavior verified"
   still holds and is called out explicitly in §A — deploying closes the
   first, not automatically the second.

## G. Safety confirmation

No destructive git operations used. `git status`/`git diff`/`git log`/
`git show`/`git merge-base` only. No `firestore.rules`/`functions/`/Dart
production file was modified. No Play Console, AdMob console, or
Firestore data was touched. `windows/flutter/*` and every `AUDIT_*.md`/
`AUDIT_SUBSCRIPTION_*.md` file remain exactly as they were — read for
evidence, never edited or staged. No `firebase deploy` command was run.

## Core Clan Mechanics Audit — Fix Phase (2026-08-28, same day) — BOTH bugs FIXED; BUG #2's rules fix DEPLOYED 2026-08-28, BUG #1's joinClan fix NOT yet released

Both P1 bugs from the audit below are now fixed in code, with permanent
regression coverage, per explicit user authorization for a scoped
code+test-only fix phase. At the time this section was originally
written, neither fix had been deployed. **Update, same day**: the
`firestore.rules` half (BUG #2) has since been deployed to production
under explicit separate authorization — see "Rules Deployment" further
below for the full record. **BUG #1's `joinClan` fix is still Dart app
code, not server config — it only takes effect once a new app build
containing it is released to users, which has NOT happened.**

### BUG #1 fix — `joinClan` converted to a transaction

**File**: `lib/data/repositories/clan_repository.dart`,
`ClanRepository.joinClan`. Converted the plain `.get()` existence-check +
unconditional `batch.update({'memberCount': FieldValue.increment(1)})`
into `_firestore.runTransaction(...)`, reading `memberDoc` inside the
transaction and only writing (member doc, membership doc, `memberCount`
increment) if it doesn't already exist — the exact same shape RISK-9
already proved for `kickMember`/`leaveClan`. The clan doc's own
existence/name lookup (`clanRef.get()`) deliberately stays a plain,
non-transactional read *outside* the transaction — including it inside
would make two genuinely different users joining the same clan
concurrently retry against each other for no reason, since they'd share
a read-set on the same clan doc. The `memberCount` increment stays a
blind, un-read write inside the transaction (safe because
`FieldValue.increment` is a pure additive transform — same reasoning
`kickMember` already relies on).

**Tests added** (`test/clan_reentrancy_test.dart`, new "Join — backend
transaction" group, 5 tests, all against a Completer-gated fake
`FirebaseFirestore`/`Transaction` extended in this pass to support
`Transaction.set()` and a real increment-sign read via `FieldValue`
value-equality, not a hardcoded sign):
- (a) two concurrent `joinClan()` calls for the SAME `(code, uid)` →
  `memberCount` increments exactly once, not twice.
- (b) two concurrent `joinClan()` calls for TWO DIFFERENT uids on the
  same clan → both succeed independently, `memberCount` +2, no
  cross-user retry/interference.
- (c) `joinClan()` when the uid is already a member → safe no-op,
  `memberCount` unchanged.
- (d) `joinClan()` against a nonexistent clan code → throws
  `StateError`, no member doc created, no `memberCount` written
  anywhere.
- (e) a realistic mixed batch (3 concurrent new joins + 1 already-member
  retry, no forced interleaving) → lands on exactly base + 3.

**Old reproduction → new reproduction (fail-then-pass, verified by
actually reverting the fix in place)**: temporarily reverted `joinClan`
to its old plain-batch shape (kept the new test file's `Transaction.set`
support, added a temporary `WriteBatch` fake so the old code could run
against the same store) and re-ran the "Join" test group. **Test (a)
correctly failed**: `Expected: <2>, Actual: <3>` — the exact
double-increment this bug describes, reproduced against the specific
new permanent test, not just the old throwaway one. Tests (b)/(c)/(d)/
(e) don't exercise the same-uid race and correctly still passed against
old code (expected — they were never proof of this specific bug, just
adjacent correctness properties). Restored the real fix; full group
re-ran 5/5 PASS.

The original audit-only throwaway proof, `test/_audit_clan_mechanics_test.dart`,
is **deleted** (never committed, its fake infra no longer matches the
transactional shape and is fully superseded by the permanent coverage
above).

### BUG #2 fix — `firestore.rules`: leadership authority derived from `hostUid`, never from a mutable `role` value

**File**: `firestore.rules` — `actorRole()` (~line 583) and the
`clans/{code}/members/{memberUid}` `allow write`/`allow update` rules
(~line 294-333).

Two layers, both needed (found a second, more severe self-elevation
path mid-fix that the original audit hadn't named — see below):

1. **`actorRole()` hardened** — now reads `hostUid` first and treats it
   as the sole source of truth for `'leader'` status. A stored `role`
   of `'leader'` is only honored when it genuinely came from the host;
   every other uid's stored role is still trusted for
   `'coLeader'`/`'member'` (so legitimate promote/demote between those
   two is completely unaffected), but a non-host's row can never read
   back as `'leader'` no matter what value is written to it — this
   alone makes a forged `'leader'` value harmless for every
   leader-gated check in the file (`canKick`, announcements, promote/
   demote), even before the write-time restrictions below.
2. **Write-time value restrictions**, defense-in-depth on top of (1):
   - `allow update` (leader promotes/demotes ANOTHER member): now also
     requires `request.resource.data.role in ['member', 'coLeader']` —
     a leader can no longer write `'leader'` onto someone else's row at
     all, closing the exact path the original audit proof exercised.
   - `allow write` (own-row create/update/delete): **a second,
     previously-undocumented escalation path was found while designing
     this fix** — the existing rule had *no* restriction on `role`'s
     value at all, meaning *any* existing member could self-elevate by
     directly editing their own roster row (`updateDoc(ownRef, {role:
     'leader'})`), a simpler and more direct exploit than the
     leader-grants-to-another path the audit named. Fixed by requiring
     that an existing row's own self-write can never change `role` at
     all (whatever it currently is, it must stay exactly the same) — a
     brand-new row (fresh join, or the host's own row at clan creation)
     is left unrestricted at create time, since `createClan`'s own
     separate rule on the `clans/{code}` doc already guarantees
     `hostUid == request.auth.uid` for that one legitimate case, and
     `joinClan` always constructs a fresh member with `role: 'member'`.

**Tests added** (`firestore_rules_tests/clan_role_authority.test.js`,
new **permanent** file, run against the real Rules Emulator, 5 tests —
covers every scenario named in the task instruction):
- (a) the real leader can still legitimately promote a member to
  coLeader.
- (b) an ordinary member cannot promote themself by editing their own
  roster row (the self-elevation path found mid-fix).
- (c) a forged stored `role: 'leader'` on a non-host row (seeded
  directly, bypassing rules, to simulate a legacy/corrupted document)
  grants no real leader privileges — cannot promote anyone else.
- (d) the same forged non-host `'leader'` row cannot kick the real clan
  owner — the exact end-to-end chain the original audit proof
  demonstrated.
- (e) legitimate kick policy for the real leader and a real coLeader
  still works exactly as before (leader kicks member: succeeds;
  coLeader kicks member: succeeds; coLeader kicks leader: still
  denied).

**Old reproduction → new reproduction (fail-then-pass, verified against
the real rules engine, not source-inspection)**: re-ran the original
audit's throwaway `firestore_rules_tests/_audit_clan_escalation.test.js`
(2 tests, both `assertSucceeds` on the malicious writes) against the
**new, fixed** rules — **both now correctly `PERMISSION_DENIED`,
causing the `assertSucceeds` assertions to fail** — i.e. the exploit
this file was built to prove is now blocked. That confirms the fix
closes exactly what the audit found. The throwaway file is then
**deleted** (never committed), superseded by the 5 permanent scenarios
above, which cover strictly more ground (including the second
self-elevation path).

**Emulator harness gotcha found and worked around**: running multiple
`*.test.js` files in one `node --test file1 file2 file3` invocation
against the shared `demo-teisou-rules-test` emulator project caused
spurious cross-file failures (`Transaction lock timeout`, docs
unexpectedly missing) — Node's test runner parallelizes across files by
default, and every file's own `beforeEach: clearFirestore()` raced
against the others. Not a rules bug — confirmed by re-running the exact
same three files **sequentially** (`node --test a && node --test b &&
node --test c`, matching this project's own documented single-file
`package.json` convention) inside one `emulators:exec` session: clean,
zero failures, every time.

### Verification — full cross-check suite, all green

- **`flutter analyze`** (whole repo): **0 issues.**
- **`flutter test --concurrency=1`** (whole repo): **881/881 pass**,
  zero regressions anywhere.
- **Firestore Rules Emulator**, sequential per-file (`rules.test.js` +
  `wildcard_probe.test.js` + `clan_role_authority.test.js`): **73 + 1 +
  5 = 79/79 pass.** No `firestore.rules` regression on any pre-existing
  behavior (RISK-2's full 74-test suite unchanged and still green).
- **Cloud Functions suite** (`node --test` in `functions/`): **314/314
  pass**, unaffected (this phase never touched `functions/`).
- **`test/clan_reentrancy_test.dart`** specifically (all RISK-9 clan/
  friend coverage + the new Join group): **13/13 pass** — all 4 kick/
  leave/invite/friend-request client-layer tests, both kick/leave
  backend-transaction tests, and all 5 new join tests.
- **`test/clan_cross_user_write_test.dart`**: 2/2 pass, unaffected.
- **`test/coin_buy_reentrancy_test.dart`** (RISK-5) / **`test/premium_purchase_reentrancy_test.dart`**
  (RISK-4): 9/9 + 7/7 pass, unaffected — confirmed untouched by this
  phase, run anyway per the cross-check requirement.

### Files changed

- `firestore.rules` — `actorRole()` + `members/{memberUid}` `allow
  write`/`allow update` rules (BUG #2 fix).
- `lib/data/repositories/clan_repository.dart` — `joinClan` (BUG #1
  fix).
- `test/clan_reentrancy_test.dart` — extended fake Firestore
  infrastructure (`Transaction.set`, a plain gate-aware
  `DocumentReference.get()`, correct `FieldValue.increment` sign
  reading via value-equality, `seedClan` gained `name`/`hostUid`
  params) + 5 new permanent Join tests.
- `firestore_rules_tests/clan_role_authority.test.js` — new permanent
  file, 5 tests.
- Deleted (never committed, so no `git rm` trace):
  `test/_audit_clan_mechanics_test.dart`,
  `firestore_rules_tests/_audit_clan_escalation.test.js`.

### Deployment status — explicit, do not skim past this

- **`firestore.rules`**: **DEPLOYED 2026-08-28, see the dedicated
  "Rules Deployment" record below** for the full detail (this
  paragraph originally said NOT DEPLOYED — corrected in place rather
  than left stale, since the deploy happened later the same UTC day
  under separate explicit authorization). BUG #2 (both the
  leader-grants-to-another path and the self-elevation path) is closed
  in production as of that deploy.
- **`lib/data/repositories/clan_repository.dart`**: this is app code,
  not server config — it only takes effect once a new app build
  (containing this commit) is released to users. **Still NOT released
  as of this writing** — the currently-shipped app build still has the
  old, double-increment-vulnerable `joinClan`. This is unaffected by
  the rules deploy above (a Firestore Rules deploy is server-side only
  and never touches what's inside an already-installed app binary).
- **Production behavioral verification = NOT DONE, and not attempted
  by design** — the rules deploy was verified via Firebase's own
  compile/upload/release confirmation (a real, authoritative response
  from the Rules control plane), not by running a write against live
  production data. Per explicit instruction for the deployment task:
  no malicious write was attempted against production merely to prove
  denial. Status is honestly **DEPLOYED — BEHAVIOR NOT DIRECTLY
  PROBED**, not VERIFIED.

### Recommended next action

The rules fix is live; `joinClan`'s fix is not:
1. ~~`firebase deploy --only firestore:rules` — closes BUG #2 in
   production immediately (server-side, no app update needed).~~ **DONE
   2026-08-28, see "Rules Deployment" below.**
2. Ship a new app build containing the `joinClan` transaction fix —
   closes BUG #1 for future joins (existing corrupted `memberCount`
   values, if any already occurred in production, are not
   retroactively repaired by this fix — that would be a separate
   one-time backfill, out of this phase's scope and not investigated).

## Rules Deployment — Clan role-escalation fix (BUG #2) LIVE (2026-08-28)

Explicit, separately-authorized deploy task: deploy ONLY the current
`firestore.rules` (source: commit `b5fbb10`), nothing else. No source
was modified as part of this task.

**Pre-flight**:
- `git merge-base --is-ancestor b5fbb10 HEAD` confirmed `b5fbb10` is an
  ancestor of HEAD (`e7fab5a` at the time).
- `firestore.rules` confirmed to contain all four expected fix markers:
  `actorRole()` deriving authority from `hostUid` first
  (`let hostUid = get(...).data.hostUid;` and
  `uid == hostUid ? 'leader' : (storedRole == 'leader' ? 'member' :
  storedRole)`), the leader-promotes-another rule's value restriction
  (`request.resource.data.role in ['member', 'coLeader']`), and the
  own-row rule's self-elevation block
  (`request.resource.data.role == resource.data.role`).
- `git status`/`git diff --stat` on `firestore.rules` alone: **zero
  local drift** — the committed version is exactly what was deployed.
- `.firebaserc` confirmed `"default": "teisou-kana-master"`.

**Pre-deploy test run** (Firestore Rules Emulator, run sequentially per
this repo's own documented single-file convention, matching the
cross-file-race workaround found during the fix phase): `rules.test.js`
73/73, `wildcard_probe.test.js` 1/1, `clan_role_authority.test.js` 5/5
— **79/79 pass**, immediately before deploying.

**Deploy command**: `npx --yes firebase-tools@latest deploy --only
firestore:rules --project teisou-kana-master` (the bare `firebase`
binary is broken in this environment — crashes on its own first-run
`welcome.js` script — this `npx` substitute is the repo-documented
workaround, same one used for RISK-2's original deploy and RISK-3's
index/Functions deploy).

**Deploy result**: **SUCCEEDED.**
```
cloud.firestore: checking firestore.rules for compilation errors...
cloud.firestore: rules file firestore.rules compiled successfully
firestore: uploading rules firestore.rules...
firestore: released rules firestore.rules to cloud.firestore
Deploy complete!
```
Timestamp: **2026-08-28 17:02:17 UTC** (machine clock at the moment
immediately following the deploy command's completion). Project:
**teisou-kana-master**.

**Post-deploy verification**: no dedicated `firebase firestore:rules:*`
read-back subcommand exists in this CLI (`firebase firestore --help`
lists only `delete`/`bulkdelete`/`indexes`/`locations`/`operations`/
`databases`/`backups` — nothing for reading back an active ruleset's
content), so the deploy command's own response above — a genuine
compile→upload→release round trip against Firebase's real Rules
control plane, not a local assumption — is the verification evidence.
**No write was attempted against live production Firestore data to
prove the fix behaviorally** — per explicit instruction, this task
does not corrupt/modify production data merely to demonstrate a
denial. Production behavioral status is honestly recorded as
**DEPLOYED — BEHAVIOR NOT DIRECTLY PROBED**, not VERIFIED; the 79/79
emulator result immediately above, against the byte-identical rules
content that was just deployed, is the evidence that the *logic* is
correct — what remains unconfirmed is only that the live project is
actually serving it, which the deploy command's own success response
already attests to.

**Scope discipline**: only `firestore:rules` was deployed — no
Functions, Hosting, Storage, or index changes; no Dart source touched;
no Play Console/AdMob/production-data changes; no destructive git
command used. `lib/data/repositories/clan_repository.dart`'s `joinClan`
fix (BUG #1) was deliberately **not** released as part of this task —
it ships only with a future app build. RISK-3's subscription backstop
was not touched.

**Files changed by this task**: `TEISOU_ROADMAP_MASTER.md` only (this
section plus the two corrections above) — `firestore.rules` itself was
deployed, not edited.

## Rank-Skip Exam Audit (2026-08-29) — AUDIT ONLY, 2 new bugs found

Read-only, end-to-end audit of the rank-skip exam flow (UI →
`RankSkipService` → `startRankSkipExam`/`submitRankSkipExam` Cloud
Functions → `battleStars.promoteToTierFloor` → Firestore →
`firestore.rules`), per the same audit-only discipline as the Core
Clan Mechanics audit above: findings are reported, not fixed, and no
production/rules/source file was modified. Both findings below were
proven against the current code with a deterministic, purpose-built
in-process fake — **no new RISK number self-assigned**, per
instruction.

### All rank-skip mutation paths (item 1)

Exactly two, both Cloud Functions (`functions/rank_skip.js`), both
`onCall`:
1. **`startRankSkipExam`** — writes `rankSkipExams/{uid}` (`session`
   object: sessionId/tier/cardIds/startedAt; passes through whatever
   `lockedUntil` it read).
2. **`submitRankSkipExam`** — writes `rankSkipExams/{uid}` (deletes
   `session`; sets `lockedUntil` only on failure) and, only on a pass,
   calls `battleStars.promoteToTierFloor(uid, tier)`, which writes
   `users/{uid}.cardGameRank` inside its own transaction and
   best-effort mirrors to `leaderboard/{uid}`.

The Dart client (`RankSkipService`, `rank_skip_screen.dart`) makes no
Firestore write of its own anywhere in this flow — it only calls the
two functions above and reads back their response. Confirmed by
reading both files in full.

### Authorization findings (item 2)

- **SAFE** — both functions check `request.auth.uid`, throw
  `unauthenticated` otherwise.
- **SAFE — eligibility**: `startRankSkipExam` derives the caller's
  *current* tier from `battleStars._internal.readRank(userSnap.data())`
  (server-read, not client-supplied) and only allows `targetTier`
  values in `tiersAbove(current.tier)` — a client cannot skip down or
  re-target the tier already held.
- **SAFE — ownership**: `examRef(uid)` is always keyed by
  `request.auth.uid`, never a client-supplied id, so a user can never
  read/submit against another user's exam session.
- **SAFE — target-tier integrity**: `submitRankSkipExam` promotes using
  `session.tier` (the value `startRankSkipExam` itself stored
  server-side), never a tier re-supplied by the client at submit time
  — a client cannot request `targetTier: 'gold'` at start and then
  claim a promotion to `emerald` at submit.
- **SAFE — cannot forge a result**: grading is 100% server-side
  (`isCorrect()`, reusing `battle_scoring`'s own rule so an exam cannot
  mark right what a battle would mark wrong); the client only ever
  sends raw typed `answers`, never a score or a pass/fail boolean.
  `rankSkipExams/{uid}` (which holds the answer key) is fully sealed in
  `firestore.rules` (`allow read, write: if false;` — confirmed by
  reading the rule directly, read-only per instruction) — a client
  cannot read the key nor write a forged session/result.
- **SAFE — `cardGameRank` cannot be client-written**: confirmed in
  `firestore.rules`'s `users/{uid}` `allow create`/`allow update` rules
  — `!('cardGameRank' in request.resource.data)` on create,
  `request.resource.data.get('cardGameRank', null) ==
  resource.data.get('cardGameRank', null)` on update (client writes
  must leave it byte-identical). The only writer is
  `battleStars.promoteToTierFloor`/`onBattleMatchConcluded`, both
  Admin SDK, not subject to rules at all.

### Race / atomicity findings (items 5-11, 15-16)

- **BUG — TOCTOU, `startRankSkipExam` vs `submitRankSkipExam` racing on
  `rankSkipExams/{uid}` (P2, PROVEN BY TEST)**. Neither handler uses a
  Firestore transaction on this document — both read it with a plain
  `ref.get()` and write with a plain `ref.set(..., {merge:true})`.
  `startRankSkipExam` always re-asserts whatever `lockedUntil` value it
  read (`lockedUntil: existing.lockedUntil || null`) as part of its own
  write. If a `startRankSkipExam` call reads the still-unlocked state,
  then a concurrent `submitRankSkipExam` call fails and writes a fresh
  `lockedUntil`, then the paused `startRankSkipExam` call finally
  writes — its write lands **last**, using its **stale** (pre-fail,
  still-null) `lockedUntil`, silently wiping the cooldown the failing
  submission had just set. Worse: this same write also installs a
  **brand-new exam session** in the same commit — so the end state
  isn't just "cooldown gone," it's "cooldown gone AND a fresh attempt
  is already loaded and ready." A player (or a trivial script) firing a
  `startRankSkipExam` call immediately alongside every failing
  `submitRankSkipExam` call can defeat the 24-hour cooldown
  indefinitely — the intended anti-grinding throttle is not just
  weakened but fully bypassable on demand. This does **not** let
  anyone forge a pass or an unearned promotion — every individual
  attempt is still genuinely, correctly graded server-side — it only
  removes the cost/friction the cooldown exists to impose. Severity is
  P2 (gameplay-integrity, not a data-corruption or unauthorized-access
  bug) rather than P1 for that reason.
- **Related design gap (INFO, not separately proven — evident from
  reading the code)**: `startRankSkipExam` has **no check at all** for
  an already-in-progress, unexpired session — only the `lockedUntil`
  cooldown is checked. This means a player can call
  `startRankSkipExam` repeatedly and sequentially (no race needed) to
  discard an exam they're unsure of and draw a fresh one, at zero cost,
  as long as they never actually submit a losing attempt. Combined
  with the TOCTOU bug above, this means the *entire* 24-hour cooldown
  mechanic is effectively opt-in: a player who avoids submitting (or
  who races a start against a losing submit) never pays it. This is
  the same underlying "no per-session commitment on `startRankSkipExam`"
  root cause as the TOCTOU bug, not a second independent bug — recorded
  together so a future fix addresses both from the same root (e.g. a
  transactional start that also rejects starting over an unexpired
  session, and/or making the whole read-modify-write on
  `rankSkipExams/{uid}` a single transaction for both handlers).
- **BUG — atomicity gap: a promotion failure after a genuine pass
  strands the player (P2, PROVEN BY TEST)**. `submitRankSkipExam`
  deletes the exam `session` (`ref.set({session: FieldValue.delete(),
  ...})`) **before** calling `battleStars.promoteToTierFloor`. If that
  call throws (a transient Firestore error, for instance —
  `promoteToTierFloor` itself is a solid, correctly-idempotent
  transaction; the risk here is any ordinary failure *reaching* it, not
  a flaw inside it), the whole `submitRankSkipExam` call rejects to the
  client, but the session is already gone. The player genuinely passed,
  was never promoted, is not locked out either (no cooldown on a pass
  branch), and has no way to retry the *same* graded attempt — they
  must retake the entire 20-question exam from scratch, and nothing
  anywhere records that they once passed. Not an attacker-facing
  exploit; a player-hostile reliability gap.
- **SAFE / PROVEN SAFE — double-promotion from concurrent submits**:
  `promoteToTierFloor` (`battle_stars.js`) is a genuine transaction that
  reads current rank and only promotes if `totalStars(current) <
  floor`, so two (or more) concurrent `submitRankSkipExam` calls for the
  same passing session each independently calling
  `promoteToTierFloor` converge to exactly one real promotion — every
  call after the first correctly reads the already-promoted state and
  no-ops. This is the same transaction-conflict-and-retry contract
  already proven throughout this project's earlier fixes (RISK-9,
  Core Clan Mechanics BUG #1) — verified here by direct code reading of
  `promoteToTierFloor`'s transaction body (reads `current`, checks the
  floor, conditionally writes), not re-proven with a fresh test, since
  `battle_stars.test.js` already covers the ladder arithmetic and the
  transaction shape is identical to what earlier phases already
  deterministically proved race-safe elsewhere in this codebase.
- **SAFE — session cannot be consumed twice**: `submitRankSkipExam`
  unconditionally deletes `session` as part of its own write (pass or
  fail), and a later call with the same `sessionId` finds
  `session.sessionId !== sessionId` (session gone) and throws
  `failed-precondition`. Even under N-way concurrent submission on the
  *same* session (more than two racers), every promotion attempt still
  converges safely per the point above — the safety property comes
  from `promoteToTierFloor`'s own idempotency, not from any dedup on
  the exam side, but the net effect is the same: no double reward.
- **SAFE — expiry has no exploitable asymmetry found**: an expired
  session (`SESSION_MINUTES` elapsed) is cleared with no cooldown, by
  explicit design ("expiring is not failing" — read directly from the
  code's own doc comment). No forced-race test was built for this
  specific path; classified SAFE from direct reading, not PROVEN SAFE.

### Idempotency findings (item 11) — folded into the atomicity section
above; summary: `promoteToTierFloor` is genuinely idempotent (SAFE/
PROVEN via code reading, not re-tested), the exam-session lifecycle
itself is not (the two bugs above), and no XP/coin system is touched
by this flow at all (confirmed: `rank_skip.js` has zero references to
`award_xp`/`spend_coins`/any XP or coin field — item 19 is a clean
**SAFE, no cross-system interaction exists**).

### Rules findings (item 17)

- **SAFE** — `rankSkipExams/{uid}` is sealed at the top level
  (`match /rankSkipExams/{uid} { match /{document=**} { allow read,
  write: if false; } }`), sitting entirely outside `users/{uid}`'s own
  match tree — it was never exposed by (and is unaffected by) the
  Core Clan Mechanics session's recursive-wildcard fix, since it isn't
  under that wildcard's path at all. Confirmed by reading the rule
  directly (read-only, per instruction — not modified).
- **SAFE** — `cardGameRank` write-protection on `users/{uid}` (see
  Authorization findings above) is the second, independent layer that
  would still hold even if `rankSkipExams` were somehow compromised —
  a client still could not write a promotion directly.

### Test gaps (item 6/20)

- **`functions/rank_skip.test.js` (the only existing test file) covers
  ONLY the pure, exported `_internal` helpers** (`poolFor`, `sample`,
  `isCorrect`, `tiersAbove`) — **zero coverage of either `onCall`
  handler itself**, and zero coverage of any concurrency, atomicity, or
  idempotency property. Every finding above required a purpose-built
  temporary test to even exercise the real handlers.
- **No dependency-injection seam** — unlike `spend_coins.js`/
  `award_xp.js`/`subscription_backstop.js` (which all take an
  injectable `firestore`/`dbInstance` option specifically so a test can
  substitute a fake), `rank_skip.js`'s `db()` calls `getFirestore()`
  directly with no override point. This audit's temporary test worked
  around it via a `require.cache`-style substitution of
  `firebase-admin/firestore`'s exported `getFirestore` (confirmed
  isolated to its own file — Node's test runner runs each file in its
  own worker, verified by running the full 317-test suite together and
  seeing only this audit's own 2 deliberate failures, no leakage into
  any other file) — the same technique `spend_coins.js`'s own doc
  comment says this codebase already used before that file grew a
  proper seam. A permanent fix phase would likely want the same seam
  added to `rank_skip.js`.
- **No client-side reentrancy guard on `_start`/`_submit`**
  (`rank_skip_screen.dart`) — unlike every purchase/social-mutation
  button already fixed elsewhere in this app (RISK-4/5/8/9), neither
  method has an early-return guard checking "already in flight" before
  its first `setState`; the only protection is that `_phase ==
  working` swaps the whole tier-choice/answer UI out for a bare
  spinner once the rebuild lands — the same shape that was previously
  proven exploitable elsewhere in this app for a same-frame double-tap,
  before each of those was fixed with an explicit guard. Not
  independently proven exploitable here (not attempted — the SERVER-side
  findings above already show a double-`submit()` is largely safe via
  `promoteToTierFloor`'s idempotency, and a double-`start()`'s
  consequence is covered by the TOCTOU/no-session-lock finding already
  reported), but flagged since it's inconsistent with this app's own
  established convention and unverified. **P3 / TEST GAP, not
  separately classified as its own BUG.**

### Temporary audit files (item 7)

- `functions/_audit_rank_skip_toctou.test.js` — 3 tests: the TOCTOU
  proof (fails against current code), the atomicity/promotion-failure
  proof (fails against current code), and a sequential control
  (correctly passes, confirming the cooldown mechanism itself works
  and the bug is specifically about the race). Contains its own small,
  purpose-built in-process Firestore fake (deliberately not the shared
  `functions/test_helpers/fake_firestore.js`, since that fake's gating
  hook only applies inside `runTransaction`'s retry loop and
  `rank_skip.js`'s two handlers never use a transaction on
  `rankSkipExams/{uid}` at all — itself one of this audit's findings).
  **Not committed**, per instruction — kept `_audit_`-prefixed pending
  a fix phase.

### Test results (item 8)

- `functions/rank_skip.test.js` (pre-existing, unmodified): 6/6 pass.
- `functions/battle_stars.test.js` (pre-existing, unmodified): 16/16
  pass — re-run to confirm `promoteToTierFloor`'s own ladder-arithmetic
  coverage is unaffected.
- `functions/_audit_rank_skip_toctou.test.js` (new, temporary): 3
  tests — **2 fail as designed** (the TOCTOU proof and the atomicity
  proof, both correctly reproducing their respective bug against
  current, unmodified code), **1 passes** (the sequential control).
- Full `functions/` suite (`node --test *.test.js`, includes the
  temporary file above): **317 total, 315 pass, exactly the 2
  deliberate audit failures fail** — confirms zero regression anywhere
  else and confirms the `require.cache` substitution technique did not
  leak into any other test file.
- No Dart test run was needed — the client-side files read
  (`rank_skip_service.dart`, `rank_skip_screen.dart`) make no Firestore
  writes of their own, so there was nothing Dart-side to prove with a
  new test; existing Dart suite left untouched by this audit.

### Production code modified

**None.** No `firestore.rules`, no `functions/rank_skip.js`, no
`functions/battle_stars.js`, no Dart source. This was audit-only, per
instruction.

### Recommended next phase (not started)

Two real bugs proven, both P2, both rooted in the same place —
`rankSkipExams/{uid}`'s read-modify-write not being atomic:
1. `startRankSkipExam`: convert to a transaction that reads
   `lockedUntil` *and* checks for an unexpired in-progress session
   inside the same transaction as its own write, closing both the
   TOCTOU race and the free-retry design gap in one fix.
2. `submitRankSkipExam`: keep the session (or its outcome) intact
   until `promoteToTierFloor` actually commits, so a downstream
   failure doesn't strand a genuinely-passed attempt.
Both would benefit from `rank_skip.js` growing the same
`options.firestore` injection seam `spend_coins.js`/`award_xp.js`
already have, so the fix's own regression tests don't need a
`require.cache` workaround. RISK-3's subscription backstop was not
touched by this audit and its scheduled-invocation checkpoint remains
a separate, unrelated pending item.

## Rank-Skip Fix Phase (2026-08-29, same day) — BOTH P2 bugs FIXED, NOT DEPLOYED

Both bugs from the audit above are now fixed in code, with permanent
regression coverage, per explicit user authorization for a scoped
code+test-only fix phase. **Neither `firestore.rules` (unchanged —
confirmed by `git status`/`git diff`, zero lines touched) nor any Cloud
Function was deployed — `firebase deploy` was never run.** Production
is running the OLD, still-vulnerable `rank_skip.js` until a human
explicitly ships a new Functions deploy.

### BUG #1 fix — `startRankSkipExam`/`submitRankSkipExam` made
transactional on `rankSkipExams/{uid}`

**File**: `functions/rank_skip.js`. Both handlers' logic was extracted
into testable functions (`startRankSkipExamFor`/`submitRankSkipExamFor`,
taking `options.firestore` — the same DI shape `spend_coins.js`'s
`spendCoinsFor`/`award_xp.js`'s `awardXpFor` already established in
this codebase), and the read-then-write on `rankSkipExams/{uid}` in
each is now wrapped in a single `firestore.runTransaction(...)` instead
of a plain, non-transactional `.get()`+`.set()` pair. Both handlers'
transactions operate on the SAME document, so Firestore's optimistic
concurrency control now genuinely serializes them: whichever commits
first wins outright, and the other is forced to retry against the
fresh post-commit state rather than blindly overwriting it. A second,
independent piece of the fix: `startRankSkipExamFor`'s write no longer
mentions `lockedUntil` at all (previously it explicitly re-asserted
`existing.lockedUntil || null` on every write, which was the literal
mechanism that clobbered a freshly-set cooldown) — a merge write that
never names a field leaves it exactly as it stood, removing the
clobbering vector at its source, independent of the transaction
wrapping it.

DI seam justification (per the task's explicit "do not add DI merely
for style" instruction): genuinely required — the regression test for
this fix needs to force two calls into a specific, deterministic
interleaving around a real `runTransaction` retry, which is only
possible if the test can hand both calls a shared Firestore double.
`rank_skip.js` previously had no way to receive one at all (`db()`
called `getFirestore()` unconditionally). Scoped narrowly: only
`options.firestore` (both functions) and `options.promoteToTierFloor`
(submit only, for BUG #2's own test needs below) were added — no other
refactor.

### BUG #2 fix — session no longer deleted before promotion

**File**: `functions/rank_skip.js`, `submitRankSkipExamFor`. The
grading transaction now only writes something when the attempt FAILS
(cooldown + session-delete, as before — still one atomic write, still
what BUG #1's fix needs, since it's the same transaction
`startRankSkipExamFor` conflicts against). **On a PASS, the session is
deliberately left untouched** — it is the durable record that this
exact attempt passed. `promoteToTierFloor` (the real one, unmodified —
called via the injected `promote` reference, defaulting to
`battleStars.promoteToTierFloor`) is then attempted; only once it has
actually committed does a **second**, separate transaction finally
clear the session, guarded by re-checking the session's own `sessionId`
still matches (so a finalize racing a brand-new exam the player already
started cannot delete the wrong one).

**Why this is safe under retry** (per the task's explicit "demonstrate
why the resulting state machine is safe, don't just move the delete"
instruction): grading is a pure function of `session.cardIds` +
the submitted `answers`, so re-submitting the same `sessionId` after a
transient promotion failure re-derives the identical `passed: true`
result deterministically and simply retries `promoteToTierFloor` —
which is where the real idempotency guarantee already lives (proven
in `battle_stars.js`: it only ever writes when the player's current
standing is still below the target tier's floor, so a second successful
call after a failed first one, or two overlapping successful calls,
both converge to exactly one promotion). **No second, independent
source of truth for rank was created** — `promoteToTierFloor` itself
was not touched, reimplemented, or duplicated; `rank_skip.js` only
calls it and reacts to its outcome.

**Deliberately not a single cross-document transaction** spanning both
`rankSkipExams/{uid}` and `users/{uid}` — that would require either
reimplementing `promoteToTierFloor`'s own transaction inline (ruled out
by the point above) or threading an external transaction handle into
`battle_stars.js` (a broader change to a file no bug was found in). Two
transactions plus `promoteToTierFloor`'s own pre-existing idempotency is
the smaller, already-proven-safe shape.

### Permanent regression coverage

`functions/rank_skip.test.js` — 8 new integration-level tests against
`startRankSkipExamFor`/`submitRankSkipExamFor` (using the shared
`functions/test_helpers/fake_firestore.js`, extended — see below — plus
a small local `fakePromote()` helper that stands in for
`battleStars.promoteToTierFloor` without touching real Firestore or
`battle_stars.js`'s own transaction machinery at all):
1. Ordinary successful exam — passes, promotes, session cleared.
2. Ordinary failed exam — fails, sets the 24h cooldown, a sequential
   retry is correctly rejected (`resource-exhausted`).
3. **BUG #1's proof** — a start racing a failing submit on the same uid
   never leaves a fresh exam coexisting with a freshly-established
   cooldown (forces the race via `FakeFirestore`'s `beforeCommit` hook,
   targeting the transaction whose write shape matches `startRankSkip
   ExamFor`'s specifically, so the proof doesn't depend on incidental
   scheduling order between two structurally different async chains).
   Plus (3b) a control: two genuinely different users racing their own
   exams never interfere with each other.
4. **BUG #2's proof** — a promotion failure after a genuine pass keeps
   the session retryable (does not delete it).
5. Retrying after a transient promotion failure succeeds and does not
   double-promote (both calls target the same `(uid, tier)`).
6. Concurrent submissions of the SAME passing session converge safely
   — no crash, no half-finalized state.
7. The target tier at promotion time always comes from the
   server-stored session — `submitRankSkipExamFor`'s own signature has
   no tier parameter at all for a client to abuse.
8. Authorization/eligibility invariants (unknown tier, non-skippable
   tier, tier not above current rank, unknown/forged sessionId) still
   hold through the new DI seam.

`functions/test_helpers/fake_firestore.js` — two small, additive
extensions, needed to make the above deterministic and NOT because of
any style preference:
- `FieldValue.delete()` handling in `applyWrite` (previously left the
  raw sentinel object sitting as the field's literal value instead of
  actually removing the key — `rank_skip.js`'s own `session:
  FieldValue.delete()` writes need this to be modeled correctly for a
  test to tell "deleted" from "present").
- `FakeCollectionRef.doc()` (no argument) and a new `FakeDocRef.id`
  getter — real Firestore auto-generates a random id for this call
  shape (`rank_skip.js`'s own `ref.collection("_").doc().id`, and
  `index.js`'s notification docs use the identical pattern); previously
  this silently produced the literal path segment `"undefined"` with no
  `.id` getter to read back at all.
- **Explicitly tried and reverted**: auto-coercing a written `Date`
  into a `Timestamp`-shim (`{toDate: () => date}`) on read-back, to
  match the real Admin SDK's own behavior — `rank_skip.js`'s
  `lockedUntil` field needed this at first. Reverted after it broke
  `subscription_backstop.test.js` (2 failures — that suite reads a
  stored date field back as a raw `Date` via `.toISOString()` directly,
  a real, pre-existing, legitimate dependency on the fake's current
  unwrapped behavior). **RISK-3 was not touched and must not
  regress** — instead, `rank_skip.js` itself gained a small, local
  `toJsDate()` helper that accepts either shape (a real Timestamp via
  `.toDate()`, or an already-plain `Date`), solving the same problem
  without touching shared test infrastructure any other suite depends
  on.

### Old reproduction → new reproduction (fail-then-pass, verified by
actually reverting each fix in place)

- **BUG #1**: temporarily reverted `startRankSkipExamFor` to its old
  plain-`.get()`/`.set()` shape (keeping the DI seam so the test could
  still run against it) and re-ran test (3). **It failed** — not at the
  exact assertion originally anticipated (the old code has no
  transaction at all, so the racing start's plain write simply executes
  unblocked and immediately overwrites the session, before the gate
  logic can even apply), but deterministically and for the same root
  cause: `submitRankSkipExamFor` itself threw `failed-precondition "No
  exam in progress."`, because by the time it ran, the racing start had
  already silently clobbered its session with no coordination
  whatsoever. This is arguably a MORE direct demonstration of the
  underlying flaw (zero coordination between the two calls, not merely
  a narrow timing window) than the originally-audited manifestation.
  Restored the fix; test (3) passed cleanly (24.2ms).
- **BUG #2**: temporarily reverted the grading transaction to delete
  the session unconditionally (pass or fail, matching the old
  behavior) before calling `promote`. Re-ran test (4) — **failed**,
  with the exact anticipated assertion: `finalDoc.session` was
  `undefined` after a simulated promotion failure, i.e. the session
  really was destroyed despite the attempt having genuinely passed.
  Also re-ran test (5) (retry) against the same revert — **failed**,
  with `submitRankSkipExamFor` throwing `failed-precondition "No exam
  in progress."` on the retry attempt, since the session it needed to
  re-grade against was already gone. Restored the fix; both tests
  passed cleanly.

### Test results

- `functions/rank_skip.test.js`: **15/15 pass** (7 pre-existing pure
  tests, unmodified + 8 new).
- `functions/battle_stars.test.js`: 16/16 pass, unaffected (re-run to
  confirm `promoteToTierFloor`'s own coverage untouched).
- Full `functions/` suite (`node --test *.test.js`): **323/323 pass**,
  zero regressions anywhere — includes the shared-fake extensions
  above, confirmed not to break any other file (this count is with the
  temporary audit file already removed, see below).
- `flutter analyze` (whole repo): **0 issues** (no Dart file touched by
  this phase).
- `flutter test --concurrency=1` (whole repo): **all pass**, zero
  regressions. Explicitly re-confirmed the suites named in the task
  instruction as their own targeted run before the full-repo run:
  `clan_reentrancy_test.dart` + `premium_purchase_reentrancy_test.dart`
  + `coin_buy_reentrancy_test.dart` + `cosmetic_equip_decision_test.dart`
  + `iap_test.dart` = **88/88 pass**.

### Temporary audit file — removed

`functions/_audit_rank_skip_toctou.test.js` (never committed) is
**deleted**. Its own fake infrastructure was built for the OLD
plain-`.get()`/`.set()` shape and is structurally incompatible with the
new `runTransaction`-based code (it has no `runTransaction` support at
all) — its coverage is fully superseded by `rank_skip.test.js`'s new
tests (3) and (4) above, which cover the same two findings plus six
more scenarios the audit-only phase never had permanent coverage for.

### Files changed

- `functions/rank_skip.js` — both bugs' fixes, DI seam.
- `functions/rank_skip.test.js` — 8 new permanent tests.
- `functions/test_helpers/fake_firestore.js` — `FieldValue.delete()`
  handling, auto-id `.doc()`/`.id` support (both additive, confirmed
  via the full suite that nothing else regressed).
- Deleted (never committed): `functions/_audit_rank_skip_toctou.test.js`.
- No `firestore.rules`, no other Cloud Function, no Dart source.

### Deployment status — explicit, do not skim past this

- **`functions/rank_skip.js`**: **NOT DEPLOYED.** The live project is
  still running the vulnerable version from before this fix phase.
  Both P2 bugs (the cooldown-wipe race and the promotion-failure
  session loss) **remain live in production** until a human runs
  `firebase deploy --only functions:startRankSkipExam,functions:
  submitRankSkipExam` (or a broader Functions deploy) with explicit
  authorization.
- **Production verification = NOT DONE**, and cannot be, until that
  deploy actually ships — this phase was code + test only, no
  `firebase deploy`, no Play Console action, no production Firestore
  write, per the explicit task constraint.
- **`firestore.rules` is unchanged** — confirmed via `git diff
  firestore.rules` showing zero lines touched throughout this phase, as
  required.

### Remaining UNKNOWN

None identified specific to these two bugs' fixes — both are proven
fail-then-pass against a deterministic reproduction, and the resulting
state machine's safety under every traced interleaving (same-uid race,
cross-user race, promotion failure + retry, concurrent same-session
submission) was reasoned through explicitly, not assumed. The one
genuinely open, previously-flagged design question — whether
`startRankSkipExamFor` should also reject starting over an *unexpired,
still-in-progress* session (not just a `lockedUntil` cooldown) — was
**not** addressed in this phase, matching its scope (only the two
proven bugs); it remains recorded in the audit section above as a
related-but-separate design gap, not silently closed by this fix.

## Core Clan Mechanics Audit (2026-08-28) — AUDIT ONLY, 2 new bugs found

Read-only, end-to-end audit of all 13 core Clan mutation paths (create/
join/leave/kick/promote/demote/invite/accept/decline/disband/icon-
description/capacity/creation-quota), tracing UI → repository →
Firestore writes → `firestore.rules` enforcement for each. No source or
rules changed — both findings below are reported, not fixed, per
explicit instruction. **No new numbered RISK assigned by this session**
— left for the user to decide when a fix phase is scheduled.

### Confirmed SAFE / PROVEN SAFE (7 of 13)

- **Leave Clan** / **Kick Member** (the mechanism itself) — RISK-9's
  transactional fix re-confirmed still holding: `test/
  clan_reentrancy_test.dart` re-run fresh, **8/8 PASS**, unchanged.
- **Decline Invite** — plain idempotent `.set(merge:true)` on the
  learner's own invite doc.
- **Disband Clan** — leader-only via `clans/{code}`'s `hostUid ==
  auth.uid` check on `allow delete`; the bulk member-row deletes go
  through the same `canKick` path kick already uses, correctly, and
  disband is **not** reachable via the role-escalation bug below (that
  only ever grants kick/announcement powers, never `hostUid`).
- **Clan icon/description changes** — plain idempotent merge-set,
  covered by the pre-existing host-only `clans/{code}` update rule, no
  capacity/atomicity concern.
- **Clan creation quota (`clanFreeSlotUsed`)** — reasoned through (not
  independently proof-tested, given the scope already covered): two
  concurrent `createClan` calls by the same host can't both consume the
  free slot, because `clanFreeSlotUsed/{uid}` only ever permits `create`
  (never `update`) in `firestore.rules` — the second concurrent batch's
  write to that doc is evaluated as an `update` once the first has
  committed, gets denied, and the WHOLE second batch fails atomically
  (Firestore batches are all-or-nothing) rather than silently granting
  a second free clan. **Noted P3 UX gap, not a security bug**: a
  legitimate double-tap during a slow network could surface as a
  confusing permission-denied error instead of either succeeding
  cleanly or being absorbed as a no-op.
- **Ad-reward/coin/level gating for clan creation** (`canCreateClan`) —
  traced against `hasActiveClanAdReward`/`isPremiumUser`, matches the
  Dart-side `CreateClanDialog` gating design intent; server-side is the
  real gate, client is a UX head-start only, same established pattern
  as every other premium-gated feature in this app.

### BUG #1 — `joinClan` memberCount double-increment (P1, PROVEN BY TEST)

**File/function**: `lib/data/repositories/clan_repository.dart`,
`ClanRepository.joinClan` (lines ~153-191).

**Root cause**: unlike `kickMember`/`leaveClan` (fixed in RISK-9),
`joinClan` was never converted to a transaction — it's still a plain
`.get()` existence-check followed by an unconditional `batch.update({
'memberCount': FieldValue.increment(1)})`. Two concurrent calls for the
SAME `(code, uid)` pair (a realistic double-tap, or a client retry after
a network timeout) each independently read "not yet a member" before
either commits, and each add `+1` — corrupting `memberCount` by `+1` for
what is really a single join. This is the exact bug class RISK-8
originally flagged as a *latent* concern and RISK-9 explicitly left
unfixed (out of that phase's 3-bug scope) — **this audit proves it is
real, not just latent.**

**Proof**: temporary test `test/_audit_clan_mechanics_test.dart` (NOT
committed — kept `_audit_`-prefixed pending a fix phase), a Completer-
gated fake `FirebaseFirestore`/`WriteBatch` forcing the SAME real
interleaving pattern already proven for the RISK-9 fixes. Result:
**memberCount ends up 3 instead of the correct 2** (seed 1 + one real
join) after two concurrent same-uid joins — deterministic, reproduced,
not inferred.

**Affected paths**: both known callers inherit this —
`JoinClanDialog._join` (has its own `_joining` client guard, so not
currently exploitable through the *official* app UI alone) and
`respondToInvite`'s accept branch (reuses `joinClan` internally,
guarded client-side by `_InviteRow`'s `_responding` flag) — same
"client guard is the only protection, no server-side defense-in-depth"
shape RISK-8/9 already closed for kick/leave. A future caller, a
modified client, or a client-guard regression would reopen this
immediately.

**Recommended minimal fix (not applied)**: convert `joinClan` to
`runTransaction`, mirroring `kickMember`'s/`leaveClan`'s exact RISK-9
shape — read the member doc inside the transaction, only set + increment
if it doesn't already exist.

**Required regression tests**: a permanent version of the temporary
proof above (two concurrent same-uid `joinClan` calls → `memberCount`
increments exactly once), plus a defect-injection check (revert the fix,
confirm the test fails again) matching this project's own established
discipline for every other RISK-9 fix.

### BUG #2 — Clan role escalation via unvalidated `role` value (P1, PROVEN AGAINST THE REAL RULES ENGINE)

**File/function**: `firestore.rules`, the `clans/{code}/members/
{memberUid}` `allow update` rule (~line 303-306) and `actorRole()`
(~line 555-562).

**Root cause**: the rule that lets a leader change another member's
`role` (`request.auth.uid != memberUid && actorRole(code, request.auth
.uid) == 'leader' && request.resource.data.diff(resource.data)
.affectedKeys().hasOnly(['role'])`) validates *which key* changed, but
**never validates what value `role` is being set to.** Meanwhile
`actorRole()` — the function every leader-gated rule in this file
depends on (`canKick`, `announcements.create`, this same update rule) —
reads the roster row's *stored* `role` field first, falling back to a
`hostUid` comparison only when `role` is absent. Combined: a genuine
leader can write `role: 'leader'` onto ANY other member's own roster
row, and from that point on `actorRole()` treats that member as a
second, fully-privileged leader — even though `Clan.hostUid` (the only
value the app's own Dart-side documentation claims determines
leadership — `ClanRepository`'s class doc comment: *"The leader role
itself is never granted or removed this way; it's fixed to
Clan.hostUid... no host-transfer feature"*) never changed. This directly
contradicts that documented invariant — the client (Dart `assert(role !=
ClanRole.leader, ...)` in `setMemberRole`) is a **debug-only** guard,
stripped entirely from release builds, and was never backed by an
equivalent server-side check.

**Proof**: temporary test `firestore_rules_tests/_audit_clan_escalation
.test.js` (NOT committed), run against the **real Firestore Rules CEL
engine** via the emulator (not source-inspection) — 2/2 `assertSucceeds`
confirmed:
1. A genuine leader can `updateDoc` another member's roster row with
   `{role: 'leader'}` — succeeds, no rule rejects it.
2. That now-fraudulent "leader" can then `deleteDoc` the REAL leader's
   own roster row (`canKick`'s `actor == 'leader' && actorUid !=
   targetUid` branch) — **succeeds**, kicking the actual clan owner out
   of their own clan's member list.

**Blast radius, precisely bounded**: this requires an already-genuine
leader to initiate (not "any authenticated user can become leader") —
and even a fully "escalated" fraudulent leader still **cannot** disband
the clan, rename it, or pass the `clans/{code}` update rule's `hostUid`
branch (those check `resource.data.hostUid` directly, not `actorRole`).
The real damage: kicking the genuine owner out of the roster (after
which the real owner's own `actorRole()` lookup fails — their roster row
is gone — locking them out of every leader-gated action except disband,
since disband alone checks `hostUid` independently), granting further
fraudulent 'leader' roles to others, and posting announcements as a
fake leader.

**Recommended minimal fix (not applied)**: add a value check to the
`members/{memberUid}` update rule — e.g. `&& request.resource.data.role
in ['member', 'coLeader']` — so a leader can only ever set the two
non-leader role values through this path, matching the "leadership is
not reassignable" invariant the Dart code already assumes but never
enforced.

**Required regression tests**: a permanent version of both temporary
rules-emulator tests above (leader cannot write `role: 'leader'` onto
another member's row; a legitimate promote-to-coLeader/demote-to-member
still succeeds unaffected).

### TEST GAP (2 of 13, both already known/unfixed, not newly discovered)

- **Invite Member (`sendInvite`)** — server never dedupes "already
  invited" (only "already a member"); a fast double-tap can still create
  two invite documents server-side even though the client-side guard
  added in RISK-9 (`_invitingUids`) closes the *practical* exploit
  through the official UI. Unchanged since RISK-8/9 — not re-proven this
  session, carried forward as still-open.
- **Accept Invite (`respondToInvite`, accept branch)** — inherits BUG
  #1 above (it calls `joinClan` internally). Separately: if `joinClan`
  succeeds but the follow-up invite-status `.set(merge:true)` fails, the
  invite stays `pending` while the learner is already a member — not
  independently proof-tested this session (time-boxed out of this
  audit's scope), recorded as a genuine open question rather than
  asserted safe or unsafe.

### INFO — Clan capacity does not exist as a feature

Grepped the entire `lib/` tree and every rule in `firestore.rules` for
`maxMember`/`capacity`/member-count-limit language — **none found,
anywhere, client or server.** There is no maximum clan size in this
app today. Not a bug (this audit does not invent a policy the product
never specified) — recorded here so a future "why did a clan reach N
members" question isn't mistaken for a missed enforcement bug.

### Re-checked per explicit instruction (Section J)

- **`ClanRepository.joinClan`**, previously a RISK-8 *latent* concern —
  **no longer latent, proven exploitable this session (BUG #1 above).**
- **`kickMember`/`leaveClan`** (RISK-9 fixes) — **re-confirmed still
  correct**, `clan_reentrancy_test.dart` re-run fresh, 8/8 PASS, no
  regression.
- **Invite/friend-request reentrancy** (RISK-9 fixes) — not independently
  re-tested this session (unchanged source, no reason to suspect
  regression); the client-side guards are the same ones RISK-9 proved
  and this audit did not touch.

### Temporary audit files (kept, not committed, per instruction)

- `test/_audit_clan_mechanics_test.dart` — joinClan double-increment
  proof.
- `firestore_rules_tests/_audit_clan_escalation.test.js` — role-
  escalation proof, against the real emulator.

Both remain `_audit_`-prefixed and unstaged. Recommended: keep them
until a fix phase is scheduled, since they're the exact reproduction a
fix would need to flip from FAIL to PASS (matching this project's own
"prove don't assume" discipline for every fix in this engagement so
far).

### Recommended next phase

Two real, proven bugs are now sitting ready for a scoped fix phase,
whenever the user schedules one:
1. `joinClan` → transaction (mirrors the exact RISK-9 shape already
   proven for kick/leave).
2. `firestore.rules`' `members/{memberUid}` update rule → restrict
   `role`'s value, matching the "leadership is not reassignable"
   invariant the Dart code already assumes.
Both are small, well-understood, minimal fixes with reproduction tests
already written and proven to fail on current code — a fix phase for
either would not need to re-derive root cause from scratch.

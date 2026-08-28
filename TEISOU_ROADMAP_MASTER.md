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
| RISK-1 | Cosmetic equip reentrancy (avatar/frame/card-skin double-tap) | ✅ DONE |
| RISK-2 | (see git history — completed before this file existed) | ✅ DONE |
| RISK-3 | (see git history — completed before this file existed) | ✅ DONE |
| RISK-4 | Premium purchase (IAP) reentrancy | ✅ DONE |
| RISK-5 | Coin-purchase reentrancy (Avatar/Frame/Cover pickers) + `spend_coins.js` DI seam | ✅ DONE |
| RISK-6 | Cross-function race audit (spendCoins vs claimXpReward vs verifyPurchase) | ✅ DONE (audit-only, no bug found) |
| RISK-7 | Global error handling (`main.dart` boundary + `fcm_service.dart` listeners) | ✅ DONE |
| RISK-8 | Global async-action/reentrancy audit (app-wide inventory) | ✅ DONE |
| RISK-9 | Fix RISK-8's 3 confirmed bugs (clan kick/leave/invite/friend-request reentrancy) | ✅ DONE |

## RISK-1 through RISK-3 (pre-dates this file)

Completed in earlier sessions. RISK-1 (cosmetic equip double-tap guard)
is directly referenced by this file's own RISK-8/RISK-9 entries as an
already-proven-safe baseline pattern (`f9e1078`). RISK-2 and RISK-3's
exact scope is not re-derived here — see `git log` around the same
period (commits `f9e1078` through `cb3fcf1`, cosmetic-equip/leaderboard-
sync fixes) for the actual diffs. Not re-audited as part of RISK-8/9
per explicit instruction not to re-touch an already-verified baseline
without new regression evidence.

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

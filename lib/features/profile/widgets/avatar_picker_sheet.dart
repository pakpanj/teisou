import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/avatars.dart';
import '../../../core/constants/frames.dart';
import '../../../core/providers.dart';
import '../../../core/services/coin_spend_service.dart';
import '../identity_sync.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/purchase_success_snackbar.dart';
import '../../../data/models/app_language.dart';
import '../../../data/models/unlocked_cosmetics.dart';
import '../../../data/models/user_profile.dart';
import '../../paywall/paywall_screen.dart';

/// Bottom sheet for picking a profile avatar: Google photo, free presets,
/// and premium presets (locked behind [PaywallScreen] for free users).
///
/// There is deliberately no gallery-upload option. It existed once and was
/// removed: the app has a public global leaderboard and no moderation tools
/// or admin surface, so an arbitrary user-supplied image had no path to
/// being reviewed or taken down. Every avatar a user can now choose is
/// bundled art. Don't reintroduce picking from the device without a
/// moderation story to go with it.
class AvatarPickerSheet extends ConsumerStatefulWidget {
  const AvatarPickerSheet({super.key});

  @override
  ConsumerState<AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

/// The `moduleId` watching an ad on [PaywallScreen] grants a one-time
/// unlock for — the premium-presets grid below, matching the "Avatar
/// Premium" offer on that screen.
const _avatarPremiumModuleId = 'avatar_premium';

/// Same idea as [_avatarPremiumModuleId], scoped to [FramePresets.lockedIds]
/// instead — a separate module id so watching an ad for one never spends
/// the other's unlock.
const _framePremiumModuleId = 'frame_premium';

enum _PickerMode { avatar, frame }

/// The sheet itself is now just chrome (drag handle + the Avatar/Bingkai
/// tab switch) around [AvatarPickerBody]/[FramePickerBody] — both are also
/// used standalone, without this wrapper, inside the Toko tab's own
/// "Avatar"/"Bingkai" sub-tabs. Splitting it this way means the picking
/// logic (ad-reward unlocks, the actual save) lives in exactly one place
/// either way, instead of the sheet and the shop screen slowly drifting
/// into two slightly different copies of the same grid.
class _AvatarPickerSheetState extends ConsumerState<AvatarPickerSheet> {
  _PickerMode _mode = _PickerMode.avatar;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.palette.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.palette.textNavy.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _PickerModeTab(
                    label: s.pickAvatarTitle,
                    active: _mode == _PickerMode.avatar,
                    onTap: () => setState(() => _mode = _PickerMode.avatar),
                  ),
                  const SizedBox(width: 20),
                  _PickerModeTab(
                    label: s.pickFrameTitle,
                    active: _mode == _PickerMode.frame,
                    onTap: () => setState(() => _mode = _PickerMode.frame),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_mode == _PickerMode.avatar)
                const AvatarPickerBody()
              else
                const FramePickerBody(),
            ],
          ),
        );
      },
    );
  }
}

/// Whether an unspent ad-reward unlock for [_avatarPremiumModuleId]
/// exists is read live from `unlockedCosmeticsProvider` (see that
/// provider's own doc comment) inside `build()` below — originally this
/// was a one-shot fetch (`ProgressRepository.getAdRewards`) cached in a
/// `State` field, refreshed only in `initState` and again right after
/// `PaywallScreen` returned. That version fixed a real earlier bug
/// (`getAdRewards` existed with no reader anywhere, so watching the
/// rewarded ad recorded the unlock but nothing ever consulted it — the
/// tile just reopened the paywall again) but introduced a different one:
/// an already-mounted instance of this widget (Toko's own copy is kept
/// alive for the app's whole session, see `HomeScreen`'s
/// `_KeepAlivePage`) never refreshed again once mounted, so a level-up
/// reward granted through Home's "Klaim hadiah" button — a different
/// screen entirely — left Toko showing that same item as locked for the
/// rest of the session (BUG-1, AUDIT_COSMETIC_PROFILE_SHOP.md). Watching
/// the provider instead closes both gaps at once: no picker-specific
/// refresh call is needed anywhere, on mount or on return from anything,
/// because every consumer just sees Firestore's current state directly.
/// One ad still grants exactly one avatar change: picking a premium
/// preset calls `ProgressRepository.consumeAdReward` right after
/// succeeding, rather than leaving it active for its full 24h backstop
/// window.
///
/// The grid of Google photo / free presets / premium presets, shared by
/// [AvatarPickerSheet] (as its "Avatar" tab) and the Toko screen's own
/// "Avatar" tab. [popOnSelect] is true inside the sheet (picking closes
/// it, the sheet's whole reason to exist) and false inside Toko (picking
/// there should just update the selection in place, the same way tapping
/// a different card skin in the shop doesn't close the shop).
class AvatarPickerBody extends ConsumerStatefulWidget {
  final bool popOnSelect;

  /// True only inside the Toko tab. **Buying happens in Toko, not in
  /// Profile** — the profile sheet only ever shows what's already owned
  /// (no locked/"Belum Dimiliki" section at all, per explicit product
  /// decision), so every preset still to unlock — ad, coin, or Premium —
  /// lives here instead, where a learner can actually do something about
  /// it. A preset appears in Profile the moment it's been unlocked here,
  /// never before.
  final bool shopMode;

  const AvatarPickerBody({
    super.key,
    this.popOnSelect = true,
    this.shopMode = false,
  });

  @override
  ConsumerState<AvatarPickerBody> createState() => _AvatarPickerBodyState();
}

class _AvatarPickerBodyState extends ConsumerState<AvatarPickerBody> {
  /// Reentrancy guard for [_select] — RISK-1 (AUDIT_COSMETIC_PROFILE_SHOP.md).
  /// A free/already-unlocked tile equips with no intervening dialog or
  /// route push, so nothing else stops a second tap from reaching the same
  /// `InkWell` again before the first `_select` call's Firestore write
  /// resolves: proven in `test/cosmetic_equip_decision_test.dart`'s
  /// "RISK-1" group (`updateAvatar` fired twice from one realistic
  /// double-tap, even with zero frames between the two taps). Same shape
  /// as `CardSkinPickerBody._saving` — the entire grid absorbs pointer
  /// events while an equip write is in flight, so a second tap on any
  /// tile is simply ignored until the first one finishes.
  ///
  /// **Still deliberately does not guard [_openPaywall]** — same file's
  /// own RISK-1 tests double-tapped a locked premium-only tile the same
  /// way and found it never stacks a second route: the paywall's own
  /// full-screen route push already makes the grid tile beneath it
  /// un-tappable the instant it appears, with no gap for a second tap to
  /// land in. [_buyWithCoins] no longer shares that exemption — see
  /// [_buyingWithCoins]'s own doc comment for why (RISK-5).
  bool _saving = false;

  /// RISK-5: reentrancy guard for [_buyWithCoins], same shape as
  /// `ShopTab._buyingWithCoins`. The confirm dialog's own modal barrier
  /// only closes the *first* gap (a second tap can't reach the tile while
  /// the dialog is showing) — it says nothing about the window right
  /// after the dialog closes, while `CoinSpendService.buy()` is still
  /// in-flight and the tile is still un-owned as far as Firestore's
  /// snapshot has reported. Proven exploitable in
  /// `test/coin_buy_reentrancy_test.dart`: tap -> confirm -> tap the same
  /// tile again before `buy()` resolves opened a SECOND confirm dialog
  /// and, once confirmed, fired a second concurrent `buy()` call.
  /// `spend_coins.js`'s own transaction is idempotent against this (RISK-5
  /// audit, PROVEN BY TEST server-side), so this was never a double-charge
  /// risk — but two wasted Cloud Function calls and two stacked dialogs
  /// is still worth closing at the source. Set **before** `showDialog`
  /// opens, not just around the `CoinSpendService.buy()` call, so the
  /// entire range (tap -> dialog -> confirm -> buy() settling) is closed,
  /// not just the async tail of it.
  bool _buyingWithCoins = false;

  Future<void> _select(
    String uid,
    AvatarType type,
    String? value, {
    required String displayName,
    String? photoUrl,
    bool consumeReward = false,
  }) async {
    setState(() => _saving = true);
    try {
      try {
        // The source of truth, and the only write whose failure means the
        // avatar did not change. The mirrors below used to sit inside this
        // try, so a leaderboard hiccup reported "avatar save failed" for an
        // avatar that had in fact saved — and returned early, skipping the
        // clan sync too.
        await ref
            .read(progressRepositoryProvider)
            .updateAvatar(uid, type, value);
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(appStringsProvider).avatarSaveFailed),
          ),
        );
        return;
      }
      // Every denormalized copy — leaderboard, clan rosters, friends — each
      // best-effort and independent of the others.
      await syncIdentityEverywhere(
        ref,
        uid: uid,
        displayName: displayName,
        photoUrl: photoUrl,
        avatarType: type,
        avatarValue: value,
      );
      if (consumeReward) {
        // Best-effort only — the avatar itself already saved successfully
        // above, so a hiccup here must not surface as a failure.
        try {
          await ref
              .read(progressRepositoryProvider)
              .consumeAdReward(uid, _avatarPremiumModuleId);
        } catch (_) {}
      }
      if (!mounted) return;
      if (widget.popOnSelect) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openPaywall(
    BuildContext context, {
    required bool showAdOption,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaywallScreen(
          moduleId: _avatarPremiumModuleId,
          moduleTitle: 'Avatar Premium',
          singleUse: true,
          showAdOption: showAdOption,
        ),
      ),
    );
    // No manual refresh needed on return: `unlockedCosmeticsProvider`
    // (watched in `build()` below) live-streams `adRewards` off the same
    // document the SSV-verified ad-reward grant writes to, so the grid
    // updates on its own the moment Firestore does — before this even had
    // a one-shot re-fetch to do it, that re-fetch was also the only thing
    // keeping this picker's ad-reward status from going stale the moment
    // it stayed mounted (see BUG-1, AUDIT_COSMETIC_PROFILE_SHOP.md).
  }

  /// The coin-tier path — see `AvatarPresets.coinIds`'s own doc comment
  /// for the three-way split this is one third of. A confirmation first,
  /// since spending real money's worth of coins on the wrong tile by a
  /// stray tap is a worse failure than one extra dialog.
  Future<void> _buyWithCoins(BuildContext context, AvatarPreset preset) async {
    if (_buyingWithCoins) return;
    setState(() => _buyingWithCoins = true);
    try {
      final s = ref.read(appStringsProvider);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(s.coinBuyConfirmTitle),
          content: Text(s.coinBuyConfirmBody(AvatarPresets.coinPrice)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(s.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(s.coinBuyConfirmButton),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
      try {
        await ref
            .read(coinSpendServiceProvider)
            .buy(CoinSpendKind.avatar, preset.id);
        if (!mounted) return;
        // No local optimistic set update needed: `unlockedCosmeticsProvider`
        // watches the exact `xp.unlockedAvatarIds` field this purchase just
        // wrote, so the grid unlocks the tile on its own once Firestore's
        // snapshot listener reports it — normally within the same frame or
        // two, since the callable above only resolves after its own
        // Firestore transaction has already committed. Keeping ownership in
        // exactly one place (the provider) avoids a second, hand-maintained
        // copy that could drift from it.
        if (!context.mounted) return;
        showPurchaseSuccessSnackBar(context, message: s.coinBuySuccess);
      } on CoinSpendException catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.notEnoughCoins ? s.coinBuyNotEnough : s.coinBuyFailed,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _buyingWithCoins = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appStartupProvider).valueOrNull;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final isPremium =
        ref.watch(subscriptionProvider).valueOrNull?.isPremium ?? false;
    // Live, not a one-shot fetch cached in State — see
    // `unlockedCosmeticsProvider`'s own doc comment (BUG-1,
    // AUDIT_COSMETIC_PROFILE_SHOP.md) for why this matters specifically
    // for this picker's Toko copy, which stays mounted for the whole app
    // session.
    final unlocked =
        ref.watch(unlockedCosmeticsProvider).valueOrNull ??
        UnlockedCosmetics.empty;
    // Three tiers, three different answers to "is this unlocked":
    // subscribing unlocks everything regardless of tier; a permanent
    // unlock (level-reward or coin-bought — both land in the same
    // `xp.unlockedAvatarIds` set) unlocks that one id forever; the ad
    // reward only ever counts for an ad-tier id, never a coin- or
    // premium-only one — see `AvatarPresets.isAdUnlockable`'s doc
    // comment for why an ad must not silently unlock either of those.
    bool avatarIdUnlocked(String id) {
      if (isPremium) return true;
      if (unlocked.avatarIds.contains(id)) return true;
      return AvatarPresets.isAdUnlockable(id) &&
          unlocked.isAdRewardActive(_avatarPremiumModuleId);
    }

    final uid = user?.uid;
    final s = ref.watch(appStringsProvider);
    final displayName =
        profile?.resolveDisplayName(user) ??
        (user?.displayName ?? s.defaultLearnerName);

    // Free presets are always unlocked; a premium one is locked unless it's
    // been earned/bought or the account is Premium — see
    // `avatarIdUnlocked`'s own doc comment above for the three-tier logic.
    bool isLocked(AvatarPreset preset) =>
        preset.premium && !avatarIdUnlocked(preset.id);

    // One combined list, split by ownership rather than by free/premium —
    // per explicit request, so a learner sees what they already have
    // separately from what's still to unlock, instead of a "Preset
    // Gratis"/"Preset Premium" split that mixed owned and locked tiles
    // together inside "Premium". The full catalog either way — which of
    // owned/notOwned actually gets *rendered* is what differs between
    // Profile and Toko, see the `notOwned` section below.
    final allPresets = [...AvatarPresets.free, ...AvatarPresets.premium];
    final owned = allPresets.where((p) => !isLocked(p)).toList();
    final notOwned = allPresets.where(isLocked).toList();

    bool isSelected(AvatarPreset preset) {
      final type = preset.premium
          ? AvatarType.presetPremium
          : AvatarType.presetFree;
      return profile?.avatarType == type && profile?.avatarValue == preset.id;
    }

    void handleTap(AvatarPreset preset) {
      final id = preset.id;
      if (!isLocked(preset)) {
        if (uid == null) return;
        // Only an ad-tier id newly unlocked by the still-active reward
        // should ever consume it — a coin-bought or premium-unlocked id
        // must not accidentally burn an unrelated ad reward sitting
        // active for a different tile.
        final consumeReward =
            preset.premium &&
            !isPremium &&
            AvatarPresets.isAdUnlockable(id) &&
            unlocked.isAdRewardActive(_avatarPremiumModuleId) &&
            !unlocked.avatarIds.contains(id);
        _select(
          uid,
          preset.premium ? AvatarType.presetPremium : AvatarType.presetFree,
          id,
          displayName: displayName,
          photoUrl: user?.photoURL,
          consumeReward: consumeReward,
        );
        return;
      }
      if (AvatarPresets.isCoinUnlockable(id)) {
        _buyWithCoins(context, preset);
        return;
      }
      _openPaywall(context, showAdOption: AvatarPresets.isAdUnlockable(id));
    }

    // RISK-1/RISK-5: absorbs every tap on this grid while `_select`'s
    // write OR a coin purchase (`_buyWithCoins`) is in flight — see
    // `_saving`'s/`_buyingWithCoins`'s own doc comments above for what
    // each guards against.
    return AbsorbPointer(
      absorbing: _saving || _buyingWithCoins,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (user != null && !user.isAnonymous && user.photoURL != null) ...[
            PickerSectionTitle(s.accountPhotoSection),
            _GoogleAvatarTile(
              photoUrl: user.photoURL!,
              label: s.googleAccountPhotoLabel,
              selected:
                  profile != null && profile.avatarType == AvatarType.google,
              onTap: uid == null
                  ? null
                  : () => _select(
                      uid,
                      AvatarType.google,
                      null,
                      displayName: displayName,
                      photoUrl: user.photoURL,
                    ),
            ),
          ],
          PickerSectionTitle(s.ownedSectionTitle),
          _PresetGrid(
            presets: owned,
            language: s.language,
            isSelected: isSelected,
            locked: (_) => false,
            onTap: handleTap,
          ),
          // Locked presets only ever show up in Toko — see [shopMode]'s own
          // doc comment. The Profile sheet stops here, at the owned grid.
          if (widget.shopMode && notOwned.isNotEmpty) ...[
            PickerSectionTitle(s.notOwnedSectionTitle),
            _PresetGrid(
              presets: notOwned,
              language: s.language,
              isSelected: isSelected,
              locked: (_) => true,
              coinPriceFor: (preset) =>
                  AvatarPresets.isCoinUnlockable(preset.id)
                  ? AvatarPresets.coinPrice
                  : null,
              onTap: handleTap,
            ),
          ],
        ],
      ),
    );
  }
}

/// The frame grid, shared the same way [AvatarPickerBody] is — see its doc
/// comment for the split's reasoning and [popOnSelect].
class FramePickerBody extends ConsumerStatefulWidget {
  final bool popOnSelect;

  /// See [AvatarPickerBody.shopMode] — same "buying happens in Toko"
  /// split, applied to [FramePresets.all] instead.
  final bool shopMode;

  const FramePickerBody({
    super.key,
    this.popOnSelect = true,
    this.shopMode = false,
  });

  @override
  ConsumerState<FramePickerBody> createState() => _FramePickerBodyState();
}

class _FramePickerBodyState extends ConsumerState<FramePickerBody> {
  /// Reentrancy guard for [_selectFrame] — see `_AvatarPickerBodyState
  /// ._saving`'s doc comment for the full reasoning (RISK-1,
  /// AUDIT_COSMETIC_PROFILE_SHOP.md): same double-tap risk, same fix. Still
  /// deliberately does not guard [_openFramePaywall] — see
  /// `_AvatarPickerBodyState._saving`'s doc comment for why. [_buyWithCoins]
  /// no longer shares that exemption — see [_buyingWithCoins].
  bool _saving = false;

  /// RISK-5: see `_AvatarPickerBodyState._buyingWithCoins`'s doc comment
  /// for the full reasoning — same gap, same fix, applied to frames.
  bool _buyingWithCoins = false;

  Future<void> _selectFrame(
    String uid,
    String? frameId, {
    bool consumeReward = false,
  }) async {
    setState(() => _saving = true);
    try {
      try {
        await ref.read(progressRepositoryProvider).updateFrame(uid, frameId);
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(appStringsProvider).frameSaveFailed),
          ),
        );
        return;
      }
      // Best-effort — the frame itself already saved successfully above, so
      // a hiccup publishing it to the leaderboard must not surface as a
      // failure. Lets other learners see the same frame everywhere
      // LeaderboardAvatar renders this account (leaderboard rows, clan
      // roster, public profile), not just on this account's own device.
      try {
        await ref
            .read(leaderboardRepositoryProvider)
            .updateFrameId(uid, frameId);
      } catch (_) {}
      if (consumeReward) {
        // Best-effort only — the frame itself already saved successfully
        // above, so a hiccup here must not surface as a failure.
        try {
          await ref
              .read(progressRepositoryProvider)
              .consumeAdReward(uid, _framePremiumModuleId);
        } catch (_) {}
      }
      if (!mounted) return;
      if (widget.popOnSelect) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openFramePaywall(
    BuildContext context, {
    required bool showAdOption,
  }) async {
    final s = ref.read(appStringsProvider);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaywallScreen(
          moduleId: _framePremiumModuleId,
          moduleTitle: s.framePremiumTitle,
          singleUse: true,
          showAdOption: showAdOption,
        ),
      ),
    );
    // No manual refresh needed on return — see `AvatarPickerBody
    // ._openPaywall`'s identical note; `unlockedCosmeticsProvider`
    // (watched in `build()` below) live-streams `adRewards` off the same
    // document the SSV-verified grant writes to.
  }

  /// The coin-tier path — see `AvatarPickerBody._buyWithCoins`, which
  /// this mirrors exactly for frames.
  Future<void> _buyWithCoins(BuildContext context, String frameId) async {
    if (_buyingWithCoins) return;
    setState(() => _buyingWithCoins = true);
    try {
      final s = ref.read(appStringsProvider);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(s.coinBuyConfirmTitle),
          content: Text(s.coinBuyConfirmBody(FramePresets.coinPrice)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(s.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(s.coinBuyConfirmButton),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
      try {
        await ref
            .read(coinSpendServiceProvider)
            .buy(CoinSpendKind.frame, frameId);
        if (!mounted) return;
        // No local optimistic set update needed — see `AvatarPickerBody
        // ._buyWithCoins`'s identical note; `unlockedCosmeticsProvider`
        // watches the exact `xp.unlockedFrameIds` field this write lands in.
        if (!context.mounted) return;
        showPurchaseSuccessSnackBar(context, message: s.coinBuySuccess);
      } on CoinSpendException catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.notEnoughCoins ? s.coinBuyNotEnough : s.coinBuyFailed,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _buyingWithCoins = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appStartupProvider).valueOrNull;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final isPremium =
        ref.watch(subscriptionProvider).valueOrNull?.isPremium ?? false;
    final uid = user?.uid;
    final s = ref.watch(appStringsProvider);

    // Live, not a one-shot fetch — see `unlockedCosmeticsProvider`'s own
    // doc comment (BUG-1, AUDIT_COSMETIC_PROFILE_SHOP.md).
    final unlocked =
        ref.watch(unlockedCosmeticsProvider).valueOrNull ??
        UnlockedCosmetics.empty;

    // Same three-tier reasoning as `_AvatarPickerBodyState
    // .avatarIdUnlocked` — see its doc comment.
    bool frameIdUnlocked(String id) {
      if (isPremium) return true;
      if (unlocked.frameIds.contains(id)) return true;
      return FramePresets.isAdUnlockable(id) &&
          unlocked.isAdRewardActive(_framePremiumModuleId);
    }

    // Same owned-vs-not split as `AvatarPickerBody`'s — see its doc
    // comment above `isLocked`.
    bool isLocked(FramePreset f) =>
        FramePresets.isLocked(f.id) && !frameIdUnlocked(f.id);
    final owned = FramePresets.all.where((f) => !isLocked(f)).toList();
    final notOwned = FramePresets.all.where(isLocked).toList();

    void handleTap(String frameId) {
      if (uid == null) return;
      // A free frame (`!FramePresets.isLocked(frameId)`) must always be
      // equippable — `frameIdUnlocked` alone can't tell that: it only ever
      // tracks *extra* unlocks (ad reward, coin purchase, level reward,
      // Premium), never the base-free tier, since a free id is never added
      // to `unlocked.frameIds`. Calling `frameIdUnlocked` by itself here
      // (as this used to) meant every free frame reported "not unlocked"
      // and fell straight through to the paywall — the bug this guards
      // against. Mirrors `AvatarPickerBody.handleTap`'s own `!isLocked(preset)`
      // check, which never had this gap because it already routes through
      // the local `isLocked` wrapper instead of the raw premium-tier check.
      if (!FramePresets.isLocked(frameId) || frameIdUnlocked(frameId)) {
        final consumeReward =
            !isPremium &&
            FramePresets.isAdUnlockable(frameId) &&
            unlocked.isAdRewardActive(_framePremiumModuleId) &&
            !unlocked.frameIds.contains(frameId);
        _selectFrame(uid, frameId, consumeReward: consumeReward);
        return;
      }
      if (FramePresets.isCoinUnlockable(frameId)) {
        _buyWithCoins(context, frameId);
        return;
      }
      _openFramePaywall(
        context,
        showAdOption: FramePresets.isAdUnlockable(frameId),
      );
    }

    // RISK-1/RISK-5: see `_saving`'s/`_buyingWithCoins`'s own doc comments
    // above.
    return AbsorbPointer(
      absorbing: _saving || _buyingWithCoins,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PickerSectionTitle(s.ownedSectionTitle),
          _FrameGrid(
            frames: owned,
            language: s.language,
            selectedId: profile?.frameId,
            coinPriceFor: (_) => null,
            onTap: handleTap,
          ),
          // Locked frames only ever show up in Toko — see [shopMode]'s own
          // doc comment.
          if (widget.shopMode && notOwned.isNotEmpty) ...[
            PickerSectionTitle(s.notOwnedSectionTitle),
            _FrameGrid(
              frames: notOwned,
              language: s.language,
              selectedId: profile?.frameId,
              locked: true,
              coinPriceFor: (id) => FramePresets.isCoinUnlockable(id)
                  ? FramePresets.coinPrice
                  : null,
              onTap: handleTap,
            ),
          ],
        ],
      ),
    );
  }
}

/// One of the two labels next to each other at the top of the sheet
/// ("Pilih Avatar" / "Pilih Bingkai") that switch which section is shown
/// below, instead of everything being one long scroll.
class _PickerModeTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _PickerModeTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? context.palette.primaryCoral : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: active
                ? context.palette.textNavy
                : context.palette.textNavy.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}

/// A small bold section header — "Sudah Dimiliki"/"Belum Dimiliki" above an
/// owned/not-owned grid, "Foto Akun" above the Google-photo tile, and so
/// on. Public (not `_`-prefixed) so [CoverPickerBody] in a different file
/// can reuse the exact same header instead of a near-duplicate copy.
class PickerSectionTitle extends StatelessWidget {
  final String title;

  const PickerSectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: context.palette.textNavy,
        ),
      ),
    );
  }
}

class _GoogleAvatarTile extends StatelessWidget {
  final String photoUrl;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _GoogleAvatarTile({
    required this.photoUrl,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.palette.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: selected
              ? Border.all(color: context.palette.primaryCoral, width: 2)
              : null,
        ),
        child: Row(
          children: [
            // errorBuilder, not a bare backgroundImage: NetworkImage(...) —
            // see _NetworkPhotoCircle's doc comment in user_avatar.dart for
            // why that combination silently paints a blank circle on a
            // failed load instead of falling back to anything.
            ClipOval(
              child: SizedBox(
                width: 48,
                height: 48,
                child: Image.network(
                  photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => CircleAvatar(
                    radius: 24,
                    backgroundColor: context.palette.hiraganaCardBg,
                    child: const Icon(Icons.person),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: context.palette.textNavy),
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: context.palette.primaryCoral),
          ],
        ),
      ),
    );
  }
}

class _PresetGrid extends StatelessWidget {
  final List<AvatarPreset> presets;
  final AppLanguage language;
  final bool Function(AvatarPreset) isSelected;
  final bool Function(AvatarPreset) locked;
  final void Function(AvatarPreset) onTap;

  /// Non-null while a locked, unowned tile should show its coin price
  /// instead of a plain padlock — the visual cue for "buy this with
  /// coins" versus "watch an ad / subscribe for this", so a learner
  /// doesn't have to tap a tile just to find out which kind of lock it
  /// is.
  final int? Function(AvatarPreset)? coinPriceFor;

  const _PresetGrid({
    required this.presets,
    required this.language,
    required this.isSelected,
    required this.locked,
    required this.onTap,
    this.coinPriceFor,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: presets.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        // < 1 so each cell has extra height below the square art for the
        // name caption (see `_PresetTile`) — a plain 1:1 cell only fits the
        // artwork itself.
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, index) {
        final preset = presets[index];
        final isLocked = locked(preset);
        return _PresetTile(
          preset: preset,
          label: preset.labelFor(language),
          selected: isSelected(preset),
          locked: isLocked,
          coinPrice: isLocked ? coinPriceFor?.call(preset) : null,
          onTap: () => onTap(preset),
        );
      },
    );
  }
}

class _PresetTile extends StatelessWidget {
  final AvatarPreset preset;
  final String label;
  final bool selected;
  final bool locked;
  final int? coinPrice;
  final VoidCallback onTap;

  const _PresetTile({
    required this.preset,
    required this.label,
    required this.selected,
    required this.locked,
    required this.onTap,
    this.coinPrice,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      // The name sits below the artwork as its own caption, not baked into
      // the image — the badges (selected check, lock, coin price) stay
      // overlaid on the art itself since they're status, not identity.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: AvatarPresetArt(
                    preset: preset,
                    imageSize: double.infinity,
                    emojiFontSize: 28,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (selected)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: context.palette.primaryCoral,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              if (selected)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Icon(
                    Icons.check_circle,
                    color: context.palette.primaryCoral,
                    size: 18,
                  ),
                ),
              if (locked && coinPrice != null)
                Positioned(
                  right: 4,
                  top: 4,
                  child: _CoinPriceBadge(price: coinPrice!),
                )
              else if (locked)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: context.palette.textNavy,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: context.palette.textNavy.withValues(
                alpha: locked ? 0.55 : 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The coin-price pill shown in place of a plain padlock on a coin-tier
/// locked tile — shared by avatar, frame and cover grids so the visual
/// language for "buy this with coins" stays identical across all three.
class _CoinPriceBadge extends StatelessWidget {
  final int price;

  const _CoinPriceBadge({required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: context.palette.tertiaryAmber,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, color: Colors.white, size: 10),
          const SizedBox(width: 2),
          Text(
            '$price',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid of selectable avatar frames/borders, drawn from [frames] — the
/// caller (`_FramePickerBodyState.build`) already splits [FramePresets.all]
/// into an owned grid and a not-owned grid, so every tile in one call is
/// uniformly [locked] or not; there's no more per-tile lock lookup here.
///
/// **There used to be a "no frame" tile at index 0** (always available,
/// picking it cleared `profile.frameId`) — removed at explicit request. A
/// learner can still end up with no frame (a fresh profile's `frameId` is
/// null by default), just not by picking it back off from here.
class _FrameGrid extends StatelessWidget {
  final List<FramePreset> frames;
  final AppLanguage language;
  final String? selectedId;

  /// True for every tile in this grid, or false for every tile — the
  /// caller passes one `_FrameGrid` per section (owned / not owned), never
  /// a mixed list.
  final bool locked;

  /// Non-null for a locked frame that should show its coin price instead
  /// of a plain padlock. Ignored (never called) for the owned grid.
  final int? Function(String id) coinPriceFor;

  final void Function(String frameId) onTap;

  const _FrameGrid({
    required this.frames,
    required this.language,
    required this.selectedId,
    this.locked = false,
    required this.coinPriceFor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: frames.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        // Same reasoning as `_PresetGrid`'s — room below the art for the
        // name caption.
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, index) {
        final preset = frames[index];
        return _FrameTile(
          selected: selectedId == preset.id,
          locked: locked,
          caption: preset.labelFor(language),
          coinPrice: locked ? coinPriceFor(preset.id) : null,
          // Sized off the tile rather than a fixed 40 — these are detailed
          // wreath illustrations, and at 40 inside a ~92 tile they rendered
          // too small to tell apart. Invisible while FramePresets.all was
          // empty; only showed up once real art landed.
          child: LayoutBuilder(
            builder: (context, constraints) => FrameOverlay(
              preset: preset,
              avatarSize: constraints.maxWidth - 12,
              scale: 1,
            ),
          ),
          onTap: () => onTap(preset.id),
        );
      },
    );
  }
}

class _FrameTile extends StatelessWidget {
  final bool selected;
  final bool locked;
  final int? coinPrice;

  /// The name shown below the tile, as its own line — not drawn inside the
  /// artwork.
  final String caption;
  final Widget child;
  final VoidCallback onTap;

  const _FrameTile({
    required this.selected,
    required this.locked,
    required this.caption,
    required this.child,
    required this.onTap,
    this.coinPrice,
  });

  @override
  Widget build(BuildContext context) {
    final box = Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: context.palette.cardWhite,
            borderRadius: BorderRadius.circular(16),
            border: selected
                ? Border.all(color: context.palette.primaryCoral, width: 2)
                : null,
          ),
          alignment: Alignment.center,
          child: Opacity(opacity: locked ? 0.35 : 1, child: child),
        ),
        if (selected)
          Positioned(
            right: 4,
            top: 4,
            child: Icon(
              Icons.check_circle,
              color: context.palette.primaryCoral,
              size: 18,
            ),
          ),
        if (locked && coinPrice != null)
          Positioned(
            right: 4,
            top: 4,
            child: _CoinPriceBadge(price: coinPrice!),
          )
        else if (locked)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: context.palette.textNavy,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock, color: Colors.white, size: 12),
            ),
          ),
      ],
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: box),
          const SizedBox(height: 4),
          Text(
            caption,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: context.palette.textNavy.withValues(
                alpha: locked ? 0.55 : 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

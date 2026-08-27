import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/covers.dart';
import '../../../data/models/app_language.dart';
import '../../../data/models/unlocked_cosmetics.dart';
import '../../../core/providers.dart';
import '../../../core/services/coin_spend_service.dart';
import '../../../core/theme/app_palette.dart';
import '../../paywall/paywall_screen.dart';
import 'avatar_picker_sheet.dart' show PickerSectionTitle;

/// The `moduleId` watching an ad on [PaywallScreen] grants a one-time
/// unlock for — the 4 [CoverPresets.lockedIds] below.
const _coverPremiumModuleId = 'cover_premium';

/// Bottom sheet for picking the Profile header's cover illustration: one of
/// [CoverPresets.all]. Mirrors [AvatarPickerSheet]'s grid-of-tiles shape,
/// including its ad-reward-unlock pattern for [CoverPresets.lockedIds] — see
/// `unlockedCosmeticsProvider`'s doc comment for the full mechanism this
/// one reuses (one ad grants exactly one locked-cover change, consumed via
/// `ProgressRepository.consumeAdReward` right after it's spent, not left
/// active for its full 24h backstop).
class CoverPickerSheet extends ConsumerWidget {
  const CoverPickerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
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
              Text(
                s.pickCoverTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.palette.textNavy,
                ),
              ),
              const SizedBox(height: 16),
              const CoverPickerBody(),
            ],
          ),
        );
      },
    );
  }
}

/// The cover grid, shared by [CoverPickerSheet] and the Toko screen's own
/// "Sampul" tab — see `AvatarPickerBody`'s doc comment for the split's
/// reasoning and [popOnSelect].
class CoverPickerBody extends ConsumerStatefulWidget {
  final bool popOnSelect;

  /// See `AvatarPickerBody.shopMode` — same "buying happens in Toko"
  /// split, applied to [CoverPresets.all] instead.
  final bool shopMode;

  const CoverPickerBody({
    super.key,
    this.popOnSelect = true,
    this.shopMode = false,
  });

  @override
  ConsumerState<CoverPickerBody> createState() => _CoverPickerBodyState();
}

class _CoverPickerBodyState extends ConsumerState<CoverPickerBody> {
  /// Reentrancy guard for [_select] — see `_AvatarPickerBodyState._saving`'s
  /// doc comment for the full reasoning (RISK-1,
  /// AUDIT_COSMETIC_PROFILE_SHOP.md): same double-tap risk, same fix, and
  /// the same deliberate choice not to also guard [_buyWithCoins]/
  /// [_openPaywall].
  bool _saving = false;

  Future<void> _select(
    String uid,
    String? coverId, {
    bool consumeReward = false,
  }) async {
    setState(() => _saving = true);
    try {
      try {
        await ref.read(progressRepositoryProvider).updateCover(uid, coverId);
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(appStringsProvider).coverSaveFailed),
          ),
        );
        return;
      }
      // Best-effort — the cover itself already saved successfully above, so
      // a hiccup publishing it to the leaderboard must not surface as a
      // failure. Lets other learners' PublicProfileScreen show the same
      // cover this account's own Profile header now does.
      try {
        await ref
            .read(leaderboardRepositoryProvider)
            .updateCoverId(uid, coverId);
      } catch (_) {}
      if (consumeReward) {
        // Best-effort only — the cover itself already saved successfully
        // above, so a hiccup here must not surface as a failure.
        try {
          await ref
              .read(progressRepositoryProvider)
              .consumeAdReward(uid, _coverPremiumModuleId);
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
    final s = ref.read(appStringsProvider);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaywallScreen(
          moduleId: _coverPremiumModuleId,
          moduleTitle: s.coverPremiumTitle,
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
  /// this mirrors exactly for covers.
  Future<void> _buyWithCoins(BuildContext context, String coverId) async {
    final s = ref.read(appStringsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.coinBuyConfirmTitle),
        content: Text(s.coinBuyConfirmBody(CoverPresets.coinPrice)),
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
          .buy(CoinSpendKind.cover, coverId);
      if (!mounted) return;
      // No local optimistic set update needed — see `AvatarPickerBody
      // ._buyWithCoins`'s identical note; `unlockedCosmeticsProvider`
      // watches the exact `xp.unlockedCoverIds` field this write lands in.
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.coinBuySuccess)));
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
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appStartupProvider).valueOrNull;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final isPremium =
        ref.watch(subscriptionProvider).valueOrNull?.isPremium ?? false;
    // Live, not a one-shot fetch — see `unlockedCosmeticsProvider`'s own
    // doc comment (BUG-1, AUDIT_COSMETIC_PROFILE_SHOP.md).
    final unlocked =
        ref.watch(unlockedCosmeticsProvider).valueOrNull ??
        UnlockedCosmetics.empty;
    // Same three-tier reasoning as `_AvatarPickerBodyState
    // .avatarIdUnlocked` — see its doc comment.
    bool coverIdUnlocked(String id) {
      if (isPremium) return true;
      if (unlocked.coverIds.contains(id)) return true;
      return CoverPresets.isAdUnlockable(id) &&
          unlocked.isAdRewardActive(_coverPremiumModuleId);
    }

    final uid = user?.uid;
    final selectedId = profile?.coverId;
    final s = ref.watch(appStringsProvider);

    // Same owned-vs-not split as `AvatarPickerBody`/`FramePickerBody` —
    // see the former's doc comment above its own `isLocked`.
    bool isLocked(CoverPreset c) =>
        CoverPresets.isLocked(c.id) && !coverIdUnlocked(c.id);
    final owned = CoverPresets.all.where((c) => !isLocked(c)).toList();
    final notOwned = CoverPresets.all.where(isLocked).toList();

    void handleTap(CoverPreset preset) {
      if (uid == null) return;
      if (!isLocked(preset)) {
        final consumeReward =
            !isPremium &&
            CoverPresets.isAdUnlockable(preset.id) &&
            unlocked.isAdRewardActive(_coverPremiumModuleId) &&
            !unlocked.coverIds.contains(preset.id);
        _select(uid, preset.id, consumeReward: consumeReward);
        return;
      }
      if (CoverPresets.isCoinUnlockable(preset.id)) {
        _buyWithCoins(context, preset.id);
        return;
      }
      _openPaywall(
        context,
        showAdOption: CoverPresets.isAdUnlockable(preset.id),
      );
    }

    // RISK-1: see `_saving`'s own doc comment above.
    return AbsorbPointer(
      absorbing: _saving,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PickerSectionTitle(s.ownedSectionTitle),
          _CoverGrid(
            covers: owned,
            language: s.language,
            // A user who has never picked a cover has no stored coverId,
            // and now sees the fallback preset highlighted instead of a
            // separate "Default" tile — see CoverPresets.fallback.
            selectedId: selectedId ?? CoverPresets.fallback.id,
            locked: false,
            onTap: uid == null ? null : handleTap,
          ),
          // Locked covers only ever show up in Toko — see [shopMode]'s own
          // doc comment.
          if (widget.shopMode && notOwned.isNotEmpty) ...[
            PickerSectionTitle(s.notOwnedSectionTitle),
            _CoverGrid(
              covers: notOwned,
              language: s.language,
              selectedId: selectedId ?? CoverPresets.fallback.id,
              locked: true,
              onTap: uid == null ? null : handleTap,
            ),
          ],
        ],
      ),
    );
  }
}

/// The cover grid itself, drawn from [covers] — the caller already splits
/// [CoverPresets.all] into an owned grid and a not-owned grid, so every
/// tile in one call is uniformly [locked] or not, same shape as
/// `_FrameGrid` in `avatar_picker_sheet.dart`.
class _CoverGrid extends StatelessWidget {
  final List<CoverPreset> covers;
  final AppLanguage language;
  final String? selectedId;
  final bool locked;
  final void Function(CoverPreset preset)? onTap;

  const _CoverGrid({
    required this.covers,
    required this.language,
    required this.selectedId,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: covers.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        // Lower than the artwork's own 1.3 ratio — the name used to be
        // drawn over the image itself; now it's a caption below, so each
        // cell needs the extra height for that line.
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, index) {
        final preset = covers[index];
        return _CoverTile(
          preset: preset,
          language: language,
          selected: selectedId == preset.id,
          locked: locked,
          coinPrice: locked && CoverPresets.isCoinUnlockable(preset.id)
              ? CoverPresets.coinPrice
              : null,
          onTap: onTap == null ? null : () => onTap!(preset),
        );
      },
    );
  }
}

class _CoverTile extends StatelessWidget {
  final AppLanguage language;
  final CoverPreset preset;
  final bool selected;
  final bool locked;
  final int? coinPrice;
  final VoidCallback? onTap;

  const _CoverTile({
    required this.preset,
    required this.language,
    required this.selected,
    required this.locked,
    required this.onTap,
    this.coinPrice,
  });

  @override
  Widget build(BuildContext context) {
    // The name used to be drawn as text overlaid on the artwork itself
    // (bottom-left corner, white-on-image so it stayed readable over a
    // dark scene). It's now a plain caption below the tile instead — the
    // same treatment `_PresetTile`/`_FrameTile` give avatars and frames,
    // and closer to how the "Skin Kartu" tab shows its own items (name
    // beside/below the thumbnail, never baked into it).
    final art = LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: selected
                    ? Border.all(color: context.palette.primaryCoral, width: 2)
                    : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  CoverArt(
                    preset: preset,
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                  ),
                  if (locked)
                    Container(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      color: Colors.black.withValues(alpha: 0.35),
                    ),
                ],
              ),
            ),
            if (selected)
              Positioned(
                right: 6,
                top: 6,
                child: Icon(
                  Icons.check_circle,
                  color: context.palette.primaryCoral,
                  size: 20,
                ),
              ),
            if (locked && coinPrice != null)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: context.palette.tertiaryAmber,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '$coinPrice',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (locked)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock, color: Colors.white, size: 14),
                ),
              ),
          ],
        );
      },
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: art),
          const SizedBox(height: 4),
          Text(
            preset.labelFor(language),
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

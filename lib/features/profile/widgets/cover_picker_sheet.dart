import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/covers.dart';
import '../../../data/models/app_language.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_palette.dart';
import '../../paywall/paywall_screen.dart';

/// The `moduleId` watching an ad on [PaywallScreen] grants a one-time
/// unlock for — the 4 [CoverPresets.lockedIds] below.
const _coverPremiumModuleId = 'cover_premium';

/// Bottom sheet for picking the Profile header's cover illustration: one of
/// [CoverPresets.all]. Mirrors [AvatarPickerSheet]'s grid-of-tiles shape,
/// including its ad-reward-unlock pattern for [CoverPresets.lockedIds] — see
/// that sheet's `_adRewardActive` doc comment for the full mechanism this
/// one reuses (one ad grants exactly one locked-cover change, consumed via
/// `ProgressRepository.consumeAdReward` right after it's spent, not left
/// active for its full 24h backstop).
class CoverPickerSheet extends ConsumerStatefulWidget {
  const CoverPickerSheet({super.key});

  @override
  ConsumerState<CoverPickerSheet> createState() => _CoverPickerSheetState();
}

class _CoverPickerSheetState extends ConsumerState<CoverPickerSheet> {
  bool _adRewardActive = false;

  @override
  void initState() {
    super.initState();
    _refreshAdRewardStatus();
  }

  Future<void> _refreshAdRewardStatus() async {
    final uid = ref.read(appStartupProvider).valueOrNull?.uid;
    if (uid == null) return;
    final rewards = await ref.read(progressRepositoryProvider).getAdRewards(uid);
    final active = rewards[_coverPremiumModuleId]?.isActive ?? false;
    if (mounted) setState(() => _adRewardActive = active);
  }

  Future<void> _select(String uid, String? coverId, {bool consumeReward = false}) async {
    try {
      await ref.read(progressRepositoryProvider).updateCover(uid, coverId);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(appStringsProvider).coverSaveFailed)),
      );
      return;
    }
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
    Navigator.of(context).pop();
  }

  Future<void> _openPaywall(BuildContext context) async {
    final s = ref.read(appStringsProvider);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaywallScreen(
          moduleId: _coverPremiumModuleId,
          moduleTitle: s.coverPremiumTitle,
          singleUse: true,
        ),
      ),
    );
    // PaywallScreen pops itself the moment the reward is earned, so by the
    // time this await resolves the write (if any) has already landed —
    // safe to read it back immediately, no extra delay needed.
    if (!mounted) return;
    await _refreshAdRewardStatus();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appStartupProvider).valueOrNull;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final isPremium = ref.watch(subscriptionProvider).valueOrNull?.isPremium ?? false;
    final unlocked = isPremium || _adRewardActive;
    final viaAdReward = !isPremium && _adRewardActive;
    final uid = user?.uid;
    final selectedId = profile?.coverId;
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
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: CoverPresets.all.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                ),
                itemBuilder: (context, index) {
                  final preset = CoverPresets.all[index];
                  final isLocked = CoverPresets.isLocked(preset.id) && !unlocked;
                  return _CoverTile(
                    preset: preset,
                    language: s.language,
                    // A user who has never picked a cover has no stored
                    // coverId, and now sees the fallback preset highlighted
                    // instead of a separate "Default" tile — see
                    // CoverPresets.fallback.
                    selected: (selectedId ?? CoverPresets.fallback.id) == preset.id,
                    locked: isLocked,
                    onTap: uid == null
                        ? null
                        : () {
                            if (isLocked) {
                              _openPaywall(context);
                              return;
                            }
                            _select(
                              uid,
                              preset.id,
                              consumeReward:
                                  viaAdReward && CoverPresets.isLocked(preset.id),
                            );
                          },
                  );
                },
              ),
            ],
          ),
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
  final VoidCallback? onTap;

  const _CoverTile({
    required this.preset,
    required this.language,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: LayoutBuilder(
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
                  child: Icon(Icons.check_circle, color: context.palette.primaryCoral, size: 20),
                ),
              if (locked)
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
              Positioned(
                left: 8,
                bottom: 6,
                child: Text(
                  preset.labelFor(language),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: locked ? Colors.white : context.palette.textNavy,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

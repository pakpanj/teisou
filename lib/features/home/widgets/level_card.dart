import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/xp_progress.dart';

/// The Home tab's "Level N" card — total XP earned across every learning
/// action in the app, a progress bar to the next level, and a gift button
/// for claiming any level-up rewards still pending. See
/// `ProgressRepository.addXp`/`claimLevelReward` for where XP actually
/// comes from and what a claim grants.
class HomeLevelCard extends ConsumerWidget {
  const HomeLevelCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final xp = ref.watch(xpProgressProvider).valueOrNull ?? XpProgress.empty;
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.hiraganaCardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Image.asset(
              'assets/icons/xp_level_badge.png',
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: BoxDecoration(
                  color: palette.primaryCoral.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text('🌸', style: TextStyle(fontSize: 22)),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.homeLevelLabel(xp.level),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: palette.textNavy,
                  ),
                ),
                Text(
                  s.homeLevelSubtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: palette.textNavy.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: xp.levelProgress,
                          minHeight: 6,
                          backgroundColor: palette.progressTrack,
                          color: palette.primaryCoral,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      s.homeLevelPointsLabel(xp.xpIntoLevel, XpProgress.xpPerLevel),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: palette.textNavy.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _GiftButton(pendingRewards: xp.pendingRewards),
        ],
      ),
    );
  }
}

class _GiftButton extends ConsumerStatefulWidget {
  final int pendingRewards;

  const _GiftButton({required this.pendingRewards});

  @override
  ConsumerState<_GiftButton> createState() => _GiftButtonState();
}

class _GiftButtonState extends ConsumerState<_GiftButton> {
  bool _claiming = false;

  Future<void> _claim() async {
    if (_claiming || widget.pendingRewards <= 0) return;
    setState(() => _claiming = true);
    final s = ref.read(appStringsProvider);
    final uid = ref.read(appStartupProvider).valueOrNull?.uid;
    XpReward? reward;
    if (uid != null) {
      reward = await ref.read(progressRepositoryProvider).claimLevelReward(uid);
      ref.invalidate(xpProgressProvider);
    }
    if (!mounted) return;
    setState(() => _claiming = false);
    final kindLabel = switch (reward?.kind) {
      XpRewardKind.avatar => s.xpRewardKindAvatar,
      XpRewardKind.frame => s.xpRewardKindFrame,
      XpRewardKind.cover => s.xpRewardKindCover,
      null => null,
    };
    // Only an avatar's own `label` is an emoji (see AvatarPreset.emoji) —
    // a frame/cover's is a text name like "Sakura & Fuji", so those get a
    // generic kind icon here instead of trying to render that text huge.
    final previewGlyph = switch (reward?.kind) {
      XpRewardKind.avatar => reward!.label,
      XpRewardKind.frame => '🖼️',
      XpRewardKind.cover => '🎨',
      null => null,
    };
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(reward != null ? s.xpRewardClaimedTitle : s.xpRewardNoneTitle),
        content: reward != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(previewGlyph!, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.xpRewardClaimedBody(
                        reward.kind == XpRewardKind.avatar
                            ? '$kindLabel ${reward.label}'
                            : '$kindLabel "${reward.label}"',
                      ),
                    ),
                  ),
                ],
              )
            : Text(s.xpRewardNoneBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final active = widget.pendingRewards > 0;
    final s = ref.watch(appStringsProvider);

    return Tooltip(
      message: s.xpClaimRewardTooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: active ? _claim : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: _claiming
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: palette.primaryCoral,
                      ),
                    )
                  : Opacity(
                      opacity: active ? 1 : 0.35,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Image.asset(
                          'assets/icons/xp_reward_omamori.png',
                          errorBuilder: (context, error, stackTrace) =>
                              const Text('🎁', style: TextStyle(fontSize: 20)),
                        ),
                      ),
                    ),
            ),
            if (active)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: palette.errorRed,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.2),
                  ),
                  child: Text(
                    '${widget.pendingRewards}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

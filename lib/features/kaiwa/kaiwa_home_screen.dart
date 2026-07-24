import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_refresh_indicator.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../data/models/jlpt_level.dart';
import '../../data/models/kaiwa_jlpt_level_info.dart';
import 'kaiwa_level_screen.dart';
import 'kaiwa_providers.dart';

/// Entry point for the Kaiwa module: JLPT level picker (N5-N1), mirroring
/// `BunpouHomeScreen`. Only levels with a real dataset are tappable; the
/// rest show a "Segera" badge. Tapping a level opens `KaiwaLevelScreen`,
/// which is what this screen used to be before the level layer was added
/// on top of the original flat scenario-category picker.
class KaiwaHomeScreen extends ConsumerWidget {
  const KaiwaHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelsAsync = ref.watch(kaiwaLevelsProvider);
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Kaiwa')),
      body: levelsAsync.when(
        data: (levels) => Column(
          children: [
            Expanded(
              child: AppRefreshIndicator(
                onRefresh: () => ref.refresh(kaiwaLevelsProvider.future),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: [
                    for (final level in levels) ...[
                      _LevelCard(level: level),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
            const FreeTierBannerAd(),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(s.failedToLoadLevels(e))),
      ),
    );
  }
}

class _LevelCard extends ConsumerWidget {
  final KaiwaJlptLevelInfo level;

  const _LevelCard({required this.level});

  void _open(BuildContext context, AppStrings s) {
    if (!level.available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.kaiwaLevelComingSoon(level.name))),
      );
      return;
    }
    AppNavigator.slideFromRight(
      context,
      KaiwaLevelScreen(
        level: JlptLevelX.fromKey(level.id),
        levelName: level.name,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = level.available;
    final progress = available
        ? ref
              .watch(kaiwaLevelProgressProvider(JlptLevelX.fromKey(level.id)))
              .valueOrNull
        : null;
    final s = ref.watch(appStringsProvider);

    return Material(
      color: available ? AppColors.cardWhite : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _open(context, s),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color:
                      (available
                              ? AppColors.primaryCoral
                              : AppColors.freeBadgeGrey)
                          .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  level.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: available
                        ? AppColors.primaryCoral
                        : AppColors.freeBadgeGrey,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.kaiwaLevelTitle(level.name),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: available
                            ? AppColors.textNavy
                            : AppColors.freeBadgeGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (available)
                      Text(
                        progress != null && progress.$1 > 0
                            ? s.progressLearned(progress.$1, progress.$2)
                            : s.themeCount(level.themeCount ?? 0),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textNavy.withValues(alpha: 0.6),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.freeBadgeGrey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          s.soonBadge,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.freeBadgeGrey,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: available
                    ? AppColors.primaryCoral
                    : AppColors.freeBadgeGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

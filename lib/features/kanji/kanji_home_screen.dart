import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_refresh_indicator.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../data/models/jlpt_level.dart';
import '../../data/models/kanji_level.dart';
import 'kanji_level_screen.dart';
import 'kanji_providers.dart';

/// Entry point for the Kanji module: JLPT level picker (N5-N1). Only
/// levels with a real dataset are tappable; the rest show a "Segera"
/// badge, same convention as [KotobaHomeScreen]'s category grid.
class KanjiHomeScreen extends ConsumerWidget {
  const KanjiHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelsAsync = ref.watch(kanjiLevelsProvider);
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: const Text('Kanji')),
      body: levelsAsync.when(
        data: (levels) => Column(
          children: [
            Expanded(
              child: AppRefreshIndicator(
                onRefresh: () => ref.refresh(kanjiLevelsProvider.future),
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
  final KanjiLevel level;

  const _LevelCard({required this.level});

  void _open(BuildContext context, AppStrings s) {
    if (!level.available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.kanjiLevelComingSoon(level.name))),
      );
      return;
    }
    AppNavigator.slideFromRight(
      context,
      KanjiLevelScreen(
        jlptLevel: JlptLevelX.fromKey(level.id),
        levelName: level.name,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = level.available;
    final progress = available
        ? ref
              .watch(kanjiLevelProgressProvider(JlptLevelX.fromKey(level.id)))
              .valueOrNull
        : null;
    final s = ref.watch(appStringsProvider);

    return Material(
      color: available ? context.palette.cardWhite : Colors.grey.shade100,
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
                              ? context.palette.primaryCoral
                              : context.palette.freeBadgeGrey)
                          .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  level.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: available
                        ? context.palette.primaryCoral
                        : context.palette.freeBadgeGrey,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.kanjiLevelCardTitle(level.name),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: available
                            ? context.palette.textNavy
                            : context.palette.freeBadgeGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (available)
                      Text(
                        progress != null && progress.$1 > 0
                            ? s.progressLearned(progress.$1, progress.$2)
                            : s.kanjiCount(level.kanjiCount ?? 0),
                        style: TextStyle(
                          fontSize: 12,
                          color: context.palette.textNavy.withValues(alpha: 0.6),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: context.palette.freeBadgeGrey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          s.soonBadge,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: context.palette.freeBadgeGrey,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: available
                    ? context.palette.primaryCoral
                    : context.palette.freeBadgeGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

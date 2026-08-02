import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_refresh_indicator.dart';
import '../../core/widgets/mascot_guide_bubble.dart';
import '../../core/widgets/mascot_widget.dart';
import '../../data/models/jlpt_level.dart';
import 'bab_level_screen.dart';
import 'bab_providers.dart';

/// Entry point for the Bab curriculum: a JLPT level picker, mirroring
/// [KanjiHomeScreen]'s shape. Unlike Kanji/Kotoba/Bunpou/Kaiwa, Bab has no
/// separate `_levels.json` metadata file — the dataset is small enough
/// that level availability/counts are derived straight from
/// [babByLevelProvider] instead.
class BabHomeScreen extends ConsumerWidget {
  const BabHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final nextUp = ref.watch(babNextUpProvider).valueOrNull;

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: Text(s.babTitle)),
      body: AppRefreshIndicator(
        onRefresh: () async {
          ref.invalidate(babAllProvider);
          ref.invalidate(babNextUpProvider);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            MascotGuideBubble(
              mood: nextUp != null ? MascotMood.excited : MascotMood.happy,
              message: nextUp != null
                  ? s.babGuideContinue(nextUp.localizedTitle(s.language))
                  : s.babGuideIntro,
            ),
            const SizedBox(height: 24),
            for (final level in JlptLevel.values) ...[
              _LevelCard(level: level),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends ConsumerWidget {
  final JlptLevel level;

  const _LevelCard({required this.level});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapters = ref.watch(babByLevelProvider(level)).valueOrNull;
    final available = (chapters?.isNotEmpty ?? false);
    final s = ref.watch(appStringsProvider);

    void open() {
      if (!available) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.babLevelComingSoon(level.key))),
        );
        return;
      }
      AppNavigator.slideFromRight(context, BabLevelScreen(level: level));
    }

    return Material(
      color: available ? context.palette.cardWhite : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: open,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: (available
                          ? context.palette.primaryCoral
                          : context.palette.freeBadgeGrey)
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  level.key,
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
                      s.babLevelCardTitle(level.key),
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
                        s.babChapterCount(chapters!.length),
                        style: TextStyle(
                          fontSize: 12,
                          color: context.palette.textNavy.withValues(alpha: 0.6),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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
                color: available ? context.palette.primaryCoral : context.palette.freeBadgeGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

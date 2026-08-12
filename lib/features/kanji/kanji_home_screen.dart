import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_refresh_indicator.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../core/widgets/module_level_card.dart';
import '../../core/widgets/module_skyline_banner.dart';
import '../../core/widgets/module_title_plaque.dart';
import '../../data/models/jlpt_level.dart';
import '../../data/models/kanji_level.dart';
import 'kanji_level_screen.dart';
import 'kanji_providers.dart';
import '../../core/widgets/mascot_advisor.dart';
import '../../core/widgets/mascot_widget.dart';
import '../../core/widgets/app_loading.dart';

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: context.palette.textNavy,
        title: const ModuleTitlePlaque(title: 'Kanji'),
      ),
      body: levelsAsync.when(
        data: (levels) => Column(
          children: [
            Expanded(
              // Brush in paw: this is the module about writing characters
              // by hand, and it was the one that had no mascot at all.
              child: MascotAdvisor(
                mood: MascotMood.writing,
                message: s.kanjiGuideMessage,
                child: AppRefreshIndicator(
                  onRefresh: () => ref.refresh(kanjiLevelsProvider.future),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      const ModuleSkylineBanner(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          20,
                          20,
                          20,
                          MascotAdvisor.reservedBottomSpace,
                        ),
                        child: Column(
                          children: [
                            for (final level in levels) ...[
                              _LevelCard(level: level),
                              const SizedBox(height: 12),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const FreeTierBannerAd(),
          ],
        ),
        loading: () => const AppLoading(),
        error: (e, _) => Center(child: Text(s.failedToLoadLevels(e))),
      ),
    );
  }
}

class _LevelCard extends ConsumerWidget {
  final KanjiLevel level;

  const _LevelCard({required this.level});

  void _open(BuildContext context, AppStrings s, bool gateReached) {
    if (!level.available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.kanjiLevelComingSoon(level.name))),
      );
      return;
    }
    if (!gateReached) {
      final thisLevel = JlptLevelX.fromKey(level.id);
      final previousLevel =
          JlptLevel.values[JlptLevel.values.indexOf(thisLevel) - 1];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.kanjiLevelLockedReason(previousLevel.key))),
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
    final thisLevel = JlptLevelX.fromKey(level.id);
    final gates = ref.watch(kanjiLevelGateProvider).valueOrNull;
    // While the gate is still loading, treat every level but N5 as locked
    // rather than briefly open — a card that's tappable and then locks
    // under the learner's finger is worse than one that resolves from
    // locked to open, same reasoning Bab's own level gate documents.
    final gateReached = gates
            ?.firstWhere((g) => g.level == thisLevel)
            .reachedByProgress ??
        (thisLevel == JlptLevel.n5);
    final available = level.available && gateReached;
    final progress = available
        ? ref.watch(kanjiLevelProgressProvider(thisLevel)).valueOrNull
        : null;
    final s = ref.watch(appStringsProvider);
    final total = progress?.$2 ?? level.kanjiCount ?? 0;
    final learned = progress?.$1 ?? 0;
    final percent = total > 0 ? ((learned / total) * 100).round() : 0;

    return ModuleLevelCard(
      badgeLabel: level.name,
      title: s.kanjiLevelCardTitle(level.name),
      subtitle: s.kanjiCount(level.kanjiCount ?? 0),
      percent: available ? percent : null,
      available: available,
      soonLabel: level.available ? s.babLevelLockedBadge : s.soonBadge,
      accent: context.palette.primaryCoral,
      onTap: () => _open(context, s, gateReached),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/mascot_advisor.dart';
import '../../core/widgets/mascot_widget.dart';
import '../../core/widgets/module_level_card.dart';
import '../../core/widgets/module_skyline_banner.dart';
import '../../core/widgets/module_title_plaque.dart';
import '../../data/models/choukai_jlpt_level_info.dart';
import '../../data/models/jlpt_level.dart';
import 'choukai_level_screen.dart';
import 'choukai_providers.dart';
import '../../core/widgets/app_loading.dart';
import '../../data/repositories/onboarding_repository.dart';
import '../../features/onboarding/coach_mark_tour.dart';
import '../../features/onboarding/first_visit_tutorial.dart';
import '../../features/onboarding/module_tours.dart';

/// Entry point for Choukai (listening comprehension) within Ujian: JLPT
/// level picker, mirrors `DokkaiHomeScreen`. Every level currently shows
/// "Segera" — the architecture is ready (see `ChoukaiRepository`), content
/// hasn't been authored yet, same as Kaiwa's N4-N1 levels before they were.
class ChoukaiHomeScreen extends ConsumerWidget {
  const ChoukaiHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelsAsync = ref.watch(choukaiLevelsProvider);
    final s = ref.watch(appStringsProvider);

    return FirstVisitTutorial(
      id: TutorialId.choukai,
      tour: choukaiTourSteps,
      child: Scaffold(
        backgroundColor: context.palette.background,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: context.palette.textNavy,
          title: const ModuleTitlePlaque(title: 'Choukai'),
        ),
        body: levelsAsync.when(
          data: (levels) => MascotAdvisor(
            // Explaining, not reacting — this message tells the learner how
            // the screen (and the score-based level lock) works, same
            // MascotMood.explaining convention BabLevelScreen already uses.
            mood: MascotMood.explaining,
            message: s.choukaiGuideMessage,
            child: ListView(
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
                      for (var i = 0; i < levels.length; i++) ...[
                        anchorFirst(
                          i,
                          kTutorialFirstItem,
                          _LevelCard(level: levels[i]),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          loading: () => const AppLoading(),
          error: (e, _) => Center(child: Text(s.failedToLoadLevels(e))),
        ),
      ),
    );
  }
}

class _LevelCard extends ConsumerWidget {
  final ChoukaiJlptLevelInfo level;

  const _LevelCard({required this.level});

  void _open(BuildContext context, AppStrings s, bool gateReached) {
    if (!level.available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.choukaiLevelComingSoon(level.name))),
      );
      return;
    }
    if (!gateReached) {
      final thisLevel = JlptLevelX.fromKey(level.id);
      final previousLevel =
          JlptLevel.values[JlptLevel.values.indexOf(thisLevel) - 1];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.choukaiLevelLockedReason(previousLevel.key))),
      );
      return;
    }
    AppNavigator.slideFromRight(
      context,
      ChoukaiLevelScreen(
        level: JlptLevelX.fromKey(level.id),
        levelName: level.name,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final thisLevel = JlptLevelX.fromKey(level.id);
    final gates = ref.watch(choukaiLevelGateProvider).valueOrNull;
    // While the gate is still loading, treat every level but N5 as locked
    // rather than briefly open, same reasoning Bab's own level gate
    // documents.
    final gateReached =
        gates?.firstWhere((g) => g.level == thisLevel).reachedByProgress ??
        (thisLevel == JlptLevel.n5);
    final available = level.available && gateReached;

    return ModuleLevelCard(
      badgeLabel: level.name,
      title: s.choukaiLevelTitle(level.name),
      subtitle: s.clipCount(level.clipCount ?? 0),
      // Same as Dokkai — no per-level completion concept to show a bar for.
      percent: null,
      available: available,
      soonLabel: level.available ? s.babLevelLockedBadge : s.soonBadge,
      accent: context.palette.primaryCoral,
      onTap: () => _open(context, s, gateReached),
    );
  }
}

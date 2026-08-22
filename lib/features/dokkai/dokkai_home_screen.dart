import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/mascot_advisor.dart';
import '../../core/widgets/mascot_widget.dart';
import '../../core/widgets/module_level_card.dart';
import '../../core/widgets/module_skyline_banner.dart';
import '../../core/widgets/module_title_plaque.dart';
import '../../data/models/dokkai_jlpt_level_info.dart';
import '../../data/models/jlpt_level.dart';
import 'dokkai_exam_screen.dart';
import 'dokkai_providers.dart';
import '../../core/widgets/app_loading.dart';
import '../../data/repositories/onboarding_repository.dart';
import '../../features/onboarding/coach_mark_tour.dart';
import '../../features/onboarding/first_visit_tutorial.dart';
import '../../features/onboarding/module_tours.dart';

/// Entry point for Dokkai (reading comprehension) within Ujian: JLPT level
/// picker, mirrors `KaiwaHomeScreen`/`BunpouHomeScreen`. Only levels with a
/// real passage set are tappable. Unlike every other browse-flow module in
/// this app, there is deliberately no intermediate passage-list screen —
/// tapping a level picks one random passage from it and opens the exam
/// directly, per an explicit product decision (Ujian is meant to feel like
/// "take a quiz now", not "browse a catalog").
class DokkaiHomeScreen extends ConsumerWidget {
  const DokkaiHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelsAsync = ref.watch(dokkaiLevelsProvider);
    final s = ref.watch(appStringsProvider);

    return FirstVisitTutorial(
      id: TutorialId.dokkai,
      tour: dokkaiTourSteps,
      child: Scaffold(
        backgroundColor: context.palette.background,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: context.palette.textNavy,
          title: const ModuleTitlePlaque(title: 'Dokkai'),
        ),
        body: levelsAsync.when(
          data: (levels) => MascotAdvisor(
            // Explaining, not reacting — this message tells the learner how
            // the screen (and the score-based level lock) works, same
            // MascotMood.explaining convention BabLevelScreen already uses.
            mood: MascotMood.explaining,
            message: s.dokkaiGuideMessage,
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
  final DokkaiJlptLevelInfo level;

  const _LevelCard({required this.level});

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    bool gateReached,
  ) async {
    final s = ref.read(appStringsProvider);
    if (!level.available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.dokkaiLevelComingSoon(level.name))),
      );
      return;
    }
    if (!gateReached) {
      final thisLevel = JlptLevelX.fromKey(level.id);
      final previousLevel =
          JlptLevel.values[JlptLevel.values.indexOf(thisLevel) - 1];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.dokkaiLevelLockedReason(previousLevel.key))),
      );
      return;
    }
    final passages = await ref.read(
      dokkaiByLevelProvider(JlptLevelX.fromKey(level.id)).future,
    );
    if (passages.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.noPassagesForLevel(level.name))));
      return;
    }
    // Shuffle the whole level pool and hand it all to DokkaiExamScreen,
    // which consumes passages in order and stops once it has enough
    // questions for one session (default 50) — a bigger pool here means
    // more session variety for free, no logic change needed as content
    // keeps growing.
    final shuffled = List.of(passages)..shuffle(Random());
    if (!context.mounted) return;
    AppNavigator.slideFromRight(context, DokkaiExamScreen(passages: shuffled));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final thisLevel = JlptLevelX.fromKey(level.id);
    final gates = ref.watch(dokkaiLevelGateProvider).valueOrNull;
    // While the gate is still loading, treat every level but N5 as locked
    // rather than briefly open, same reasoning Bab's own level gate
    // documents.
    final gateReached =
        gates?.firstWhere((g) => g.level == thisLevel).reachedByProgress ??
        (thisLevel == JlptLevel.n5);
    final available = level.available && gateReached;

    return ModuleLevelCard(
      badgeLabel: level.name,
      title: s.dokkaiLevelTitle(level.name),
      subtitle: s.dokkaiLevelSubtitle(
        level.passageCount ?? 0,
        DokkaiExamScreen.sessionQuestionTarget,
      ),
      // Dokkai has no learned/completed concept — every session is a fresh
      // random draw from the level's whole pool, so there's no percentage
      // to show, matching the reference design (count + session size only,
      // no progress bar).
      percent: null,
      available: available,
      soonLabel: level.available ? s.babLevelLockedBadge : s.soonBadge,
      accent: context.palette.primaryCoral,
      onTap: () => _open(context, ref, gateReached),
    );
  }
}

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../data/models/dokkai_jlpt_level_info.dart';
import '../../data/models/jlpt_level.dart';
import 'dokkai_exam_screen.dart';
import 'dokkai_providers.dart';

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

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: const Text('Dokkai')),
      body: levelsAsync.when(
        data: (levels) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            for (final level in levels) ...[
              _LevelCard(level: level),
              const SizedBox(height: 12),
            ],
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(s.failedToLoadLevels(e))),
      ),
    );
  }
}

class _LevelCard extends ConsumerWidget {
  final DokkaiJlptLevelInfo level;

  const _LevelCard({required this.level});

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final s = ref.read(appStringsProvider);
    if (!level.available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.dokkaiLevelComingSoon(level.name))),
      );
      return;
    }
    final passages = await ref.read(
      dokkaiByLevelProvider(JlptLevelX.fromKey(level.id)).future,
    );
    if (passages.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.noPassagesForLevel(level.name)),
        ),
      );
      return;
    }
    // Shuffle the whole level pool and hand it all to DokkaiExamScreen,
    // which consumes passages in order and stops once it has enough
    // questions for one session (default 50) — a bigger pool here means
    // more session variety for free, no logic change needed as content
    // keeps growing.
    final shuffled = List.of(passages)..shuffle(Random());
    if (!context.mounted) return;
    AppNavigator.slideFromRight(
      context,
      DokkaiExamScreen(passages: shuffled),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final available = level.available;

    return Material(
      color: available ? context.palette.cardWhite : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _open(context, ref),
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
                      s.dokkaiLevelTitle(level.name),
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
                        s.dokkaiLevelSubtitle(
                          level.passageCount ?? 0,
                          DokkaiExamScreen.sessionQuestionTarget,
                        ),
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

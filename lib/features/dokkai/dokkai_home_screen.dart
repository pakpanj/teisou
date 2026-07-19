import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/theme/app_colors.dart';
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

    return Scaffold(
      backgroundColor: AppColors.background,
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
        error: (e, _) => Center(child: Text('Gagal memuat level: $e')),
      ),
    );
  }
}

class _LevelCard extends ConsumerWidget {
  final DokkaiJlptLevelInfo level;

  const _LevelCard({required this.level});

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    if (!level.available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dokkai ${level.name} segera hadir!')),
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
          content: Text('Bacaan untuk Dokkai ${level.name} belum tersedia.'),
        ),
      );
      return;
    }
    final passage = passages[Random().nextInt(passages.length)];
    if (!context.mounted) return;
    AppNavigator.slideFromRight(context, DokkaiExamScreen(passage: passage));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = level.available;

    return Material(
      color: available ? AppColors.cardWhite : Colors.grey.shade100,
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
                      'Dokkai ${level.name}',
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
                        '${level.passageCount ?? 0} bacaan · acak setiap kali',
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
                        child: const Text(
                          'Segera',
                          style: TextStyle(
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

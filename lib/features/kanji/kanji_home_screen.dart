import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/theme/app_colors.dart';
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Kanji')),
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
  final KanjiLevel level;

  const _LevelCard({required this.level});

  void _open(BuildContext context) {
    if (!level.available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kanji ${level.name} segera hadir!')),
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
        ? ref.watch(kanjiLevelProgressProvider(JlptLevelX.fromKey(level.id))).valueOrNull
        : null;

    return Material(
      color: available ? AppColors.cardWhite : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: (available ? AppColors.primaryCoral : AppColors.freeBadgeGrey)
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  level.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: available ? AppColors.primaryCoral : AppColors.freeBadgeGrey,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kanji ${level.name}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: available ? AppColors.textNavy : AppColors.freeBadgeGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (available)
                      Text(
                        progress != null && progress.$1 > 0
                            ? '${progress.$1}/${progress.$2} dipelajari'
                            : '${level.kanjiCount ?? 0} kanji',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textNavy.withValues(alpha: 0.6),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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
                color: available ? AppColors.primaryCoral : AppColors.freeBadgeGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

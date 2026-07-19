import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/choukai_jlpt_level_info.dart';
import '../../data/models/jlpt_level.dart';
import 'choukai_level_screen.dart';
import 'choukai_providers.dart';

/// Entry point for Choukai (listening comprehension) within Ujian: JLPT
/// level picker, mirrors `DokkaiHomeScreen`. Every level currently shows
/// "Segera" — the architecture is ready (see `ChoukaiRepository`), content
/// hasn't been authored yet, same as Kaiwa's N4-N1 levels before they were.
class ChoukaiHomeScreen extends ConsumerWidget {
  const ChoukaiHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelsAsync = ref.watch(choukaiLevelsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Choukai')),
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

class _LevelCard extends StatelessWidget {
  final ChoukaiJlptLevelInfo level;

  const _LevelCard({required this.level});

  void _open(BuildContext context) {
    if (!level.available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Choukai ${level.name} segera hadir!')),
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
  Widget build(BuildContext context) {
    final available = level.available;

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
                      'Choukai ${level.name}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: available ? AppColors.textNavy : AppColors.freeBadgeGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (available)
                      Text(
                        '${level.clipCount ?? 0} klip',
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/jlpt_level.dart';
import 'kanji_combo_exam_screen.dart';
import 'kanji_combo_providers.dart';

/// Entry point for Kanji-Kombinasi within Ujian: a mode toggle (single
/// kanji vs. 2-3 kanji compound word) plus a JLPT level list. Unlike
/// Dokkai/Choukai, there's no intermediate "pick an item" screen — content
/// is generated on the fly from the existing Kanji/Kotoba datasets (see
/// `KanjiComboRepository`), so tapping an available level starts the exam
/// directly.
class KanjiComboHomeScreen extends ConsumerStatefulWidget {
  const KanjiComboHomeScreen({super.key});

  @override
  ConsumerState<KanjiComboHomeScreen> createState() => _KanjiComboHomeScreenState();
}

class _KanjiComboHomeScreenState extends ConsumerState<KanjiComboHomeScreen> {
  bool _combination = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Ujian Kanji')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Kanji Tunggal')),
                ButtonSegment(value: true, label: Text('Kombinasi Kanji')),
              ],
              selected: {_combination},
              onSelectionChanged: (selection) =>
                  setState(() => _combination = selection.first),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              children: [
                for (final level in JlptLevel.values) ...[
                  _LevelCard(level: level, combination: _combination),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelCard extends ConsumerWidget {
  final JlptLevel level;
  final bool combination;

  const _LevelCard({required this.level, required this.combination});

  void _open(BuildContext context, bool available) {
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${level.key} belum cukup data untuk mode ini.')),
      );
      return;
    }
    AppNavigator.slideFromRight(
      context,
      KanjiComboExamScreen(level: level, combination: combination),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableAsync =
        ref.watch(kanjiComboAvailabilityProvider((level, combination)));
    final available = availableAsync.valueOrNull ?? false;

    return Material(
      color: available ? AppColors.cardWhite : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _open(context, available),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: (available ? AppColors.tertiaryAmber : AppColors.freeBadgeGrey)
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  level.key,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: available ? AppColors.tertiaryAmber : AppColors.freeBadgeGrey,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  combination ? 'Kombinasi Kanji ${level.key}' : 'Kanji Tunggal ${level.key}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: available ? AppColors.textNavy : AppColors.freeBadgeGrey,
                  ),
                ),
              ),
              if (!available)
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
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: available ? AppColors.tertiaryAmber : AppColors.freeBadgeGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

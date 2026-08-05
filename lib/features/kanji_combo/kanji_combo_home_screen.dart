import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
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
    final s = ref.watch(appStringsProvider);
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: Text(s.kanjiComboExamTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text(s.examCategoryKanjiComboSingle),
                ),
                ButtonSegment(
                  value: true,
                  label: Text(s.examCategoryKanjiComboCombination),
                ),
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

  void _open(BuildContext context, AppStrings s, bool available) {
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.kanjiComboNotEnoughData(level.key))),
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
    final s = ref.watch(appStringsProvider);

    return Material(
      color: available ? context.palette.cardWhite : context.palette.mutedSurface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _open(context, s, available),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: (available ? context.palette.tertiaryAmber : context.palette.freeBadgeGrey)
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  level.key,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: available ? context.palette.tertiaryAmber : context.palette.freeBadgeGrey,
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
                    color: available ? context.palette.textNavy : context.palette.freeBadgeGrey,
                  ),
                ),
              ),
              if (!available)
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
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: available ? context.palette.tertiaryAmber : context.palette.freeBadgeGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

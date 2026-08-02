import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../kanji_combo/kanji_combo_home_screen.dart';
import 'kana_exam_mode_picker_screen.dart';

/// Top of the Ujian tab: a category picker (Kana / Kanji-Kombinasi). Kana
/// has no JLPT levels (it predates the level concept entirely — Batch 1),
/// so it still opens straight into its own 3-mode picker; Kanji-Kombinasi
/// needs a JLPT level first, so it opens its own level-picker home screen
/// instead of being flattened into one shared list.
///
/// Dokkai and Choukai used to be picker cards here too. Dokkai is reading-
/// *practice* material (500 real passages), not an exam — it now lives in
/// Home's "Latihan" section (`ModulesSection`) alongside Kaiwa instead.
/// Choukai is removed entirely for now, not just moved — it has zero
/// authored content (architecture-only, see CLAUDE.md), so showing it here
/// promised a category that does nothing yet. Re-add it once it has real
/// clips.
class ExamModePickerScreen extends ConsumerWidget {
  const ExamModePickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.exam), automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _CategoryCard(
              color: context.palette.primaryCoral,
              icon: Icons.text_fields,
              title: 'Kana',
              subtitle: s.kanaCategorySubtitle,
              onTap: () => AppNavigator.slideFromBottom(
                context,
                const KanaExamModePickerScreen(),
              ),
            ),
            const SizedBox(height: 16),
            _CategoryCard(
              color: context.palette.primaryCoral,
              icon: Icons.translate_rounded,
              title: 'Kanji',
              subtitle: s.kanjiComboCategorySubtitle,
              onTap: () => AppNavigator.slideFromBottom(
                context,
                const KanjiComboHomeScreen(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.palette.textNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.palette.textNavy.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

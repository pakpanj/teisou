import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../choukai/choukai_home_screen.dart';
import '../dokkai/dokkai_home_screen.dart';
import '../kanji_combo/kanji_combo_home_screen.dart';
import 'kana_exam_mode_picker_screen.dart';

/// Top of the Ujian tab: a category picker (Kana / Dokkai / Choukai /
/// Kanji-Kombinasi). Kana has no JLPT levels (it predates the level
/// concept entirely — Batch 1), so it still opens straight into its own
/// 3-mode picker; the other three each need a JLPT level first, so they
/// open their own level-picker home screen instead of being flattened into
/// one shared list.
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
              color: AppColors.primaryCoral,
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
              color: AppColors.secondaryBlue,
              icon: Icons.menu_book_rounded,
              title: 'Dokkai',
              subtitle: s.dokkaiCategorySubtitle,
              onTap: () => AppNavigator.slideFromBottom(
                context,
                const DokkaiHomeScreen(),
              ),
            ),
            const SizedBox(height: 16),
            _CategoryCard(
              color: AppColors.tertiaryAmber,
              icon: Icons.headphones_rounded,
              title: 'Choukai',
              subtitle: s.choukaiCategorySubtitle,
              onTap: () => AppNavigator.slideFromBottom(
                context,
                const ChoukaiHomeScreen(),
              ),
            ),
            const SizedBox(height: 16),
            _CategoryCard(
              color: AppColors.primaryCoral,
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textNavy.withValues(alpha: 0.6),
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

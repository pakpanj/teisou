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
/// Dokkai and Choukai used to be picker cards here too. Both are
/// *practice* material, not exams, so both now live in Home's own module
/// list (`ModulesSection`) instead — Dokkai (500 real passages) alongside
/// Kaiwa, Choukai (500 real clips, 100 per JLPT level, fully authored —
/// correction to a stale claim this comment used to make about it having
/// "zero authored content") with its own `ChoukaiHomeScreen`.
///
/// **JFT-Basic and JLPT (2026-08-31): entry points only, deliberately
/// locked.** Two real, distinct exam frameworks this app has never had a
/// dedicated mock-exam category for — JFT-Basic (used for Indonesia's
/// Specified Skilled Worker visa track) and a real JLPT N5-N1 mock exam
/// (as opposed to the JLPT *level* concept, which already organizes
/// Kanji/Bunpou/Bab everywhere else in this app, but was never itself a
/// standalone timed exam a learner could sit). Both ship as `_LockedCategoryCard`
/// — same "entry exists, tap explains why, via a SnackBar" contract this
/// codebase already used for Choukai before it had content and for Cam
/// Detector's own locked module card — with zero content authored behind
/// either yet. Authoring a real JFT-Basic/JLPT mock exam (question bank,
/// scoring, pass thresholds) is a separate, much larger task; this only
/// reserves the entry point so it doesn't need inserting again later.
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
            const SizedBox(height: 16),
            _LockedCategoryCard(
              icon: Icons.public,
              title: s.jftCategoryTitle,
              subtitle: s.jftCategorySubtitle,
              reason: s.jftCategoryLockedReason,
              badge: s.soonBadge,
            ),
            const SizedBox(height: 16),
            _LockedCategoryCard(
              icon: Icons.school,
              title: s.jlptCategoryTitle,
              subtitle: s.jlptCategorySubtitle,
              reason: s.jlptCategoryLockedReason,
              badge: s.soonBadge,
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

/// An exam entry that exists but has no content behind it yet — mirrors
/// `modules_section.dart`'s `_LockedModuleCard` exactly (same grey
/// `mutedSurface`/`freeBadgeGrey` palette, same "tap explains why, via a
/// SnackBar, instead of opening a dead screen" contract) rather than a
/// second private copy of that widget, since this screen has no shared
/// import path to it. JFT/JLPT are real, planned exam categories with no
/// authored content at all yet — this is deliberately just an entry
/// point + lock, not a stub screen, matching this task's own scope.
class _LockedCategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String reason;
  final String badge;

  const _LockedCategoryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.reason,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.mutedSurface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(reason))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.palette.freeBadgeGrey.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: context.palette.freeBadgeGrey),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: context.palette.textNavy,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: context.palette.freeBadgeGrey.withValues(
                              alpha: 0.2,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: context.palette.freeBadgeGrey,
                            ),
                          ),
                        ),
                      ],
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
              Icon(Icons.lock, color: context.palette.freeBadgeGrey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

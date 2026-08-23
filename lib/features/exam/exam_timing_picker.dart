import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/exam_timing.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';

/// Asks whether the exam about to start should run against a clock.
///
/// **One sheet shared by all four exams** (Kana, Kanji, Dokkai, Choukai)
/// rather than a switch on each start screen: the four are opened from
/// four different places, and a per-screen control would have drifted into
/// four slightly different questions. It also keeps the choice where it
/// belongs — immediately before the paper starts, not buried in settings
/// where nobody would find it.
///
/// Returns null when the learner backs out, which means no exam should
/// start at all.
Future<ExamTiming?> showExamTimingPicker(
  BuildContext context, {
  required ExamKind kind,
  required int questionCount,
}) {
  return showModalBottomSheet<ExamTiming>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) =>
        _TimingSheet(kind: kind, questionCount: questionCount),
  );
}

class _TimingSheet extends ConsumerWidget {
  const _TimingSheet({required this.kind, required this.questionCount});

  final ExamKind kind;
  final int questionCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final palette = context.palette;
    final limit = examTimeLimit(kind, questionCount);
    // Rounded up: a paper worth 2 minutes 30 is offered as "3 minutes"
    // rather than "2", so the number shown is never less than the time
    // actually given.
    final minutes = (limit.inSeconds / 60).ceil();

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: palette.cardWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: palette.textNavy.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              s.examTimingTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: palette.textNavy,
              ),
            ),
            const SizedBox(height: 16),
            _TimingCard(
              icon: Icons.timer_outlined,
              colour: palette.primaryCoral,
              title: s.examTimedTitle,
              subtitle: s.examTimedSubtitle(minutes),
              onTap: () => Navigator.of(context).pop(ExamTiming.timed),
            ),
            const SizedBox(height: 12),
            _TimingCard(
              icon: Icons.self_improvement,
              colour: palette.secondaryBlue,
              title: s.examUntimedTitle,
              subtitle: s.examUntimedSubtitle,
              onTap: () => Navigator.of(context).pop(ExamTiming.untimed),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimingCard extends StatelessWidget {
  const _TimingCard({
    required this.icon,
    required this.colour,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color colour;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: colour.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colour,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: palette.textNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: palette.textNavy.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

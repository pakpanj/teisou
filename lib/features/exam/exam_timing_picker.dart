import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/exam_timing.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';

/// What the learner chose before the paper starts: whether there is a
/// clock, and how long each question gets.
class ExamTimingChoice {
  const ExamTimingChoice.untimed() : perQuestion = null;
  const ExamTimingChoice.timed(Duration this.perQuestion);

  /// Null for an untimed run.
  final Duration? perQuestion;
}

/// Asks whether the exam should run against a clock, and at what pace.
///
/// **One sheet shared by all four exams** (Kana, Kanji, Dokkai, Choukai)
/// rather than a control on each start screen: the four are opened from
/// four different places, and a per-screen version would have drifted
/// into four slightly different questions. It also keeps the choice where
/// it belongs — immediately before the paper starts, not buried in
/// settings where nobody would find it.
///
/// The pace is picked by the learner rather than fixed per exam kind. A
/// number chosen for "a Dokkai question takes about a minute" is right
/// for the average learner and wrong for everyone else; the exam kind now
/// only decides where the picker *starts*.
///
/// Returns null when the learner backs out, which means no exam should
/// start at all.
Future<ExamTimingChoice?> showExamTimingPicker(
  BuildContext context, {
  required ExamKind kind,
}) {
  return showModalBottomSheet<ExamTimingChoice>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _TimingSheet(kind: kind),
  );
}

class _TimingSheet extends ConsumerStatefulWidget {
  const _TimingSheet({required this.kind});

  final ExamKind kind;

  @override
  ConsumerState<_TimingSheet> createState() => _TimingSheetState();
}

class _TimingSheetState extends ConsumerState<_TimingSheet> {
  late int _seconds = examDefaultSecondsPerQuestion(widget.kind);

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final palette = context.palette;

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.textNavy.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                s.examTimingTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: palette.textNavy,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _Heading(icon: Icons.timer_outlined, text: s.examTimedTitle),
            const SizedBox(height: 4),
            Text(
              s.examTimedSubtitle,
              style: TextStyle(
                fontSize: 13,
                height: 1.3,
                color: palette.textNavy.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              s.examPerQuestionLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: palette.textNavy.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final choice in kExamPerQuestionChoices)
                  _SecondsChip(
                    label: s.examSecondsShort(choice),
                    selected: choice == _seconds,
                    onTap: () => setState(() => _seconds = choice),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: palette.primaryCoral,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.of(
                  context,
                ).pop(ExamTimingChoice.timed(Duration(seconds: _seconds))),
                child: Text(
                  s.examStartTimed(_seconds),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Divider(color: palette.divider, height: 1),
            const SizedBox(height: 16),
            _UntimedCard(
              onTap: () =>
                  Navigator.of(context).pop(const ExamTimingChoice.untimed()),
            ),
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: [
        Icon(icon, size: 20, color: palette.primaryCoral),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: palette.textNavy,
          ),
        ),
      ],
    );
  }
}

class _SecondsChip extends StatelessWidget {
  const _SecondsChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: selected
          ? palette.primaryCoral
          : palette.primaryCoral.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : palette.textNavy,
            ),
          ),
        ),
      ),
    );
  }
}

class _UntimedCard extends ConsumerWidget {
  const _UntimedCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final palette = context.palette;
    return Material(
      color: palette.secondaryBlue.withValues(alpha: 0.12),
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
                  color: palette.secondaryBlue,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.self_improvement, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.examUntimedTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: palette.textNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.examUntimedSubtitle,
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

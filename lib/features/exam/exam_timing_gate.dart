import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/exam_timing.dart';
import 'exam_timing_picker.dart';

/// Asks for the timing mode once, then builds the exam with it.
///
/// **Asked here rather than on the screen that opens the exam** because
/// only this side knows how many questions there are: Dokkai, Choukai and
/// Kanji-Kombinasi all size their paper from content that is still
/// loading when the previous screen is tapped, and the sheet quotes the
/// budget in minutes. Kana is the exception and asks earlier — its paper
/// is always [ExamRepository.questionsPerExam] questions, so the number is
/// known before anything loads.
///
/// Backing out of the sheet leaves the exam entirely. A learner who
/// dismissed it has said they do not want to sit this paper, and dropping
/// them into an untimed run instead would be answering for them.
class ExamTimingGate extends ConsumerStatefulWidget {
  const ExamTimingGate({
    super.key,
    required this.kind,
    required this.questionCount,
    required this.builder,
  });

  final ExamKind kind;
  final int questionCount;

  /// Builds the exam. `limit` is null for an untimed run.
  final Widget Function(BuildContext context, Duration? limit) builder;

  @override
  ConsumerState<ExamTimingGate> createState() => _ExamTimingGateState();
}

class _ExamTimingGateState extends ConsumerState<ExamTimingGate> {
  ExamTiming? _timing;

  /// Guards against asking twice. `build` runs again for every unrelated
  /// rebuild underneath — a provider settling, a theme change — and
  /// without this each one would stack another sheet.
  bool _asked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ask());
  }

  Future<void> _ask() async {
    if (_asked || !mounted) return;
    _asked = true;
    final choice = await showExamTimingPicker(
      context,
      kind: widget.kind,
      questionCount: widget.questionCount,
    );
    if (!mounted) return;
    if (choice == null) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _timing = choice);
  }

  @override
  Widget build(BuildContext context) {
    final timing = _timing;
    // Nothing until the choice is made: starting the paper behind the
    // sheet would run a clock the learner has not agreed to yet, and on
    // Choukai it would start the audio too.
    if (timing == null) return const SizedBox.shrink();
    return widget.builder(
      context,
      timing == ExamTiming.timed
          ? examTimeLimit(widget.kind, widget.questionCount)
          : null,
    );
  }
}

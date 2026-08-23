import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/exam_timing.dart';
import 'exam_timing_picker.dart';

/// Asks for the timing mode once, then builds the exam with it.
///
/// Asked here, right before the paper starts, rather than back on
/// whichever screen opened it — so the answer is never stale by the time
/// the questions appear, and so Choukai's audio does not begin before the
/// learner has agreed to a clock.
///
/// Backing out of the sheet leaves the exam entirely. A learner who
/// dismissed it has said they do not want to sit this paper, and dropping
/// them into an untimed run instead would be answering for them.
class ExamTimingGate extends ConsumerStatefulWidget {
  const ExamTimingGate({super.key, required this.kind, required this.builder});

  final ExamKind kind;

  /// Builds the exam. `limit` is null for an untimed run.
  final Widget Function(BuildContext context, Duration? limit) builder;

  @override
  ConsumerState<ExamTimingGate> createState() => _ExamTimingGateState();
}

class _ExamTimingGateState extends ConsumerState<ExamTimingGate> {
  ExamTimingChoice? _choice;

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
    final choice = await showExamTimingPicker(context, kind: widget.kind);
    if (!mounted) return;
    if (choice == null) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _choice = choice);
  }

  @override
  Widget build(BuildContext context) {
    final choice = _choice;
    // Nothing until the choice is made: starting the paper behind the
    // sheet would run a clock the learner has not agreed to yet, and on
    // Choukai it would start the audio too.
    if (choice == null) return const SizedBox.shrink();
    return widget.builder(context, choice.perQuestion);
  }
}

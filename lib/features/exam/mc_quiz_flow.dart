import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/services/mascot_coach.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/mascot_companion.dart';

/// Shared "N multiple-choice questions, one at a time, tap to reveal
/// correct/wrong, Next button, tally a score" flow for Dokkai/Choukai/
/// Kanji-Kombinasi — mirrors `ExamScreen`'s `_OptionTile` visuals but
/// generalized over index-based options instead of the kana model's
/// romaji-string comparisons, and over a caller-supplied header per
/// question (a passage card, an audio-replay button, a kanji glyph, ...)
/// instead of one fixed kana-character display.
class McQuizFlow extends ConsumerStatefulWidget {
  final int totalQuestions;
  final Widget Function(BuildContext context, int index) headerBuilder;
  final List<String> Function(int index) optionsOf;
  final int Function(int index) correctIndexOf;
  final void Function(int score, int total) onComplete;

  const McQuizFlow({
    super.key,
    required this.totalQuestions,
    required this.headerBuilder,
    required this.optionsOf,
    required this.correctIndexOf,
    required this.onComplete,
  });

  @override
  ConsumerState<McQuizFlow> createState() => _McQuizFlowState();
}

class _McQuizFlowState extends ConsumerState<McQuizFlow> {
  int _index = 0;
  int? _selected;
  int _score = 0;

  /// Held by the state, not rebuilt per frame: it remembers the run of
  /// correct answers and what it said last, and both would reset on every
  /// rebuild if it were created in `build`.
  final MascotCoach _coach = MascotCoach();

  /// What the mascot is saying about the answer just given, or null while
  /// the question is still unanswered.
  CoachLine? _reaction;

  void _select(int optionIndex) {
    if (_selected != null) return;
    final correctIndex = widget.correctIndexOf(_index);
    final correct = optionIndex == correctIndex;
    if (correct) _score++;

    final options = widget.optionsOf(_index);
    setState(() {
      _selected = optionIndex;
      _reaction = _coach.onAnswer(
        ref.read(appStringsProvider),
        correct: correct,
        // Guarded rather than indexed straight: a caller whose
        // correctIndexOf disagrees with its own options list would
        // otherwise take the whole quiz down mid-question.
        correctAnswer: correctIndex >= 0 && correctIndex < options.length
            ? options[correctIndex]
            : '',
      );
    });
  }

  void _next() {
    final isLast = _index >= widget.totalQuestions - 1;
    if (isLast) {
      widget.onComplete(_score, widget.totalQuestions);
      return;
    }
    setState(() {
      _index++;
      _selected = null;
      // Cleared with the question: a reaction left standing would be
      // praising the previous answer over the next question.
      _reaction = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.optionsOf(_index);
    final correctIndex = widget.correctIndexOf(_index);
    final s = ref.watch(appStringsProvider);

    return Column(
      children: [
        LinearProgressIndicator(
          value: (_index + 1) / widget.totalQuestions,
          backgroundColor: context.palette.primaryCoral.withValues(alpha: 0.15),
          color: context.palette.primaryCoral,
          minHeight: 6,
        ),
        const SizedBox(height: 12),
        Text(
          s.questionOf(_index + 1, widget.totalQuestions),
          style: TextStyle(
            color: context.palette.textNavy,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                widget.headerBuilder(context, _index),
                const SizedBox(height: 24),
                for (var i = 0; i < options.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OptionTile(
                      label: options[i],
                      index: i,
                      selectedIndex: _selected,
                      correctIndex: correctIndex,
                      onTap: () => _select(i),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        // Between the options and the Next button, where it is next to
        // the thing it is reacting to and still cannot cover either.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: MascotCompanion(line: _reaction),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selected == null ? null : _next,
              child: Text(
                _index >= widget.totalQuestions - 1
                    ? s.done
                    : s.nextQuestionButton,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum _OptionState { neutral, correct, wrong }

class _OptionTile extends StatelessWidget {
  final String label;
  final int index;
  final int? selectedIndex;
  final int correctIndex;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.correctIndex,
    required this.onTap,
  });

  _OptionState get _state {
    if (selectedIndex == null) return _OptionState.neutral;
    if (index == correctIndex) return _OptionState.correct;
    if (index == selectedIndex) return _OptionState.wrong;
    return _OptionState.neutral;
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final answered = selectedIndex != null;

    Color background;
    Color foreground;
    Widget? trailing;

    switch (state) {
      case _OptionState.correct:
        background = context.palette.successGreen;
        foreground = Colors.white;
        trailing = const Icon(Icons.check_circle, color: Colors.white);
        break;
      case _OptionState.wrong:
        background = context.palette.errorRed;
        foreground = Colors.white;
        trailing = const Icon(Icons.cancel, color: Colors.white);
        break;
      case _OptionState.neutral:
        background = answered
            ? context.palette.cardWhite.withValues(alpha: 0.6)
            : context.palette.cardWhite;
        foreground = context.palette.textNavy;
        trailing = null;
        break;
    }

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: answered ? null : onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: state == _OptionState.neutral
                  ? context.palette.progressTrack
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

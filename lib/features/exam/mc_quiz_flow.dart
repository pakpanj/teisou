import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/services/furigana_dictionary.dart';
import '../../core/services/mascot_coach.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/furigana_text.dart';
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

  /// Whether options should be annotated with furigana — the caller
  /// decides this from its own JLPT level via `showFuriganaFor` (see
  /// `furigana_text.dart`), since this widget has no level of its own.
  /// Harmless when the options aren't kanji-bearing Japanese text (e.g.
  /// Kanji-Kombinasi's Indonesian meaning options, or pure-kana reading
  /// options) — `FuriganaSentence` only annotates kanji runs it
  /// recognizes, so a run with none just renders as plain text either way.
  final bool showFurigana;

  const McQuizFlow({
    super.key,
    required this.totalQuestions,
    required this.headerBuilder,
    required this.optionsOf,
    required this.correctIndexOf,
    required this.onComplete,
    this.showFurigana = false,
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

  final Random _random = Random();

  /// Per-question display order for [optionsOf]'s options — a permutation
  /// of their original indices, computed once the first time that question
  /// is shown and cached here, not recomputed on every rebuild (same
  /// "shuffle once per turn" reasoning as `KaiwaDialogueScreen._optionOrder`
  /// — recomputing on every `setState` would make the tiles visibly jump
  /// position after every tap). Needed because several content sources
  /// wired through this widget (Dokkai, Choukai) always author the correct
  /// answer at the same fixed position — `optionsOf`/`correctIndexOf` are
  /// rendered exactly as given, so without this the on-screen answer order
  /// would just replay that authoring bias back to the learner.
  final Map<int, List<int>> _displayOrder = {};

  List<int> _orderFor(int questionIndex, int optionCount) {
    return _displayOrder.putIfAbsent(
      questionIndex,
      () => List<int>.generate(optionCount, (i) => i)..shuffle(_random),
    );
  }

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
    final order = _orderFor(_index, options.length);
    final s = ref.watch(appStringsProvider);
    final furiganaDictionary = widget.showFurigana
        ? ref.watch(furiganaDictionaryProvider).valueOrNull
        : null;

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
                // Rendered in the shuffled display order, but each tile
                // still carries its ORIGINAL index (for `label`, `index`,
                // and `onTap`) — that's what `correctIndex`/`_selected`
                // compare against, so the correct/wrong logic below needs
                // no changes at all, only the on-screen order changes.
                for (final i in order)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OptionTile(
                      label: options[i],
                      index: i,
                      selectedIndex: _selected,
                      correctIndex: correctIndex,
                      onTap: () => _select(i),
                      furiganaDictionary: furiganaDictionary,
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
  final FuriganaDictionary? furiganaDictionary;

  const _OptionTile({
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.correctIndex,
    required this.onTap,
    this.furiganaDictionary,
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
    Color borderColor;
    Widget? trailing;

    // A wash of colour behind the answer with a matching outline, rather
    // than a solid fill — the same treatment the Kanji/Kotoba/Bunpou/
    // Partikel quizzes already use, so the four flows that come through
    // here stop being the odd ones out.
    //
    // Blue for the right answer, not green. A solid red-vs-green pair is
    // the one contrast a red-green colourblind learner cannot separate,
    // and with white-on-solid text there was nothing else to go on. Blue
    // against red stays distinguishable, and the icons and the outline
    // give a second cue that does not rely on hue at all.
    switch (state) {
      case _OptionState.correct:
        background = context.palette.secondaryBlue.withValues(alpha: 0.15);
        borderColor = context.palette.secondaryBlue;
        foreground = context.palette.textNavy;
        trailing = Icon(Icons.check_circle,
            color: context.palette.secondaryBlue, size: 20);
        break;
      case _OptionState.wrong:
        background = context.palette.errorRed.withValues(alpha: 0.12);
        borderColor = context.palette.errorRed;
        foreground = context.palette.textNavy;
        trailing =
            Icon(Icons.cancel, color: context.palette.errorRed, size: 20);
        break;
      case _OptionState.neutral:
        background = context.palette.cardWhite;
        borderColor = context.palette.progressTrack;
        // Dimmed once the question is settled, so the options nobody
        // picked recede instead of competing with the two that matter.
        foreground = answered
            ? context.palette.textNavy.withValues(alpha: 0.4)
            : context.palette.textNavy;
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
              color: borderColor,
              width: state == _OptionState.neutral ? 1 : 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: furiganaDictionary != null
                    ? FuriganaSentence(
                        text: label,
                        dictionary: furiganaDictionary!,
                        style: TextStyle(
                          color: foreground,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    : Text(
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

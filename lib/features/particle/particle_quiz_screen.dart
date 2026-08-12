import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/services/mascot_coach.dart';
import '../../core/widgets/mascot_companion.dart';
import '../../data/models/cloze_example.dart';
import '../../data/models/particle_entry.dart';
import '../../data/models/quiz_review_entry.dart';
import '../exam/quiz_review_screen.dart';

/// Fill-in-the-blank ("cloze") mini-game over one category's particles:
/// shown a sentence with the particle blanked out, pick the correct
/// particle from 4 options. Unlike Bunpou's quiz (pattern↔meaning
/// matching, two modes), this only has one mode — there's no
/// mode-picker sheet on the way in. Standalone practice tool — quiz
/// results don't affect the "Sudah Dipelajari" marks from the detail
/// screen.
class ParticleQuizScreen extends ConsumerStatefulWidget {
  final String categoryName;
  final List<ParticleEntry> entries;

  const ParticleQuizScreen({
    super.key,
    required this.categoryName,
    required this.entries,
  });

  @override
  ConsumerState<ParticleQuizScreen> createState() => _ParticleQuizScreenState();
}

class _QuizQuestion {
  final ClozeExample cloze;
  final String correctParticle;
  final List<String> options;
  final int correctIndex;

  _QuizQuestion({
    required this.cloze,
    required this.correctParticle,
    required this.options,
    required this.correctIndex,
  });
}

class _ParticleQuizScreenState extends ConsumerState<ParticleQuizScreen> {
  static const _questionCount = 10;

  late final List<_QuizQuestion> _questions = _buildQuestions();
  int _index = 0;
  int _score = 0;
  int? _selected;
  final List<QuizReviewEntry> _wrongAnswers = [];

  /// Held here rather than built in `build`: it remembers the run of
  /// correct answers, which a per-frame instance would silently reset.
  final MascotCoach _coach = MascotCoach();

  /// What the mascot is saying about the answer just given, or null while
  /// the question is unanswered.
  CoachLine? _reaction;

  List<_QuizQuestion> _buildQuestions() {
    final random = Random();

    final pool = <(ClozeExample, String)>[];
    for (final entry in widget.entries) {
      for (final fn in entry.functions) {
        for (final cloze in fn.clozeExamples) {
          pool.add((cloze, entry.particle));
        }
      }
    }
    pool.shuffle(random);
    final chosen = pool.take(min(_questionCount, pool.length)).toList();

    final allParticles = widget.entries.map((e) => e.particle).toSet();

    return chosen.map((pair) {
      final (cloze, ownerParticle) = pair;
      final distractorPool = allParticles.where((p) => p != ownerParticle).toList()
        ..shuffle(random);
      final distractors = distractorPool.take(3);
      final options = [ownerParticle, ...distractors]..shuffle(random);
      return _QuizQuestion(
        cloze: cloze,
        correctParticle: ownerParticle,
        options: options,
        correctIndex: options.indexOf(ownerParticle),
      );
    }).toList();
  }

  void _select(int optionIndex) {
    if (_selected != null) return;
    final question = _questions[_index];
    final correct = optionIndex == question.correctIndex;
    // Guarded rather than indexed straight, so a question whose
    // correctIndex disagreed with its own options list could not take the
    // quiz down mid-answer.
    final correctAnswer = question.correctIndex >= 0 &&
            question.correctIndex < question.options.length
        ? question.options[question.correctIndex]
        : '';
    setState(() {
      _selected = optionIndex;
      if (correct) {
        _score++;
      } else {
        _wrongAnswers.add(QuizReviewEntry(
          question:
              '${question.cloze.sentenceBefore} ___ ${question.cloze.sentenceAfter}',
          userAnswer: question.options[optionIndex],
          correctAnswer: correctAnswer,
        ));
      }
      _reaction = _coach.onAnswer(
        ref.read(appStringsProvider),
        correct: correct,
        correctAnswer: correctAnswer,
      );
    });
  }

  void _next() {
    if (_index >= _questions.length - 1) {
      setState(() => _index = _questions.length);
      return;
    }
    setState(() {
      _index++;
      _selected = null;
      // Cleared with the question: a reaction left standing would be
      // praising the previous answer over the next one.
      _reaction = null;
    });
  }

  void _restart() {
    setState(() {
      _questions
        ..clear()
        ..addAll(_buildQuestions());
      _index = 0;
      _score = 0;
      _selected = null;
      _reaction = null;
      _wrongAnswers.clear();
      _coach.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final finished = _index >= _questions.length;
    final s = ref.watch(appStringsProvider);
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: Text(s.particleQuizTitle(widget.categoryName))),
      body: SafeArea(
        child: finished
            ? _ResultView(
                score: _score,
                total: _questions.length,
                strings: s,
                onRestart: _restart,
                wrongAnswers: _wrongAnswers,
              )
            : _buildQuestion(s),
      ),
    );
  }

  Widget _buildQuestion(AppStrings s) {
    final question = _questions[_index];
    final cloze = question.cloze;
    final answered = _selected != null;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.questionOf(_index + 1, _questions.length),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: context.palette.textNavy.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_index) / _questions.length,
              minHeight: 6,
              backgroundColor: context.palette.progressTrack,
              valueColor: AlwaysStoppedAnimation(context.palette.primaryCoral),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            s.whichParticleFits,
            style: TextStyle(fontSize: 14, color: context.palette.textNavy.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(
              color: context.palette.cardWhite,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Column(
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: cloze.sentenceBefore,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: context.palette.textNavy,
                        ),
                      ),
                      TextSpan(
                        text: ' ___ ',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: context.palette.primaryCoral,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      TextSpan(
                        text: cloze.sentenceAfter,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: context.palette.textNavy,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                if (cloze.romaji != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    cloze.romaji!,
                    style: TextStyle(fontSize: 13, color: context.palette.textNavy.withValues(alpha: 0.6)),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  cloze.localizedTranslation(s.language),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: context.palette.textNavy.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: question.options.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _OptionTile(
                text: question.options[i],
                state: !answered
                    ? _OptionState.neutral
                    : i == question.correctIndex
                        ? _OptionState.correct
                        : i == _selected
                            ? _OptionState.wrong
                            : _OptionState.disabled,
                onTap: () => _select(i),
              ),
            ),
          ),
          // Between the options and the way forward, where it is beside
          // what it is reacting to and cannot cover either.
          MascotCompanion(line: _reaction),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: answered ? _next : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.palette.primaryCoral,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(_index >= _questions.length - 1 ? s.seeScore : s.continueLabel),
            ),
          ),
        ],
      ),
    );
  }
}

enum _OptionState { neutral, correct, wrong, disabled }

class _OptionTile extends StatelessWidget {
  final String text;
  final _OptionState state;
  final VoidCallback onTap;

  const _OptionTile({
    required this.text,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color background;
    Color textColor = context.palette.textNavy;
    Color borderColor = Colors.transparent;
    IconData? icon;

    switch (state) {
      case _OptionState.neutral:
        background = context.palette.cardWhite;
      case _OptionState.correct:
        background = context.palette.secondaryBlue.withValues(alpha: 0.15);
        borderColor = context.palette.secondaryBlue;
        icon = Icons.check_circle;
      case _OptionState.wrong:
        background = context.palette.errorRed.withValues(alpha: 0.12);
        borderColor = context.palette.errorRed;
        icon = Icons.cancel;
      case _OptionState.disabled:
        background = context.palette.cardWhite;
        textColor = context.palette.textNavy.withValues(alpha: 0.4);
    }

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: state == _OptionState.neutral ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(fontSize: 20, color: textColor),
                ),
              ),
              if (icon != null)
                Icon(
                  icon,
                  size: 20,
                  color: state == _OptionState.correct ? context.palette.secondaryBlue : context.palette.errorRed,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final int score;
  final int total;
  final AppStrings strings;
  final VoidCallback onRestart;
  final List<QuizReviewEntry> wrongAnswers;

  const _ResultView({
    required this.score,
    required this.total,
    required this.strings,
    required this.onRestart,
    required this.wrongAnswers,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : score / total;
    final message = ratio >= 0.8
        ? strings.resultExcellent
        : ratio >= 0.5
            ? strings.resultGood
            : strings.reviewParticlesAgain;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.palette.textNavy),
          ),
          const SizedBox(height: 8),
          Text(
            strings.scoreOf(score, total),
            style: TextStyle(fontSize: 15, color: context.palette.textNavy.withValues(alpha: 0.7)),
          ),
          if (wrongAnswers.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => QuizReviewScreen(entries: wrongAnswers),
                  ),
                ),
                child: Text(strings.reviewMistakesButton),
              ),
            ),
          ],
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(strings.finish),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onRestart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.palette.primaryCoral,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(strings.retry),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

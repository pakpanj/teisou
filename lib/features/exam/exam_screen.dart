import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/services/mascot_coach.dart';
import '../../core/widgets/mascot_companion.dart';
import '../../data/models/exam_mode.dart';
import '../../data/models/exam_question.dart';
import '../../data/models/quiz_review_entry.dart';
import '../../data/models/user_profile.dart' show AvatarType;
import '../exam_result/exam_result_screen.dart';
import '../profile/exam_history_providers.dart';
import 'exam_providers.dart';
import '../../core/widgets/app_loading.dart';
import 'exam_countdown.dart';

class ExamScreen extends ConsumerStatefulWidget {
  final ExamMode mode;

  /// How long the whole paper gets, or null for an untimed run — see
  /// [examTimeLimit]. When it runs out the exam is submitted as it
  /// stands, with everything unanswered counting as wrong.
  final Duration? timeLimit;

  const ExamScreen({super.key, required this.mode, this.timeLimit});

  @override
  ConsumerState<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends ConsumerState<ExamScreen> {
  int _currentIndex = 0;
  String? _selectedAnswer;

  /// Whether [_selectedAnswer] has been confirmed and graded. Until it is,
  /// the learner can change their pick — tapping used to be the commit,
  /// which made a mis-tap unrecoverable.
  bool _committed = false;
  final List<AnsweredQuestion> _answers = [];
  bool _submitting = false;

  /// Set once the paper has been handed in, by either route. Without it
  /// the clock expiring just as the last Next is pressed would submit
  /// twice.
  bool _finished = false;

  /// Held here, not built in `build`, so the run of correct answers
  /// survives rebuilds.
  final MascotCoach _coach = MascotCoach();

  /// What the mascot is saying about the answer just given, or null while
  /// the question is unanswered.
  CoachLine? _reaction;

  @override
  void initState() {
    super.initState();
    // Preload in the background so it's ready by the time ExamResultScreen
    // wants to show it — no visible loading delay, no ad shown here.
    ref.read(adServiceProvider).preloadInterstitial();
  }

  void _selectAnswer(String answer, ExamQuestion question) {
    if (_committed) return;
    setState(() => _selectedAnswer = answer);
  }

  /// Grades the chosen answer and reveals which option was right.
  void _confirm(ExamQuestion question) {
    final answer = _selectedAnswer;
    if (answer == null || _committed) return;
    setState(() {
      _committed = true;
      // The screen already reveals which option was right the moment one
      // is tapped, so the mascot adds encouragement here, not information
      // the exam was withholding.
      _reaction = _coach.onAnswer(
        ref.read(appStringsProvider),
        correct: answer == question.correctAnswer,
        correctAnswer: question.correctAnswer,
      );
    });
  }

  Future<void> _handleNext(List<ExamQuestion> questions) async {
    final selected = _selectedAnswer;
    if (selected == null) return;

    final answered = AnsweredQuestion(
      question: questions[_currentIndex],
      selectedAnswer: selected,
    );
    _answers.add(answered);

    final isLast = _currentIndex >= questions.length - 1;
    if (!isLast) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _committed = false;
        // Cleared with the question, or it would be praising the previous
        // answer over the next one.
        _reaction = null;
      });
      return;
    }

    await _submit(questions);
  }

  /// Hands the paper in early because the clock ran out.
  ///
  /// Every question not yet answered is recorded with an empty answer,
  /// which grades as wrong — including the one on screen. Scoring only
  /// what was reached would mean running out of time *improves* the
  /// percentage, which would make the timed mode the easy one.
  Future<void> _timeUp(List<ExamQuestion> questions) async {
    if (_finished || _submitting) return;
    for (var i = _answers.length; i < questions.length; i++) {
      _answers.add(
        AnsweredQuestion(question: questions[i], selectedAnswer: ''),
      );
    }
    await _submit(questions);
  }

  Future<void> _submit(List<ExamQuestion> questions) async {
    if (_finished) return;
    _finished = true;
    setState(() => _submitting = true);
    final s = ref.read(appStringsProvider);
    final user = ref.read(appStartupProvider).valueOrNull;
    if (user == null) {
      _finished = false;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.failedToSaveExamResult)));
      return;
    }

    final profile = ref.read(userProfileProvider).valueOrNull;
    try {
      final result = await ref
          .read(examRepositoryProvider)
          .submitExam(
            uid: user.uid,
            mode: widget.mode,
            answers: _answers,
            displayName:
                profile?.resolveDisplayName(user) ??
                (user.displayName ?? s.defaultLearnerName),
            photoUrl: user.photoURL,
            avatarType: profile?.avatarType ?? AvatarType.google,
            avatarValue: profile?.avatarValue,
          );

      // Invalidate rather than rely on autoDispose alone: Profile's exam
      // history section stays alive via AutomaticKeepAliveClientMixin (it's
      // a Home-tab sibling, never truly disposed while the app runs), so
      // fullExamHistoryProvider's watcher count never drops to zero and it
      // never naturally refetches on its own — confirmed by an on-device
      // test where a freshly submitted exam didn't appear in either the
      // mini-list or the full history screen until this invalidation was
      // added. See CLAUDE.md's exam-history-screen fix update for detail.
      ref.invalidate(fullExamHistoryProvider);
      await ref.read(progressRepositoryProvider).addXp(user.uid, 10);
      ref.invalidate(xpProgressProvider);

      if (!mounted) return;
      final wrongAnswers = _answers
          .where((a) => !a.isCorrect)
          .map(
            (a) => QuizReviewEntry(
              question: a.question.kana.character,
              userAnswer: a.selectedAnswer,
              correctAnswer: a.question.correctAnswer,
            ),
          )
          .toList();
      AppNavigator.replaceFadeScale(
        context,
        ExamResultScreen(result: result, wrongAnswers: wrongAnswers),
      );
    } catch (_) {
      if (!mounted) return;
      // Let them try again: the paper is not lost just because the write
      // failed.
      _finished = false;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.failedToSaveExamResult)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(examQuestionsProvider(widget.mode));
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.mode.title)),
      body: questionsAsync.when(
        data: (questions) {
          if (questions.isEmpty) {
            return Center(child: Text(s.noQuestionsAvailable));
          }
          final question = questions[_currentIndex];
          final total = questions.length;

          return Column(
            children: [
              LinearProgressIndicator(
                value: (_currentIndex + 1) / total,
                backgroundColor: context.palette.primaryCoral.withValues(
                  alpha: 0.15,
                ),
                color: context.palette.primaryCoral,
                minHeight: 6,
              ),
              if (widget.timeLimit != null)
                ExamCountdown(
                  limit: widget.timeLimit!,
                  onExpired: () => _timeUp(questions),
                ),
              const SizedBox(height: 12),
              Text(
                s.questionOf(_currentIndex + 1, total),
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
                      Text(
                        s.whatIsThisCharacterReading,
                        style: TextStyle(
                          fontSize: 16,
                          color: context.palette.textNavy,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        decoration: BoxDecoration(
                          color: context.palette.cardWhite,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            question.kana.character,
                            style: TextStyle(
                              fontSize: 72,
                              fontWeight: FontWeight.bold,
                              color: context.palette.textNavy,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ...question.options.map(
                        (option) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _OptionTile(
                            label: option,
                            selectedAnswer: _selectedAnswer,
                            committed: _committed,
                            correctAnswer: question.correctAnswer,
                            onTap: () => _selectAnswer(option, question),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: MascotCompanion(line: _reaction),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedAnswer == null || _submitting
                        ? null
                        : (_committed
                              ? () => _handleNext(questions)
                              : () => _confirm(question)),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _committed
                                ? s.nextQuestionButton
                                : s.checkAnswerButton,
                          ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const AppLoading(),
        error: (e, _) => Center(child: Text(s.failedToLoadQuestions(e))),
      ),
    );
  }
}

enum _OptionState { neutral, chosen, correct, wrong }

class _OptionTile extends StatelessWidget {
  final String label;
  final String? selectedAnswer;

  /// False while the learner is still choosing.
  final bool committed;
  final String correctAnswer;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.selectedAnswer,
    required this.committed,
    required this.correctAnswer,
    required this.onTap,
  });

  _OptionState get _state {
    if (!committed) {
      return label == selectedAnswer
          ? _OptionState.chosen
          : _OptionState.neutral;
    }
    if (selectedAnswer == null) return _OptionState.neutral;
    if (label == correctAnswer) return _OptionState.correct;
    if (label == selectedAnswer) return _OptionState.wrong;
    return _OptionState.neutral;
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final answered = committed;

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
        trailing = Icon(
          Icons.check_circle,
          color: context.palette.secondaryBlue,
          size: 20,
        );
        break;
      case _OptionState.wrong:
        background = context.palette.errorRed.withValues(alpha: 0.12);
        borderColor = context.palette.errorRed;
        foreground = context.palette.textNavy;
        trailing = Icon(
          Icons.cancel,
          color: context.palette.errorRed,
          size: 20,
        );
        break;
      case _OptionState.chosen:
        // "You picked this", not "this is right" — the answer colours must
        // not appear before the learner has committed.
        background = context.palette.primaryCoral.withValues(alpha: 0.12);
        borderColor = context.palette.primaryCoral;
        foreground = context.palette.textNavy;
        trailing = Icon(
          Icons.radio_button_checked,
          color: context.palette.primaryCoral,
          size: 20,
        );
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
        // Still tappable while uncommitted, so the pick can be changed.
        onTap: committed ? null : onTap,
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
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
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

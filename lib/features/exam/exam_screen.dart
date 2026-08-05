import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../data/models/exam_mode.dart';
import '../../data/models/exam_question.dart';
import '../../data/models/user_profile.dart' show AvatarType;
import '../exam_result/exam_result_screen.dart';
import '../profile/exam_history_providers.dart';
import 'exam_providers.dart';

class ExamScreen extends ConsumerStatefulWidget {
  final ExamMode mode;

  const ExamScreen({super.key, required this.mode});

  @override
  ConsumerState<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends ConsumerState<ExamScreen> {
  int _currentIndex = 0;
  String? _selectedAnswer;
  final List<AnsweredQuestion> _answers = [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Preload in the background so it's ready by the time ExamResultScreen
    // wants to show it — no visible loading delay, no ad shown here.
    ref.read(adServiceProvider).preloadInterstitial();
  }

  void _selectAnswer(String answer) {
    if (_selectedAnswer != null) return;
    setState(() => _selectedAnswer = answer);
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
      });
      return;
    }

    setState(() => _submitting = true);
    final s = ref.read(appStringsProvider);
    final user = ref.read(appStartupProvider).valueOrNull;
    if (user == null) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.failedToSaveExamResult)),
      );
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
            displayName: profile?.resolveDisplayName(user) ?? (user.displayName ?? s.defaultLearnerName),
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

      if (!mounted) return;
      AppNavigator.replaceFadeScale(context, ExamResultScreen(result: result));
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.failedToSaveExamResult)),
      );
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
                backgroundColor: context.palette.primaryCoral.withValues(alpha: 0.15),
                color: context.palette.primaryCoral,
                minHeight: 6,
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
                            correctAnswer: question.correctAnswer,
                            onTap: () => _selectAnswer(option),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedAnswer == null || _submitting
                        ? null
                        : () => _handleNext(questions),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(s.nextQuestionButton),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(s.failedToLoadQuestions(e))),
      ),
    );
  }
}

enum _OptionState { neutral, correct, wrong }

class _OptionTile extends StatelessWidget {
  final String label;
  final String? selectedAnswer;
  final String correctAnswer;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.onTap,
  });

  _OptionState get _state {
    if (selectedAnswer == null) return _OptionState.neutral;
    if (label == correctAnswer) return _OptionState.correct;
    if (label == selectedAnswer) return _OptionState.wrong;
    return _OptionState.neutral;
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final answered = selectedAnswer != null;

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

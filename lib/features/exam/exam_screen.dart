import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/exam_mode.dart';
import '../../data/models/exam_question.dart';
import '../../data/models/user_profile.dart' show AvatarType;
import '../exam_result/exam_result_screen.dart';
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
    final user = ref.read(appStartupProvider).valueOrNull;
    if (user == null) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan hasil ujian, coba lagi.')),
      );
      return;
    }

    final profile = ref.read(userProfileProvider).valueOrNull;
    final result = await ref
        .read(examRepositoryProvider)
        .submitExam(
          uid: user.uid,
          mode: widget.mode,
          answers: _answers,
          displayName: profile?.resolveDisplayName(user) ?? (user.displayName ?? 'Pelajar Kana'),
          photoUrl: user.photoURL,
          avatarType: profile?.avatarType ?? AvatarType.google,
          avatarValue: profile?.avatarValue,
        );

    if (!mounted) return;
    AppNavigator.replaceFadeScale(context, ExamResultScreen(result: result));
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(examQuestionsProvider(widget.mode));

    return Scaffold(
      appBar: AppBar(title: Text(widget.mode.title)),
      body: questionsAsync.when(
        data: (questions) {
          if (questions.isEmpty) {
            return const Center(child: Text('Soal tidak tersedia'));
          }
          final question = questions[_currentIndex];
          final total = questions.length;

          return Column(
            children: [
              LinearProgressIndicator(
                value: (_currentIndex + 1) / total,
                backgroundColor: AppColors.primaryCoral.withValues(alpha: 0.15),
                color: AppColors.primaryCoral,
                minHeight: 6,
              ),
              const SizedBox(height: 12),
              Text(
                'Soal ${_currentIndex + 1} / $total',
                style: const TextStyle(
                  color: AppColors.textNavy,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      const Text(
                        'Apa bacaan dari huruf ini?',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textNavy,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        decoration: BoxDecoration(
                          color: AppColors.cardWhite,
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
                            style: const TextStyle(
                              fontSize: 72,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textNavy,
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
                        : const Text('Soal Berikutnya'),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat soal: $e')),
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
        background = AppColors.successGreen;
        foreground = Colors.white;
        trailing = const Icon(Icons.check_circle, color: Colors.white);
        break;
      case _OptionState.wrong:
        background = AppColors.errorRed;
        foreground = Colors.white;
        trailing = const Icon(Icons.cancel, color: Colors.white);
        break;
      case _OptionState.neutral:
        background = answered
            ? AppColors.cardWhite.withValues(alpha: 0.6)
            : AppColors.cardWhite;
        foreground = AppColors.textNavy;
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
                  ? Colors.grey.shade300
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

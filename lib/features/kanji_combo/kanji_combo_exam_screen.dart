import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../data/models/jlpt_level.dart';
import '../../data/models/quiz_review_entry.dart';
import '../../data/models/simple_exam_result.dart';
import '../../data/models/user_profile.dart' show AvatarType;
import '../../data/models/xp_progress.dart';
import '../exam/mc_quiz_flow.dart';
import '../exam/simple_exam_result_screen.dart';
import '../profile/exam_history_providers.dart';
import 'kanji_combo_providers.dart';
import '../../core/widgets/app_loading.dart';
import '../../core/constants/exam_timing.dart';
import '../exam/exam_timing_gate.dart';

class KanjiComboExamScreen extends ConsumerWidget {
  final JlptLevel level;
  final bool combination;

  const KanjiComboExamScreen({
    super.key,
    required this.level,
    required this.combination,
  });

  Future<void> _onComplete(
    BuildContext context,
    WidgetRef ref,
    int score,
    int total,
    List<QuizReviewEntry> wrongAnswers,
  ) async {
    final user = ref.read(appStartupProvider).valueOrNull;
    final result = SimpleExamResult(
      itemId: combination ? 'combo_${level.key}' : 'single_${level.key}',
      jlptLevel: level.key,
      score: score,
      total: total,
      completedAt: DateTime.now(),
    );
    if (user != null) {
      try {
        final profile = ref.read(userProfileProvider).valueOrNull;
        await ref
            .read(kanjiComboExamHistoryRepositoryProvider)
            .submit(
              uid: user.uid,
              result: result,
              displayName:
                  profile?.resolveDisplayName(user) ??
                  (user.displayName ?? 'Pelajar Kana'),
              photoUrl: user.photoURL,
              avatarType: profile?.avatarType ?? AvatarType.google,
              avatarValue: profile?.avatarValue,
            );
        ref.invalidate(fullExamHistoryProvider);
        await ref
            .read(progressRepositoryProvider)
            .addXp(user.uid, XpAction.examCompleted);
        ref.invalidate(xpProgressProvider);
      } catch (_) {
        // Best-effort mirror only — see DokkaiExamScreen for the same
        // reasoning.
      }
    }
    if (!context.mounted) return;
    final s = ref.read(appStringsProvider);
    AppNavigator.replaceFadeScale(
      context,
      SimpleExamResultScreen(
        title: s.examResultTitle(
          combination
              ? s.examCategoryKanjiComboCombination
              : s.examCategoryKanjiComboSingle,
        ),
        result: result,
        wrongAnswers: wrongAnswers,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(
      kanjiComboQuestionsProvider((level, combination)),
    );
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        title: Text(
          '${combination ? s.examCategoryKanjiComboCombination : s.examCategoryKanjiComboSingle} ${level.key}',
        ),
      ),
      body: questionsAsync.when(
        data: (questions) {
          if (questions.isEmpty) {
            return Center(child: Text(s.noQuestionsAvailable));
          }
          return ExamTimingGate(
            kind: ExamKind.kanji,
            builder: (context, limit) => McQuizFlow(
              timeLimit: limit,
              totalQuestions: questions.length,
              // No furigana anywhere in this screen, on either question
              // type — a reading question's prompt would leak the answer,
              // and a meaning question's prompt would let a learner skip
              // recognizing the kanji itself, which is exactly the skill
              // this exam is meant to test.
              headerBuilder: (context, index) => _KanjiPrompt(
                text: questions[index].prompt,
                promptLabel: questions[index].promptLabel,
              ),
              optionsOf: (index) => questions[index].options,
              correctIndexOf: (index) => questions[index].correctIndex,
              questionLabelOf: (index) => questions[index].prompt,
              onComplete: (score, total, wrongAnswers) =>
                  _onComplete(context, ref, score, total, wrongAnswers),
            ),
          );
        },
        loading: () => const AppLoading(),
        error: (e, _) => Center(child: Text(s.failedToLoadQuestions(e))),
      ),
    );
  }
}

class _KanjiPrompt extends StatelessWidget {
  final String text;
  final String promptLabel;

  const _KanjiPrompt({required this.text, required this.promptLabel});

  @override
  Widget build(BuildContext context) {
    final promptStyle = TextStyle(
      fontSize: 56,
      fontWeight: FontWeight.bold,
      color: context.palette.textNavy,
    );
    return Column(
      children: [
        Text(
          promptLabel,
          style: TextStyle(fontSize: 16, color: context.palette.textNavy),
        ),
        const SizedBox(height: 16),
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
          child: Center(child: Text(text, style: promptStyle)),
        ),
      ],
    );
  }
}

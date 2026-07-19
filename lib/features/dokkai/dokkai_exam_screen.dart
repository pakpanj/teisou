import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/dokkai_passage.dart';
import '../../data/models/jlpt_level.dart';
import '../../data/models/simple_exam_result.dart';
import '../exam/mc_quiz_flow.dart';
import '../exam/simple_exam_result_screen.dart';

/// Runs one Dokkai passage: the Japanese text stays visible (this is a
/// reading exercise, unlike Choukai) above each question, via
/// [McQuizFlow]'s per-question header slot.
class DokkaiExamScreen extends ConsumerWidget {
  final DokkaiPassage passage;

  const DokkaiExamScreen({super.key, required this.passage});

  Future<void> _onComplete(
    BuildContext context,
    WidgetRef ref,
    int score,
    int total,
  ) async {
    final user = ref.read(appStartupProvider).valueOrNull;
    final result = SimpleExamResult(
      itemId: passage.id,
      jlptLevel: passage.jlptLevel.key,
      score: score,
      total: total,
      completedAt: DateTime.now(),
    );
    if (user != null) {
      try {
        await ref
            .read(dokkaiExamHistoryRepositoryProvider)
            .submit(user.uid, result);
      } catch (_) {
        // Best-effort mirror only — the score is shown either way, same
        // "don't let a network failure block the result" reasoning as
        // every other progress repository in this app.
      }
    }
    if (!context.mounted) return;
    AppNavigator.replaceFadeScale(
      context,
      SimpleExamResultScreen(title: 'Hasil Dokkai', result: result),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(passage.title)),
      body: McQuizFlow(
        totalQuestions: passage.questions.length,
        headerBuilder: (context, index) => _PassageHeader(
          passage: passage,
          prompt: passage.questions[index].prompt,
        ),
        optionsOf: (index) => passage.questions[index].options,
        correctIndexOf: (index) => passage.questions[index].correctIndex,
        onComplete: (score, total) => _onComplete(context, ref, score, total),
      ),
    );
  }
}

class _PassageHeader extends StatelessWidget {
  final DokkaiPassage passage;
  final String prompt;

  const _PassageHeader({required this.passage, required this.prompt});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            passage.passageJapanese,
            style: const TextStyle(fontSize: 16, height: 1.6, color: AppColors.textNavy),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          prompt,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textNavy,
          ),
        ),
      ],
    );
  }
}

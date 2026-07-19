import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/jlpt_level.dart';
import '../../data/models/simple_exam_result.dart';
import '../exam/mc_quiz_flow.dart';
import '../exam/simple_exam_result_screen.dart';
import 'kanji_combo_providers.dart';

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
        await ref
            .read(kanjiComboExamHistoryRepositoryProvider)
            .submit(user.uid, result);
      } catch (_) {
        // Best-effort mirror only — see DokkaiExamScreen for the same
        // reasoning.
      }
    }
    if (!context.mounted) return;
    AppNavigator.replaceFadeScale(
      context,
      SimpleExamResultScreen(
        title: combination ? 'Hasil Kombinasi Kanji' : 'Hasil Kanji Tunggal',
        result: result,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync =
        ref.watch(kanjiComboQuestionsProvider((level, combination)));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(combination ? 'Kombinasi Kanji ${level.key}' : 'Kanji Tunggal ${level.key}'),
      ),
      body: questionsAsync.when(
        data: (questions) {
          if (questions.isEmpty) {
            return const Center(child: Text('Soal tidak tersedia'));
          }
          return McQuizFlow(
            totalQuestions: questions.length,
            headerBuilder: (context, index) => _KanjiPrompt(
              text: questions[index].prompt,
              combination: combination,
            ),
            optionsOf: (index) => questions[index].options,
            correctIndexOf: (index) => questions[index].correctIndex,
            onComplete: (score, total) => _onComplete(context, ref, score, total),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat soal: $e')),
      ),
    );
  }
}

class _KanjiPrompt extends StatelessWidget {
  final String text;
  final bool combination;

  const _KanjiPrompt({required this.text, required this.combination});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          combination ? 'Bagaimana bacaan kata ini?' : 'Apa artinya kanji ini?',
          style: const TextStyle(fontSize: 16, color: AppColors.textNavy),
        ),
        const SizedBox(height: 16),
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
              text,
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: AppColors.textNavy,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

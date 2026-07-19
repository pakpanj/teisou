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

/// One (passage, question) pair — the flattened unit [McQuizFlow] steps
/// through. Kept as a small typedef record rather than a new model class
/// since it's purely a display-layer pairing, not persisted data.
typedef _SessionItem = ({DokkaiPassage passage, DokkaiQuestion question});

/// Runs one Dokkai session: [sessionQuestionTarget] questions (default 50)
/// pulled from [passages] in order, grouping every passage's own questions
/// together so the reading-comprehension context (the Japanese text) stays
/// visible and coherent while its 2-3 questions are being answered, before
/// moving on to the next passage. [passages] is expected to already be
/// shuffled by the caller (`DokkaiHomeScreen`) — this screen just consumes
/// them in order and stops once it has enough questions, so a bigger
/// content pool naturally means more session variety without any change
/// here.
class DokkaiExamScreen extends ConsumerWidget {
  final List<DokkaiPassage> passages;
  static const sessionQuestionTarget = 50;

  const DokkaiExamScreen({super.key, required this.passages});

  List<_SessionItem> get _items {
    final items = <_SessionItem>[];
    for (final passage in passages) {
      for (final question in passage.questions) {
        items.add((passage: passage, question: question));
        if (items.length >= sessionQuestionTarget) return items;
      }
    }
    return items;
  }

  Future<void> _onComplete(
    BuildContext context,
    WidgetRef ref,
    int score,
    int total,
  ) async {
    final user = ref.read(appStartupProvider).valueOrNull;
    final result = SimpleExamResult(
      itemId: 'dokkai_session_${DateTime.now().millisecondsSinceEpoch}',
      jlptLevel: passages.first.jlptLevel.key,
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
    final items = _items;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Dokkai · ${items.length} Soal')),
      body: McQuizFlow(
        totalQuestions: items.length,
        headerBuilder: (context, index) => _PassageHeader(
          passage: items[index].passage,
          prompt: items[index].question.prompt,
        ),
        optionsOf: (index) => items[index].question.options,
        correctIndexOf: (index) => items[index].question.correctIndex,
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
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: AppColors.textNavy,
            ),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../data/models/jlpt_level.dart';
import '../../data/models/simple_exam_result.dart';
import '../exam/mc_quiz_flow.dart';
import '../exam/simple_exam_result_screen.dart';
import 'bab_gate_quiz_generator.dart';
import 'bab_providers.dart';

/// The cumulative "gerbang" (gate) quiz standing between one Bab chapter
/// and the next. Passing it — with a perfect score, no partial credit —
/// marks [babId] complete and unlocks the chapter right after [upToOrder];
/// failing leaves the next chapter locked and this screen can simply be
/// re-entered for a freshly-shuffled attempt (see `buildGateQuestions`).
///
/// Every question is generated at runtime from real Kotoba/Bunpou/Partikel
/// content already authored for chapters 1 through [upToOrder] — there is
/// no separate gate-quiz dataset to keep in sync as the curriculum grows.
class BabGateQuizScreen extends ConsumerStatefulWidget {
  final JlptLevel level;
  final int upToOrder;
  final String babId;

  const BabGateQuizScreen({
    super.key,
    required this.level,
    required this.upToOrder,
    required this.babId,
  });

  @override
  ConsumerState<BabGateQuizScreen> createState() => _BabGateQuizScreenState();
}

class _BabGateQuizScreenState extends ConsumerState<BabGateQuizScreen> {
  List<GateQuestion>? _questions;

  Future<void> _onComplete(int score, int total) async {
    final passed = total > 0 && score == total;
    if (passed) {
      final uid = ref.read(appStartupProvider).valueOrNull?.uid;
      await ref.read(babProgressRepositoryProvider).markCompleted(
            widget.babId,
            widget.level.key,
            uid: uid,
          );
      ref.invalidate(babCompletedIdsProvider);
      ref.invalidate(babNextUpProvider);
    }
    if (!mounted) return;
    final s = ref.read(appStringsProvider);
    final result = SimpleExamResult(
      itemId: 'bab_gate_${widget.babId}_${DateTime.now().millisecondsSinceEpoch}',
      jlptLevel: widget.level.key,
      score: score,
      total: total,
      completedAt: DateTime.now(),
    );
    AppNavigator.replaceFadeScale(
      context,
      SimpleExamResultScreen(
        title: s.babGateQuizTitle,
        result: result,
        reviewContent: Text(
          passed ? s.babGatePassedMessage : s.babGateFailedMessage,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: passed ? context.palette.successGreen : context.palette.errorRed,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final resolvedAsync = ref.watch(babAllResolvedProvider(widget.level));

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: Text(s.babGateQuizTitle)),
      body: resolvedAsync.when(
        data: (allResolved) {
          final questions = _questions ??= buildGateQuestions(
            allResolved: allResolved,
            upToOrder: widget.upToOrder,
            language: s.language,
          );
          if (questions.isEmpty) {
            return Center(child: Text(s.babGateNoQuestions));
          }
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: McQuizFlow(
              totalQuestions: questions.length,
              headerBuilder: (context, index) => _QuestionCard(
                prompt: questions[index].prompt,
              ),
              optionsOf: (index) => questions[index].options,
              correctIndexOf: (index) => questions[index].correctIndex,
              onComplete: _onComplete,
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(s.failedToLoadLevels(e))),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final String prompt;

  const _QuestionCard({required this.prompt});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.palette.cardWhite,
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
        prompt,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: context.palette.textNavy,
        ),
      ),
    );
  }
}

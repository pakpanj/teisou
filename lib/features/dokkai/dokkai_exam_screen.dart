import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/furigana_text.dart';
import '../../data/models/dokkai_passage.dart';
import '../../data/models/jlpt_level.dart';
import '../../data/models/quiz_review_entry.dart';
import '../../data/models/simple_exam_result.dart';
import '../../data/models/user_profile.dart' show AvatarType;
import '../../data/models/xp_progress.dart';
import '../exam/mc_quiz_flow.dart';
import '../exam/simple_exam_result_screen.dart';
import '../profile/exam_history_providers.dart';
import '../../core/constants/exam_timing.dart';
import '../exam/exam_timing_gate.dart';

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
    List<QuizReviewEntry> wrongAnswers,
    List<GradedAnswer> answers,
  ) async {
    final user = ref.read(appStartupProvider).valueOrNull;
    final result = SimpleExamResult(
      itemId: 'dokkai_session_${DateTime.now().millisecondsSinceEpoch}',
      jlptLevel: passages.first.jlptLevel.key,
      score: score,
      total: total,
      completedAt: DateTime.now(),
      answers: answers
          .map((a) => {
                'contentId': a.contentId,
                'selectedIndex': a.selectedIndex,
                'submittedText': a.submittedText,
              })
          .toList(),
    );
    if (user != null) {
      try {
        final profile = ref.read(userProfileProvider).valueOrNull;
        await ref
            .read(dokkaiExamHistoryRepositoryProvider)
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
        // See ExamScreen._handleNext's comment for why this invalidation
        // is required, not just autoDispose's default behaviour.
        ref.invalidate(fullExamHistoryProvider);
        await ref
            .read(progressRepositoryProvider)
            .addXp(user.uid, XpAction.examCompleted);
        ref.invalidate(xpProgressProvider);
      } catch (_) {
        // Best-effort mirror only — the score is shown either way, same
        // "don't let a network failure block the result" reasoning as
        // every other progress repository in this app.
      }
    }
    if (!context.mounted) return;
    final s = ref.read(appStringsProvider);
    AppNavigator.replaceFadeScale(
      context,
      SimpleExamResultScreen(
        title: s.examResultTitle(s.examCategoryDokkai),
        result: result,
        wrongAnswers: wrongAnswers,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = _items;
    final s = ref.watch(appStringsProvider);
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: Text(s.dokkaiSessionTitle(items.length))),
      body: ExamTimingGate(
        kind: ExamKind.dokkai,
        builder: (context, limit) => McQuizFlow(
          timeLimit: limit,
          totalQuestions: items.length,
          showFurigana: showFuriganaFor(passages.first.jlptLevel),
          headerBuilder: (context, index) => _PassageHeader(
            passage: items[index].passage,
            prompt: items[index].question.prompt,
          ),
          optionsOf: (index) => items[index].question.options,
          correctIndexOf: (index) => items[index].question.correctIndex,
          questionLabelOf: (index) => items[index].question.prompt,
          contentIdOf: (index) =>
              '${items[index].passage.id}|${items[index].question.id}',
          onComplete: (score, total, wrongAnswers, answers) => _onComplete(
              context, ref, score, total, wrongAnswers, answers),
        ),
      ),
    );
  }
}

class _PassageHeader extends ConsumerWidget {
  final DokkaiPassage passage;
  final String prompt;

  const _PassageHeader({required this.passage, required this.prompt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showFurigana = showFuriganaFor(passage.jlptLevel);
    final dictionary = showFurigana
        ? ref.watch(furiganaDictionaryProvider).valueOrNull
        : null;
    final passageStyle = TextStyle(
      fontSize: 16,
      height: 1.6,
      color: context.palette.textNavy,
    );
    final promptStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: context.palette.textNavy,
    );
    return Column(
      children: [
        Container(
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
          child: dictionary != null
              ? FuriganaSentence(
                  text: passage.passageJapanese,
                  dictionary: dictionary,
                  style: passageStyle,
                )
              : Text(passage.passageJapanese, style: passageStyle),
        ),
        const SizedBox(height: 20),
        dictionary != null
            ? FuriganaSentence(
                text: prompt,
                dictionary: dictionary,
                style: promptStyle,
              )
            : Text(prompt, style: promptStyle),
      ],
    );
  }
}

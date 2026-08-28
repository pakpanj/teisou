import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/localization/app_strings.dart';
import 'package:kana_master/features/exam/mc_quiz_flow.dart';
import 'package:kana_master/data/models/app_language.dart';
import 'package:kana_master/data/models/quiz_review_entry.dart';

/// Tapping an option used to *be* the commit: it scored the answer and
/// locked the question, while a button sat underneath looking exactly like
/// the confirm step it was not. A mis-tap could not be taken back, which
/// matters most in the Bab gate quiz — that one demands 100%, so one slip
/// fails the whole chapter and it has to be sat again.
///
/// Now the tap only moves the highlight and the button grades.
void main() {
  Widget harness({
    required void Function(int score, int total, List<QuizReviewEntry> wrong, List<GradedAnswer> answers)
        onComplete,
  }) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: McQuizFlow(
            totalQuestions: 1,
            questionLabelOf: (_) => 'Soal',
            optionsOf: (_) => const ['benar', 'salah'],
            correctIndexOf: (_) => 0,
            headerBuilder: (_, _) => const SizedBox.shrink(),
            onComplete: onComplete,
          ),
        ),
      ),
    );
  }

  testWidgets('a pick can be changed until it is confirmed', (tester) async {
    var score = -1;
    await tester.pumpWidget(harness(onComplete: (s, _, _, _) => score = s));
    await tester.pumpAndSettle();

    final s = AppStrings(AppLanguage.indonesian);

    // Tap the wrong answer first — the mis-tap this exists to forgive.
    await tester.tap(find.text('salah'));
    await tester.pumpAndSettle();

    // Nothing is revealed yet: no tick, no cross.
    expect(find.byIcon(Icons.check_circle), findsNothing);
    expect(find.byIcon(Icons.cancel), findsNothing);
    expect(find.text(s.checkAnswerButton), findsOneWidget);

    // Change your mind.
    await tester.tap(find.text('benar'));
    await tester.pumpAndSettle();

    // Confirm, and only now is it graded. `pump`, not `pumpAndSettle`:
    // the mascot's reaction animates continuously, so settling never
    // arrives once it is on screen.
    await tester.tap(find.text(s.checkAnswerButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    await tester.tap(find.text(s.done));
    await tester.pump();
    expect(
      score,
      1,
      reason: 'the first tap was scored, so changing your mind did nothing',
    );
  });

  testWidgets('a confirmed answer is final', (tester) async {
    var score = -1;
    await tester.pumpWidget(harness(onComplete: (s, _, _, _) => score = s));
    await tester.pumpAndSettle();
    final s = AppStrings(AppLanguage.indonesian);

    await tester.tap(find.text('salah'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(s.checkAnswerButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Too late to switch now.
    await tester.tap(find.text('benar'));
    await tester.pump();
    await tester.tap(find.text(s.done));
    await tester.pump();
    expect(score, 0, reason: 'a graded answer was changed after the fact');
  });
}

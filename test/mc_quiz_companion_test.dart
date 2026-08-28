import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/theme/app_theme.dart';
import 'package:kana_master/core/widgets/mascot_companion.dart';
import 'package:kana_master/core/widgets/mascot_widget.dart';
import 'package:kana_master/data/models/quiz_review_entry.dart';
import 'package:kana_master/features/exam/mc_quiz_flow.dart';

/// The mascot sitting inside a lesson, reacting to each answer.
///
/// [McQuizFlow] is shared by the Bab gate quiz, Choukai, Dokkai and Kanji
/// Kombinasi, so this one wiring is four screens' worth of behaviour — and
/// four screens' worth of damage if the companion covers the Next button or
/// keeps praising the previous question.
void main() {
  /// Three questions with an obvious right answer, so the flow can be
  /// driven by tapping text rather than by index bookkeeping.
  Widget wrap(
          {void Function(int score, int total, List<QuizReviewEntry> wrong, List<GradedAnswer> answers)?
              onComplete}) =>
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: McQuizFlow(
              totalQuestions: 3,
              headerBuilder: (context, i) => Text('soal $i'),
              optionsOf: (i) => ['benar $i', 'salah $i'],
              correctIndexOf: (i) => 0,
              questionLabelOf: (i) => 'soal $i',
              onComplete: onComplete ?? (_, _, _, _) {},
            ),
          ),
        ),
      );

  testWidgets('says nothing until the learner answers', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.byType(MascotWidget), findsNothing,
        reason: 'an unanswered question should look exactly as it always did');
  });

  testWidgets('reacts as soon as an answer is given', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    await tester.tap(find.text('benar 0'));
    await tester.pump(const Duration(milliseconds: 300));
    // Tapping only picks now; the coach reacts once the answer is
    // confirmed, which is the step this flow gained so a mis-tap
    // can be taken back.
    await tester.tap(find.text('Periksa Jawaban'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(MascotWidget), findsOneWidget);
  });

  testWidgets('names the right answer when the learner gets it wrong',
      (tester) async {
    // The one piece of teaching this can honestly do on every question.
    await tester.pumpWidget(wrap());
    await tester.pump();

    await tester.tap(find.text('salah 0'));
    await tester.pump(const Duration(milliseconds: 300));
    // Tapping only picks now; the coach reacts once the answer is
    // confirmed, which is the step this flow gained so a mis-tap
    // can be taken back.
    await tester.tap(find.text('Periksa Jawaban'));
    await tester.pump(const Duration(milliseconds: 300));

    final bubble = tester.widgetList<Text>(
      find.descendant(
        of: find.byType(MascotCompanion),
        matching: find.byType(Text),
      ),
    );
    expect(bubble.map((t) => t.data).join(), contains('benar 0'));
  });

  testWidgets('stops talking about the previous question', (tester) async {
    // A reaction left standing would be praising the last answer while the
    // learner reads the next question.
    await tester.pumpWidget(wrap());
    await tester.pump();

    await tester.tap(find.text('benar 0'));
    await tester.pump(const Duration(milliseconds: 300));
    // Tapping only picks now; the coach reacts once the answer is
    // confirmed, which is the step this flow gained so a mis-tap
    // can be taken back.
    await tester.tap(find.text('Periksa Jawaban'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(MascotWidget), findsOneWidget);

    await tester.tap(find.text('Soal Berikutnya'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(MascotWidget), findsNothing);
  });

  testWidgets('leaves the Next button reachable while it is talking',
      (tester) async {
    // The reason the companion is laid out inline instead of floating: on
    // a quiz screen there is nowhere to float that is not on top of
    // something the learner needs.
    await tester.pumpWidget(wrap());
    await tester.pump();

    await tester.tap(find.text('benar 0'));
    await tester.pump(const Duration(milliseconds: 300));
    // Tapping only picks now; the coach reacts once the answer is
    // confirmed, which is the step this flow gained so a mis-tap
    // can be taken back.
    await tester.tap(find.text('Periksa Jawaban'));
    await tester.pump(const Duration(milliseconds: 300));

    final button = find.text('Soal Berikutnya');
    expect(button, findsOneWidget);
    final buttonRect = tester.getRect(button);
    final companionRect = tester.getRect(find.byType(MascotCompanion));
    expect(companionRect.overlaps(buttonRect), isFalse,
        reason: 'the mascot must not sit on top of the way forward');
  });

  testWidgets('still finishes the quiz and reports the score', (tester) async {
    // Guards the wiring itself: the companion is threaded through the same
    // _select that tallies the score.
    int? score;
    int? total;
    await tester.pumpWidget(wrap(onComplete: (s, t, _, _) {
      score = s;
      total = t;
    }));
    await tester.pump();

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text(i == 1 ? 'salah $i' : 'benar $i'));
      await tester.pump(const Duration(milliseconds: 300));
      // Tapping only picks now; the coach reacts once the answer is
      // confirmed, which is the step this flow gained so a mis-tap
      // can be taken back.
      await tester.tap(find.text('Periksa Jawaban'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text(i == 2 ? 'Selesai' : 'Soal Berikutnya'));
      await tester.pump(const Duration(milliseconds: 300));
    }

    expect(score, 2);
    expect(total, 3);
  });
}

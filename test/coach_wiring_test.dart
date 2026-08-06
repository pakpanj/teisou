import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every screen that grades an answer should have the mascot react to it.
///
/// This is a source check rather than a widget test on purpose. The wiring
/// is the same four lines in each screen — hold a `MascotCoach`, call
/// `onAnswer`, clear the reaction in the next-question handler, render a
/// `MascotCompanion` — and the way it goes wrong is not that one screen
/// breaks loudly. It is that a new quiz screen gets written later by
/// copying an older one, and quietly has no mascot in it, which nobody
/// notices because every screen still works.
///
/// Driving six real quizzes through a widget test would need six sets of
/// fixtures and would still not catch the seventh screen somebody adds.
void main() {
  /// Screens known to grade an answer and therefore to owe the learner a
  /// reaction. `mc_quiz_flow.dart` covers the Bab gate quiz, Choukai,
  /// Dokkai and Kanji Kombinasi in one place.
  const wired = <String>[
    'lib/features/exam/mc_quiz_flow.dart',
    'lib/features/exam/exam_screen.dart',
    'lib/features/kanji/kanji_quiz_screen.dart',
    'lib/features/kotoba/kotoba_quiz_screen.dart',
    'lib/features/bunpou/bunpou_quiz_screen.dart',
    'lib/features/particle/particle_quiz_screen.dart',
  ];

  for (final path in wired) {
    group(path.split('/').last, () {
      late String source;

      setUpAll(() => source = File(path).readAsStringSync());

      test('reacts to the answer through the coach', () {
        expect(source, contains('MascotCoach'));
        expect(source, contains('_coach.onAnswer('));
        expect(source, contains('MascotCompanion'));
      });

      test('holds the coach on the state rather than building it per frame',
          () {
        // A coach rebuilt in `build` forgets the run of correct answers,
        // so the streak reaction would simply never fire — and nothing
        // would look broken.
        expect(source, contains('final MascotCoach _coach = MascotCoach();'));
      });

      test('stops talking about the previous question', () {
        // Without this the mascot praises the last answer while the
        // learner reads the next question.
        expect(source, contains('_reaction = null;'));
      });
    });
  }

  test('every screen that reveals a correct answer is on the list', () {
    // Catches the real failure mode: a new quiz screen written by copying
    // an old one, with the mascot left out. `correctIndex`/`correctAnswer`
    // is what a screen that grades an answer looks like in this codebase.
    final missing = <String>[];
    for (final entity in Directory('lib/features').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (wired.contains(path)) continue;

      final source = entity.readAsStringSync();
      final grades = source.contains('correctIndex') ||
          source.contains('correctAnswer');
      // Models, generators and result screens name a correct answer
      // without ever asking the learner for one.
      final isScreen = source.contains('ConsumerState<') &&
          source.contains('onTap:') &&
          !path.contains('_result') &&
          !path.contains('kaiwa');
      if (grades && isScreen) missing.add(path);
    }

    expect(missing, isEmpty,
        reason: 'these screens grade an answer but have no mascot reaction; '
            'wire MascotCoach + MascotCompanion, or add them to `wired` '
            'with a note saying why they are exempt');
  });
}

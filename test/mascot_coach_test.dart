import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/localization/app_strings.dart';
import 'package:kana_master/data/models/app_language.dart';
import 'package:kana_master/core/services/mascot_coach.dart';
import 'package:kana_master/core/widgets/mascot_widget.dart';

/// What the mascot says while a learner works through a lesson.
///
/// Tested as logic rather than by looking at a quiz, because the two ways
/// this can be wrong are both invisible in a screenshot of one question:
/// saying the same sentence under all ten, and turning cold on a child who
/// gets one wrong.
void main() {
  final id = AppStrings(AppLanguage.indonesian);
  final en = AppStrings(AppLanguage.english);

  group('correct answers', () {
    test('praises, and does not say the same thing twice in a row', () {
      // Seeded so the run is reproducible; the guarantee under test is
      // that consecutive picks differ, not which line comes up.
      final coach = MascotCoach(random: Random(7));
      final seen = <String>[];
      for (var i = 0; i < 2; i++) {
        seen.add(
          coach.onAnswer(id, correct: true, correctAnswer: 'ねこ').message,
        );
      }
      expect(seen[0], isNot(seen[1]));
    });

    test('gets louder after a run of correct answers', () {
      final coach = MascotCoach(random: Random(1));
      late CoachLine line;
      for (var i = 0; i < MascotCoach.streakThreshold; i++) {
        line = coach.onAnswer(id, correct: true, correctAnswer: 'ねこ');
      }
      expect(coach.currentRun, MascotCoach.streakThreshold);
      expect(line.message, contains('${MascotCoach.streakThreshold}'),
          reason: 'the streak line should name the run it is celebrating');
    });

    test('a wrong answer ends the run', () {
      final coach = MascotCoach(random: Random(1));
      coach.onAnswer(id, correct: true, correctAnswer: 'ねこ');
      coach.onAnswer(id, correct: true, correctAnswer: 'ねこ');
      coach.onAnswer(id, correct: false, correctAnswer: 'ねこ');
      expect(coach.currentRun, 0);
    });
  });

  group('wrong answers', () {
    test('always name the right answer', () {
      // The one piece of teaching that is honest for every question. A
      // line that forgot it would leave the learner knowing only that
      // they were wrong.
      final coach = MascotCoach(random: Random(3));
      for (var i = 0; i < 20; i++) {
        final line = coach.onAnswer(id, correct: false, correctAnswer: 'いぬ');
        expect(line.message, contains('いぬ'));
      }
    });

    test('never pull a sad face at the learner', () {
      // The rule this whole class is built around, and the one a future
      // edit is most likely to break by adding a "disappointed" line
      // because it seems expressive. The audience is children.
      final coach = MascotCoach(random: Random(11));
      for (var i = 0; i < 40; i++) {
        final line = coach.onAnswer(id, correct: false, correctAnswer: 'いぬ');
        expect(line.mood, isNot(MascotMood.sad));
      }
    });

    test('vary rather than repeating one sentence', () {
      final coach = MascotCoach(random: Random(5));
      final seen = <String>{};
      for (var i = 0; i < 12; i++) {
        seen.add(
          coach.onAnswer(id, correct: false, correctAnswer: 'いぬ').message,
        );
      }
      expect(seen.length, greaterThan(1));
    });
  });

  group('finishing', () {
    test('celebrates a strong result', () {
      final coach = MascotCoach(random: Random(2));
      final line = coach.onFinished(id, score: 8, total: 10);
      expect(line.mood, anyOf(MascotMood.cheering, MascotMood.proud));
      expect(line.message, contains('8'));
    });

    test('stays warm on a weak result', () {
      // A child who got 2 out of 10 is the one who most needs the mascot
      // not to turn on them.
      final coach = MascotCoach(random: Random(2));
      final line = coach.onFinished(id, score: 2, total: 10);
      expect(line.mood, isNot(MascotMood.sad));
      expect(line.message, contains('2'));
    });

    test('two thirds counts as strong, so it is reachable', () {
      final coach = MascotCoach(random: Random(2));
      final strong = coach.onFinished(id, score: 2, total: 3);
      expect(strong.mood, anyOf(MascotMood.cheering, MascotMood.proud));
    });

    test('an empty quiz does not divide by zero', () {
      final coach = MascotCoach(random: Random(2));
      expect(() => coach.onFinished(id, score: 0, total: 0), returnsNormally);
    });
  });

  test('speaks the language the app is set to', () {
    // The app ships Indonesian and English side by side and has a test
    // guarding against hardcoded UI strings; these lines must not be the
    // exception that slips through in one language only.
    final coach = MascotCoach(random: Random(4));
    final indonesian =
        coach.onAnswer(id, correct: true, correctAnswer: 'ねこ').message;
    coach.reset();
    final english =
        coach.onAnswer(en, correct: true, correctAnswer: 'ねこ').message;
    expect(indonesian, isNot(english));
  });

  test('a fresh lesson does not inherit the last one\'s run', () {
    final coach = MascotCoach(random: Random(9));
    for (var i = 0; i < 5; i++) {
      coach.onAnswer(id, correct: true, correctAnswer: 'ねこ');
    }
    coach.reset();
    expect(coach.currentRun, 0);
  });
}

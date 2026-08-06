import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every quiz marks a right and a wrong answer the same way.
///
/// A source check, because the failure is not that a screen breaks. It is
/// that six quizzes drift into six colour schemes, one screen at a time,
/// and each one looks fine on its own — which is exactly what had
/// happened: four quizzes used a tinted wash while the shared McQuizFlow
/// and the kana exam still filled the answer solid green and red.
///
/// Green is the specific thing being kept out. Solid red against solid
/// green is the one pair a red-green colourblind learner cannot separate,
/// and with white text on top there was no second cue to fall back on.
void main() {
  /// Screens that colour an answered option.
  const quizzes = <String>[
    'lib/features/exam/mc_quiz_flow.dart',
    'lib/features/exam/exam_screen.dart',
    'lib/features/kanji/kanji_quiz_screen.dart',
    'lib/features/kotoba/kotoba_quiz_screen.dart',
    'lib/features/bunpou/bunpou_quiz_screen.dart',
    'lib/features/particle/particle_quiz_screen.dart',
  ];

  for (final path in quizzes) {
    group(path.split('/').last, () {
      late String source;
      setUpAll(() => source = File(path).readAsStringSync());

      test('marks the right answer in blue, not green', () {
        expect(source, contains('secondaryBlue'));
        expect(source, isNot(contains('successGreen')),
            reason: 'green here is unreadable next to the red wrong answer '
                'for a red-green colourblind learner');
      });

      test('washes the colour rather than filling it solid', () {
        // The look the user asked for, and the reason the text can stay
        // navy: a solid fill needs white text, which removes the last cue
        // that is not hue.
        expect(source, contains('secondaryBlue.withValues(alpha:'));
        expect(source, contains('errorRed.withValues(alpha:'));
      });

      test('outlines the answer as well as tinting it', () {
        // The cue that survives when hue does not: an outlined option
        // reads as marked even in greyscale.
        expect(source, contains('borderColor'));
      });
    });
  }
}

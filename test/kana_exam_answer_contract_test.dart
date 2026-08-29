import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regression coverage for the Kana client/server answer-field contract
/// (see `TEISOU_ROADMAP_MASTER.md`'s "Flutter Release Readiness Audit"
/// section). `functions/exam_grading.js`'s `gradeKana` reads
/// `a.submittedText` for every answer — the live, deployed server-side
/// grader for the P0 exam-history authority fix. Kana's own submission
/// site once serialized the identical value under a DIFFERENT key,
/// `submittedAnswer`, so every Kana submission silently graded
/// `serverScore: 0` regardless of correctness, even from a client that
/// otherwise correctly sent real `answers`.
///
/// This is a source check, not a widget/unit test invoking
/// `ExamRepository.submitExam` directly, for the same reason
/// `coach_wiring_test.dart` is one: the failure mode here is not a
/// crash or a visibly wrong screen, it is a silently-wrong wire-format
/// key that every hand-constructed test fixture elsewhere in this
/// codebase (`exam_grading.test.js`, `exam_history_authority.test.js`)
/// already gets right by construction, since those fixtures were
/// written to match the SERVER's expectation directly rather than by
/// exercising the real client code path — which is exactly how this bug
/// went undetected through implementation, review, and a live
/// production deployment. Driving `submitExam` end-to-end would need a
/// full Firestore double this repository has none of; a source check on
/// the exact literal key is the smallest test that would fail again if
/// the field were accidentally renamed back.
void main() {
  const kanaRepoPath = 'lib/data/repositories/exam_repository.dart';

  group('Kana exam answer submission', () {
    late String source;

    setUpAll(() => source = File(kanaRepoPath).readAsStringSync());

    test('serializes the selected answer under `submittedText`', () {
      expect(source, contains("'submittedText': a.selectedAnswer"),
          reason: 'the real Kana submission payload must use the same '
              'wire-format key the live, deployed gradeKana() reads '
              '(functions/exam_grading.js) — see this file\'s own top '
              'doc comment for why this exact literal is being checked');
    });

    test('never emits the old, mismatched `submittedAnswer` key', () {
      expect(source, isNot(contains('submittedAnswer')),
          reason: "a reintroduced 'submittedAnswer' key would silently "
              'grade every Kana submission to serverScore: 0 again — '
              'the exact bug this test guards against, and the reason a '
              'plain presence check for submittedText alone would not '
              'be enough (both keys could coexist without this test '
              'ever failing)');
    });
  });

  test('all four exam modules agree on the same wire-format key '
      '(submittedText), matching what the live server grader expects '
      'for every one of them', () {
    const perModulePaths = <String>[
      kanaRepoPath,
      'lib/features/dokkai/dokkai_exam_screen.dart',
      'lib/features/choukai/choukai_exam_screen.dart',
      'lib/features/kanji_combo/kanji_combo_exam_screen.dart',
    ];
    for (final path in perModulePaths) {
      final source = File(path).readAsStringSync();
      expect(source, contains('submittedText'),
          reason: '$path must serialize its answers using the shared '
              "'submittedText' key — the same contract every one of "
              'functions/exam_grading.js\'s four grade* functions reads '
              'from');
    }
  });
}

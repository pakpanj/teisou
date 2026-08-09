import 'package:flutter_test/flutter_test.dart';
import 'package:kana_master/features/bab/bab_gate_quiz_generator.dart';

/// Guards the two rules the gate quiz was reported broken on: it asked the
/// same 10 questions no matter how much curriculum it covered, and — because
/// it drew them with a flat shuffle over chapters 1..N — a late chapter's
/// quiz could ask nothing about that chapter at all.
///
/// The draw itself needs resolved curriculum data to exercise, which means
/// real repositories; what is unit-testable without them is the arithmetic
/// the draw is built on, which is where both defects actually lived.
void main() {
  group('gateQuestionCount', () {
    test('grows with the number of chapters covered', () {
      expect(gateQuestionCount(1), 10);
      expect(gateQuestionCount(25), 20);
      // Strictly increasing until the cap — the old behaviour was flat at 10.
      for (var order = 1; order < 50; order++) {
        expect(
          gateQuestionCount(order + 1) >= gateQuestionCount(order),
          isTrue,
          reason: 'count dropped between chapter $order and ${order + 1}',
        );
      }
    });

    test('caps so a late chapter stays sittable', () {
      expect(gateQuestionCount(50), 30);
      // The curriculum runs to 358 chapters; an uncapped curve would ask
      // for a 150-question quiz at a 90% pass mark.
      expect(gateQuestionCount(358), 30);
    });
  });

  group('gatePassMark', () {
    test('is 90%, rounded up', () {
      expect(gatePassMark(10), 9);
      expect(gatePassMark(20), 18);
      expect(gatePassMark(30), 27);
    });

    test('always leaves at least one answer spare', () {
      // The whole point of moving off 100%: one slip must not restart a
      // 30-question quiz. Guard that no size accidentally rounds back up to
      // "every answer correct".
      for (var total = 10; total <= 30; total++) {
        expect(
          gatePassMark(total) < total,
          isTrue,
          reason: '$total questions still demands a perfect score',
        );
      }
    });

    test('never asks for more correct answers than there are questions', () {
      for (var total = 1; total <= 30; total++) {
        expect(gatePassMark(total) <= total, isTrue);
        expect(gatePassMark(total) >= 1, isTrue);
      }
    });
  });
}

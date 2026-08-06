import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/widgets/mascot_widget.dart';

/// The mascot's reaction to being poked.
///
/// Tested by pumping frames rather than by looking, because a spring is
/// exactly the thing a screenshot cannot prove: it squashes and recovers
/// inside half a second, so capturing it over adb is a lottery — three
/// attempts on a device produced three identical frames and settled
/// nothing. What matters is checkable here: that it compresses, that it
/// overshoots on the way back, and that it returns to rest.
void main() {
  /// Vertical scale currently applied to the body, read off the transform
  /// the squash is implemented with.
  double squashOf(WidgetTester tester) {
    final transform = tester.widget<Transform>(
      find.descendant(
        of: find.byType(MascotWidget),
        matching: find.byWidgetPredicate(
          (w) => w is Transform && w.alignment == Alignment.bottomCenter,
        ),
      ),
    );
    return transform.transform.storage[5]; // scale Y
  }

  Future<void> pumpMascot(WidgetTester tester) {
    return tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: MascotWidget(mood: MascotMood.happy)),
        ),
      ),
    );
  }

  testWidgets('resting mascot sits at its natural size', (tester) async {
    await pumpMascot(tester);
    expect(squashOf(tester), closeTo(1, 0.001));
  });

  testWidgets('a poke compresses it immediately', (tester) async {
    await pumpMascot(tester);
    await tester.tap(find.byType(MascotWidget));
    await tester.pump();

    // Instant, not eased: the impact should read as a knock. Easing into
    // the squash as well makes it feel like rubber.
    expect(squashOf(tester), lessThan(0.9));
  });

  testWidgets('it springs back past its resting size before settling',
      (tester) async {
    await pumpMascot(tester);
    await tester.tap(find.byType(MascotWidget));
    await tester.pump();

    var overshot = false;
    var returned = false;
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      final scale = squashOf(tester);
      // Above 1 means it went past its resting size on the way back, which
      // is the difference between a spring and a shrink-and-grow.
      if (scale > 1.01) overshot = true;
      if (overshot && (scale - 1).abs() < 0.005) {
        returned = true;
        break;
      }
    }

    expect(overshot, isTrue, reason: 'no overshoot means no spring');
    expect(returned, isTrue,
        reason: 'a mascot left mid-bounce would sit permanently deformed');
  });

  testWidgets('poking it mid-bounce re-compresses and still comes to rest',
      (tester) async {
    // Each poke deliberately applies the same compression rather than
    // stacking onto the squash already in flight: stacking looks livelier
    // for two taps and then drives an impatient child's mascot down to
    // nothing. What must hold is that an interrupting poke still produces
    // a fresh squash and still settles — never a mascot left deformed.
    await pumpMascot(tester);
    await tester.tap(find.byType(MascotWidget));
    await tester.pump(const Duration(milliseconds: 80));

    await tester.tap(find.byType(MascotWidget));
    await tester.pump();
    expect(squashOf(tester), lessThan(0.9), reason: 'compressed again');

    for (var i = 0; i < 200; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      if ((squashOf(tester) - 1).abs() < 0.005) break;
    }
    expect(squashOf(tester), closeTo(1, 0.01));
  });
}

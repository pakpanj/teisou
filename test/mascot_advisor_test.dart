import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/theme/app_theme.dart';
import 'package:kana_master/core/widgets/mascot_advisor.dart';
import 'package:kana_master/core/widgets/mascot_widget.dart';

/// The advisor standing at the bottom of a screen.
///
/// The behaviour worth pinning down is not that it appears — that is
/// obvious the moment you look at it — but that it *gets out of the way*.
/// Its first version simply floated over the page, which looked correct on
/// a short screen and, on the 50-row chapter list, sat on top of two
/// tappable chapters and greyed out their text. A screenshot of the short
/// screen would have declared it fine.
void main() {
  const rows = 40;

  /// A tall list under an advisor, the shape every real caller has.
  Widget wrap({ScrollController? controller}) => ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: MascotAdvisor(
              mood: MascotMood.happy,
              message: 'Pilih satu bab untuk mulai belajar.',
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.only(
                  bottom: MascotAdvisor.reservedBottomSpace,
                ),
                children: [
                  for (var i = 0; i < rows; i++)
                    SizedBox(height: 80, child: Text('bab $i')),
                ],
              ),
            ),
          ),
        ),
      );

  /// How visible the advisor currently is, read off the fade it hides with.
  double opacityOf(WidgetTester tester) {
    return tester
        .widget<AnimatedOpacity>(
          // Scoped to the advisor's own wrapper: the list it wraps has
          // AnimatedOpacitys of its own, and a plain descendant search
          // reaches those first.
          find.descendant(
            of: find.byType(MascotAdvisor),
            matching: find.ancestor(
              of: find.byType(MascotWidget),
              matching: find.byType(AnimatedOpacity),
            ),
          ),
        )
        .opacity;
  }

  bool ignoringPointers(WidgetTester tester) {
    return tester
        .widget<IgnorePointer>(
          // Scoped to the advisor's own wrapper: the list it wraps has
          // IgnorePointers of its own, and a plain descendant search
          // reaches those first.
          find.descendant(
            of: find.byType(MascotAdvisor),
            matching: find.ancestor(
              of: find.byType(MascotWidget),
              matching: find.byType(IgnorePointer),
            ),
          ),
        )
        .ignoring;
  }

  testWidgets('greets the learner while the list is at its top',
      (tester) async {
    await tester.pumpWidget(wrap());
    // Past the entrance, not pumpAndSettle: the mascot's idle animation
    // repeats forever, so nothing on this screen ever settles.
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Pilih satu bab untuk mulai belajar.'), findsOneWidget);
    expect(opacityOf(tester), 1);
  });

  testWidgets('steps aside once the learner scrolls', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(wrap(controller: controller));
    await tester.pump(const Duration(milliseconds: 600));

    controller.jumpTo(400);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(opacityOf(tester), 0,
        reason: 'a character parked over the chapter rows hides two of them');
  });

  testWidgets('lets taps through to the content it was covering',
      (tester) async {
    // The half of the bug a fade alone does not fix: an invisible character
    // still eats the tap meant for the chapter underneath it.
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(wrap(controller: controller));
    await tester.pump(const Duration(milliseconds: 600));

    controller.jumpTo(400);
    await tester.pump();

    expect(ignoringPointers(tester), isTrue);
  });

  testWidgets('comes back when the learner returns to the top',
      (tester) async {
    // Otherwise stepping aside is indistinguishable from leaving for good,
    // and the guidance is gone for the rest of the session.
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(wrap(controller: controller));
    await tester.pump(const Duration(milliseconds: 600));

    controller.jumpTo(400);
    await tester.pump();
    controller.jumpTo(0);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(opacityOf(tester), 1);
    expect(ignoringPointers(tester), isFalse);
  });

  testWidgets('stays put on a screen with nothing to scroll', (tester) async {
    // The same widget serves both kinds of screen, so a rule that only
    // makes sense for long lists must not hide the advisor on short ones.
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: MascotAdvisor(
              mood: MascotMood.happy,
              message: 'Halo!',
              child: SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(opacityOf(tester), 1);
    expect(find.text('Halo!'), findsOneWidget);
  });

  testWidgets('tapping the bubble quiets it and tapping the character '
      'brings it back', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.text('Pilih satu bab untuk mulai belajar.'));
    // Advanced in steps rather than one 400ms jump. AnimatedSwitcher drops
    // the outgoing bubble from a status listener, so the frame that ends
    // the fade only schedules the removal; a zero-duration pump after a
    // single long jump does not reliably deliver the rebuild that performs
    // it. Measured: the bubble is gone 240ms after the tap.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Pilih satu bab untuk mulai belajar.'), findsNothing);

    // A dismissed advisor with no way back would strand the learner
    // without the one hint the screen offers.
    await tester.tap(find.byType(MascotWidget));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Pilih satu bab untuk mulai belajar.'), findsOneWidget);
  });
}

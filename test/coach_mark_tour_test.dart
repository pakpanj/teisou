import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/theme/app_theme.dart';
import 'package:kana_master/core/widgets/mascot_widget.dart';
import 'package:kana_master/features/onboarding/coach_mark_tour.dart';

/// The coach-mark tour: the mascot pointing at real parts of a real
/// screen.
///
/// What can go wrong here is not that it fails to draw. It is that a step
/// points at a card that is no longer on the screen, or that a child taps
/// somewhere sensible and nothing happens — both of which look completely
/// fine in a screenshot of step one, which is exactly how the dead zone
/// under the speech bubble survived a first pass on a real device.
void main() {
  Widget host({
    required List<CoachStep> steps,
    required List<String> anchors,
    VoidCallback? onDone,
  }) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Builder(
        builder: (context) => Scaffold(
          body: Column(
            children: [
              for (final id in anchors)
                TutorialTarget(
                  id: id,
                  child: SizedBox(height: 80, width: 200, child: Text(id)),
                ),
              ElevatedButton(
                onPressed: () => Navigator.of(context)
                    .push(
                      PageRouteBuilder<void>(
                        opaque: false,
                        pageBuilder: (_, _, _) => CoachMarkTour(
                          steps: steps,
                          nextLabel: 'Lanjut',
                          finishLabel: 'Siap!',
                          skipLabel: 'Lewati',
                        ),
                      ),
                    )
                    .then((_) => onDone?.call()),
                child: const Text('start'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  CoachStep step(String id, String message) =>
      CoachStep(anchorId: id, message: message, mood: MascotMood.explaining);

  /// The mascot breathes on a loop, so `pumpAndSettle` never returns
  /// here — it waits for an animation that is designed never to stop.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  Future<void> start(WidgetTester tester) async {
    await tester.tap(find.text('start'));
    await settle(tester);
  }

  setUp(TutorialAnchors.clear);

  testWidgets('points at the first thing before anything else', (tester) async {
    await tester.pumpWidget(
      host(
        anchors: ['a', 'b'],
        steps: [step('a', 'first'), step('b', 'second')],
      ),
    );
    await start(tester);

    expect(find.text('first'), findsOneWidget);
    expect(find.text('second'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('advances from the button', (tester) async {
    await tester.pumpWidget(
      host(
        anchors: ['a', 'b'],
        steps: [step('a', 'first'), step('b', 'second')],
      ),
    );
    await start(tester);

    await tester.tap(find.text('Lanjut'));
    await settle(tester);

    expect(find.text('second'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('advances from a tap on the speech bubble itself', (
    tester,
  ) async {
    // The bubble is not a button, so a plain Container there swallows the
    // tap and leaves the tour frozen with no sign anything is wrong. A
    // child aiming at the mascot's words rather than the small button is
    // the likeliest tap of all.
    await tester.pumpWidget(
      host(
        anchors: ['a', 'b'],
        steps: [step('a', 'first'), step('b', 'second')],
      ),
    );
    await start(tester);

    await tester.tap(find.text('first'));
    await settle(tester);

    expect(find.text('second'), findsOneWidget);
  });

  testWidgets('advances from a tap on the dimmed area', (tester) async {
    await tester.pumpWidget(
      host(
        anchors: ['a', 'b'],
        steps: [step('a', 'first'), step('b', 'second')],
      ),
    );
    await start(tester);

    // The far corner: dimming, no bubble, no badge, no button.
    await tester.tapAt(const Offset(4, 4));
    await settle(tester);

    expect(find.text('second'), findsOneWidget);
  });

  testWidgets('closes at the last step instead of running on', (tester) async {
    var closed = false;
    await tester.pumpWidget(
      host(
        anchors: ['a'],
        steps: [step('a', 'only')],
        onDone: () => closed = true,
      ),
    );
    await start(tester);

    expect(find.text('Siap!'), findsOneWidget, reason: 'last step');
    await tester.tap(find.text('Siap!'));
    await settle(tester);

    expect(closed, isTrue);
    expect(find.text('only'), findsNothing);
  });

  testWidgets('can be left at any point', (tester) async {
    var closed = false;
    await tester.pumpWidget(
      host(
        anchors: ['a', 'b'],
        steps: [step('a', 'first'), step('b', 'second')],
        onDone: () => closed = true,
      ),
    );
    await start(tester);

    await tester.tap(find.text('Lewati'));
    await settle(tester);

    expect(closed, isTrue);
  });

  testWidgets('skips a step whose target is not on the screen', (tester) async {
    // A card removed from the home screen must not dim everything and
    // point at nothing. This is the whole reason steps name an id
    // instead of holding coordinates.
    await tester.pumpWidget(
      host(
        anchors: ['a', 'c'],
        steps: [step('a', 'first'), step('b', 'gone'), step('c', 'third')],
      ),
    );
    await start(tester);

    await tester.tap(find.text('Lanjut'));
    await settle(tester);

    expect(find.text('gone'), findsNothing);
    expect(find.text('third'), findsOneWidget);
  });

  testWidgets('closes rather than hanging when nothing can be found', (
    tester,
  ) async {
    var closed = false;
    await tester.pumpWidget(
      host(
        anchors: [],
        steps: [step('a', 'first')],
        onDone: () => closed = true,
      ),
    );
    await start(tester);

    expect(closed, isTrue);
  });

  testWidgets('skip moves aside when it would sit on the highlight', (
    tester,
  ) async {
    // Every module tour ends on the quiz icon in the top-right of the app
    // bar, which is exactly where skip is drawn.
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Stack(
              children: [
                Positioned(
                  top: 4,
                  right: 4,
                  child: TutorialTarget(
                    id: 'corner',
                    child: const SizedBox(height: 48, width: 48),
                  ),
                ),
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      PageRouteBuilder<void>(
                        opaque: false,
                        pageBuilder: (_, _, _) => CoachMarkTour(
                          steps: [step('corner', 'up here')],
                          nextLabel: 'Lanjut',
                          finishLabel: 'Siap!',
                          skipLabel: 'Lewati',
                        ),
                      ),
                    ),
                    child: const Text('start'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await start(tester);

    final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    expect(
      tester.getCenter(find.text('Lewati')).dx,
      lessThan(width / 2),
      reason: 'skip is still drawn over the highlight it should avoid',
    );
  });

  testWidgets('skip stays put for a target that is merely near the top', (
    tester,
  ) async {
    // A full-width card just under the app bar: it reaches as far right
    // as skip does and sits close to it, but below it. Moving skip out of
    // its way lands it on the back button instead.
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Bab')),
            body: Column(
              children: [
                const SizedBox(height: 24),
                const TutorialTarget(
                  id: 'card',
                  child: SizedBox(height: 90, width: double.infinity),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    PageRouteBuilder<void>(
                      opaque: false,
                      pageBuilder: (_, _, _) => CoachMarkTour(
                        steps: [step('card', 'just below')],
                        nextLabel: 'Lanjut',
                        finishLabel: 'Siap!',
                        skipLabel: 'Lewati',
                      ),
                    ),
                  ),
                  child: const Text('start'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await start(tester);

    final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    expect(tester.getCenter(find.text('Lewati')).dx, greaterThan(width / 2));
  });

  testWidgets('an anchor leaving the tree does not take its id with it', (
    tester,
  ) async {
    // Two screens can hold the same id during a transition. The one
    // going away must not unregister the one arriving.
    final key = GlobalKey();
    TutorialAnchors.register('a', key);
    final stale = GlobalKey();
    TutorialAnchors.unregister('a', stale);

    expect(TutorialAnchors.keyFor('a'), same(key));
  });
}

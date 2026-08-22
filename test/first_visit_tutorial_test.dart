import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kana_master/core/theme/app_theme.dart';
import 'package:kana_master/core/widgets/mascot_widget.dart';
import 'package:kana_master/data/repositories/onboarding_repository.dart';
import 'package:kana_master/features/onboarding/coach_mark_tour.dart';
import 'package:kana_master/features/onboarding/first_visit_tutorial.dart';

/// When a module tutorial is allowed to start.
///
/// The bug this covers only exists on screens that animate in, which is
/// every module screen and not the home screen — so it shipped looking
/// perfect on home and put the very first module highlight off the edge
/// of the screen, over nothing.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TutorialAnchors.clear();
  });

  Widget app() => ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => FirstVisitTutorial(
                        id: TutorialId.kanji,
                        tour: (_) => [
                          const CoachStep(
                            anchorId: 'a',
                            message: 'here',
                            mood: MascotMood.explaining,
                          ),
                        ],
                        child: const Scaffold(
                          body: TutorialTarget(
                            id: 'a',
                            child: SizedBox(height: 60, width: 120),
                          ),
                        ),
                      ),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

  testWidgets('highlights where the target really is, not where it was '
      'mid-slide', (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text('open'));

    // Frame by frame through the push, which is exactly the situation
    // that broke it: measuring during the slide gives the target's
    // position at that instant, several hundred pixels off to the right
    // of where it comes to rest.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(find.text('here'), findsOneWidget, reason: 'the tour is up');

    final target = tester.getRect(find.byType(TutorialTarget));
    // The badge sits on the highlight's top-left corner, so it is a
    // readable stand-in for where the hole was cut.
    final badge = tester.getCenter(find.text('1'));

    expect((badge.dx - target.left).abs(), lessThan(40),
        reason: 'the highlight is ${badge.dx - target.left}px to the side '
            'of the thing it is meant to be around');
    expect((badge.dy - target.top).abs(), lessThan(40));
  });

  testWidgets('shows once, then never again', (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text('open'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(find.text('here'), findsOneWidget);

    await tester.tap(find.text('Lewati'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    // Back on the module screen; leave it and come back. Popped
    // directly because this stand-in screen has no app bar to press.
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.tap(find.text('open'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(find.text('here'), findsNothing,
        reason: 'skipping counts as seen — replaying it next visit '
            'overrides the learner saying no');
  });
}

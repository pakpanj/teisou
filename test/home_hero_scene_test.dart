import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/theme/app_theme.dart';
import 'package:kana_master/core/widgets/mascot_widget.dart';
import 'package:kana_master/features/home/widgets/home_hero_scene.dart';

/// The home banner is the first thing anyone sees, and in dark mode it was
/// rendering as a flat triangle and two circles with no cat in it —
/// reported from a screenshot as simply looking broken.
///
/// The cause was not a failed load. `_FujiSakuraPainter`'s own doc comment
/// describes Mt. Fuji as "centered **behind the mascot**", and the dark
/// path never placed a mascot: the scene was drawn as a backdrop and then
/// shipped without its subject.
void main() {
  Future<void> pumpHero(WidgetTester tester, ThemeData theme) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(body: HomeHeroScene()),
      ),
    );
    await tester.pump();
  }

  testWidgets('the dark hero still has the mascot in it', (tester) async {
    await pumpHero(tester, AppTheme.dark);
    expect(
      find.byType(MascotWidget),
      findsOneWidget,
      reason: 'dark mode shows the backdrop with nothing standing in it, so '
          'the app has no character on its own home screen',
    );
  });

  testWidgets('the mascot is waving, not reacting to anything', (tester) async {
    // This banner greets; it is not responding to an answer. Any of the
    // coaching moods here would be the mascot reacting to nothing.
    await pumpHero(tester, AppTheme.dark);
    final mascot = tester.widget<MascotWidget>(find.byType(MascotWidget));
    expect(mascot.mood, MascotMood.waving);
    expect(
      mascot.showBackdrop,
      isFalse,
      reason: 'a disc behind the cat would sit on top of the scene',
    );
  });

  testWidgets('light mode renders without throwing', (tester) async {
    // The light path loads a real illustration; a missing or broken asset
    // must fall through to the drawn scene rather than take Home down.
    await pumpHero(tester, AppTheme.light);
    expect(tester.takeException(), isNull);
  });
}

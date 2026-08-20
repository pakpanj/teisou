import 'dart:io';

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
///
/// A night illustration now exists, so dark mode shows that instead — and
/// the mascot lives inside the PNG, where no widget test can see it. What
/// is worth guarding therefore moved: that dark asks for its own art
/// rather than silently reusing the day art, and that the fallback still
/// carries a mascot for whenever the asset cannot be loaded.
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

  test('the night illustration exists and is its own file', () {
    final dark = File('assets/banners/home_hero_dark.png');
    final light = File('assets/banners/home_hero.png');
    expect(dark.existsSync(), isTrue, reason: 'dark falls back to geometry');
    expect(
      dark.readAsBytesSync().length,
      isNot(light.readAsBytesSync().length),
      reason: 'the dark banner is a copy of the day one, which on a dark '
          'ground is a bright rectangle rather than a night scene',
    );
  });

  test('each theme is pointed at its own asset', () {
    final source =
        File('lib/features/home/widgets/home_hero_scene.dart').readAsStringSync();
    expect(source.contains("'assets/banners/home_hero_dark.png'"), isTrue);
    expect(source.contains("'assets/banners/home_hero.png'"), isTrue);
  });

  testWidgets('the drawn fallback still has a mascot standing in it',
      (tester) async {
    // Reached when an asset fails to load. Without this the fallback is a
    // backdrop with nothing in front of it — the original defect.
    const fallback = HomeHeroFallback();
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const Scaffold(body: fallback)),
    );
    await tester.pump();

    expect(find.byType(MascotWidget), findsOneWidget);
    final mascot = tester.widget<MascotWidget>(find.byType(MascotWidget));
    // This banner greets; it is not responding to an answer, so any of the
    // coaching moods here would be the mascot reacting to nothing.
    expect(mascot.mood, MascotMood.waving);
    expect(
      mascot.showBackdrop,
      isFalse,
      reason: 'a disc behind the cat would sit on top of the scene',
    );
  });

  testWidgets('both themes render without throwing', (tester) async {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      await pumpHero(tester, theme);
      expect(tester.takeException(), isNull);
    }
  });
}

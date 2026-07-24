import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kana_master/core/providers.dart';
import 'package:kana_master/data/models/app_language.dart';
import 'package:kana_master/data/models/jlpt_level.dart';
import 'package:kana_master/features/kanji/kanji_level_screen.dart';
import 'package:kana_master/features/kotoba/kotoba_home_screen.dart';
import 'package:kana_master/features/particle/particle_home_screen.dart';

void main() {
  // kanjiLearnedIdsProvider reads SharedPreferences — without a mock, the
  // plugin channel has nothing to respond to in a pure widget-test
  // environment.
  SharedPreferences.setMockInitialValues({});

  testWidgets(
    'KotobaHomeScreen app bar title switches language',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          child: const MaterialApp(home: KotobaHomeScreen()),
        ),
      );
      expect(find.text('Kosakata'), findsOneWidget);

      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [languageProvider.overrideWith((ref) => AppLanguage.english)],
          child: const MaterialApp(home: KotobaHomeScreen()),
        ),
      );
      expect(find.text('Vocabulary'), findsOneWidget);
      expect(find.text('Kosakata'), findsNothing);
    },
  );

  testWidgets(
    'KanjiLevelScreen filter chips switch language once real N5 data loads',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [languageProvider.overrideWith((ref) => AppLanguage.english)],
          child: const MaterialApp(
            home: KanjiLevelScreen(jlptLevel: JlptLevel.n5, levelName: 'N5'),
          ),
        ),
      );
      // kanji_data.json (2425 entries) is large enough that loading it
      // doesn't settle via plain pump() calls inside testWidgets' fake-async
      // zone — runAsync briefly escapes that zone so the real asset-load
      // future actually completes.
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
      await tester.pump();
      await tester.pump();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Not Learned'), findsOneWidget);
      expect(find.text('Learned'), findsOneWidget);
      expect(find.text('Semua'), findsNothing);
    },
  );

  testWidgets(
    'ParticleHomeScreen app bar title switches language',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          child: const MaterialApp(home: ParticleHomeScreen()),
        ),
      );
      expect(find.text('Partikel'), findsOneWidget);

      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [languageProvider.overrideWith((ref) => AppLanguage.english)],
          child: const MaterialApp(home: ParticleHomeScreen()),
        ),
      );
      expect(find.text('Particles'), findsOneWidget);
      expect(find.text('Partikel'), findsNothing);
    },
  );
}

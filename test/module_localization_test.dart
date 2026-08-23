import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kana_master/core/providers.dart';
import 'package:kana_master/data/models/app_language.dart';
import 'package:kana_master/data/models/jlpt_level.dart';
import 'package:kana_master/features/exam/exam_mode_picker_screen.dart';
import 'package:kana_master/features/kanji/kanji_level_screen.dart';
import 'package:kana_master/features/kotoba/kotoba_home_screen.dart';
import 'package:kana_master/features/particle/particle_home_screen.dart';
import 'package:kana_master/features/paywall/paywall_screen.dart';

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
      // kanji_data.json (2425 entries) does not settle via plain pump()
      // inside testWidgets' fake-async zone — runAsync briefly escapes
      // that zone so the real asset-load future can complete.
      //
      // **Polled rather than slept.** A flat 500ms wait was enough while
      // the parse ran inline; it stopped being enough the moment the
      // parse moved to a background isolate, because spawning one in a
      // test is slow, and the failure looked like a missing widget
      // rather than a timeout. Waiting for the thing itself does not
      // need re-tuning the next time the load gets slower or faster.
      for (var attempt = 0; attempt < 40; attempt++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
        if (find.text('All').evaluate().isNotEmpty) break;
      }

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

  testWidgets(
    'ExamModePickerScreen category subtitles switch language',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [languageProvider.overrideWith((ref) => AppLanguage.english)],
          child: const MaterialApp(home: ExamModePickerScreen()),
        ),
      );

      expect(find.text('Hiragana, Katakana, or mixed'), findsOneWidget);
      expect(find.text('Single kanji or word combinations'), findsOneWidget);
      expect(find.text('Hiragana, Katakana, atau campuran'), findsNothing);
    },
  );

  testWidgets(
    'PaywallScreen benefit list switches language',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [languageProvider.overrideWith((ref) => AppLanguage.english)],
          child: const MaterialApp(
            home: PaywallScreen(moduleId: 'kanji', moduleTitle: 'Kanji N5'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Unlock All Modules!'), findsOneWidget);
      expect(find.text('⭐ Exclusive Battle Card skins'), findsOneWidget);
      expect(find.text('📚 Complete learning materials'), findsOneWidget);
      expect(find.text('📝 Premium practice questions'), findsOneWidget);
      expect(find.text('🚫 Ad-free'), findsOneWidget);
      expect(find.text('Watch Ad for 24-Hour Preview'), findsOneWidget);
      expect(find.text('Buka Semua Modul!'), findsNothing);
    },
  );
}

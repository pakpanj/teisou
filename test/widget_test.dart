import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/providers.dart';
import 'package:kana_master/data/models/app_language.dart';
import 'package:kana_master/features/home/home_screen.dart';

void main() {
  testWidgets('HomeScreen shows title and menu cards', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: HomeScreen()),
      ),
    );

    expect(find.textContaining('Kana'), findsOneWidget);
    expect(find.text('Belajar Hiragana'), findsOneWidget);
    expect(find.text('Belajar Katakana'), findsOneWidget);
    expect(find.text('Uji kemampuanmu!'), findsOneWidget);
  });

  testWidgets(
    'HomeScreen switches to English chrome text when languageProvider is English',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [languageProvider.overrideWith((ref) => AppLanguage.english)],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      expect(find.text('Learn Hiragana'), findsOneWidget);
      expect(find.text('Learn Katakana'), findsOneWidget);
      expect(find.text('Test your skills!'), findsOneWidget);
      expect(find.text('Belajar Hiragana'), findsNothing);
    },
  );
}

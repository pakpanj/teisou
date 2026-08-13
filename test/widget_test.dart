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
    // The menu is grouped by learning stage now; "Dasar" is the first
    // heading and holds the two kana cards. There is deliberately no Ujian
    // card here any more — it duplicated the bottom nav's Ujian tab.
    expect(find.text('Dasar'), findsOneWidget);
    expect(find.text('Belajar Hiragana'), findsOneWidget);
    expect(find.text('Belajar Katakana'), findsOneWidget);
    expect(find.text('Uji kemampuanmu!'), findsNothing);
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

      expect(find.text('Basics'), findsOneWidget);
      expect(find.text('Learn Hiragana'), findsOneWidget);
      expect(find.text('Learn Katakana'), findsOneWidget);
      expect(find.text('Belajar Hiragana'), findsNothing);
      expect(find.text('Dasar'), findsNothing);
    },
  );

  // Card Game Mode had a finished, deployed engine -- matchmaking, a bot,
  // server-side scoring, a star ladder -- and no way in from Home for
  // weeks: the only entry point was a friend challenge buried in the chat
  // hub. That is not a failure any other check can see, because every
  // screen involved compiles, renders and passes its own tests while
  // being unreachable. This is the guard for it.
  testWidgets('HomeScreen has a way into Card Game Mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Mode Kartu'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Mode Kartu'), findsOneWidget);
    expect(find.text('Bertanding'), findsOneWidget);
  });
}

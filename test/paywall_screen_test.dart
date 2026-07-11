import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/features/paywall/paywall_screen.dart';

void main() {
  testWidgets('PaywallScreen shows benefits and both upgrade paths', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: PaywallScreen(moduleId: 'kanji', moduleTitle: 'Kanji N5'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Buka Semua Modul!'), findsOneWidget);
    expect(find.text('Akses semua modul belajar'), findsOneWidget);
    expect(find.text('Tanpa iklan'), findsOneWidget);
    expect(find.text('Progress tersimpan cloud'), findsOneWidget);
    expect(find.text('Leaderboard eksklusif'), findsOneWidget);
    expect(find.textContaining('Upgrade Premium'), findsOneWidget);
    expect(find.text('Nonton Iklan untuk Preview 24 Jam'), findsOneWidget);
  });
}

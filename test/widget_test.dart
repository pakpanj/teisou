import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
}

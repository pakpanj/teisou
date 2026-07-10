import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/data/models/kana_type.dart';
import 'package:kana_master/features/flashcard/flashcard_screen.dart';
import 'package:kana_master/features/flashcard/widgets/flip_card.dart';

void main() {
  testWidgets(
    'FlashcardScreen renders first hiragana card and flips to show '
    'romaji + example, without crashing even without Firebase available',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(type: KanaType.hiragana),
          ),
        ),
      );

      // Kana JSON + bundled SVG glyph load for real; Firebase-backed
      // progress stream errors out in the test harness and should fall
      // back gracefully.
      await tester.pumpAndSettle();

      expect(find.text('Belajar Hiragana'), findsOneWidget);
      expect(find.text('1 / 46'), findsOneWidget);
      expect(find.byType(SvgPicture), findsOneWidget);

      // Tapping the card should flip it to reveal the romaji + example.
      await tester.tap(find.byType(FlipCard));
      await tester.pumpAndSettle();

      expect(find.text('A'), findsOneWidget);
      expect(find.text('Contoh Kata'), findsOneWidget);
    },
  );
}

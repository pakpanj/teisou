import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/data/models/kana_type.dart';
import 'package:kana_master/features/flashcard/flashcard_screen.dart';
import 'package:kana_master/core/widgets/stroke_order_animator.dart';
import 'package:kana_master/features/flashcard/widgets/flip_card.dart';

void main() {
  // Each test reads the kana dataset, and rootBundle caches one Future
  // per asset globally — without clearing it the second test awaits a
  // Future from the first test's fake-async zone and hangs instead of
  // failing. Same trap as kanjivg_parser_test and kana_table_screen_test.
  setUp(rootBundle.clear);

  testWidgets(
    'FlashcardScreen renders first hiragana card and flips to show '
    'romaji + example, without crashing even without Firebase available',
    (WidgetTester tester) async {
      // The card face is a fixed 700dp tall by design, so the default test
      // surface (800x600) isn't tall enough to lay it out without
      // overflowing. Use a taller surface matching a real device instead of
      // shrinking the card.
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(type: KanaType.hiragana),
          ),
        ),
      );

      // Kana JSON + bundled SVG glyph load for real; Firebase-backed
      // progress stream errors out in the test harness and should fall
      // back gracefully. Wrapped in runAsync — same reasoning as the large
      // Kanji dataset elsewhere in this suite: a real asset-bundle
      // round-trip doesn't reliably complete under the fake-async zone
      // pumpAndSettle otherwise runs in, and this got slower to load once
      // the kana dataset grew from 92 to 208 entries.
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
      await tester.pumpAndSettle();

      expect(find.text('Belajar Hiragana'), findsOneWidget);
      expect(find.text('1 / 104'), findsOneWidget);
      // The front face draws the stroke animation, not a flat SVG. It used
      // to be an SvgPicture, which rendered the KanjiVG file complete with
      // its baked-in stroke-number layer — order but never direction.
      expect(find.byType(StrokeOrderAnimator), findsOneWidget);
      expect(find.byType(SvgPicture), findsNothing);

      // Tapping the card should flip it to reveal the romaji + example.
      await tester.tap(find.byType(FlipCard));
      await tester.pumpAndSettle();

      expect(find.text('A'), findsOneWidget);
      expect(find.text('Contoh Kata'), findsOneWidget);
      // The back face keeps the flat glyph: it is a thumbnail beside the
      // romaji, not a practice surface.
      expect(find.byType(SvgPicture), findsOneWidget);
    },
  );

  testWidgets(
    'moving to the next card slides the two cards past each other rather '
    'than cutting straight to the new one',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(type: KanaType.hiragana),
          ),
        ),
      );
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FlipCard), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pump();
      // Partway through the 280ms transition, not at either end of it.
      await tester.pump(const Duration(milliseconds: 120));

      // A hard swap would only ever have one card in the tree.
      expect(find.byType(FlipCard), findsNWidgets(2));

      final leaving = tester.getCenter(find.byKey(const ValueKey('hiragana_a')));
      final arriving = tester.getCenter(find.byKey(const ValueKey('hiragana_i')));

      // Going forward, the new card comes in from the right and the old one
      // leaves to the left. If both were given the same side the deck would
      // read as moving backwards on every second step.
      expect(arriving.dx, greaterThan(leaving.dx));
      expect(arriving.dx - leaving.dx, greaterThan(20));

      await tester.pumpAndSettle();
      expect(find.byType(FlipCard), findsOneWidget);
      expect(find.text('2 / 104'), findsOneWidget);
    },
  );
}

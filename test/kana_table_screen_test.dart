import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/data/models/kana_type.dart';
import 'package:kana_master/features/flashcard/flashcard_screen.dart';
import 'package:kana_master/features/flashcard/kana_table_screen.dart';

/// The kana chart that stands in front of the flashcards.
///
/// Two things here are easy to "tidy up" into being wrong later, so both are
/// pinned: the chart keeps its holes (や has nothing beside it, ん stands
/// alone) because the alignment down each vowel column is the whole point of
/// a kana chart, and the three blocks are split at the dataset's own row
/// boundaries rather than by counting.
void main() {
  // **Without this only the first test in the file can load the dataset.**
  // `rootBundle` caches the Future for each asset globally, so every test
  // after the first awaits a Future created inside a previous test's
  // fake-async zone — one that is already complete but can never deliver
  // that completion here. The screen then sits on its loading state
  // forever, which reads as "the character is not on screen" and sends you
  // hunting through the widget rather than the harness.
  setUp(rootBundle.clear);

  /// **The surface is deliberately absurd (800x6000).** The chart is 27 rows
  /// tall, and a `ListView` only builds what fits — on a phone-sized surface
  /// the dakuten and combined blocks are never laid out, so `find.text` does
  /// not merely fail to see them, they do not exist as elements at all. A
  /// surface tall enough to lay out the whole chart is what lets the test
  /// look at it, rather than scrolling to each character in turn.
  ///
  /// `pumpAndSettle` is also avoided: the banner ad placeholder animates
  /// indefinitely, so settling never completes. Fixed pumps are enough here
  /// because nothing being asserted on is mid-transition.
  Future<void> pumpTable(WidgetTester tester, KanaType type) async {
    tester.view.physicalSize = const Size(800, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: KanaTableScreen(type: type)),
      ),
    );
    // Polled rather than waited out. A fixed delay passed for the first
    // test in this file and then failed for the second — the asset-bundle
    // round trip does not complete under the fake-async zone, so how much
    // real time one `runAsync` buys is luck. Waiting for the data to
    // actually appear is the only version that does not flake.
    for (var attempt = 0; attempt < 60; attempt++) {
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      if (find.text('Huruf Dasar').evaluate().isNotEmpty) break;
    }
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('splits the deck into the three blocks a chart is taught in',
      (tester) async {
    await pumpTable(tester, KanaType.hiragana);

    expect(find.text('Huruf Dasar'), findsOneWidget);
    expect(find.text('Tenten & Maru'), findsOneWidget);
    expect(find.text('Huruf Gabungan'), findsOneWidget);

    // 46 + 25 + 33 = the 104 the home card advertises. A wrong row boundary
    // moves characters between blocks without losing any, so the counts are
    // what catches it.
    expect(find.text('46 huruf'), findsOneWidget);
    expect(find.text('25 huruf'), findsOneWidget);
    expect(find.text('33 huruf'), findsOneWidget);
  });

  testWidgets('every character is reachable, and only once', (tester) async {
    await pumpTable(tester, KanaType.hiragana);

    // The point of the screen: a character that used to need ~80 swipes is
    // present as its own tappable cell.
    for (final character in ['あ', 'ん', 'を', 'ぱ', 'ぴょ', 'じゃ']) {
      expect(find.text(character), findsOneWidget, reason: character);
    }
  });

  testWidgets('keeps the holes in the chart rather than closing them up',
      (tester) async {
    await pumpTable(tester, KanaType.hiragana);

    // や is followed immediately by ゆ in the data. If the row were packed
    // left-to-right they would end up side by side; laid out by column, ゆ
    // sits under う with a gap where い would be. Comparing their centres is
    // what tells the two layouts apart.
    final ya = tester.getCenter(find.text('や'));
    final yu = tester.getCenter(find.text('ゆ'));
    final a = tester.getCenter(find.text('あ'));
    final u = tester.getCenter(find.text('う'));

    expect(ya.dx, moreOrLessEquals(a.dx, epsilon: 1),
        reason: 'や belongs under あ');
    expect(yu.dx, moreOrLessEquals(u.dx, epsilon: 1),
        reason: 'ゆ belongs under う, not packed next to や');
    expect(yu.dx - ya.dx, greaterThan(20),
        reason: 'a gap should sit between them where い would be');
  });

  testWidgets('tapping a character opens that card, not the first one',
      (tester) async {
    await pumpTable(tester, KanaType.hiragana);

    await tester.tap(find.text('き'));
    // One frame only. That is enough for the route to be pushed and the
    // screen constructed, and stopping there deliberately avoids letting
    // the flashcard finish loading: it carries a banner ad, and the ads
    // plugin has no implementation under test. Stubbing that channel was
    // tried and is worse — the plugin uses its own codec, so a mock
    // returning null fails to decode and breaks every test in the file
    // with "Message corrupted".
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final card = tester.widget<FlashcardScreen>(find.byType(FlashcardScreen));
    // き is the 7th character of the deck, so index 6. A null or 0 here
    // would mean the tapped character never reached the deck and the
    // learner would land back on あ.
    expect(card.initialIndex, 6);
    tester.takeException();
  });

  testWidgets('katakana gets the same chart', (tester) async {
    await pumpTable(tester, KanaType.katakana);

    expect(find.text('Katakana'), findsOneWidget);
    expect(find.text('ア'), findsOneWidget);
    expect(find.text('ピョ'), findsOneWidget);
  });
}

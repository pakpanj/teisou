import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/theme/app_palette.dart';
import 'package:kana_master/core/theme/app_theme.dart';
import 'package:kana_master/features/battle/battle_card_picker_screen.dart';

/// The hand is where the mode's only real decision is made, and the link
/// it depends on — this card's face maps to this card's id — is invisible
/// once it is wrong: tapping あ would simply send some other card, and the
/// opponent would answer a question you never chose.
///
/// It is tested here rather than on a device because catching the ten
/// second choosing window over adb reliably proved impractical; the
/// window is short and each screenshot round trip eats most of it.
///
/// The hand used to be a strip along the bottom of the arena and is now a
/// screen of its own, which changed how a card is played: tapping used to
/// send it immediately, and now tapping selects while the button
/// confirms. Every assertion below survived that move — they are about
/// what the player sees and what comes back, not about the layout.
void main() {
  const hand = [
    (cardId: 'kana_a', prompt: 'あ'),
    (cardId: 'kana_ki', prompt: 'き'),
    (cardId: 'kana_zu', prompt: 'ず'),
  ];

  /// A clock the test moves by hand.
  ///
  /// `testWidgets` runs timers on a fake clock while `DateTime.now`
  /// keeps answering with the real one, so pumping past the deadline
  /// fires the tick and then finds the window still open. Both sides
  /// have to be the same clock for the deadline to mean anything here.
  late DateTime fakeNow;

  /// Pushes the picker over a bare screen, so `pop` has somewhere to go
  /// and its return value can be read the way the arena reads it.
  Future<void> open(
    WidgetTester tester, {
    required List<String?> popped,
    Duration left = const Duration(seconds: 7),
  }) async {
    fakeNow = DateTime(2026, 8, 20, 12);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    popped.add(
                      await Navigator.of(context).push<String>(
                        MaterialPageRoute(
                          builder: (_) => BattleCardPickerScreen(
                            cards: hand,
                            totalCards: 20,
                            deadline: fakeNow.add(left),
                            clock: () => fakeNow,
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows every card still in hand', (tester) async {
    await open(tester, popped: []);
    expect(find.text('あ'), findsOneWidget);
    expect(find.text('き'), findsOneWidget);
    expect(find.text('ず'), findsOneWidget);
  });

  testWidgets('returns the card that was tapped, not another one', (
    tester,
  ) async {
    final popped = <String?>[];
    await open(tester, popped: popped);

    await tester.tap(find.text('き'));
    await tester.pump();
    await tester.tap(find.text('Kirim ke Lawan'));
    await tester.pumpAndSettle();

    expect(popped, ['kana_ki']);
  });

  testWidgets('sends nothing until a card is chosen', (tester) async {
    final popped = <String?>[];
    await open(tester, popped: popped);

    // Pressing send with nothing selected must not close the screen — a
    // send with no card would mean the dealt card goes out while the
    // player believes they picked one.
    await tester.tap(find.text('Kirim ke Lawan'));
    await tester.pumpAndSettle();

    expect(popped, isEmpty);
    expect(find.text('あ'), findsOneWidget);
  });

  testWidgets('counts the choosing window down where the player can see it',
      (tester) async {
    await open(tester, popped: []);
    expect(find.text('7s'), findsOneWidget);
  });

  testWidgets('says how much of the hand is left, not just what is in it',
      (tester) async {
    await open(tester, popped: []);

    // Three cards left of twenty. Without the denominator this reads as
    // a small hand rather than a nearly spent one, which is the opposite
    // of what it means.
    expect(find.text('3 / 20'), findsOneWidget);
  });

  testWidgets('closes itself when the window runs out', (tester) async {
    final popped = <String?>[];
    await open(tester, popped: popped, left: const Duration(seconds: 1));

    // The dealt card goes out on its own at the deadline. A picker still
    // sitting there afterwards invites a choice that no longer counts.
    fakeNow = fakeNow.add(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('あ'), findsNothing);
    expect(popped, [null]);
  });

  testWidgets('a card can be read in either theme', (tester) async {
    // This shipped unreadable once. The first version coloured its text
    // `palette.cardWhite`, whose name says white and whose dark-theme
    // value is 0xFF1C2130 — a surface, not ink. Every character on the
    // screen came out near-black on a near-black card, which a widget
    // test catches and a passing build does not.
    for (final (theme, palette) in [
      (AppTheme.light, AppPalette.light),
      (AppTheme.dark, AppPalette.dark),
    ]) {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: theme,
            home: BattleCardPickerScreen(
              cards: hand,
              totalCards: 20,
              deadline: DateTime(2026, 8, 20, 12, 0, 7),
              clock: () => DateTime(2026, 8, 20, 12),
            ),
          ),
        ),
      );
      // Long enough for MaterialApp's own theme animation to land.
      // A single pump reads the *old* theme mid-lerp, which made the
      // dark case report the light palette and look like a bug in the
      // screen rather than in the test. Not pumpAndSettle: the picker's
      // clock ticks forever, so settling never comes.
      await tester.pump(const Duration(milliseconds: 400));

      final kana = tester.widget<Text>(find.text('あ'));
      expect(
        kana.style?.color,
        palette.textNavy,
        reason: 'the card text is not the theme ink',
      );
    }
  });
}

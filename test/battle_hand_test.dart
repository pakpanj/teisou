import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/features/battle/widgets/battle_arena.dart';

/// The hand is where the mode's only real decision is made, and the link
/// it depends on — this card's face maps to this card's id — is invisible
/// once it is wrong: tapping あ would simply send some other card, and the
/// opponent would answer a question you never chose.
///
/// It is tested here rather than on a device because catching the ten
/// second choosing window over adb reliably proved impractical; the
/// window is short and each dump-and-tap round trip eats most of it.
void main() {
  Widget host({required void Function(String) onPlay}) {
    return MaterialApp(
      home: Scaffold(
        body: BattleHand(
          title: 'Pilih kartu',
          secondsLeft: 7,
          totalCards: 20,
          cards: const [
            (cardId: 'kana_a', prompt: 'あ'),
            (cardId: 'kana_ki', prompt: 'き'),
            (cardId: 'kana_zu', prompt: 'ず'),
          ],
          onPlay: onPlay,
        ),
      ),
    );
  }

  testWidgets('shows every card still in hand', (tester) async {
    await tester.pumpWidget(host(onPlay: (_) {}));
    expect(find.text('あ'), findsOneWidget);
    expect(find.text('き'), findsOneWidget);
    expect(find.text('ず'), findsOneWidget);
  });

  testWidgets('plays the card that was tapped, not another one', (
    tester,
  ) async {
    final played = <String>[];
    await tester.pumpWidget(host(onPlay: played.add));

    await tester.tap(find.text('き'));
    await tester.pump();

    expect(played, ['kana_ki']);
  });

  testWidgets('counts the choosing window down where the player can see it',
      (tester) async {
    await tester.pumpWidget(host(onPlay: (_) {}));
    expect(find.text('7s'), findsOneWidget);

  });

  testWidgets('says how much of the hand is left, not just what is in it',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BattleHand(
            title: 'Kartu di tanganmu',
            secondsLeft: 7,
            totalCards: 20,
            cards: const [
              (cardId: 'kana_a', prompt: 'あ'),
              (cardId: 'kana_ki', prompt: 'き'),
              (cardId: 'kana_zu', prompt: 'ず'),
            ],
            onPlay: (_) {},
          ),
        ),
      ),
    );

    // Three cards left of twenty. Without the denominator this reads
    // as a small hand rather than a nearly spent one, which is the
    // opposite of what it means.
    expect(find.text('3 / 20'), findsOneWidget);
  });
}

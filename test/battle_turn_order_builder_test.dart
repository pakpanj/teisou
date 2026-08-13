import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/services/battle_turn_order_builder.dart';

void main() {
  List<String> deck(String prefix) =>
      List.generate(20, (i) => '$prefix$i');

  test('turnOrder has exactly 20 rounds, indexed 0-19 in order', () {
    final entries = buildTurnOrder(
      firstUid: 'a',
      firstDeck: deck('a'),
      secondUid: 'b',
      secondDeck: deck('b'),
      random: Random(1),
    );
    expect(entries.length, 20);
    for (var i = 0; i < 20; i++) {
      expect(entries[i].round, i);
    }
  });

  test('firstUid always owns round 0, then turns strictly alternate', () {
    final entries = buildTurnOrder(
      firstUid: 'a',
      firstDeck: deck('a'),
      secondUid: 'b',
      secondDeck: deck('b'),
      random: Random(1),
    );
    expect(entries[0].deckOwnerUid, 'a');
    for (var i = 0; i < 20; i++) {
      expect(entries[i].deckOwnerUid, i.isEven ? 'a' : 'b');
    }
  });

  test('each player ends up with exactly 10 rounds', () {
    final entries = buildTurnOrder(
      firstUid: 'a',
      firstDeck: deck('a'),
      secondUid: 'b',
      secondDeck: deck('b'),
      random: Random(1),
    );
    expect(entries.where((e) => e.deckOwnerUid == 'a').length, 10);
    expect(entries.where((e) => e.deckOwnerUid == 'b').length, 10);
  });

  test('no card id repeats within the match, for either player', () {
    final entries = buildTurnOrder(
      firstUid: 'a',
      firstDeck: deck('a'),
      secondUid: 'b',
      secondDeck: deck('b'),
      random: Random(1),
    );
    final cardIds = entries.map((e) => e.cardId).toList();
    expect(cardIds.toSet().length, cardIds.length);
  });

  test('only 10 of each player\'s 20-card deck are used — half sits '
      'out, per "setengah deck tidak terpakai"', () {
    final entries = buildTurnOrder(
      firstUid: 'a',
      firstDeck: deck('a'),
      secondUid: 'b',
      secondDeck: deck('b'),
      random: Random(1),
    );
    final aCards = entries
        .where((e) => e.deckOwnerUid == 'a')
        .map((e) => e.cardId)
        .toSet();
    final bCards = entries
        .where((e) => e.deckOwnerUid == 'b')
        .map((e) => e.cardId)
        .toSet();
    expect(aCards.length, 10);
    expect(aCards.every((c) => deck('a').contains(c)), isTrue);
    expect(bCards.length, 10);
    expect(bCards.every((c) => deck('b').contains(c)), isTrue);
  });

  test('is deterministic given the same seeded Random', () {
    final first = buildTurnOrder(
      firstUid: 'a',
      firstDeck: deck('a'),
      secondUid: 'b',
      secondDeck: deck('b'),
      random: Random(42),
    );
    final second = buildTurnOrder(
      firstUid: 'a',
      firstDeck: deck('a'),
      secondUid: 'b',
      secondDeck: deck('b'),
      random: Random(42),
    );
    for (var i = 0; i < 20; i++) {
      expect(first[i].cardId, second[i].cardId);
    }
  });

  test('a different seed produces a different card selection (proves it '
      'is actually shuffling, not just taking the deck in order)', () {
    final first = buildTurnOrder(
      firstUid: 'a',
      firstDeck: deck('a'),
      secondUid: 'b',
      secondDeck: deck('b'),
      random: Random(1),
    );
    final second = buildTurnOrder(
      firstUid: 'a',
      firstDeck: deck('a'),
      secondUid: 'b',
      secondDeck: deck('b'),
      random: Random(2),
    );
    final firstCards = first.map((e) => e.cardId).toList();
    final secondCards = second.map((e) => e.cardId).toList();
    expect(firstCards, isNot(equals(secondCards)));
  });

  test('works with a deck larger than 20 (extra cards are simply never '
      'drawn from)', () {
    final entries = buildTurnOrder(
      firstUid: 'a',
      firstDeck: List.generate(30, (i) => 'a$i'),
      secondUid: 'b',
      secondDeck: deck('b'),
      random: Random(1),
    );
    expect(entries.length, 20);
  });
}

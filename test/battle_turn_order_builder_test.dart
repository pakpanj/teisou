import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/constants/battle_rules.dart';
import 'package:kana_master/core/services/battle_turn_order_builder.dart';

void main() {
  List<String> deck(String prefix) =>
      List.generate(20, (i) => '$prefix$i');

  test('turnOrder covers both decks in full, indexed in order', () {
    final entries = buildTurnOrder(
      firstUid: 'a',
      firstDeck: deck('a'),
      secondUid: 'b',
      secondDeck: deck('b'),
      random: Random(1),
    );
    expect(entries.length, kBattleTotalRounds);
    for (var i = 0; i < kBattleTotalRounds; i++) {
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
    for (var i = 0; i < kBattleTotalRounds; i++) {
      expect(entries[i].deckOwnerUid, i.isEven ? 'a' : 'b');
    }
  });

  test('each player owns exactly half the rounds', () {
    final entries = buildTurnOrder(
      firstUid: 'a',
      firstDeck: deck('a'),
      secondUid: 'b',
      secondDeck: deck('b'),
      random: Random(1),
    );
    expect(entries.where((e) => e.deckOwnerUid == 'a').length,
        kBattleTotalRounds ~/ 2);
    expect(entries.where((e) => e.deckOwnerUid == 'b').length,
        kBattleTotalRounds ~/ 2);
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

  // Corrected 2026-08-14: this used to assert the opposite — that only
  // half of each deck was ever drawn from. That followed from reading
  // the main phase as ten cards in total rather than ten each, which
  // also left the whole extension unreachable. Every card a player is
  // dealt can now actually come up.
  test('a full match draws on every card in both decks', () {
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
    expect(aCards.length, kBattleTotalRounds ~/ 2);
    expect(aCards.every((c) => deck('a').contains(c)), isTrue);
    expect(bCards.length, kBattleTotalRounds ~/ 2);
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
    for (var i = 0; i < kBattleTotalRounds; i++) {
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

  test('works with a deck larger than the match needs', () {
    final entries = buildTurnOrder(
      firstUid: 'a',
      firstDeck: List.generate(60, (i) => 'a$i'),
      secondUid: 'b',
      secondDeck: deck('b'),
      random: Random(1),
    );
    expect(entries.length, kBattleTotalRounds);
  });
}

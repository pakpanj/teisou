import 'dart:math';

import '../constants/battle_rules.dart';

import '../../data/models/turn_order_entry.dart';

/// Builds the whole `turnOrder` for a fresh match, once, at creation —
/// see `NOTES_CARD_GAME_MODE.md`'s "Detail penilaian Cloud Function"
/// ("Urutan kartu ditentukan sekali, bukan diturunkan ulang tiap kali
/// diperlukan").
///
/// [firstDeck]/[secondDeck] must each hold a player's full 20-card deck,
/// and **all of it is now reachable**: ten cards each decide the main
/// phase, and if that ends level the rest are played out to the end. See
/// `kBattleMainPhaseRounds` for the correction that made that true — the
/// first version dealt each player only ten of their twenty cards and
/// spent five of those before the match could already be over, so half
/// of every deck could never be drawn at all.
///
/// [firstUid] always plays round 0 — the coin flip for who goes first
/// happens at the call site (`Random` at match-creation time), not in
/// here. Turns then strictly alternate, so each player owns exactly half
/// the rounds.
List<TurnOrderEntry> buildTurnOrder({
  required String firstUid,
  required List<String> firstDeck,
  required String secondUid,
  required List<String> secondDeck,
  Random? random,
}) {
  assert(
    firstDeck.length >= kBattleTotalRounds ~/ 2,
    'firstDeck must hold a full deck',
  );
  assert(
    secondDeck.length >= kBattleTotalRounds ~/ 2,
    'secondDeck must hold a full deck',
  );

  final rng = random ?? Random();
  final cardsPerPlayer = kBattleTotalRounds ~/ 2;
  final firstPool = (List<String>.from(firstDeck)..shuffle(rng))
      .take(cardsPerPlayer)
      .toList();
  final secondPool = (List<String>.from(secondDeck)..shuffle(rng))
      .take(cardsPerPlayer)
      .toList();

  final entries = List<TurnOrderEntry?>.filled(kBattleTotalRounds, null);
  for (var i = 0; i < cardsPerPlayer; i++) {
    entries[i * 2] = TurnOrderEntry(
      round: i * 2,
      deckOwnerUid: firstUid,
      cardId: firstPool[i],
    );
    entries[i * 2 + 1] = TurnOrderEntry(
      round: i * 2 + 1,
      deckOwnerUid: secondUid,
      cardId: secondPool[i],
    );
  }
  return entries.cast<TurnOrderEntry>();
}

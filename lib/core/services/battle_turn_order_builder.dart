import 'dart:math';

import '../../data/models/turn_order_entry.dart';

/// Builds the full 20-round `turnOrder` for a fresh match, once, at
/// creation — see `NOTES_CARD_GAME_MODE.md`'s "Detail penilaian Cloud
/// Function" ("Urutan kartu ditentukan sekali, bukan diturunkan ulang
/// tiap kali diperlukan") and "Tiga pertanyaan yang tersisa".
///
/// [firstDeck]/[secondDeck] must each have at least 20 cards (a player's
/// full deck) — only the first 10 of each player's own shuffle are
/// actually used this match, split 5 into the main phase (rounds 0-9)
/// and 5 into the extension (rounds 10-19) in shuffle order. The other
/// 10 per player are deliberately left unused, so which cards come up
/// varies match to match — see "Kenapa deck 20 tapi main hanya 10"
/// ("setengah deck tidak terpakai tiap match").
///
/// [firstUid] always plays round 0 — the coin flip for who goes first
/// happens at the call site (`Random` at match-creation time), not in
/// here. Turns then strictly alternate, so with an even 20 rounds this
/// always gives each player exactly 10 rounds if the match goes the
/// full distance, matching the "10 kartu per pemain, 20 jawaban"
/// figure quoted for a fully-extended match.
///
/// **A judgment call worth flagging**: the notes' prose ("10 pertama
/// dipakai untuk ronde 0-9 milik pemain itu, 10 sisanya mengisi ronde
/// 10-19 kalau lanjut ke babak tambahan") reads, taken completely
/// literally, as if a player's first 10 shuffled cards fill *all* of
/// rounds 0-9 and their second 10 fill *all* of rounds 10-19 — but
/// turns alternate between two players, so each player only actually
/// owns 5 of the 10 slots in each phase, not 10. Taking the prose
/// literally is therefore inconsistent with "turns alternate" and
/// "turnOrder has length 20" holding at the same time. This
/// implementation resolves the conflict by taking a player's first 10
/// shuffled cards as their entire pool for the match (5 spent in the
/// main phase, 5 in the extension, in shuffle order) — the only reading
/// that satisfies every other explicitly locked number (deck size 20,
/// max 10 cards/player, half the deck unused, alternating turns,
/// main/extension split at round 9) simultaneously. If a future
/// clarification says otherwise, only this function needs to change —
/// nothing else derives its own copy of this logic.
List<TurnOrderEntry> buildTurnOrder({
  required String firstUid,
  required List<String> firstDeck,
  required String secondUid,
  required List<String> secondDeck,
  Random? random,
}) {
  assert(firstDeck.length >= 20, 'firstDeck must have at least 20 cards');
  assert(secondDeck.length >= 20, 'secondDeck must have at least 20 cards');

  final rng = random ?? Random();
  final firstPool = (List<String>.from(firstDeck)..shuffle(rng))
      .take(10)
      .toList();
  final secondPool = (List<String>.from(secondDeck)..shuffle(rng))
      .take(10)
      .toList();

  final entries = List<TurnOrderEntry?>.filled(20, null);
  for (var i = 0; i < 10; i++) {
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

/// One card in a `BattleMatch.turnOrder` — which round it's played on,
/// whose deck it comes from, and which card. See
/// `NOTES_CARD_GAME_MODE.md`'s "Bentuk data" / "Detail penilaian Cloud
/// Function" for why this is a single pre-interleaved array rather than
/// two separate per-player decks that need cross-referencing at runtime.
class TurnOrderEntry {
  /// 0-based, global across the whole match — 0-9 is the main phase,
  /// 10-19 is the extension played only if the main phase ends tied.
  final int round;

  /// Whose deck this card came from. The card is answered by the
  /// **other** player in the match, never by this uid.
  final String deckOwnerUid;

  final String cardId;

  TurnOrderEntry({
    required this.round,
    required this.deckOwnerUid,
    required this.cardId,
  });

  factory TurnOrderEntry.fromMap(Map<String, dynamic> map) => TurnOrderEntry(
    round: map['round'] as int,
    deckOwnerUid: map['deckOwnerUid'] as String,
    cardId: map['cardId'] as String,
  );

  Map<String, dynamic> toMap() => {
    'round': round,
    'deckOwnerUid': deckOwnerUid,
    'cardId': cardId,
  };
}

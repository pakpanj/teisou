import 'package:cloud_firestore/cloud_firestore.dart';

/// One entry in `battleMatches/{matchId}/answers/{round}` — the raw text
/// a player typed for that round's card. Deliberately just text: this
/// app's clients never write a correctness verdict, only what was
/// typed — see `NOTES_CARD_GAME_MODE.md`'s "Penilaian di server, bukan
/// di HP".
class BattleAnswer {
  /// Whoever answered — always the player who does **not** own the
  /// deck the card came from, never `TurnOrderEntry.deckOwnerUid`.
  final String byUid;

  final String text;

  final DateTime? submittedAt;

  BattleAnswer({required this.byUid, required this.text, this.submittedAt});

  factory BattleAnswer.fromMap(Map<String, dynamic> map) {
    final rawSubmittedAt = map['submittedAt'];
    return BattleAnswer(
      byUid: map['byUid'] as String,
      text: map['text'] as String? ?? '',
      submittedAt: rawSubmittedAt is Timestamp
          ? rawSubmittedAt.toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'byUid': byUid,
    'text': text,
    'submittedAt': FieldValue.serverTimestamp(),
  };
}

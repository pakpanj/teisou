import 'package:cloud_firestore/cloud_firestore.dart';

import 'turn_order_entry.dart';

enum BattleMatchStatus { active, finished }

extension BattleMatchStatusX on BattleMatchStatus {
  String get key => this == BattleMatchStatus.finished ? 'finished' : 'active';

  static BattleMatchStatus fromKey(String? key) =>
      key == 'finished' ? BattleMatchStatus.finished : BattleMatchStatus.active;
}

/// A live (or just-finished) Card Game Mode match — `battleMatches/{id}`.
/// See `NOTES_CARD_GAME_MODE.md`'s "Bentuk data" for the full schema
/// this mirrors.
///
/// **`officialScore` and `result` are Cloud-Function-only fields.**
/// Nothing in this app's own code ever writes them — `firestore.rules`
/// enforces that a client write can never change either, and the Cloud
/// Function scoring work itself (Tahap 2 butir 7 in the notes) hasn't
/// been built yet. They're modeled here (read-only from the client's
/// point of view) so a future match/result screen has something to
/// watch once that Cloud Function exists — same "infrastructure ready
/// ahead of the screen that needs it" shape as `presenceProvider`.
class BattleMatch {
  final String id;

  /// Always exactly 2 uids.
  final List<String> players;

  final BattleMatchStatus status;

  /// 0-based index into [turnOrder] — which card is currently up.
  final int currentRound;

  /// Length 20, built once at creation — see [buildTurnOrder] in
  /// `battle_turn_order_builder.dart`.
  final List<TurnOrderEntry> turnOrder;

  /// Server timestamp anchoring the current round's countdown — reset
  /// every time a round advances.
  final DateTime? turnStartedAt;

  /// Computed locally on whichever device notices the match conclude,
  /// purely so that device's "match over" screen can show instantly
  /// instead of waiting for the Cloud Function. Never used for anything
  /// that moves stars — see [result].
  final String? clientResult;

  /// `{uid: score}` — the authoritative score, written only by the
  /// Cloud Function after independently re-validating each answer.
  final Map<String, int> officialScore;

  /// Winner's uid, `'draw'`, or `null` while the match is still running
  /// — written only by the Cloud Function, once every round has been
  /// processed. This, not [clientResult], is what moves stars.
  final String? result;

  BattleMatch({
    required this.id,
    required this.players,
    required this.status,
    required this.currentRound,
    required this.turnOrder,
    this.turnStartedAt,
    this.clientResult,
    required this.officialScore,
    this.result,
  });

  /// The uid of whichever player is expected to answer
  /// `turnOrder[currentRound]` — always the player who does *not* own
  /// that round's deck.
  String? get currentAnswererUid {
    if (currentRound < 0 || currentRound >= turnOrder.length) return null;
    final deckOwner = turnOrder[currentRound].deckOwnerUid;
    return players.firstWhere(
      (uid) => uid != deckOwner,
      orElse: () => deckOwner,
    );
  }

  factory BattleMatch.fromMap(String id, Map<String, dynamic> map) {
    return BattleMatch(
      id: id,
      players: List<String>.from(map['players'] as List? ?? const []),
      status: BattleMatchStatusX.fromKey(map['status'] as String?),
      currentRound: map['currentRound'] as int? ?? 0,
      turnOrder: (map['turnOrder'] as List? ?? const [])
          .map((e) => TurnOrderEntry.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      turnStartedAt: _toDateTime(map['turnStartedAt']),
      clientResult: map['clientResult'] as String?,
      officialScore: Map<String, int>.from(
        (map['officialScore'] as Map?)?.map(
              (k, v) => MapEntry(k as String, (v as num).toInt()),
            ) ??
            const {},
      ),
      result: map['result'] as String?,
    );
  }

  /// Only what's needed to create a fresh match — `officialScore`
  /// starts at 0 for both players and `result` starts absent; neither
  /// is ever included in a later client update.
  Map<String, dynamic> toCreateMap() => {
    'players': players,
    'status': status.key,
    'currentRound': currentRound,
    'turnOrder': turnOrder.map((e) => e.toMap()).toList(),
    'turnStartedAt': FieldValue.serverTimestamp(),
    'clientResult': null,
    'officialScore': {for (final uid in players) uid: 0},
    'result': null,
  };

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

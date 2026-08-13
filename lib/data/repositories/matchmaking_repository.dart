import 'package:firebase_database/firebase_database.dart';

import '../models/card_game_rank.dart';

/// Card Game Mode's public matchmaking queue — see
/// `NOTES_CARD_GAME_MODE.md`'s "Pemasangan lawan publik". Reuses
/// Realtime Database the same way `PresenceService` does, for the same
/// reason: pairing two waiting players needs an atomic claim, which is
/// what `functions/battle_matchmaking.js`'s RTDB transaction performs
/// server-side. This repository only ever writes/reads its own side of
/// the handshake — it never attempts the pairing itself.
///
/// Schema (mirrors `database.rules.json`):
///   matchmakingQueue/{tier}/{uid}: { joinedAt: server time }
///   matchmakingResults/{uid}: { matchId: string }
///
/// **Needs the same Realtime Database instance `PresenceService` needs**
/// — see that class's own doc comment for the one-time Console
/// provisioning caveat, which already happened in this project (Tahap 1
/// butir 3), so this repository's calls are live, not merely
/// forward-compatible code.
class MatchmakingRepository {
  DatabaseReference _queueRef(CardGameTier tier, String uid) =>
      FirebaseDatabase.instance.ref('matchmakingQueue/${tier.key}/$uid');

  DatabaseReference _resultRef(String uid) =>
      FirebaseDatabase.instance.ref('matchmakingResults/$uid');

  /// Writes [uid] into [tier]'s queue — the client-side half of
  /// "Pemasangan lawan publik". `onValueCreated` on this exact path is
  /// what `functions/battle_matchmaking.js`'s trigger listens for.
  Future<void> joinQueue({required CardGameTier tier, required String uid}) {
    return _queueRef(tier, uid).set({'joinedAt': ServerValue.timestamp});
  }

  /// Removes [uid] from [tier]'s queue — called either when the caller
  /// gives up after its own 20-second wait (see
  /// `NOTES_CARD_GAME_MODE.md`'s "usulan: 20 detik") and falls back to a
  /// bot match, or as best-effort cleanup once matched (the Cloud
  /// Function's own claim transaction already removes both queue
  /// entries as part of pairing, so this is usually a harmless no-op by
  /// the time it runs after a successful match).
  Future<void> leaveQueue({required CardGameTier tier, required String uid}) {
    return _queueRef(tier, uid).remove();
  }

  /// Live — fires once `functions/battle_matchmaking.js` pairs [uid]
  /// with someone else and writes the resulting matchId here. `null`
  /// while still waiting (node doesn't exist yet) or after
  /// [clearMatchResult] has run.
  Stream<String?> watchMatchResult(String uid) {
    return _resultRef(uid).onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null) return null;
      final map = Map<String, dynamic>.from(value as Map);
      return map['matchId'] as String?;
    });
  }

  /// One-shot read of the same node [watchMatchResult] streams — used by
  /// the give-up-after-20-seconds path to check, once more, whether a
  /// match landed in the small window right at the timeout boundary
  /// before falling back to a bot match (see the matchmaking screen's
  /// own doc comment for the accepted trade-off this doesn't fully
  /// close).
  Future<String?> getMatchResult(String uid) async {
    final snapshot = await _resultRef(uid).get();
    final value = snapshot.value;
    if (value == null) return null;
    final map = Map<String, dynamic>.from(value as Map);
    return map['matchId'] as String?;
  }

  /// Cleans up `matchmakingResults/{uid}` once its matchId has been
  /// consumed (joined) — best-effort, a leftover node here only means a
  /// stale value future matchmaking attempts would need to overwrite,
  /// never a correctness problem (each write fully replaces the node's
  /// value with the new matchId).
  Future<void> clearMatchResult(String uid) {
    return _resultRef(uid).remove();
  }
}

import '../../data/models/turn_order_entry.dart';

/// A running tally of each player's correct answers, built purely from
/// rounds resolved on this device so far — this is the client's own
/// "fast path" guess, never the authoritative score. See
/// `NOTES_CARD_GAME_MODE.md`'s "Penilaian di server, bukan di HP":
/// `BattleMatch.officialScore` (Cloud-Function-only) is what actually
/// moves stars; this exists purely so a match screen can show something
/// instantly instead of a blank wait.
class BattleScoreTally {
  final Map<String, int> _scores;

  BattleScoreTally(Map<String, int> scores) : _scores = scores;

  int scoreOf(String uid) => _scores[uid] ?? 0;
}

/// Tallies each answerer's score from the rounds resolved so far.
/// [correctByRound] must already reflect whether that round's answer was
/// correct (kana cards compared directly, kanji cards after converting
/// the typed hiragana to romaji) — this function only sums, it has no
/// opinion on how a round's correctness was decided.
BattleScoreTally tallyScores({
  required List<String> players,
  required List<TurnOrderEntry> turnOrder,
  required Map<int, bool> correctByRound,
}) {
  final scores = {for (final p in players) p: 0};
  correctByRound.forEach((round, correct) {
    if (!correct) return;
    if (round < 0 || round >= turnOrder.length) return;
    final deckOwner = turnOrder[round].deckOwnerUid;
    final answerer = players.firstWhere(
      (p) => p != deckOwner,
      orElse: () => deckOwner,
    );
    scores[answerer] = (scores[answerer] ?? 0) + 1;
  });
  return BattleScoreTally(scores);
}

/// Whether the match should be considered concluded given the rounds
/// resolved so far — see `NOTES_CARD_GAME_MODE.md`'s "Aturan
/// kesimpulannya". Only meaningful to check once the main phase (rounds
/// 0-9) has fully resolved; returns `null` (not concluded) before that.
/// Returns the winner's uid, `'draw'`, or `null` if the match should
/// continue into (or further through) the extension.
String? clientConclusion({
  required List<String> players,
  required BattleScoreTally tally,
  required int highestResolvedRound,
}) {
  if (highestResolvedRound < 9) return null;
  if (players.length < 2) return null;
  final scoreA = tally.scoreOf(players[0]);
  final scoreB = tally.scoreOf(players[1]);
  if (scoreA != scoreB) return scoreA > scoreB ? players[0] : players[1];
  if (highestResolvedRound >= 19) return 'draw';
  return null;
}

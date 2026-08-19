import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/battle_match.dart';
import '../../data/repositories/battle_repository.dart' show battleBotUid;

/// How many past matches the lobby shows. Deliberately short — this is a
/// glance at "how have I been doing lately", not an archive.
const kRecentMatchLimit = 5;

/// The player's last few matches, newest first.
///
/// **Not autoDispose, and invalidated by hand instead.** The card game
/// shell is an `IndexedStack`, so every tab stays alive the whole time the
/// shell is open — an autoDispose provider read from a tab that is never
/// disposed simply never refetches, which is exactly how a stale read
/// survived twice already in this app (the exam history, then the module
/// gate). `BattleScreen` invalidates this the moment a match concludes,
/// which is the only time the answer can change.
///
/// A failed read yields an empty list rather than an error. The likeliest
/// reason to fail is the composite index not existing yet, and a lobby
/// that refuses to render because of a missing index would take the whole
/// screen down over a section that is decoration.
final recentMatchesProvider = FutureProvider<List<BattleMatch>>((ref) async {
  final user = await ref.watch(appStartupProvider.future);
  try {
    return await ref
        .watch(battleRepositoryProvider)
        .recentMatches(user.uid, limit: kRecentMatchLimit);
  } catch (_) {
    return const [];
  }
});

/// Display rows for the recent matches — names resolved in one query.
///
/// The arena's own `battleOpponentsProvider` takes one match's player list,
/// so using it here would be five round trips for five rows. This gathers
/// every opponent across the whole list first and asks once.
///
/// Names come from `leaderboard/{uid}`, the app's only world-readable
/// profile row; `users/{uid}` is owner-only, so an opponent's name is not
/// available from there. An unresolved name falls back to a neutral label
/// rather than blanking the row.
final recentMatchRowsProvider = FutureProvider<List<RecentMatchRow>>((ref) async {
  final user = await ref.watch(appStartupProvider.future);
  final matches = await ref.watch(recentMatchesProvider.future);
  if (matches.isEmpty) return const [];

  final opponents = <String>{
    for (final match in matches)
      if (opponentOf(match, user.uid) case final uid?)
        if (uid != battleBotUid) uid,
  };

  var names = <String, String>{};
  if (opponents.isNotEmpty) {
    try {
      final entries =
          await ref.read(leaderboardRepositoryProvider).getMany(opponents.toList());
      names = {for (final e in entries) e.uid: e.displayName};
    } catch (_) {
      // Cosmetic: a row without a name still shows the score and outcome.
    }
  }

  return [
    for (final match in matches)
      RecentMatchRow(
        match: match,
        outcome: outcomeFor(match, user.uid),
        myScore: match.officialScore[user.uid] ?? 0,
        theirScore: switch (opponentOf(match, user.uid)) {
          final uid? => match.officialScore[uid] ?? 0,
          _ => 0,
        },
        opponentUid: opponentOf(match, user.uid),
        opponentName: switch (opponentOf(match, user.uid)) {
          battleBotUid => null,
          final uid? => names[uid],
          _ => null,
        },
        starDelta: match.starResult[user.uid]?.delta,
      ),
  ];
});

/// One line in the lobby's recent-matches list.
class RecentMatchRow {
  const RecentMatchRow({
    required this.match,
    required this.outcome,
    required this.myScore,
    required this.theirScore,
    required this.opponentUid,
    required this.opponentName,
    required this.starDelta,
  });

  final BattleMatch match;
  final MatchOutcome outcome;
  final int myScore;
  final int theirScore;
  final String? opponentUid;

  /// Null for the bot, and null for a player with no public row yet.
  final String? opponentName;

  /// How the star ladder moved, or null for an unranked match — a
  /// friendly challenge moves no stars, so the row shows nothing rather
  /// than a misleading zero.
  final int? starDelta;

  bool get againstBot => opponentUid == battleBotUid;
}

/// How one finished match turned out for the player looking at it.
enum MatchOutcome { win, loss, draw }

/// Reads [match] from [uid]'s side.
///
/// Kept as a plain function over the values rather than a method on the
/// model: the same match is a win for one player and a loss for the other,
/// so "who won" is not a property of the match on its own.
MatchOutcome outcomeFor(BattleMatch match, String uid) {
  final result = match.result ?? match.clientResult;
  if (result == null || result == 'draw') return MatchOutcome.draw;
  return result == uid ? MatchOutcome.win : MatchOutcome.loss;
}

/// The other player's uid, or null for a match with nobody else in it.
String? opponentOf(BattleMatch match, String uid) {
  for (final player in match.players) {
    if (player != uid) return player;
  }
  return null;
}

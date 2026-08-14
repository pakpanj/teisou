import '../constants/battle_rules.dart';

/// Per-card time limit, given a 0-based global round index — see
/// `NOTES_CARD_GAME_MODE.md`'s "Timer, dan cara seri diselesaikan".
///
/// Every card of the main phase (rounds 0 to [kBattleMainPhaseRounds] - 1
/// — ten cards each) gets the full [kBattleMainPhaseSeconds]. The
/// extension, reached only when the main phase ends level, shrinks by
/// [kBattleExtensionStepSeconds] per card and stops at
/// [kBattleMinimumSeconds]; see that constant for why it stops rather
/// than running down to nothing.
Duration cardTimeLimit(int round) {
  assert(
    round >= 0 && round < kBattleTotalRounds,
    'round must be 0-${kBattleTotalRounds - 1}, got $round',
  );
  if (round < kBattleMainPhaseRounds) {
    return const Duration(seconds: kBattleMainPhaseSeconds);
  }
  final cardsIntoExtension = round - kBattleMainPhaseRounds + 1;
  final seconds =
      kBattleMainPhaseSeconds - kBattleExtensionStepSeconds * cardsIntoExtension;
  return Duration(
    seconds: seconds < kBattleMinimumSeconds ? kBattleMinimumSeconds : seconds,
  );
}

/// When the card for [round] becomes visible to the player answering it.
///
/// The round's owner gets [kBattleCardChoiceSeconds] to choose; the card
/// they were dealt goes out if they do not. Both phases hang off the one
/// `turnStartedAt` anchor rather than a second server timestamp, so
/// there is nothing extra to write — and nothing that can be written
/// late and shift a deadline the other player is already counting
/// against.
Duration cardChoiceWindow({required bool ownerIsBot}) {
  return ownerIsBot
      ? Duration.zero
      : const Duration(seconds: kBattleCardChoiceSeconds);
}

/// The whole budget for a round: choosing plus answering.
Duration roundBudget(int round, {required bool ownerIsBot}) {
  return cardChoiceWindow(ownerIsBot: ownerIsBot) + cardTimeLimit(round);
}

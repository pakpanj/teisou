/// Per-card time limit, given a 0-based global round index (0-19) — see
/// `NOTES_CARD_GAME_MODE.md`'s "Timer, dan cara seri diselesaikan".
///
/// Cards 1-10 (rounds 0-9, the main phase) get the full 30 seconds each.
/// Cards 11-20 (rounds 10-19, the extension — only reached if the main
/// phase ends tied) shrink by 2 seconds per card: 28, 26, ..., down to a
/// floor of 10 at round 19. The shrink is a pressure valve for ties, not
/// a guarantee against them — it's deliberately never allowed to reach 0.
Duration cardTimeLimit(int round) {
  assert(round >= 0 && round <= 19, 'round must be 0-19, got $round');
  final seconds = round <= 9 ? 30 : 30 - 2 * (round - 9);
  return Duration(seconds: seconds);
}

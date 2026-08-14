/// How long a Card Game Mode match runs, in rounds.
///
/// One round is one card answered by one player, and turns strictly
/// alternate — so a round count is always twice the number of cards each
/// player gets through.
///
/// **These numbers were corrected on 2026-08-14**, after the user read
/// the shipped match back against the design and found it short. The
/// rule they confirmed: each player is dealt **20 cards** and may play
/// **10** of them; if the score is still level after that, the match
/// goes all-in and both decks are played out to the end, with the timer
/// shrinking two seconds per card. The first implementation read "10
/// cards" as ten cards *in total* rather than ten *each*, which halved
/// every phase — a match could be decided after five cards apiece, and
/// the deck's other half was never reachable at all.
///
/// They live here rather than inline because four separate places
/// encode them — the turn-order builder, the timer, the client's own
/// fast-path conclusion, and the Cloud Function that writes the
/// authoritative result — and the fourth is in another language. Keeping
/// the Dart three in one place at least means a change is three edits,
/// not a hunt. **`functions/battle_scoring.js` carries its own copy and
/// must be changed with them**; the same unavoidable split already
/// documented for `RomajiConverter`.
library;

/// Cards each player plays before the score is first checked (10), as a
/// round count.
const kBattleMainPhaseRounds = 20;

/// The whole deck played out, both sides, if the main phase ends level.
const kBattleTotalRounds = 40;

/// Seconds allowed for any card in the main phase.
const kBattleMainPhaseSeconds = 30;

/// Seconds taken off each successive card of the extension.
const kBattleExtensionStepSeconds = 2;

/// The extension's shrink stops here rather than running to zero.
///
/// Twenty extension cards at two seconds each would pass zero long
/// before the deck ran out, which is not a harder question but an
/// unanswerable one. The shrink is a pressure valve for ties, never a
/// guarantee of one — a draw at the end of both decks is a real result
/// this mode accepts.
const kBattleMinimumSeconds = 10;

/// Seconds the card's owner gets to choose which of their remaining
/// cards to play, before the one dealt to that round goes out instead.
///
/// Confirmed by the user on 2026-08-14: "tiap giliran user diberikan 10
/// detik untuk memilih kartu". A default rather than a hard stop,
/// because a match must never be able to stall on a player who has put
/// the phone down — the same reasoning the answer timer already follows.
///
/// It does not apply to the bot, which has no reason to hesitate: ten
/// dead seconds every other round would be the longest part of a bot
/// match.
const kBattleCardChoiceSeconds = 10;

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

/// The 30-second reconnect grace period (2026-08-30) — how long a
/// player who has left an active match stays "away" before their
/// opponent's client (or the server-side sweep, as a backstop) is
/// allowed to finalize the match as an abandonment loss. Mirrors
/// `functions/battle_abandonment_sweep.js`'s `ABANDON_GRACE_PERIOD_MS`,
/// the same cross-language split every other constant in this file
/// already carries.
///
/// **Distinct from every timer above** — those bound one *round*; this
/// bounds the whole match staying resumable after an explicit leave
/// (back/Home navigation, the app backgrounding — see
/// `battle_screen.dart`'s lifecycle observer). See `BattleMatch.abandon`
/// for the marker this counts down from.
const kBattleAbandonGracePeriodSeconds = 30;

/// How old an `active` match may be before the "Kembali ke Pertandingan"
/// card stops offering it at all — `BattleMatch.isResumable`'s age
/// ceiling (AUDIT_ARSITEKTUR_PRESENCE_LIFECYCLE_MODE_KARTU.md's Bagian 4
/// finding M3). Client-side only: it changes what this player's own
/// lobby *advertises*, never what the server considers `active` — a
/// match past this age is not touched, deleted, or forced to conclude by
/// this constant at all, only quietly stopped from being offered as
/// "still in progress" to the one screen that reads it this way.
///
/// **Derived from `functions/battle_abandonment_sweep.js`'s own
/// documented worst case, not picked arbitrarily.** Every legitimate path
/// to a match staying `active` this long already has a bound:
/// - An explicit leave (`BattleMatch.abandon` written) resolves within
///   [kBattleAbandonGracePeriodSeconds] of whichever client or sweep
///   cycle notices it — minutes at most.
/// - No explicit leave at all (a true force-kill with no `paused`
///   transition ever firing) falls to the sweep's per-round staleness
///   check: `STALE_THRESHOLD_MS` (3 minutes) per round, one round
///   forfeited per 2-minute sweep cycle, up to `STAGE2_TRIGGER_ROUND`
///   (round 19) — worst case around 19 * 5 = 95 minutes before Stage 2's
///   bulk pass (which is fast once triggered) can even start.
///
/// So nothing that is actually still capable of concluding on its own
/// should ever reach two hours, let alone six — a match still `active`
/// past this ceiling is one where something else already went wrong
/// (this environment's own testing history has produced exactly such
/// orphaned matches), and offering it as "still in progress" forever
/// would only be misleading, not useful.
const kBattleResumableMaxAge = Duration(hours: 6);

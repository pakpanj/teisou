import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/providers.dart';
import '../../core/services/battle_deck_builder.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/mascot_widget.dart';
import '../../data/models/card_game_rank.dart';
import '../../data/repositories/battle_repository.dart' show battleBotUid;
import 'battle_challenge.dart' show cardTierContentLabel;
import 'battle_screen.dart';
import 'widgets/rank_standing.dart';
import 'widgets/search_radar.dart';

/// Card Game Mode's public-opponent matchmaking — Tahap 3 butir 10 in
/// `NOTES_CARD_GAME_MODE.md`, "Pemasangan lawan publik". A manual test
/// aid, same status as `BattleTestStartScreen` (Tahap 2 butir 6) — Card
/// Game Mode has no production navigation entry point anywhere in the
/// app yet, across every butir built so far, so this stays consistent
/// with that rather than inventing one on its own. Reach it the same
/// temporary way: push it from wherever's convenient while testing,
/// then remove that entry point again.
///
/// Content is locked to the signed-in learner's own current
/// `CardGameRank` tier — unlike a friend/clan challenge
/// (`battle_challenge.dart`), a public match never lets either side pick
/// freely (see "Isi kartu dikunci rank hanya untuk lawan publik").
/// Just the body — the shell around it (app bar, bottom nav) belongs to
/// [CardGameShell], which hosts this as its Battle tab.
class BattleMatchmakingBody extends ConsumerStatefulWidget {
  const BattleMatchmakingBody({super.key});

  @override
  ConsumerState<BattleMatchmakingBody> createState() =>
      _BattleMatchmakingBodyState();
}

enum _MatchmakingState { idle, searching, fallingBackToBot }

class _BattleMatchmakingBodyState
    extends ConsumerState<BattleMatchmakingBody> {
  /// How long to wait for a human before falling back to a bot. Named
  /// because the progress bar divides by it — an inline 20 in two places
  /// is how a bar ends up out of step with the countdown it draws.
  static const _searchSeconds = 20;

  /// How long any single network call here is allowed to take before it
  /// is treated as unreachable. Every call on this screen is either
  /// optional or has something better to do than wait: a request that
  /// cannot be answered is not worth a spinner with no end.
  static const _networkDeadline = Duration(seconds: 8);

  _MatchmakingState _state = _MatchmakingState.idle;
  int _secondsLeft = _searchSeconds;
  String? _error;

  StreamSubscription<String?>? _resultSubscription;
  Timer? _countdownTimer;
  CardGameTier? _queuedTier;

  @override
  void dispose() {
    _resultSubscription?.cancel();
    _countdownTimer?.cancel();
    // Best-effort cleanup if the learner navigates away mid-search —
    // matches this app's standing "a leftover queue/result node is a
    // harmless no-op for the next attempt, never a correctness problem"
    // trade-off (see MatchmakingRepository's own doc comments).
    final myUid = ref.read(appStartupProvider).valueOrNull?.uid;
    final tier = _queuedTier;
    if (myUid != null && tier != null) {
      ref.read(matchmakingRepositoryProvider).leaveQueue(tier: tier, uid: myUid);
      ref.read(matchmakingRepositoryProvider).clearMatchResult(myUid);
    }
    super.dispose();
  }

  /// `mm:ss`, so twenty seconds reads as a clock rather than a bare
  /// number that could be anything.
  static String _clock(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final sec = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  Future<void> _startSearching(CardGameTier tier) async {
    final myUid = ref.read(appStartupProvider).valueOrNull?.uid;
    if (myUid == null) return;

    setState(() {
      _state = _MatchmakingState.searching;
      _secondsLeft = _searchSeconds;
      _error = null;
      _queuedTier = tier;
    });

    // **Deliberately not awaited.** A Realtime Database write does not
    // complete until it reaches the server, so on a device where
    // Firebase cannot connect at all this sat here forever — and the
    // state had already flipped to "searching", so the screen showed
    // "Menunggu lawan... 20s" above a countdown that never started and a
    // listener never attached: no search, no bot fallback, no way on but
    // Batal. Reported from an iPhone, where the cause is that
    // `firebase_options.dart` still has no iOS entry at all.
    //
    // Starting the clock first means the twenty seconds run whatever the
    // network is doing, and the bot fallback still fires. Same rule this
    // codebase already learned on `appStartupProvider`: never await a
    // write on a path that has to render something.
    unawaited(
      ref
          .read(matchmakingRepositoryProvider)
          .joinQueue(tier: tier, uid: myUid)
          .catchError((Object e) {
        // Surfaced only when the write genuinely fails. A write that
        // merely never lands is left to the countdown, which ends in a
        // bot match — a better answer than an error message.
        if (mounted) setState(() => _error = '$e');
      }),
    );

    _resultSubscription = ref
        .read(matchmakingRepositoryProvider)
        .watchMatchResult(myUid)
        .listen((matchId) {
      if (matchId != null) _joinMatch(matchId, tier, myUid);
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        timer.cancel();
        _giveUpAndFallBackToBot(tier, myUid);
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  void _joinMatch(String matchId, CardGameTier tier, String myUid) {
    _resultSubscription?.cancel();
    _countdownTimer?.cancel();
    _queuedTier = null;
    // Fire-and-forget cleanup — the match itself is what matters; a
    // failed cleanup here just means the next matchmaking attempt
    // overwrites a stale leftover node, never a correctness problem
    // (see MatchmakingRepository's own doc comments).
    ref.read(matchmakingRepositoryProvider).leaveQueue(tier: tier, uid: myUid);
    ref.read(matchmakingRepositoryProvider).clearMatchResult(myUid);
    _openMatch(matchId);
  }

  /// Opens the match and — this is the part that matters — puts this
  /// screen back to idle once the learner comes out of it.
  ///
  /// Both entry points used to push without awaiting and never reset
  /// `_state`, so finishing a match revealed this screen still frozen on
  /// "Menunggu lawan..." or "Tidak ada lawan, melawan bot...", spinner
  /// and all. Nothing was actually being searched — the timer and the
  /// listener were both already cancelled — but there was no way to tell
  /// that apart from the app having started a second match on its own,
  /// which is exactly how it was reported. Worse, the only control on
  /// screen in that state is "Batal", so a learner who just won had to
  /// press Cancel to get back to a button that starts a game.
  Future<void> _openMatch(String matchId) async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BattleScreen(matchId: matchId)),
    );
    if (!mounted) return;
    setState(() {
      _state = _MatchmakingState.idle;
      _secondsLeft = _searchSeconds;
      _error = null;
      _queuedTier = null;
    });
  }

  /// After 20 seconds with no pairing, check once more for a match that
  /// may have landed right at the boundary (see
  /// `MatchmakingRepository.getMatchResult`'s own doc comment for why
  /// this doesn't fully close the race, just narrows it), then fall
  /// back to a bot match through the exact same path
  /// `BattleTestStartScreen`'s "Lawan Bot" button already uses.
  Future<void> _giveUpAndFallBackToBot(CardGameTier tier, String myUid) async {
    _resultSubscription?.cancel();
    if (!mounted) return;
    // Flipped **before** any network call, not after. The late-match
    // check below used to come first, and offline it never answered — so
    // the screen sat on "Menunggu lawan... 1s" with the countdown
    // finished and nothing left running. Seen on a device with its radios
    // off, which is the same condition an iPhone with no Firebase
    // configuration is permanently in.
    setState(() => _state = _MatchmakingState.fallingBackToBot);

    // A pairing that landed in the last moment before the clock ran out.
    // Worth checking, not worth waiting on: if the answer cannot arrive,
    // going on to the bot is the better outcome.
    final lateMatchId = await ref
        .read(matchmakingRepositoryProvider)
        .getMatchResult(myUid)
        .timeout(_networkDeadline, onTimeout: () => null)
        .catchError((Object _) => null);
    if (!mounted) return;
    if (lateMatchId != null) {
      _joinMatch(lateMatchId, tier, myUid);
      return;
    }

    try {
      // Not awaited: leaving the queue is cleanup, and a leftover node is
      // a harmless no-op for the next attempt (see
      // `MatchmakingRepository`). Waiting on it only ever delays a match.
      unawaited(
        ref
            .read(matchmakingRepositoryProvider)
            .leaveQueue(tier: tier, uid: myUid)
            .catchError((Object _) {}),
      );
      _queuedTier = null;

      final cardData = await ref.read(battleCardDataProvider.future);
      final deck = buildDeckIds(
        content: tier.cardContent,
        allKana: cardData.$1,
        allKanji: cardData.$2,
      );
      // The one call here that genuinely has to reach the server —
      // there is no match to open without it. Given a deadline rather
      // than left to hang, because a Firestore write offline simply
      // never completes, and a spinner that waits forever tells the
      // learner nothing about why.
      final matchId = await ref
          .read(battleRepositoryProvider)
          .createMatch(
            firstCandidateUid: myUid,
            firstCandidateDeck: deck,
            secondCandidateUid: battleBotUid,
            secondCandidateDeck: deck,
            cardTierContent: tier.cardContent,
          )
          .timeout(_networkDeadline);
      await _openMatch(matchId);
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _state = _MatchmakingState.idle;
        _error = ref.read(appStringsProvider).battleMatchmakingOffline;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _MatchmakingState.idle;
        _error = '$e';
      });
    }
  }

  Future<void> _cancel() async {
    final myUid = ref.read(appStartupProvider).valueOrNull?.uid;
    final tier = _queuedTier;
    _resultSubscription?.cancel();
    _countdownTimer?.cancel();
    if (myUid != null && tier != null) {
      // Cancelling must never depend on the network. These were awaited,
      // so with no connection the button did nothing at all — and it is
      // the only control on the screen in that state.
      final matchmaking = ref.read(matchmakingRepositoryProvider);
      unawaited(
        matchmaking.leaveQueue(tier: tier, uid: myUid).catchError((Object _) {}),
      );
      unawaited(
        matchmaking.clearMatchResult(myUid).catchError((Object _) {}),
      );
    }
    if (!mounted) return;
    setState(() {
      _state = _MatchmakingState.idle;
      _queuedTier = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final rankAsync = ref.watch(cardGameRankProvider);

    return rankAsync.when(
        data: (rank) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RankStanding(rank: rank, strings: s),
              const SizedBox(height: 12),
              Text(
                s.battleMatchmakingDescription(
                  cardTierContentLabel(rank.tier.cardContent, s),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: context.palette.errorRed)),
              ],
              // Centred in what is left rather than pinned under the
              // description: the deck and the button are the point of
              // this screen, and pinned to the top they sat above a
              // screen's worth of nothing.
              Expanded(
                child: Center(child: _buildStateWidget(context, s, rank)),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
    );
  }

  Widget _buildStateWidget(BuildContext context, AppStrings s, CardGameRank rank) {
    switch (_state) {
      case _MatchmakingState.idle:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The deck you are about to play, face down — the mockup's
            // opening image, and the one thing that tells a learner what
            // this button is going to hand them.
            const FannedDeck(),
            const SizedBox(height: 24),
            SizedBox(
              width: 220,
              height: 52,
              child: FilledButton(
                onPressed: () => _startSearching(rank.tier),
                child: Text(
                  s.battleMatchmakingSearchButton,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      case _MatchmakingState.searching:
        final palette = context.palette;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              s.battleSearchingTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: palette.primaryCoral,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              s.battleSearchingSubtitle,
              style: TextStyle(
                fontSize: 12,
                color: palette.textNavy.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            // The mascot waits with you, inside a dial that keeps
            // moving. Twenty seconds is the longest this mode ever asks
            // a child to sit still doing nothing.
            const SearchRadar(),
            const SizedBox(height: 14),
            Text(
              // The countdown as a clock rather than a sentence: it is
              // the only number on this screen, so it should be the
              // thing the eye lands on.
              _clock(_secondsLeft),
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: palette.textNavy,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _cancel,
              child: Text(s.battleMatchmakingCancelButton),
            ),
          ],
        );
      case _MatchmakingState.fallingBackToBot:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MascotWidget(mood: MascotMood.excited, size: 120),
            const SizedBox(height: 12),
            Text(
              s.battleMatchmakingFallingBackToBot,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.palette.textNavy,
              ),
            ),
            const SizedBox(height: 12),
            const CircularProgressIndicator(),
          ],
        );
    }
  }
}

/// Three face-down cards fanned out, drawn from shapes.
///
/// Purely an invitation — it carries no state and never changes with the
/// match. It exists because the search screen was a sentence and a
/// button, which is a form, not the front door of a card game.
class FannedDeck extends StatelessWidget {
  const FannedDeck({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    Widget card(double angle, double dx, Color color) {
      return Transform.translate(
        offset: Offset(dx, 0),
        child: Transform.rotate(
          angle: angle,
          child: Container(
            width: 84,
            height: 116,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withValues(alpha: 0.75)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.cardWhite, width: 3),
              boxShadow: [
                BoxShadow(
                  color: palette.textNavy.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              'あ',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: palette.cardWhite.withValues(alpha: 0.85),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          card(-0.26, -54, palette.secondaryBlue),
          card(0.26, 54, palette.tertiaryAmber),
          card(0, 0, palette.primaryCoral),
        ],
      ),
    );
  }
}

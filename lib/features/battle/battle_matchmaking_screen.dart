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
class BattleMatchmakingScreen extends ConsumerStatefulWidget {
  const BattleMatchmakingScreen({super.key});

  @override
  ConsumerState<BattleMatchmakingScreen> createState() =>
      _BattleMatchmakingScreenState();
}

enum _MatchmakingState { idle, searching, fallingBackToBot }

class _BattleMatchmakingScreenState
    extends ConsumerState<BattleMatchmakingScreen> {
  /// How long to wait for a human before falling back to a bot. Named
  /// because the progress bar divides by it — an inline 20 in two places
  /// is how a bar ends up out of step with the countdown it draws.
  static const _searchSeconds = 20;

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

  Future<void> _startSearching(CardGameTier tier) async {
    final myUid = ref.read(appStartupProvider).valueOrNull?.uid;
    if (myUid == null) return;

    setState(() {
      _state = _MatchmakingState.searching;
      _secondsLeft = _searchSeconds;
      _error = null;
      _queuedTier = tier;
    });

    try {
      await ref
          .read(matchmakingRepositoryProvider)
          .joinQueue(tier: tier, uid: myUid);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _MatchmakingState.idle;
        _error = '$e';
        _queuedTier = null;
      });
      return;
    }
    if (!mounted) return;

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
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BattleScreen(matchId: matchId)),
    );
  }

  /// After 20 seconds with no pairing, check once more for a match that
  /// may have landed right at the boundary (see
  /// `MatchmakingRepository.getMatchResult`'s own doc comment for why
  /// this doesn't fully close the race, just narrows it), then fall
  /// back to a bot match through the exact same path
  /// `BattleTestStartScreen`'s "Lawan Bot" button already uses.
  Future<void> _giveUpAndFallBackToBot(CardGameTier tier, String myUid) async {
    _resultSubscription?.cancel();

    final lateMatchId =
        await ref.read(matchmakingRepositoryProvider).getMatchResult(myUid);
    if (lateMatchId != null) {
      _joinMatch(lateMatchId, tier, myUid);
      return;
    }

    if (!mounted) return;
    setState(() => _state = _MatchmakingState.fallingBackToBot);

    try {
      await ref
          .read(matchmakingRepositoryProvider)
          .leaveQueue(tier: tier, uid: myUid);
      _queuedTier = null;

      final cardData = await ref.read(battleCardDataProvider.future);
      final deck = buildDeckIds(
        content: tier.cardContent,
        allKana: cardData.$1,
        allKanji: cardData.$2,
      );
      final matchId = await ref.read(battleRepositoryProvider).createMatch(
            firstCandidateUid: myUid,
            firstCandidateDeck: deck,
            secondCandidateUid: battleBotUid,
            secondCandidateDeck: deck,
            cardTierContent: tier.cardContent,
          );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => BattleScreen(matchId: matchId)),
      );
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
      await ref
          .read(matchmakingRepositoryProvider)
          .leaveQueue(tier: tier, uid: myUid);
      await ref.read(matchmakingRepositoryProvider).clearMatchResult(myUid);
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

    return Scaffold(
      appBar: AppBar(title: Text(s.battleMatchmakingTitle)),
      body: rankAsync.when(
        data: (rank) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RankStanding(rank: rank, strings: s),
              const SizedBox(height: 16),
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
      ),
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
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The mascot waits with you. A bare spinner for twenty
            // seconds is the longest this mode ever asks a child to sit
            // still doing nothing.
            const MascotWidget(mood: MascotMood.curious, size: 120),
            const SizedBox(height: 12),
            Text(
              s.battleMatchmakingWaiting(_secondsLeft),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.palette.textNavy,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                // Counts down against the same 20 seconds the fallback
                // uses, so the wait has a visible end rather than an
                // indefinite spinner.
                value: (_secondsLeft / _searchSeconds).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: context.palette.progressTrack,
              ),
            ),
            const SizedBox(height: 20),
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

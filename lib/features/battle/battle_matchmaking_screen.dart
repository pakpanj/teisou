import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/providers.dart';
import '../../core/services/battle_deck_builder.dart';
import '../../core/theme/app_palette.dart';
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
  _MatchmakingState _state = _MatchmakingState.idle;
  int _secondsLeft = 20;
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
      _secondsLeft = 20;
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
              const SizedBox(height: 24),
              Center(child: _buildStateWidget(context, s, rank)),
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
        return FilledButton(
          onPressed: () => _startSearching(rank.tier),
          child: Text(s.battleMatchmakingSearchButton),
        );
      case _MatchmakingState.searching:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(s.battleMatchmakingWaiting(_secondsLeft)),
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
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(s.battleMatchmakingFallingBackToBot),
          ],
        );
    }
  }
}

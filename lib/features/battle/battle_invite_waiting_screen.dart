import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/mascot_widget.dart';
import '../../data/models/battle_match.dart';
import '../../data/repositories/battle_repository.dart';
import 'battle_screen.dart';

/// Where the challenger waits after sending a "Tantang".
///
/// **This screen exists because the challenger used to skip it.** The
/// match document is created before the invite is sent (see
/// `BattleInvite.matchId`), and the old flow read that as permission to
/// walk straight into the arena — so the person doing the inviting was
/// already playing, alone, against someone who had not yet been asked.
/// Rounds ticked past on their own while the invitation sat unopened,
/// and by the time the other player said yes the match was several cards
/// in, all of them lost by both sides.
///
/// So: nobody plays until both have agreed. The invited player answers
/// on the match itself rather than only on the invite, because the
/// invite lives under their own user document where the challenger
/// cannot read it — see [BattleMatch.inviteState].
class BattleInviteWaitingScreen extends ConsumerStatefulWidget {
  const BattleInviteWaitingScreen({
    super.key,
    required this.matchId,
    required this.targetName,
    required this.expiresAt,
  });

  final String matchId;
  final String targetName;

  /// The invite's own 2-minute deadline, passed in rather than
  /// recomputed so this screen and the invited player's list agree on
  /// exactly when the challenge went stale.
  final DateTime expiresAt;

  @override
  ConsumerState<BattleInviteWaitingScreen> createState() =>
      _BattleInviteWaitingScreenState();
}

class _BattleInviteWaitingScreenState
    extends ConsumerState<BattleInviteWaitingScreen> {
  Timer? _ticker;

  /// Set once the accepted match has been opened, so a rebuild arriving
  /// between the navigation and this screen's disposal cannot push a
  /// second arena on top of the first.
  bool _opened = false;

  bool _cancelling = false;

  /// Captured in [initState] so [dispose] can retract the challenge
  /// without touching `ref`.
  ///
  /// **Assigned there rather than as a `late final` initialiser**, which
  /// was the first attempt and did nothing: `late` runs its initialiser
  /// on first *access*, and the only access is in `dispose` — so the
  /// provider read still happened at exactly the moment it was supposed
  /// to be avoided, threw against a defunct element, and the challenge
  /// stayed live. Caught by testing the retraction on two devices and
  /// watching the invited player walk into the match anyway.
  late final BattleRepository _battles;

  @override
  void initState() {
    super.initState();
    _battles = ref.read(battleRepositoryProvider);
    // Only to redraw the countdown; expiry itself is decided by
    // comparing against `expiresAt`, never by counting ticks — a screen
    // that slept through a lock/unlock would otherwise think it still
    // had a minute left.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    // **Leaving this screen retracts the challenge**, however it is
    // left — the Batal button, the back arrow, or the system gesture.
    //
    // Only Batal used to do it, and the gap was reported from real play:
    // a challenge went unanswered, the challenger backed out and
    // challenged somebody else, and that second match started. The first
    // invitation was still live, so when the original target finally
    // tapped Terima they were dropped into a match whose opponent was
    // already playing elsewhere — a match nobody would ever take a turn
    // in, which is what the "no cards to choose from" report was.
    //
    // Fire-and-forget by necessity: `dispose` cannot await, and there is
    // nothing useful to do with a failure at this point anyway. The
    // invite's own two-minute expiry is the backstop.
    if (!_opened && !_cancelling) {
      _battles
          .respondToMatchInvite(matchId: widget.matchId, accept: false)
          .catchError((Object _) => false);
    }
    super.dispose();
  }

  Duration get _left {
    final left = widget.expiresAt.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  Future<void> _cancel() async {
    if (_cancelling) return;
    setState(() => _cancelling = true);
    // Best-effort: a challenge nobody can answer expires on its own in
    // two minutes anyway, so a failed write here must not trap the
    // challenger on this screen.
    try {
      await _battles.respondToMatchInvite(
        matchId: widget.matchId,
        accept: false,
      );
    } catch (_) {}
    if (mounted) Navigator.of(context).pop();
  }

  void _openMatch() {
    if (_opened) return;
    _opened = true;
    // Replaces rather than pushes: backing out of a match should return
    // to the friend list, not to a waiting room for an invitation that
    // has already been answered.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppNavigator.replaceFadeScale(
        context,
        BattleScreen(matchId: widget.matchId),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final palette = context.palette;
    final match = ref.watch(battleMatchProvider(widget.matchId)).valueOrNull;
    final state = match?.inviteState ?? BattleInviteState.pending;

    if (state == BattleInviteState.accepted) _openMatch();

    final expired = _left == Duration.zero;
    final done = state == BattleInviteState.declined || expired;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: Text(s.battleInviteWaitingTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MascotWidget(
                mood: done ? MascotMood.worried : MascotMood.searching,
                size: 150,
              ),
              const SizedBox(height: 24),
              Text(
                switch (state) {
                  BattleInviteState.declined =>
                    s.battleInviteDeclined(widget.targetName),
                  _ when expired =>
                    s.battleInviteNoAnswer(widget.targetName),
                  _ => s.battleInviteWaitingFor(widget.targetName),
                },
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: palette.textNavy,
                ),
              ),
              const SizedBox(height: 10),
              if (!done) ...[
                Text(
                  // The countdown is the invite's, not a made-up one:
                  // saying nothing about it would leave the challenger
                  // guessing whether to keep holding the phone.
                  s.battleInviteWaitingCountdown(_left.inSeconds),
                  style: TextStyle(
                    fontSize: 13,
                    color: palette.textNavy.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 28),
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ] else
                Text(
                  s.battleInviteTryAgainHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: palette.textNavy.withValues(alpha: 0.6),
                  ),
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: 220,
                height: 50,
                child: done
                    ? FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(s.close),
                      )
                    : OutlinedButton(
                        onPressed: _cancelling ? null : _cancel,
                        child: Text(s.battleInviteCancel),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

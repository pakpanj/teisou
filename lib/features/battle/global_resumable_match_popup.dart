import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/battle_rules.dart';
import '../../core/navigation/root_navigator_key.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import 'battle_invite_providers.dart' show liveResumableMatchProvider;
import 'battle_screen.dart';

/// The matchId the learner has explicitly dismissed via this popup's own
/// X button. Never compared against anything but the *current*
/// [liveResumableMatchProvider] value's own id, so a dismissal only ever
/// suppresses that one match — the moment a different match becomes
/// resumable (this one resolved, or a genuinely new one started), the id
/// mismatch alone makes the stale dismissal irrelevant; nothing has to
/// explicitly reset this back to `null` for that to hold.
///
/// Deliberately a bare `StateProvider<String?>` rather than a `Set` of
/// dismissed ids: only one match can ever be resumable for a given uid at
/// a time in practice (see `BattleRepository.findResumableMatch`'s own
/// doc comment on why more than one is not assumed away, just picked
/// deterministically) — and even in that edge case, dismissing "the"
/// popup means dismissing whichever one is currently on offer, not
/// building a permanent memory of every match this player has ever
/// waved away.
final dismissedResumableMatchIdProvider = StateProvider<String?>((_) => null);

/// The "Kembali ke Pertandingan" popup, shown app-wide via
/// `MaterialApp.builder` in `main.dart` — so it follows the learner
/// across every tab and screen, not just Card Game Mode's own Beranda
/// sub-tab (where an equivalent card used to live exclusively; see
/// `card_game_shell.dart`'s `_LobbyTab` for the note left where it used
/// to be built).
///
/// Stays visible until either the X is tapped (records the match's id in
/// [dismissedResumableMatchIdProvider]) or the match itself stops being
/// resumable — [liveResumableMatchProvider] emits `null` the instant
/// that happens, whether that's the match actually resolving server-side
/// or this player's own reconnect window running out, never merely a
/// client-side countdown reaching zero on its own guess.
///
/// Renders nothing — a genuinely zero-size, non-hit-testing widget, not
/// just an invisible one — whenever there is nothing to offer, the
/// learner is already looking at that exact match
/// ([BattleScreen.currentlyOpenMatchId]), or it was dismissed.
class GlobalResumableMatchPopup extends ConsumerWidget {
  const GlobalResumableMatchPopup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startup = ref.watch(appStartupProvider);
    final myUid = startup.valueOrNull?.uid;
    if (myUid == null) return const SizedBox.shrink();

    final match = ref.watch(liveResumableMatchProvider).valueOrNull;
    if (match == null) return const SizedBox.shrink();

    // Already looking at this exact match — a floating "return to it"
    // banner over the match itself would be redundant, and would sit on
    // top of `BattleScreen`'s own paused-state UI.
    if (match.id == BattleScreen.currentlyOpenMatchId) {
      return const SizedBox.shrink();
    }

    final dismissedId = ref.watch(dismissedResumableMatchIdProvider);
    if (match.id == dismissedId) return const SizedBox.shrink();

    return Positioned.fill(
      // Top, not bottom: this popup has no idea which screen it's
      // floating over, and several of them (this app's own bottom
      // `NavigationBar`s on Home/Ujian/Profil and on Card Game Mode's own
      // shell, plus any screen with a bottom composer/action bar) already
      // occupy the bottom edge — anchoring there would sit the popup on
      // top of one of those more often than not. The area just under the
      // status bar is comparatively free across every screen this app
      // has, the same reasoning a heads-up "call in progress" bar in
      // other apps floats at the top rather than the bottom.
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: _PopupBanner(
            matchId: match.id,
            since: match.absenceOf(myUid)?.since,
          ),
        ),
      ),
    );
  }
}

class _PopupBanner extends ConsumerStatefulWidget {
  const _PopupBanner({required this.matchId, required this.since});

  final String matchId;
  final DateTime? since;

  @override
  ConsumerState<_PopupBanner> createState() => _PopupBannerState();
}

class _PopupBannerState extends ConsumerState<_PopupBanner> {
  // Same guard `_ResumableMatchShellState` used to carry — a fast
  // repeated tap on the CTA must not be able to push more than one
  // `BattleScreen` onto the root Navigator.
  bool _isOpeningBattle = false;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Only needed while there's a live "Ns" countdown to show — see
    // build() below. Runs unconditionally regardless, since [widget.since]
    // can change across rebuilds (a different resumable match, or this
    // player's own absence marker appearing/clearing) and this stays a
    // cheap 1-second `setState` either way.
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _openBattle() async {
    if (_isOpeningBattle) return;
    setState(() => _isOpeningBattle = true);
    try {
      // The root navigator, not `Navigator.of(context)` — this widget
      // sits above `MaterialApp`'s own Navigator in the Stack
      // `main.dart`'s `builder` builds, the same reason `FcmService`
      // pushes routes this way instead of threading a context through
      // from wherever a notification was handled.
      await rootNavigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => BattleScreen(matchId: widget.matchId),
        ),
      );
    } finally {
      // Guarded so a failed/interrupted push can never leave this button
      // stuck disabled forever — the exact bug class
      // `test/bug_class_sweep_test.dart` sweeps `lib/` for.
      if (mounted) setState(() => _isOpeningBattle = false);
    }
  }

  void _dismiss() {
    ref.read(dismissedResumableMatchIdProvider.notifier).state =
        widget.matchId;
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final palette = context.palette;

    final since = widget.since;
    String? subtitle;
    if (since != null) {
      final remaining =
          const Duration(seconds: kBattleAbsenceGracePeriodSeconds) -
          DateTime.now().difference(since);
      final secondsLeft = remaining.isNegative ? 0 : remaining.inSeconds + 1;
      subtitle = strings.battleResumableCountdown(secondsLeft);
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 12),
        decoration: BoxDecoration(
          color: palette.tertiaryAmberCardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        // Two rows, not one — a single row here (icon + title/subtitle +
        // the CTA's own fairly long label + a close button) was confirmed
        // on a real device to crush the `Expanded` title column down to
        // near-zero width, which doesn't overflow or error but instead
        // wraps the title one character per line ("Pertandi/ngan/masih
        // be/...") — the exact failure shape this project's own
        // `no_hardcoded_ui_strings`-adjacent history already documents
        // for a squeezed row elsewhere (`SearchFriendScreen`'s result
        // rows). Splitting the CTA onto its own row gives the title the
        // width it needs regardless of label length in either language.
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.replay_circle_filled, color: palette.primaryCoral),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        strings.battleResumableTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: palette.textNavy,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: palette.textNavy.withValues(alpha: 0.7),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close),
                  color: palette.textNavy.withValues(alpha: 0.6),
                  // No `tooltip:` — deliberately, not an oversight.
                  // `Tooltip` needs an ancestor `Overlay` to show its
                  // bubble, and this whole widget sits *outside*
                  // `MaterialApp`'s own Navigator (see `main.dart`'s
                  // `builder:`), which is the only place that `Overlay`
                  // lives — a `tooltip` here throws "No Overlay widget
                  // found" the moment this button builds (confirmed via
                  // a real on-device run: `flutter attach` logcat showed
                  // it firing repeatedly the instant this popup
                  // appeared). An icon-only close button needs no
                  // tooltip to be usable, especially on the touch-only
                  // devices this app actually ships to.
                  onPressed: _dismiss,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: palette.primaryCoral,
                ),
                // Pushes the exact same matchId — never a fresh match.
                // `BattleScreen`'s own `initState` clears this player's
                // absence entry the instant it mounts, which is what
                // actually cancels the grace period; this button only
                // navigates.
                onPressed: _isOpeningBattle ? null : _openBattle,
                child: Text(strings.battleResumableCta),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

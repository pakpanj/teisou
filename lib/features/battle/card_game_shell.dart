import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/battle_rules.dart';
import '../../core/providers.dart';
import '../../core/services/battle_deck_builder.dart';
import '../../core/theme/app_palette.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/mascot_widget.dart';
import '../../data/repositories/onboarding_repository.dart';
import '../../data/models/card_game_rank.dart';
import '../leaderboard/leaderboard_providers.dart';
import '../../core/widgets/user_avatar.dart';
import 'battle_invite_providers.dart' show battleResumableMatchProvider;
import 'battle_matchmaking_screen.dart';
import 'battle_screen.dart';
import 'card_skin_picker_screen.dart';
import '../onboarding/coach_mark_tour.dart';
import '../onboarding/first_visit_tutorial.dart';
import '../onboarding/module_tours.dart';
import 'deck_tab.dart';
import 'rank_skip_screen.dart';
import 'widgets/recent_matches_section.dart';
import 'widgets/battle_arena.dart';
import 'widgets/rank_card.dart';

/// Card Game Mode's own home, with its own bottom navigation.
///
/// Four tabs: Beranda, Deck, Battle, Skin. A mode with this much in it —
/// a ladder, a wardrobe, a card pool — stops fitting behind a single
/// screen, and burying each part one push deeper is how they end up
/// never being found.
///
/// **The shop (Toko) used to be a fifth tab here — it no longer is.**
/// Card skins, avatar, frame and cover are all cosmetics, and three of
/// those four have nothing to do with battling, so burying the only shop
/// in the app inside Card Battle's own nav meant a learner who never
/// opened Card Battle never found a shop at all. It now lives at the top
/// level, next to Home/Ujian/Profil — see `ShopScreen`. This shell keeps
/// nothing shop-related, not even a shortcut into it: Toko is one tap
/// away on the main bottom nav regardless of which screen you're on.
///
/// **Deck is still honest about being thin**: it shows the pool you are
/// dealt from rather than pretending a deck can be edited.
class CardGameShell extends ConsumerStatefulWidget {
  const CardGameShell({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<CardGameShell> createState() => _CardGameShellState();
}

/// One bottom-nav destination drawn from `assets/icons/`, in the same
/// illustrated style as the module icons on Home rather than in Material's.
///
/// [fallback] is a real Material icon, not decoration: an icon that fails
/// to decode would otherwise leave a nameless gap in the navigation bar,
/// and a bar you cannot read is a mode you cannot leave.
NavigationDestination _navIcon(String asset, String label, IconData fallback) {
  Widget art(double opacity) => Opacity(
        opacity: opacity,
        child: Image.asset(
          'assets/icons/$asset.png',
          width: 30,
          height: 30,
          errorBuilder: (context, _, _) => Icon(fallback),
        ),
      );
  return NavigationDestination(
    // Unselected tabs are dimmed rather than swapped for a different
    // drawing: with illustrated icons there is only one drawing, and
    // fading it is what a filled/outlined pair does for Material's.
    icon: art(0.55),
    selectedIcon: art(1),
    label: label,
  );
}

class _CardGameShellState extends ConsumerState<CardGameShell> {
  late int _tab = widget.initialTab;
  late final _pageController = PageController(initialPage: widget.initialTab);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Both the nav bar and [_LobbyTab]'s own "find opponent" button need to
  /// jump to a tab programmatically — swiping is the other way [_tab]
  /// changes, via [PageView.onPageChanged] below. Kept as one method so
  /// both paths agree on how a jump animates.
  void _goToTab(int index) {
    setState(() => _tab = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final palette = context.palette;

    final titles = [
      s.cardGameTabHome,
      s.cardGameTabDeck,
      s.cardGameTabBattle,
      s.cardGameTabSkin,
    ];

    return FirstVisitTutorial(
      id: TutorialId.cardGame,
      tour: cardGameTutorialSteps,
      cardBattleSkin: true,
      child: Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: Text(titles[_tab])),
      // A real PageView, so swiping left/right also switches tabs —
      // mirrors HomeScreen's own bottom-tab PageView exactly, including
      // the same reason each page is wrapped in `_KeepAlivePage`: the
      // Battle tab holds a live matchmaking countdown and a queue
      // listener, and losing that state on every tab change would cancel
      // a search the moment a learner swiped over to glance at their
      // skins. `_KeepAlivePage`'s `AutomaticKeepAliveClientMixin` keeps
      // every tab built exactly once and never torn down, the same
      // guarantee `IndexedStack` gave for free before this.
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _tab = index),
        // Off specifically while Skin (index 3) is showing —
        // `CardSkinPickerBody` has its own horizontal filter-chip strip
        // (`SingleChildScrollView(scrollDirection: Axis.horizontal)`),
        // and a horizontal drag over it would otherwise compete with
        // this PageView for the same gesture, in exactly the shape
        // `AUDIT_GESTURE_CONFLICT.md` found and fixed for Toko's
        // TabBarView-inside-PageView nesting. Unlike Toko, the chip
        // strip's own scroll can't just be turned off — there's no
        // second, tap-only way to reach a chip that overflows the
        // screen — so this disables the *outer* swipe instead, only for
        // this one tab: reaching or leaving Skin still works via the
        // bottom nav, matching the tradeoff that audit's own "option 1"
        // already accepted for this exact conflict shape.
        physics: _tab == 3
            ? const NeverScrollableScrollPhysics()
            : const PageScrollPhysics(),
        children: [
          _KeepAlivePage(child: _LobbyTab(onFindOpponent: () => _goToTab(2))),
          const _KeepAlivePage(child: DeckTab()),
          const _KeepAlivePage(child: BattleMatchmakingBody()),
          const _KeepAlivePage(child: CardSkinPickerBody()),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _goToTab,
        destinations: [
          _navIcon('nav_beranda', s.cardGameTabHome, Icons.home_outlined),
          _navIcon('nav_deck', s.cardGameTabDeck, Icons.style_outlined),
          _navIcon('nav_battle', s.cardGameTabBattle,
              Icons.sports_kabaddi_outlined),
          _navIcon('nav_skin', s.cardGameTabSkin, Icons.palette_outlined),
        ],
      ),
      ),
    );
  }
}

/// Keeps a tab's state alive once built, so swiping away and back doesn't
/// lose scroll position or rebuild it from scratch — same shape and same
/// reason as `home_screen.dart`'s private `_KeepAlivePage`, duplicated
/// here rather than exported, matching this codebase's existing
/// small-private-helper-per-file convention.
class _KeepAlivePage extends StatefulWidget {
  final Widget child;

  const _KeepAlivePage({required this.child});

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// "Pertandingan masih berlangsung" — the 30-second reconnect grace
/// period's own resume entry point (2026-08-30). See
/// `BattleRepository.findResumableMatch`'s doc comment for the query
/// this is built on, and `battle_screen.dart`'s own `initState`/app-
/// resume handling for what "resuming" actually does once this is
/// tapped — pushing the *same* `matchId`, never a new one.
///
/// Renders nothing at all while there is no resumable match — the
/// common case, so this must never reserve visible space for itself
/// when idle.
class _ResumableMatchCard extends ConsumerWidget {
  const _ResumableMatchCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = ref.watch(battleResumableMatchProvider).valueOrNull;
    if (match == null) return const SizedBox.shrink();
    final s = ref.watch(appStringsProvider);
    final myUid = ref.watch(appStartupProvider).valueOrNull?.uid;
    // Only meaningful while *this specific player* has their own entry in
    // `absence` — a match that is simply still active (no absence entries
    // at all, or only the opponent's) is still resumable, just without an
    // urgent countdown to show for it. This is FASE D's "departed player"
    // side — the offer to return, with the remaining time, that this
    // card's own doc comment already describes; the still-present
    // player's side of a pause lives on `BattleScreen` itself
    // (`_MatchPausedView`), not here.
    final myAbsence = myUid == null ? null : match.absenceOf(myUid);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: myAbsence != null
          ? _ResumableMatchCountdown(
              strings: s,
              matchId: match.id,
              since: myAbsence.since,
            )
          : _ResumableMatchStatic(strings: s, matchId: match.id),
    );
  }
}

class _ResumableMatchStatic extends StatelessWidget {
  const _ResumableMatchStatic({required this.strings, required this.matchId});

  final AppStrings strings;
  final String matchId;

  @override
  Widget build(BuildContext context) {
    return _ResumableMatchShell(
      strings: strings,
      matchId: matchId,
      subtitle: null,
    );
  }
}

/// The version with a live "Waktu tersisa: Ns" countdown — its own tiny
/// `StatefulWidget` so the 1-second tick only rebuilds this card, not
/// the whole lobby.
class _ResumableMatchCountdown extends StatefulWidget {
  const _ResumableMatchCountdown({
    required this.strings,
    required this.matchId,
    required this.since,
  });

  final AppStrings strings;
  final String matchId;
  final DateTime? since;

  @override
  State<_ResumableMatchCountdown> createState() =>
      _ResumableMatchCountdownState();
}

class _ResumableMatchCountdownState extends State<_ResumableMatchCountdown> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final since = widget.since;
    final elapsed = since == null ? Duration.zero : DateTime.now().difference(since);
    final remaining =
        const Duration(seconds: kBattleAbsenceGracePeriodSeconds) - elapsed;
    final secondsLeft = remaining.isNegative ? 0 : remaining.inSeconds + 1;
    return _ResumableMatchShell(
      strings: widget.strings,
      matchId: widget.matchId,
      subtitle: widget.strings.battleResumableCountdown(secondsLeft),
    );
  }
}

class _ResumableMatchShell extends StatefulWidget {
  const _ResumableMatchShell({
    required this.strings,
    required this.matchId,
    required this.subtitle,
  });

  final AppStrings strings;
  final String matchId;
  final String? subtitle;

  @override
  State<_ResumableMatchShell> createState() => _ResumableMatchShellState();
}

class _ResumableMatchShellState extends State<_ResumableMatchShell> {
  // A fast repeated tap on this exact button was pushing more than one
  // BattleScreen onto the Navigator stack — every other entry point into
  // BattleScreen already guarded against this (`_accept`'s `_responding`,
  // `BattleInviteWaitingScreen`'s `_opened`, matchmaking's push living
  // inside its own state machine), this one didn't. The orphaned second
  // instance kept its own Timer/answers subscription alive underneath the
  // one actually on screen, which is what surfaced later as a "Cannot use
  // ref after the widget was disposed" error scattered across several of
  // BattleScreen's own callbacks once it was finally popped.
  bool _isOpeningBattle = false;

  Future<void> _openBattle() async {
    if (_isOpeningBattle) return;
    // Set before the push starts, not after — a second tap arriving
    // while the first push is still in flight must see this immediately,
    // not race it.
    setState(() => _isOpeningBattle = true);
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => BattleScreen(matchId: widget.matchId)));
    if (!mounted) return;
    setState(() => _isOpeningBattle = false);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.tertiaryAmberCardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.replay_circle_filled, color: palette.primaryCoral),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.strings.battleResumableTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: palette.textNavy,
                  ),
                ),
                if (widget.subtitle != null)
                  Text(
                    widget.subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: palette.textNavy.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: palette.primaryCoral,
            ),
            // Pushes the exact same matchId — never
            // BattleRepository.createMatch, so this can never spawn a
            // duplicate match. BattleScreen's own initState clears this
            // player's absence entry the instant it mounts (see its
            // `_clearOwnAbsenceMark`), which is what actually cancels
            // the grace period — this button only navigates.
            onPressed: _isOpeningBattle ? null : _openBattle,
            child: Text(widget.strings.battleResumableCta),
          ),
        ],
      ),
    );
  }
}

/// The first thing you see: who you are, where you stand, and one button.
///
/// Follows the redesign's lobby panel. Three of its pieces are
/// deliberately **not** here: the mail, gift and settings icons in its
/// top corner have nothing behind them in this app, and a row of buttons
/// that do nothing is worse than a tidier corner.
class _LobbyTab extends ConsumerWidget {
  const _LobbyTab({required this.onFindOpponent});

  final VoidCallback onFindOpponent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final palette = context.palette;
    final rank = ref.watch(cardGameRankProvider).valueOrNull;
    final starTotal = ref
            .watch(selfLeaderboardEntryProvider)
            .valueOrNull
            ?.cardGameStarTotal ??
        0;

    if (rank == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return BattleBackdrop(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const _ResumableMatchCard(),
          TutorialTarget(
            id: kTutorialCardGameHeader,
            child: _LobbyHeader(rank: rank, starTotal: starTotal, strings: s),
          ),
          const SizedBox(height: 14),
          TutorialTarget(
            id: kTutorialCardGameRank,
            child: RankCard(rank: rank, starTotal: starTotal, strings: s),
          ),
          const SizedBox(height: 14),
          TutorialTarget(
            id: kTutorialCardGameDeck,
            child: _DeckStrip(rank: rank, strings: s),
          ),
          const SizedBox(height: 18),
          // Renders nothing until there is history, so a new player sees
          // the button move up rather than an empty heading.
          const RecentMatchesSection(),
          TutorialTarget(
            id: kTutorialCardGameSearch,
            child: Center(
              child: SizedBox(
                width: 280,
                height: 62,
                child: FilledButton(
                  onPressed: onFindOpponent,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.sports_kabaddi, size: 22),
                      const SizedBox(width: 10),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            s.battleMatchmakingSearchButton,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            s.cardGameSearchSubtitle,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // The way past the tiers a player has already outgrown. Put
          // under the search button rather than beside it: climbing is
          // still the normal route, and this is the exception for
          // someone who arrived already knowing kanji.
          TutorialTarget(
            id: kTutorialCardGameRankSkip,
            child: Center(
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const RankSkipScreen(),
                  ),
                ),
                icon: Icon(Icons.trending_up, color: palette.primaryCoral),
                label: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      s.rankSkipEntry,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: palette.primaryCoral,
                      ),
                    ),
                    Text(
                      s.rankSkipEntrySubtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: palette.textNavy.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Reachable again after the first visit. The walkthrough shows
          // itself once, and a mode with a star ladder, tier-locked
          // cards and a ten-second choosing window is not one to leave
          // unexplained to anyone who skipped it — or to a tester, who
          // would otherwise have to clear the app's data to see it.
          //
          // Pushed as the same transparent coach-mark route
          // `FirstVisitTutorial` uses internally (not through that
          // widget itself, which would also touch the "seen" flag — a
          // replay must not re-arm or disturb it either way). This is
          // also the one place able to give the tour its own finish
          // label (`cardTutorialStart`, "Mulai Bertanding") rather than
          // the generic one `FirstVisitTutorial`'s first-run path uses
          // for every module's tour.
          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                PageRouteBuilder<void>(
                  opaque: false,
                  barrierColor: Colors.transparent,
                  pageBuilder: (_, _, _) => CoachMarkTour(
                    steps: cardGameTutorialSteps(s),
                    nextLabel: s.tourNext,
                    finishLabel: s.cardTutorialStart,
                    skipLabel: s.tutorialSkip,
                    cardBattleSkin: true,
                  ),
                ),
              ),
              icon: Icon(Icons.help_outline,
                  size: 18, color: palette.textNavy.withValues(alpha: 0.6)),
              label: Text(
                s.cardTutorialReplay,
                style: TextStyle(
                  fontSize: 12,
                  color: palette.textNavy.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            s.cardGameLobbyHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: palette.textNavy.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Who you are, and the mode's own name — the redesign's masthead.
class _LobbyHeader extends ConsumerWidget {
  const _LobbyHeader({
    required this.rank,
    required this.starTotal,
    required this.strings,
  });

  final CardGameRank rank;
  final int starTotal;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final user = ref.watch(appStartupProvider).valueOrNull;
    final name =
        profile?.resolveDisplayName(user) ?? strings.defaultLearnerName;

    return Row(
      children: [
        UserAvatar(profile: profile, user: user, radius: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: palette.textNavy,
                ),
              ),
              Row(
                children: [
                  Text(
                    rank.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: palette.textNavy.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.star, size: 13, color: palette.primaryCoral),
                  const SizedBox(width: 2),
                  Text(
                    '$starTotal',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: palette.primaryCoral,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              strings.cardGameWordmark,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
                color: palette.primaryCoral,
              ),
            ),
            Text(
              strings.cardGameWordmarkSub,
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 0.8,
                color: palette.textNavy.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
        // The mascot belongs beside the mode's name, as in the redesign
        // — it is the mode's face, not a decoration on the lobby body.
        const MascotWidget(
          mood: MascotMood.battleReady,
          size: 54,
          showBackdrop: false,
          cardBattleSkin: true,
        ),
      ],
    );
  }
}

/// A taste of the pool a match deals from. Three cards rather than a
/// count alone: the deck is the thing being played with, and a number
/// does not look like one.
class _DeckStrip extends ConsumerWidget {
  const _DeckStrip({required this.rank, required this.strings});

  final CardGameRank rank;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final cardData = ref.watch(battleCardDataProvider).valueOrNull;
    final prompts = <String>[];
    if (cardData != null) {
      final pool = cardPoolFor(
        rank.tier.cardContent,
        cardData.$1,
        cardData.$2,
      );
      for (final id in pool.take(3)) {
        final card = resolveCard(id, cardData.$1, cardData.$2);
        if (card != null) prompts.add(card.prompt);
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: palette.cardWhite.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                strings.cardGameLobbyDeckTitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: palette.textNavy.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: palette.hiraganaCardBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  strings.cardGameLobbyDeckCount(kBattleTotalRounds ~/ 2),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: palette.textNavy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 3; i++) ...[
                _MiniCard(
                  prompt: i < prompts.length ? prompts[i] : '',
                  tint: [
                    palette.hiraganaCardBg,
                    palette.katakanaCardBg,
                    palette.tertiaryAmberCardBg,
                  ][i],
                ),
                if (i < 2) const SizedBox(width: 10),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.prompt, required this.tint});

  final String prompt;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: 62,
      height: 82,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: palette.textNavy.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          prompt,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: palette.textNavy,
          ),
        ),
      ),
    );
  }
}

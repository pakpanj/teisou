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
import 'battle_matchmaking_screen.dart';
import 'card_skin_picker_screen.dart';
import '../onboarding/first_visit_tutorial.dart';
import '../onboarding/onboarding_screen.dart';
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
      steps: cardGameTutorialSteps,
      finishLabel: s.cardTutorialStart,
      child: Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: Text(titles[_tab])),
      // IndexedStack, not a swapped child: the Battle tab holds a live
      // matchmaking countdown and a queue listener, and rebuilding it on
      // every tab change would cancel a search the moment a learner
      // glanced at their skins.
      body: IndexedStack(
        index: _tab,
        children: [
          _LobbyTab(onFindOpponent: () => setState(() => _tab = 2)),
          const DeckTab(),
          const BattleMatchmakingBody(),
          const CardSkinPickerBody(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
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
          _LobbyHeader(rank: rank, starTotal: starTotal, strings: s),
          const SizedBox(height: 14),
          RankCard(rank: rank, starTotal: starTotal, strings: s),
          const SizedBox(height: 14),
          _DeckStrip(rank: rank, strings: s),
          const SizedBox(height: 18),
          // Renders nothing until there is history, so a new player sees
          // the button move up rather than an empty heading.
          const RecentMatchesSection(),
          Center(
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
          const SizedBox(height: 12),
          // The way past the tiers a player has already outgrown. Put
          // under the search button rather than beside it: climbing is
          // still the normal route, and this is the exception for
          // someone who arrived already knowing kanji.
          Center(
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
          const SizedBox(height: 6),
          // Reachable again after the first visit. The walkthrough shows
          // itself once, and a mode with a star ladder, tier-locked
          // cards and a ten-second choosing window is not one to leave
          // unexplained to anyone who skipped it — or to a tester, who
          // would otherwise have to clear the app's data to see it.
          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OnboardingScreen(
                    steps: cardGameTutorialSteps,
                    finishLabel: s.cardTutorialStart,
                    // A replay only closes itself; the seen flag stays
                    // set, since this is not the first visit.
                    onFinished: () => Navigator.of(context).pop(),
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

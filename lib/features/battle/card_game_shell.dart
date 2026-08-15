import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/mascot_widget.dart';
import '../leaderboard/leaderboard_providers.dart';
import 'battle_matchmaking_screen.dart';
import 'card_skin_picker_screen.dart';
import 'deck_tab.dart';
import 'shop_tab.dart';
import 'widgets/rank_card.dart';

/// Card Game Mode's own home, with its own bottom navigation.
///
/// Five tabs, following the redesign: Beranda, Deck, Battle, Skin, Toko.
/// A mode with this much in it — a ladder, a wardrobe, a card pool, a
/// shop — stops fitting behind a single screen, and burying each part
/// one push deeper is how they end up never being found.
///
/// **Two of the five are honest about being thin.** Deck shows the pool
/// you are dealt from rather than pretending a deck can be edited, and
/// Toko is a window with nothing to buy until `in_app_purchase` is
/// wired. Both say so on the screen instead of looking broken.
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
      s.cardGameTabShop,
    ];

    return Scaffold(
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
          const ShopTab(),
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
          _navIcon('nav_toko', s.cardGameTabShop, Icons.storefront_outlined),
        ],
      ),
    );
  }
}

/// The first thing you see: where you stand, and one button.
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        RankCard(rank: rank, starTotal: starTotal, strings: s),
        const SizedBox(height: 12),
        // The mascot rather than the fanned deck: the deck has its own
        // tab next door now, and a lobby whose only job is "start a
        // match" reads better with somebody waiting to play than with a
        // picture of the cards. Standing on its own shadow, no disc —
        // this is a scene, not an icon in a card.
        const Center(
          child: MascotWidget(
            mood: MascotMood.battleReady,
            size: 160,
            showBackdrop: false,
            groundShadow: true,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: SizedBox(
            width: 240,
            height: 54,
            child: FilledButton(
              onPressed: onFindOpponent,
              child: Text(
                s.battleMatchmakingSearchButton,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          s.cardGameLobbyHint,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: palette.textNavy.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

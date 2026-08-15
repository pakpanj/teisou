import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
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
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: s.cardGameTabHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.style_outlined),
            selectedIcon: const Icon(Icons.style),
            label: s.cardGameTabDeck,
          ),
          NavigationDestination(
            icon: const Icon(Icons.sports_kabaddi_outlined),
            selectedIcon: const Icon(Icons.sports_kabaddi),
            label: s.cardGameTabBattle,
          ),
          NavigationDestination(
            icon: const Icon(Icons.palette_outlined),
            selectedIcon: const Icon(Icons.palette),
            label: s.cardGameTabSkin,
          ),
          NavigationDestination(
            icon: const Icon(Icons.storefront_outlined),
            selectedIcon: const Icon(Icons.storefront),
            label: s.cardGameTabShop,
          ),
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
        const SizedBox(height: 20),
        const Center(child: FannedDeck()),
        const SizedBox(height: 20),
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

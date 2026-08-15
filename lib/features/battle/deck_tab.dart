import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/services/battle_deck_builder.dart';
import '../../core/theme/app_palette.dart';
import '../../data/models/card_game_rank.dart';
import 'battle_challenge.dart' show cardTierContentLabel;

/// What your deck is made of.
///
/// **Deliberately a study screen, not a deck builder.** Nothing about a
/// deck is player-editable — twenty cards are dealt from the pool your
/// tier decides, and the tier is decided by your stars — so there is
/// nothing here to manage. What there is, is worth knowing: these are
/// the exact characters a match can ask you, and the tier above shows
/// what is coming. Pretending otherwise would mean inventing a mechanic
/// to justify a tab.
class DeckTab extends ConsumerWidget {
  const DeckTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final palette = context.palette;
    final rank = ref.watch(cardGameRankProvider).valueOrNull;
    final cardData = ref.watch(battleCardDataProvider).valueOrNull;

    if (rank == null || cardData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final tier = rank.tier;
    final pool = cardPoolFor(tier.cardContent, cardData.$1, cardData.$2);
    final next = tier.next;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          s.deckTabHeading(cardTierContentLabel(tier.cardContent, s)),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: palette.textNavy,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          s.deckTabExplanation(pool.length),
          style: TextStyle(
            fontSize: 13,
            color: palette.textNavy.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),
        _PoolGrid(
          prompts: [
            for (final id in pool)
              resolveCard(id, cardData.$1, cardData.$2)?.prompt ?? '',
          ]..removeWhere((p) => p.isEmpty),
        ),
        if (next != null) ...[
          const SizedBox(height: 28),
          Text(
            s.deckTabNextTier(
              next.displayName,
              cardTierContentLabel(next.cardContent, s),
            ),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: palette.textNavy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            s.deckTabNextTierHint,
            style: TextStyle(
              fontSize: 12,
              color: palette.textNavy.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          Opacity(
            opacity: 0.55,
            child: _PoolGrid(
              // A taste, not the whole thing: the point is "here is what
              // is coming", and the full N1 pool would bury this screen.
              prompts: [
                for (final id in cardPoolFor(
                  next.cardContent,
                  cardData.$1,
                  cardData.$2,
                ).take(24))
                  resolveCard(id, cardData.$1, cardData.$2)?.prompt ?? '',
              ]..removeWhere((p) => p.isEmpty),
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _PoolGrid extends StatelessWidget {
  const _PoolGrid({required this.prompts});

  final List<String> prompts;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final prompt in prompts)
          Container(
            width: 54,
            height: 68,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.cardWhite,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: palette.secondaryBlue.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              prompt,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: prompt.characters.length > 2 ? 16 : 24,
                fontWeight: FontWeight.bold,
                color: palette.textNavy,
              ),
            ),
          ),
      ],
    );
  }
}

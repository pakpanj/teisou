import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/card_skins.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';

/// The shop — a window, not a till.
///
/// **Nothing here can be bought yet, and the screen says so.** This app
/// has never had `in_app_purchase` wired up; it is still on the release
/// blocker list. Building the shelf now is worth it anyway — it is how
/// the paid skins get seen, and seeing them is most of what makes anyone
/// want one — but a button that takes a tap and does nothing would be
/// worse than no button. So each card is marked plainly as not yet for
/// sale.
///
/// When billing lands, the change is small and local: a price on the
/// preset, a real purchase call here, and `isCardSkinUnlocked`'s `owned`
/// argument fed from what the player has bought.
class ShopTab extends ConsumerWidget {
  const ShopTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final palette = context.palette;
    final paid = CardSkinPresets.ofSource(CardSkinSource.paid).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: palette.tertiaryAmberCardBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: palette.textNavy),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.shopNotOpenYet,
                  style: TextStyle(fontSize: 12, color: palette.textNavy),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          s.shopSkinsHeading,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: palette.textNavy,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          // The line that keeps the two families apart in the player's
          // head: what is on sale here can never be earned, and what is
          // earned can never be sold.
          s.shopSkinsSubtitle,
          style: TextStyle(
            fontSize: 12,
            color: palette.textNavy.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 14),
        for (final skin in paid) ...[
          _ShopRow(skin: skin, label: skin.labelFor(s.language)),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _ShopRow extends ConsumerWidget {
  const _ShopRow({required this.skin, required this.label});

  final CardSkinPreset skin;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.divider),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            height: 79,
            child: CardSkinBack(
              skin: skin,
              borderRadius: 10,
              showCrest: false,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: palette.textNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.shopSkinRowNote,
                  style: TextStyle(
                    fontSize: 12,
                    color: palette.textNavy.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          // Disabled on purpose rather than hidden: the shelf should look
          // like a shelf, and a greyed price reads as "not yet" where an
          // absent button reads as "never".
          FilledButton(
            onPressed: null,
            child: Text(s.shopBuySoon),
          ),
        ],
      ),
    );
  }
}

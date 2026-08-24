import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_palette.dart';
import 'coin_top_up_sheet.dart';

/// The coin balance, shown once at the top of `ShopScreen` rather than
/// per-tab — a balance is one number that belongs to the account, not to
/// whichever tab happens to be open, so it stays visible across all four.
/// Tapping "Top Up" opens [CoinTopUpSheet].
class CoinBalanceBar extends ConsumerWidget {
  const CoinBalanceBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final balance = ref.watch(coinBalanceProvider).valueOrNull ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.palette.tertiaryAmberCardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.monetization_on, color: context.palette.tertiaryAmber),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.coinBalanceAmount(balance),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: context.palette.textNavy,
                  ),
                ),
                Text(
                  s.coinBalanceLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.palette.textNavy.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.palette.tertiaryAmber,
              foregroundColor: context.palette.textNavy,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const CoinTopUpSheet(),
            ),
            child: Text(s.coinBuyTopUp),
          ),
        ],
      ),
    );
  }
}

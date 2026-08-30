import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/iap_products.dart';
import '../../../core/providers.dart';
import '../../../core/services/coin_purchase_flow.dart';
import '../../../core/services/iap_service.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/purchase_success_snackbar.dart';

/// The three coin packs, plus an explainer for the other way to earn
/// coins (placing top 1-3 on Skor Global each week — see
/// `functions/award_top_coins.js`). Mirrors `PaywallScreen`'s
/// load-in-`initState` / listen-for-outcome shape, via [CoinPurchaseFlow]
/// instead of `PremiumPurchaseFlow`.
class CoinTopUpSheet extends ConsumerStatefulWidget {
  const CoinTopUpSheet({super.key});

  @override
  ConsumerState<CoinTopUpSheet> createState() => _CoinTopUpSheetState();
}

class _CoinTopUpSheetState extends ConsumerState<CoinTopUpSheet> {
  late final CoinPurchaseFlow _purchase;
  StreamSubscription<IapOutcome>? _outcomeSub;
  String? _buying;

  /// Which pack the *last* buy attempt was for — kept separate from
  /// [_buying] on purpose. [_buying] is only "is the store sheet still
  /// opening" state: `_buy`'s own trailing cleanup clears it the moment
  /// `IapService.buyCoinPack` returns, which for a real Play purchase
  /// happens as soon as the store sheet is *launched*, not when the
  /// purchase actually completes — the real `IapOutcome` can arrive
  /// long after that, by which point `_buying` is already back to
  /// `null`. This field is never cleared by `_buy`, only ever
  /// overwritten by the next attempt, so it survives long enough for the
  /// outcome listener below to still know which pack succeeded.
  String? _lastAttemptedProductId;

  @override
  void initState() {
    super.initState();
    _purchase = CoinPurchaseFlow(ref);
    _purchase.loadPrices().then((_) {
      if (mounted) setState(() {});
    });
    _outcomeSub = _purchase.outcomes.listen((outcome) {
      if (!mounted) return;
      final boughtProductId = _lastAttemptedProductId;
      setState(() => _buying = null);
      final s = ref.read(appStringsProvider);
      final message = switch (outcome) {
        IapOutcome.delivered => s.purchaseDelivered,
        IapOutcome.cancelled => s.purchaseCancelled,
        IapOutcome.unavailable => s.storeUnavailable,
        IapOutcome.failed => s.purchaseFailed,
        // In practice unreachable for a coin pack — `verifyWithPlay`
        // only retries the subscription product (see `functions/iap.js`)
        // — but IapOutcome is shared across every purchase type, so the
        // switch stays exhaustive here too.
        IapOutcome.pendingVerification => s.purchasePendingVerification,
        // Also in practice subscription-only — a coin pack never goes
        // through account-binding classification — kept for the same
        // exhaustiveness reason as pendingVerification above.
        IapOutcome.accountMismatch => s.purchaseAccountMismatch,
      };
      if (outcome == IapOutcome.delivered) {
        // The one, polished success moment — see
        // `showPurchaseSuccessSnackBar`'s own doc comment for why every
        // purchase-success bar in the app shares this instead of a bare
        // SnackBar. Falls back to the generic message if this sheet was
        // never actually the one that bought anything (a `delivered` for
        // some other purchase entirely reaching this listener, which
        // `IapOutcome` being one shared app-wide stream makes possible in
        // principle) — `_lastAttemptedProductId` is never set to
        // anything outside `IapProducts.coinPackAmounts`'s own keys.
        final amount = IapProducts.coinPackAmounts[boughtProductId];
        showPurchaseSuccessSnackBar(
          context,
          message: amount != null ? s.coinTopUpSuccess(amount) : message,
          icon: Icons.monetization_on,
        );
        Navigator.of(context).maybePop();
        return;
      }
      // Every non-success outcome (cancelled/unavailable/failed/pending/
      // mismatch) keeps the exact plain SnackBar it always has — only the
      // success path gets the new treatment.
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    });
  }

  @override
  void dispose() {
    _outcomeSub?.cancel();
    super.dispose();
  }

  Future<void> _buy(String productId) async {
    setState(() => _buying = productId);
    _lastAttemptedProductId = productId;
    final s = ref.read(appStringsProvider);
    await _purchase.buy(context, s, productId);
    // A failure that never opened the sheet (no uid, store unavailable)
    // leaves no outcome coming — same bug shape `bug_class_sweep_test.dart`
    // already guards against elsewhere in this app.
    if (mounted && _buying == productId) setState(() => _buying = null);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.palette.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.palette.textNavy.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                s.coinTopUpTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.palette.textNavy,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                s.coinTopUpSubtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: context.palette.textNavy.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 16),
              // One row per pack, built from the locked map rather than
              // named one-by-one — six packs today, but a pack added or
              // resized later only needs an entry in
              // `IapProducts.coinPackAmounts`, not a new row here too.
              for (final entry in IapProducts.coinPackAmounts.entries) ...[
                _PackRow(
                  label: s.coinPackLabel(entry.value),
                  price: _purchase.priceFor(entry.key),
                  busy: _buying == entry.key,
                  onBuy: () => _buy(entry.key),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.palette.mutedSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.emoji_events,
                        color: context.palette.tertiaryAmber),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.coinEarnFromRankTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: context.palette.textNavy,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.coinEarnFromRankSubtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.palette.textNavy
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PackRow extends StatelessWidget {
  final String label;
  final String? price;
  final bool busy;
  final VoidCallback onBuy;

  const _PackRow({
    required this.label,
    required this.price,
    required this.busy,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.palette.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.palette.divider),
      ),
      child: Row(
        children: [
          Icon(Icons.monetization_on, color: context.palette.tertiaryAmber, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: context.palette.textNavy,
              ),
            ),
          ),
          if (busy)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            FilledButton(
              onPressed: price == null ? null : onBuy,
              child: Text(price ?? '—'),
            ),
        ],
      ),
    );
  }
}

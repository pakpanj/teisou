import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/providers.dart';
import '../../../core/services/iap_service.dart';
import '../../../core/services/premium_purchase_flow.dart';
import '../../../core/theme/app_palette.dart';

/// Profile's own Premium entry point — until now the only trace of
/// Premium on this whole screen was a small pill next to the display
/// name (`_TierBadge`), and there was no way to actually buy Premium
/// from Profile at all: every real paywall lived behind a specific
/// gated feature (a locked module card, a premium avatar). This card
/// is that missing entry point, not just a re-skin of the badge.
///
/// A free learner sees a real "become Premium" offer with the live
/// store price; a Premium subscriber sees a short thank-you instead —
/// there is nothing left to sell them, and a card still pushing an
/// upgrade at someone who already bought it reads as the app not
/// knowing its own state.
class PremiumCard extends ConsumerStatefulWidget {
  const PremiumCard({super.key});

  @override
  ConsumerState<PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends ConsumerState<PremiumCard> {
  late final PremiumPurchaseFlow _purchase;
  StreamSubscription<IapOutcome>? _outcomeSub;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _purchase = PremiumPurchaseFlow(ref);
    _purchase.loadPrice().then((_) {
      if (mounted) setState(() {});
    });
    _outcomeSub = _purchase.outcomes.listen((outcome) {
      if (!mounted) return;
      setState(() => _busy = false);
      final s = ref.read(appStringsProvider);
      final message = switch (outcome) {
        IapOutcome.delivered => s.purchaseDelivered,
        IapOutcome.cancelled => s.purchaseCancelled,
        IapOutcome.unavailable => s.storeUnavailable,
        IapOutcome.failed => s.purchaseFailed,
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    });
  }

  @override
  void dispose() {
    _outcomeSub?.cancel();
    super.dispose();
  }

  Future<void> _buy() async {
    setState(() => _busy = true);
    try {
      await _purchase.buy(context, ref.read(appStringsProvider));
    } finally {
      // A failure here must not leave the button spinning forever —
      // the same shape this project has shipped repeatedly (see
      // `bug_class_sweep_test.dart`), just a new instance of it.
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    try {
      await _purchase.restore();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final isPremium =
        ref.watch(subscriptionProvider).valueOrNull?.isPremium ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.palette.premiumCardStart,
            context.palette.premiumCardEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.palette.premiumCardEnd.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: isPremium
          ? _ActiveContent(strings: s)
          : _UpgradeContent(
              strings: s,
              price: _purchase.price,
              busy: _busy,
              onBuy: _buy,
              onRestore: _restore,
            ),
    );
  }
}

class _ActiveContent extends StatelessWidget {
  final AppStrings strings;

  const _ActiveContent({required this.strings});

  @override
  Widget build(BuildContext context) {
    final s = strings;
    return Row(
      children: [
        const Icon(Icons.workspace_premium, color: Colors.white, size: 32),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.profilePremiumActiveTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                s.profilePremiumActiveSubtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UpgradeContent extends StatelessWidget {
  final AppStrings strings;
  final String? price;
  final bool busy;
  final VoidCallback onBuy;
  final VoidCallback onRestore;

  const _UpgradeContent({
    required this.strings,
    required this.price,
    required this.busy,
    required this.onBuy,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final s = strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.workspace_premium, color: Colors.white, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                s.profilePremiumUpgradeTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          s.profilePremiumUpgradeSubtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.92),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _Chip(icon: Icons.style, label: s.planIntroValueExclusive),
            _Chip(icon: Icons.menu_book, label: s.planIntroRowKanji),
            _Chip(icon: Icons.block, label: s.planIntroValueAdsFree),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: context.palette.premiumCardEnd,
                ),
                onPressed: busy ? null : onBuy,
                child: busy
                    ? SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.palette.premiumCardEnd,
                        ),
                      )
                    : Text(s.upgradePremiumButton(price)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Center(
          child: TextButton(
            onPressed: busy ? null : onRestore,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: Text(s.purchaseRestore),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 10.5)),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/iap_service.dart';
import '../../core/constants/iap_products.dart';
import 'module_access.dart';

import '../../core/localization/app_strings.dart';
import '../../core/providers.dart';
import '../../core/services/premium_purchase_flow.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/mascot_widget.dart';

/// Shown when a free user taps a premium-gated module. Offers the (not yet
/// wired to a real Play Console SKU) monthly upgrade, or a rewarded ad —
/// either a 24h preview of [moduleId] (default), or a single use if
/// [singleUse] is set (e.g. the avatar picker: one ad grants exactly one
/// profile photo change, not a free-for-all 24h window).
class PaywallScreen extends ConsumerStatefulWidget {
  final String moduleId;
  final String moduleTitle;
  final bool singleUse;

  const PaywallScreen({
    super.key,
    required this.moduleId,
    required this.moduleTitle,
    this.singleUse = false,
  });

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {

  bool _watchingAd = false;
  StreamSubscription<IapOutcome>? _outcomeSub;
  late final PremiumPurchaseFlow _purchase;

  @override
  void initState() {
    super.initState();
    _purchase = PremiumPurchaseFlow(ref);
    // Loaded eagerly, not on button tap, so the real store price is
    // already on screen the moment this paywall opens — the same
    // pattern `ShopTab` uses for skin prices. `loadPrice` is a no-op
    // with nothing to await while `IapProducts.purchasesEnabled` is
    // off, so this is safe to call unconditionally.
    _listenForOutcome();
    _purchase.loadPrice().then((_) {
      // `IapService` mutates its own product map in place rather than
      // notifying Riverpod, so nothing rebuilds this screen on its own
      // once the store answers — this setState is what actually puts
      // the fetched price on screen.
      if (mounted) setState(() {});
    });
  }

  /// The store's own result, which arrives on a stream rather than from
  /// the buy call — a purchase can be approved by a parent hours later,
  /// or restored on a different phone entirely.
  void _listenForOutcome() {
    _outcomeSub ??= _purchase.outcomes.listen((outcome) {
      if (!mounted) return;
      final s = ref.read(appStringsProvider);
      final message = switch (outcome) {
        IapOutcome.delivered => s.purchaseDelivered,
        IapOutcome.cancelled => s.purchaseCancelled,
        IapOutcome.unavailable => s.storeUnavailable,
        IapOutcome.failed => s.purchaseFailed,
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      // Only a delivered purchase closes the paywall. A cancelled one
      // leaves the learner where they were, which is where they chose to
      // be.
      if (outcome == IapOutcome.delivered) Navigator.of(context).maybePop();
    });
  }

  Future<void> _restore() async {
    _listenForOutcome();
    await _purchase.restore();
  }

  @override
  void dispose() {
    _outcomeSub?.cancel();
    super.dispose();
  }

  Future<void> _watchAdForPreview() async {
    setState(() => _watchingAd = true);
    final s = ref.read(appStringsProvider);
    ref.read(adServiceProvider).loadAndShowRewarded(
      onRewardEarned: () async {
        try {
          final uid = ref.read(appStartupProvider).valueOrNull?.uid;
          if (uid != null) {
            await ref
                .read(progressRepositoryProvider)
                .unlockAdReward(uid, widget.moduleId);
            // **Without this the ad buys nothing.** `moduleAccessProvider`
            // is a `FutureProvider.family` that reads the reward once and
            // caches it, and its consumer sits in a Home tab held alive by
            // `AutomaticKeepAliveClientMixin` — so it is never disposed and
            // never refetches. The reward lands in Firestore, the card stays
            // locked, and tapping it reopens this same paywall: a learner
            // can watch the ad every time and never get in. Twice before in
            // this app a write had no matching read; this is the same shape.
            ref.invalidate(moduleAccessProvider);
          }
        } catch (_) {
          if (!mounted) return;
          setState(() => _watchingAd = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.previewUnlockFailed)),
          );
          return;
        }
        if (!mounted) return;
        setState(() => _watchingAd = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.singleUse
                  ? s.previewUnlockedSingleUse(widget.moduleTitle)
                  : s.previewUnlockedFor(widget.moduleTitle),
            ),
          ),
        );
        Navigator.of(context).pop();
      },
      onFailedToLoad: () {
        if (!mounted) return;
        setState(() => _watchingAd = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.adNotReadyYet)),
        );
      },
      onDismissedWithoutReward: () {
        if (!mounted) return;
        setState(() => _watchingAd = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.adClosedEarly)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: const Text('Premium')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Same gold-light/purple-dark gradient as the Profile
              // Premium card and the plan-intro price card — this was the
              // one Premium surface still ignoring the theme.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.palette.premiumCardStart,
                      context.palette.premiumCardEnd,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color:
                          context.palette.premiumCardEnd.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const MascotWidget(
                      mood: MascotMood.proud,
                      size: 130,
                      showBackdrop: false,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      s.unlockAllModulesTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.unlockAllModulesSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _BenefitList(strings: s),
              const SizedBox(height: 28),
              // While purchases are switched off this screen must not
              // become a dead end: the gate is still on, so the rewarded
              // ad below is the only way through, and offering a buy
              // button that cannot complete would read as a broken app
              // rather than a shop that has not opened.
              if (IapProducts.purchasesEnabled) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: context.palette.premiumCardEnd,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => _purchase.buy(context, s),
                    child: Text(s.upgradePremiumButton(_purchase.price)),
                  ),
                ),
                const SizedBox(height: 8),
                // Every store requires this, and a learner who paid and
                // then changed phone has no other way back to what they
                // own — the purchase is on their store account, not on
                // this device.
                TextButton(
                  onPressed: _restore,
                  child: Text(s.purchaseRestore),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: context.palette.textNavy.withValues(alpha: 0.2)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        s.orLabel,
                        style: TextStyle(
                          color: context.palette.textNavy.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: context.palette.textNavy.withValues(alpha: 0.2)),
                    ),
                  ],
                ),
              ] else
                Text(
                  s.purchaseNotSetUp,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.palette.textNavy.withValues(alpha: 0.65),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _watchingAd ? null : _watchAdForPreview,
                  child: _watchingAd
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          widget.singleUse
                              ? s.watchAdForSingleChangeButton
                              : s.watchAdForPreviewButton,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitList extends StatelessWidget {
  final AppStrings strings;

  const _BenefitList({required this.strings});

  List<String> get _benefits => [
        strings.benefitExclusiveCardSkins,
        strings.benefitFullMaterials,
        strings.benefitPremiumPractice,
        strings.benefitNoAds,
      ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _benefits
          .map(
            (benefit) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: context.palette.successGreen, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(benefit, style: TextStyle(color: context.palette.textNavy)),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

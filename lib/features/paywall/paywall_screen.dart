import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/iap_service.dart';
import '../../core/constants/iap_products.dart';
import '../../core/constants/premium_icons.dart';
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

  /// False for a subscription-only cosmetic (an avatar/frame/cover tier
  /// added 2026-08-24 that a rewarded ad deliberately can never unlock —
  /// see `AvatarPresets.isPremiumOnly`'s own doc comment for why that
  /// tier exists). Offering the ad button anyway would be the exact bug
  /// this app already shipped and fixed once: a reward gets recorded,
  /// the item stays locked, and it reads as "I watched the ad and it
  /// still won't open."
  final bool showAdOption;

  const PaywallScreen({
    super.key,
    required this.moduleId,
    required this.moduleTitle,
    this.singleUse = false,
    this.showAdOption = true,
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
                    // The mascot plus its four feature badges floating
                    // around it — the same "hero with orbiting icons"
                    // composition the user's reference image used, built
                    // from the six premium-icon assets generated
                    // 2026-08-24 (see `PremiumIcons`'s own doc comment).
                    const _MascotWithBadges(),
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
              const SizedBox(height: 20),
              // Where you are vs. what's on offer, said in one glance —
              // the same "two chests" metaphor the reference used for
              // its plan picker, just as a comparison strip here rather
              // than a pickable choice: this screen is a paywall, not
              // the onboarding plan picker, so there's nothing to
              // actually select on the Free side.
              _PlanChestStrip(strings: s),
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
                if (widget.showAdOption) ...[
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
                ],
              ] else
                Text(
                  s.purchaseNotSetUp,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.palette.textNavy.withValues(alpha: 0.65),
                  ),
                ),
              if (widget.showAdOption) ...[
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
            ],
          ),
        ),
      ),
    );
  }
}

/// The cat plus its four feature badges, floating around it the way the
/// user's reference image floated icon badges around its own mascot —
/// see [_FeatureBadge] and `PremiumIcons`'s doc comment for where the
/// art came from.
class _MascotWithBadges extends StatelessWidget {
  const _MascotWithBadges();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 178,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: const [
          MascotWidget(mood: MascotMood.proud, size: 130, showBackdrop: false),
          Positioned(top: 2, left: 0, child: _FeatureBadge(PremiumIcons.skin)),
          Positioned(top: -4, right: 4, child: _FeatureBadge(PremiumIcons.kanji)),
          Positioned(bottom: 10, left: 6, child: _FeatureBadge(PremiumIcons.kaiwa)),
          Positioned(bottom: 4, right: 0, child: _FeatureBadge(PremiumIcons.noAds)),
        ],
      ),
    );
  }
}

/// One floating icon badge. The art already carries its own circular
/// backdrop (see `PremiumIcons`'s doc comment), so this only adds the
/// drop shadow that makes it read as floating in front of the mascot
/// rather than pasted flat behind it.
class _FeatureBadge extends StatelessWidget {
  final String asset;

  const _FeatureBadge(this.asset);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Image.asset(asset, fit: BoxFit.contain),
    );
  }
}

/// "Where you are" vs. "what's on offer", the two-chest comparison from
/// the reference image — see the doc comment where this is placed in
/// `PaywallScreen.build` for why it's a comparison strip here rather
/// than a pickable choice like the onboarding flow's own chest cards.
class _PlanChestStrip extends StatelessWidget {
  final AppStrings strings;

  const _PlanChestStrip({required this.strings});

  @override
  Widget build(BuildContext context) {
    final s = strings;
    return Row(
      children: [
        Expanded(
          child: _PlanChestTile(
            asset: PremiumIcons.chestFree,
            label: s.paywallCurrentPlanLabel,
            dimmed: true,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            Icons.arrow_forward_rounded,
            color: context.palette.textNavy.withValues(alpha: 0.35),
          ),
        ),
        Expanded(
          child: _PlanChestTile(
            asset: PremiumIcons.chestPremium,
            label: s.profilePremiumUpgradeTitle,
            dimmed: false,
          ),
        ),
      ],
    );
  }
}

class _PlanChestTile extends StatelessWidget {
  final String asset;
  final String label;
  final bool dimmed;

  const _PlanChestTile({
    required this.asset,
    required this.label,
    required this.dimmed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Opacity(
          opacity: dimmed ? 0.55 : 1,
          child: Image.asset(asset, width: 64, height: 64),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: dimmed ? FontWeight.normal : FontWeight.bold,
            color: context.palette.textNavy.withValues(alpha: dimmed ? 0.55 : 1),
          ),
        ),
      ],
    );
  }
}

class _BenefitList extends StatelessWidget {
  final AppStrings strings;

  const _BenefitList({required this.strings});

  /// Icon asset paired with its label, in display order — one badge per
  /// benefit, replacing the plain green checkmark this list used to
  /// draw before the icon art existed.
  List<(String, String)> get _benefits => [
        (PremiumIcons.skin, strings.benefitExclusiveCardSkins),
        (PremiumIcons.kanji, strings.benefitFullMaterials),
        (PremiumIcons.kaiwa, strings.benefitPremiumPractice),
        (PremiumIcons.noAds, strings.benefitNoAds),
      ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _benefits
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Image.asset(entry.$1, width: 32, height: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(entry.$2, style: TextStyle(color: context.palette.textNavy)),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/localization/app_strings.dart';
import '../../core/providers.dart';
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
  static const _premiumSku = 'premium_monthly';

  bool _watchingAd = false;

  Future<void> _upgradePremium() async {
    final available = await InAppPurchase.instance.isAvailable();
    if (!mounted) return;
    final s = ref.read(appStringsProvider);

    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.storeUnavailable)),
      );
      return;
    }

    // SKU "premium_monthly" is a placeholder — it isn't registered in Play
    // Console yet, so we can't actually query/purchase it. Wire this up for
    // real once the product exists there.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.purchaseComingSoon(_premiumSku))),
    );
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
              const MascotWidget(mood: MascotMood.proud, size: 150),
              const SizedBox(height: 20),
              Text(
                s.unlockAllModulesTitle,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: context.palette.textNavy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s.unlockAllModulesSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.palette.textNavy),
              ),
              const SizedBox(height: 24),
              _BenefitList(strings: s),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _upgradePremium,
                  child: Text(s.upgradePremiumButton),
                ),
              ),
              const SizedBox(height: 16),
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
        strings.benefitAllModules,
        strings.benefitNoAds,
        strings.benefitCloudProgress,
        strings.benefitExclusiveLeaderboard,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/mascot_widget.dart';

/// Shown when a free user taps a premium-gated module. Offers the (not yet
/// wired to a real Play Console SKU) monthly upgrade, or a rewarded ad for
/// a 24h preview of [moduleId].
class PaywallScreen extends ConsumerStatefulWidget {
  final String moduleId;
  final String moduleTitle;

  const PaywallScreen({
    super.key,
    required this.moduleId,
    required this.moduleTitle,
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

    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toko aplikasi tidak tersedia di perangkat ini.'),
        ),
      );
      return;
    }

    // SKU "premium_monthly" is a placeholder — it isn't registered in Play
    // Console yet, so we can't actually query/purchase it. Wire this up for
    // real once the product exists there.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Pembelian Premium akan segera tersedia setelah paket '
          '"$_premiumSku" terdaftar di Play Console.',
        ),
      ),
    );
  }

  Future<void> _watchAdForPreview() async {
    setState(() => _watchingAd = true);
    ref.read(adServiceProvider).loadAndShowRewarded(
      onRewardEarned: () async {
        final uid = ref.read(appStartupProvider).valueOrNull?.uid;
        if (uid != null) {
          await ref
              .read(progressRepositoryProvider)
              .unlockAdReward(uid, widget.moduleId);
        }
        if (!mounted) return;
        setState(() => _watchingAd = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.moduleTitle} terbuka untuk preview 24 jam!',
            ),
          ),
        );
        Navigator.of(context).pop();
      },
      onFailedToLoad: () {
        if (!mounted) return;
        setState(() => _watchingAd = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Iklan belum tersedia, coba lagi sebentar lagi.'),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Premium')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const MascotWidget(mood: MascotMood.proud, size: 150),
              const SizedBox(height: 20),
              const Text(
                'Buka Semua Modul!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textNavy,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Akses penuh Kanji, Partikel, Bunpou, dan lebih banyak lagi',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textNavy),
              ),
              const SizedBox(height: 24),
              const _BenefitList(),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _upgradePremium,
                  child: const Text('Upgrade Premium — Rp 29.000/bulan'),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Divider(color: AppColors.textNavy.withValues(alpha: 0.2)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'atau',
                      style: TextStyle(
                        color: AppColors.textNavy.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: AppColors.textNavy.withValues(alpha: 0.2)),
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
                      : const Text('Nonton Iklan untuk Preview 24 Jam'),
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
  const _BenefitList();

  static const _benefits = [
    'Akses semua modul belajar',
    'Tanpa iklan',
    'Progress tersimpan cloud',
    'Leaderboard eksklusif',
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
                  const Icon(Icons.check_circle, color: AppColors.successGreen, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(benefit, style: const TextStyle(color: AppColors.textNavy)),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../providers.dart';
import '../services/ad_service.dart';

/// Renders a standard banner ad, or nothing at all if it hasn't loaded yet
/// (no loading spinner, no layout jump on failure — just an empty box).
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    final ad = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _bannerAd = ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          // Was silently swallowed before — the one call site in this app
          // that logged nothing at all on failure, unlike the interstitial/
          // rewarded paths in AdService. Without this there is no way to
          // tell "no fill yet" (GADErrorCode 3 / kGADErrorNoFill, expected
          // and harmless for a brand-new AdMob app/unit still ramping up)
          // apart from a real config problem (wrong unit id, app not
          // linked, network error) from a device log alone.
          debugPrint('Banner ad failed to load: $error');
          ad.dispose();
        },
      ),
    );
    ad.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _bannerAd;
    if (ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}

/// Only shows [BannerAdWidget] for `free` tier users — premium users never
/// see ads.
class FreeTierBannerAd extends ConsumerWidget {
  const FreeTierBannerAd({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(subscriptionProvider).valueOrNull?.isPremium ?? false;
    if (isPremium) return const SizedBox.shrink();
    return const BannerAdWidget();
  }
}

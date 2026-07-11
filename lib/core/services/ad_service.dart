import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Wraps google_mobile_ads: preloads/shows interstitial + rewarded ads and
/// hands out banner ad instances. Callers must check `subscription.tier`
/// themselves before loading/showing anything — this service doesn't know
/// about premium status.
class AdService {
  // Test IDs — ganti dengan production IDs sebelum release ke Play Store.
  // Production IDs didapat dari AdMob Console setelah app disetujui.
  static const String bannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String interstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String rewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  static const _interstitialFrequency = 3;

  InterstitialAd? _interstitialAd;
  bool _interstitialLoading = false;
  int _examsSinceLastInterstitial = 0;

  Future<void> initialize() => MobileAds.instance.initialize();

  /// Starts loading an interstitial in the background so it's ready by the
  /// time [maybeShowInterstitialAfterExam] wants to show it. Safe to call
  /// repeatedly — no-ops if one is already loading/loaded. Failures are not
  /// retried; the next call site just proceeds without an ad.
  void preloadInterstitial() {
    if (_interstitialLoading || _interstitialAd != null) return;
    _interstitialLoading = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialLoading = false;
        },
        onAdFailedToLoad: (error) {
          _interstitialLoading = false;
          debugPrint('Interstitial failed to load: $error');
        },
      ),
    );
  }

  /// Bumps the exam-completion counter and shows a preloaded interstitial
  /// every 3rd completion. No-op if nothing is loaded yet.
  void maybeShowInterstitialAfterExam() {
    _examsSinceLastInterstitial++;
    if (_examsSinceLastInterstitial < _interstitialFrequency) return;
    final ad = _interstitialAd;
    if (ad == null) return;

    _examsSinceLastInterstitial = 0;
    _interstitialAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) => ad.dispose(),
      onAdFailedToShowFullScreenContent: (ad, error) => ad.dispose(),
    );
    ad.show();
  }

  /// Loads and immediately shows a rewarded ad. Calls [onRewardEarned] only
  /// if the user watched it through; calls [onFailedToLoad] if the ad
  /// couldn't be fetched (no retry).
  void loadAndShowRewarded({
    required VoidCallback onRewardEarned,
    VoidCallback? onFailedToLoad,
  }) {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) => ad.dispose(),
            onAdFailedToShowFullScreenContent: (ad, error) => ad.dispose(),
          );
          ad.show(
            onUserEarnedReward: (ad, reward) => onRewardEarned(),
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
          onFailedToLoad?.call();
        },
      ),
    );
  }
}

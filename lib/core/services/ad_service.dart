import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Wraps google_mobile_ads: preloads/shows interstitial + rewarded ads and
/// hands out banner ad instances. Callers must check `subscription.tier`
/// themselves before loading/showing anything — this service doesn't know
/// about premium status.
class AdService {
  // --- Ad unit IDs -------------------------------------------------
  //
  // AdMob issues a *separate* unit per format **per platform**: an Android
  // unit will not fill on iOS and vice versa, it simply returns no ad. So
  // these are chosen at runtime rather than being one shared constant —
  // getting that wrong shows up as "iOS earns nothing", with no error to
  // point at it.
  //
  // These are still Google's public **test** units. Swap each one for the
  // real unit from the AdMob console before release; the app id lives
  // separately, in AndroidManifest.xml and ios/Runner/Info.plist, and has
  // to be swapped there too.

  static const _testAndroidBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const _testAndroidInterstitial =
      'ca-app-pub-3940256099942544/1033173712';
  static const _testAndroidRewarded = 'ca-app-pub-3940256099942544/5224354917';

  static const _testIosBanner = 'ca-app-pub-3940256099942544/2934735716';
  static const _testIosInterstitial = 'ca-app-pub-3940256099942544/4411468910';
  static const _testIosRewarded = 'ca-app-pub-3940256099942544/1712485313';

  /// Android first because that is the platform this app actually ships on
  /// today; iOS has never been built (see CLAUDE.md).
  static String _perPlatform({required String android, required String ios}) {
    return Platform.isIOS ? ios : android;
  }

  static String get bannerAdUnitId => _perPlatform(
        android: _testAndroidBanner,
        ios: _testIosBanner,
      );
  static String get interstitialAdUnitId => _perPlatform(
        android: _testAndroidInterstitial,
        ios: _testIosInterstitial,
      );
  static String get rewardedAdUnitId => _perPlatform(
        android: _testAndroidRewarded,
        ios: _testIosRewarded,
      );

  /// Whether the app is still serving Google's test inventory.
  ///
  /// Exposed so a release checklist can assert on it rather than someone
  /// having to remember to re-read this file — test ads shipped to
  /// production earn nothing and look broken to a real user.
  static bool get usingTestAdUnits =>
      bannerAdUnitId.startsWith('ca-app-pub-3940256099942544/');

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
  /// couldn't be fetched (no retry); calls [onDismissedWithoutReward] if the
  /// ad loaded and showed but the user closed it before earning the reward
  /// — without this, a caller waiting on [onRewardEarned] alone would hang
  /// forever on that exact path, since neither callback used to fire.
  void loadAndShowRewarded({
    required VoidCallback onRewardEarned,
    VoidCallback? onFailedToLoad,
    VoidCallback? onDismissedWithoutReward,
  }) {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          var earned = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!earned) onDismissedWithoutReward?.call();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              onDismissedWithoutReward?.call();
            },
          );
          ad.show(
            onUserEarnedReward: (ad, reward) {
              earned = true;
              onRewardEarned();
            },
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

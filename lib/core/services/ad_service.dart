import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../data/models/ad_audience.dart';

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

  // Real units, created 2026-08-05 under app id
  // ca-app-pub-7168330620893919~3107201564 ("Teisou Kana Master", Android).
  static const _liveAndroidBanner = 'ca-app-pub-7168330620893919/9469429932';
  static const _liveAndroidInterstitial =
      'ca-app-pub-7168330620893919/1043044924';
  static const _liveAndroidRewarded = 'ca-app-pub-7168330620893919/3809909145';

  // Real units, created 2026-08-05 under app id
  // ca-app-pub-7168330620893919~8289431398 ("Teisou Kana Master", iOS).
  // Different ids from Android's above: AdMob treats each platform as its
  // own app, and a unit from the wrong one silently never fills.
  static const _liveIosBanner = 'ca-app-pub-7168330620893919/1590939911';
  static const _liveIosInterstitial = 'ca-app-pub-7168330620893919/5119121389';
  static const _liveIosRewarded = 'ca-app-pub-7168330620893919/3939122841';

  /// The ids a release build would use, regardless of which build this is.
  ///
  /// Exposed so tests can check the real ids without having to run in
  /// release mode, which they never do.
  @visibleForTesting
  static const releaseAdUnitIds = <String, String>{
    'android/banner': _liveAndroidBanner,
    'android/interstitial': _liveAndroidInterstitial,
    'android/rewarded': _liveAndroidRewarded,
    'ios/banner': _liveIosBanner,
    'ios/interstitial': _liveIosInterstitial,
    'ios/rewarded': _liveIosRewarded,
  };

  /// Android first because that is the platform this app actually ships on
  /// today; iOS has never been built (see CLAUDE.md).
  static String _perPlatform({required String android, required String ios}) {
    return Platform.isIOS ? ios : android;
  }

  /// Real inventory in release builds, Google's test inventory everywhere
  /// else.
  ///
  /// This is not a convenience. Requesting a real ad unit during
  /// development is invalid traffic as far as Google is concerned, and
  /// repeated invalid traffic gets the AdMob account suspended — so the
  /// choice must not depend on anyone remembering to swap a constant back
  /// before running from the IDE. `kReleaseMode` makes it structural.
  static String _live({required String test, required String live}) {
    return kReleaseMode ? live : test;
  }

  static String get bannerAdUnitId => _perPlatform(
        android: _live(test: _testAndroidBanner, live: _liveAndroidBanner),
        ios: _live(test: _testIosBanner, live: _liveIosBanner),
      );
  static String get interstitialAdUnitId => _perPlatform(
        android: _live(
          test: _testAndroidInterstitial,
          live: _liveAndroidInterstitial,
        ),
        ios: _live(test: _testIosInterstitial, live: _liveIosInterstitial),
      );
  static String get rewardedAdUnitId => _perPlatform(
        android: _live(test: _testAndroidRewarded, live: _liveAndroidRewarded),
        ios: _live(test: _testIosRewarded, live: _liveIosRewarded),
      );

  /// Whether *this* build is serving Google's test inventory. True in
  /// debug and profile by design; in a release build it means real units
  /// are still missing for this platform.
  static bool get usingTestAdUnits =>
      bannerAdUnitId.startsWith('ca-app-pub-3940256099942544/');

  static const _interstitialFrequency = 3;

  InterstitialAd? _interstitialAd;
  bool _interstitialLoading = false;
  int _examsSinceLastInterstitial = 0;

  Future<void> initialize() => MobileAds.instance.initialize();

  /// Tells AdMob how this learner may be served, before any ad is
  /// requested.
  ///
  /// The app is mixed-audience — children and adults share one build — so
  /// this is per-user rather than a build-time constant. [AdAudience]
  /// answers restrictively while the age is still unknown, which is the
  /// state every fresh install starts in and the state an ad can very
  /// plausibly be requested in.
  ///
  /// Best-effort: failing to narrow the configuration must not stop the app
  /// from working. It does mean ads would be served unrestricted, so the
  /// failure is logged rather than swallowed silently — if this ever starts
  /// failing in the field it needs to be seen.
  Future<void> applyAudience(AdAudience audience, {DateTime? now}) async {
    final at = now ?? DateTime.now();
    final isChild = audience.isChildDirectedAt(at);
    final isUnderConsentAge = audience.isUnderAgeOfConsentAt(at);

    try {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          tagForChildDirectedTreatment: isChild
              ? TagForChildDirectedTreatment.yes
              : TagForChildDirectedTreatment.no,
          tagForUnderAgeOfConsent: isUnderConsentAge
              ? TagForUnderAgeOfConsent.yes
              : TagForUnderAgeOfConsent.no,
          // Capped for anyone under the age of consent, not only for
          // under-13s: a 14-year-old is not child-directed under COPPA but
          // still should not be shown mature inventory in a school app.
          maxAdContentRating: isUnderConsentAge
              ? MaxAdContentRating.g
              : MaxAdContentRating.pg,
        ),
      );
    } catch (error) {
      debugPrint('AdService.applyAudience failed: $error');
    }
  }

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

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `adRewards` is access-control state (see AUDIT_PHASE_B1/B2/B3/B4 in
/// the repo root) — the client must never treat a rewarded ad's local
/// `onUserEarnedReward` callback as proof of entitlement, only AdMob's
/// own signed server-side-verification (SSV) callback, landed via
/// `functions/ad_rewards.js`, may ever grant it.
///
/// This is a source check rather than a widget test on purpose, the
/// same reasoning `coach_wiring_test.dart` already uses in this
/// project: driving a real `RewardedAd` through a widget test would
/// need mocking the whole `google_mobile_ads` plugin, and the failure
/// mode this guards against isn't a screen crashing loudly — it's a
/// future edit quietly reintroducing a client-side grant write, which
/// would compile and run fine while silently reopening the exact
/// permission-denied-swallowed-by-catch bug this rollout fixed.
void main() {
  group('ad_service.dart', () {
    late String source;
    setUpAll(
      () => source =
          File('lib/core/services/ad_service.dart').readAsStringSync(),
    );

    test('attaches SSV options before showing the ad', () {
      // Scoped to loadAndShowRewarded specifically — ad_service.dart also
      // has an unrelated `ad.show();` inside the interstitial-ad flow
      // (maybeShowInterstitialAfterExam), which a file-wide indexOf would
      // otherwise match first.
      final methodStart = source.indexOf('void loadAndShowRewarded(');
      expect(methodStart, greaterThan(-1));
      final methodBody = source.substring(methodStart);

      final setOptionsIndex = methodBody.indexOf('setServerSideOptions');
      final showIndex = methodBody.indexOf('ad.show(');
      expect(setOptionsIndex, greaterThan(-1),
          reason: 'setServerSideOptions must be called at all');
      expect(showIndex, greaterThan(-1));
      expect(setOptionsIndex, lessThan(showIndex),
          reason: 'SSV options must be attached before the ad is shown, '
              'not after');
    });

    test('sends userId and customData, not a third invented field', () {
      expect(source, contains('userId: uid'));
      expect(source, contains('customData:'));
      expect(source, contains('rewardKey'));
    });

    test('loadAndShowRewarded accepts an optional uid and rewardKey', () {
      // Optional, not required — EditNameDialog's unrelated rewarded-ad
      // flow calls this without either, and must keep compiling.
      expect(source, contains('String? uid'));
      expect(source, contains('String? rewardKey'));
    });
  });

  group('progress_repository.dart', () {
    late String source;
    setUpAll(
      () => source =
          File('lib/data/repositories/progress_repository.dart')
              .readAsStringSync(),
    );

    test('no longer has a client-side adRewards grant method', () {
      expect(source, isNot(contains('Future<void> unlockAdReward')),
          reason: 'the grant is now server-only, via '
              'functions/ad_rewards.js\'s SSV callback — a client write '
              'here would be rejected by firestore.rules anyway, but its '
              'reappearance would mean someone tried to route around the '
              'server-authoritative design');
    });

    test('consumeAdReward calls the Cloud Function, not a direct write', () {
      expect(source, contains("_functions.httpsCallable('consumeAdReward')"));
      expect(
        source,
        isNot(contains("update({'adRewards.\$moduleId'")),
        reason: 'consume must also be server-authoritative — a direct '
            'client update here would be a Firestore Rules regression '
            'risk even if firestore.rules happens to still block it',
      );
    });
  });

  group('paywall_screen.dart', () {
    late String source;
    setUpAll(
      () => source = File('lib/features/paywall/paywall_screen.dart')
          .readAsStringSync(),
    );

    test('onRewardEarned only flips UI state, never shows success itself',
        () {
      final earnedStart = source.indexOf('onRewardEarned: () {');
      final earnedEnd = source.indexOf('onFailedToLoad:', earnedStart);
      expect(earnedStart, greaterThan(-1));
      expect(earnedEnd, greaterThan(earnedStart));
      final earnedBody = source.substring(earnedStart, earnedEnd);

      expect(
        earnedBody,
        isNot(contains('previewUnlockedFor')),
        reason: 'the local SDK callback must never itself claim the '
            'reward is granted',
      );
      expect(earnedBody, isNot(contains('previewUnlockedSingleUse')));
      expect(
        earnedBody,
        contains('_verifyingReward = true'),
        reason: 'it should switch the UI into a waiting/confirming '
            'state instead',
      );
    });

    test('success UI is shown only after reading adRewards back', () {
      final grantStart = source.indexOf('Future<void> _pollForGrant');
      expect(grantStart, greaterThan(-1));
      final grantBody = source.substring(grantStart);

      expect(grantBody, contains('getAdRewards'));
      expect(grantBody, contains('reward.isActive'));
      expect(grantBody, contains('previewUnlockedFor'));
      expect(
        grantBody.indexOf('getAdRewards'),
        lessThan(grantBody.indexOf('previewUnlockedFor')),
        reason: 'the success message must come after actually observing '
            'the grant, not before',
      );
    });

    test('never writes adRewards directly from the client', () {
      expect(source, isNot(contains('unlockAdReward')),
          reason: 'the removed client-side grant method must not be '
              'called from here either');
    });
  });
}

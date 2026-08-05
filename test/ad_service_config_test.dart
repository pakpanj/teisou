import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/services/ad_service.dart';

/// AdMob configuration, which fails in a peculiarly quiet way: a unit id
/// from the wrong platform does not error, it simply never fills. "iOS
/// earns nothing" is the only symptom, and it takes a payout report to
/// notice.
///
/// These tests run on the host, so `Platform.isIOS` is false and the
/// Android branch is what gets exercised. That still catches the mistakes
/// worth catching: a malformed id, and the two platforms silently sharing
/// one unit again.
void main() {
  const publisher = 'ca-app-pub-7168330620893919';
  const testPublisher = 'ca-app-pub-3940256099942544';

  test('every release ad unit id is well formed', () {
    // AdMob unit ids are `ca-app-pub-<16 digits>/<10 digits>`. The app id
    // uses a tilde instead of the slash and is a different thing entirely —
    // pasting one where the other belongs is an easy and silent mistake.
    final unitId = RegExp(r'^ca-app-pub-\d{16}/\d{10}$');

    AdService.releaseAdUnitIds.forEach((slot, id) {
      expect(unitId.hasMatch(id), isTrue,
          reason: '$slot: "$id" is not a valid ad unit id — an app id '
              '(with ~) or a truncated paste would look like this');
    });
  });

  test('no release unit is reused across formats or platforms', () {
    // Two slots sharing an id breaks reporting and can breach AdMob policy.
    // The iOS slots are currently the *test* ids, and those must still be
    // three distinct units, so this holds either way.
    final ids = AdService.releaseAdUnitIds.values.toSet();
    expect(ids.length, AdService.releaseAdUnitIds.length,
        reason: 'duplicate ad unit id across slots: '
            '${AdService.releaseAdUnitIds}');
  });

  test('Android release units belong to this publisher', () {
    for (final slot in ['banner', 'interstitial', 'rewarded']) {
      final id = AdService.releaseAdUnitIds['android/$slot']!;
      expect(id.startsWith('$publisher/'), isTrue,
          reason: 'android/$slot is "$id" — a unit from another AdMob '
              'account, or from the Cash Teisou app, would earn into the '
              'wrong place silently');
    }
  });

  test('iOS release units are still Google test inventory', () {
    // Stated rather than hidden: the iOS app exists in AdMob but has no
    // units yet, so an iOS release right now would serve demo ads and earn
    // nothing. When the real units land, update this test in the same
    // commit — its failure is the reminder.
    for (final slot in ['banner', 'interstitial', 'rewarded']) {
      final id = AdService.releaseAdUnitIds['ios/$slot']!;
      expect(id.startsWith('$testPublisher/'), isTrue,
          reason: 'if this fails, real iOS units have landed — good; move '
              'the assertion over to the publisher check above');
    }
  });

  test('development builds never request real inventory', () {
    // The whole point of the kReleaseMode switch: requesting a real unit
    // while developing is invalid traffic, and repeated invalid traffic
    // suspends the account. Tests run in debug, so this asserts the branch
    // a developer actually runs.
    expect(AdService.usingTestAdUnits, isTrue);
    for (final id in [
      AdService.bannerAdUnitId,
      AdService.interstitialAdUnitId,
      AdService.rewardedAdUnitId,
    ]) {
      expect(id.startsWith('$testPublisher/'), isTrue,
          reason: '"$id" is live inventory being requested from a debug '
              'build');
    }
  });

  test('every ad unit id is well formed', () {
    // AdMob unit ids are `ca-app-pub-<16 digits>/<10 digits>`. The app id
    // uses a tilde instead of the slash and is a different thing entirely —
    // pasting one where the other belongs is an easy and silent mistake.
    final unitId = RegExp(r'^ca-app-pub-\d{16}/\d{10}$');

    for (final id in [
      AdService.bannerAdUnitId,
      AdService.interstitialAdUnitId,
      AdService.rewardedAdUnitId,
    ]) {
      expect(unitId.hasMatch(id), isTrue,
          reason: '"$id" is not a valid ad unit id — an app id (with ~) or a '
              'truncated paste would look like this');
    }
  });

  test('the three formats do not share a unit', () {
    final ids = {
      AdService.bannerAdUnitId,
      AdService.interstitialAdUnitId,
      AdService.rewardedAdUnitId,
    };
    expect(ids.length, 3,
        reason: 'banner, interstitial and rewarded each need their own unit; '
            'reusing one across formats breaks reporting and can breach '
            'AdMob policy');
  });

  group('app ids', () {
    // The account behind this publisher id also holds an unrelated app
    // called Cash Teisou, and AdMob lists all four rows (two apps x two
    // platforms) together. Pasting the wrong row is the easy mistake, and
    // it is invisible: ads simply attribute to the other app.
    const androidAppId = '$publisher~3107201564';
    const iosAppId = '$publisher~8289431398';

    String manifest() =>
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    String infoPlist() => File('ios/Runner/Info.plist').readAsStringSync();

    test('Android carries its own real app id', () {
      expect(manifest(), contains(androidAppId));
      expect(manifest().contains(iosAppId), isFalse,
          reason: 'that is the iOS app id — the two are different apps');
    });

    test('iOS carries its own real app id', () {
      expect(infoPlist(), contains(iosAppId));
      expect(infoPlist().contains(androidAppId), isFalse,
          reason: 'that is the Android app id — the two are different apps');
    });

    test('neither platform still ships the test app id', () {
      // Google's sample publisher. Leaving it in place means real ad units
      // would be requested under an app id that is not yours.
      expect(manifest().contains('$testPublisher~'), isFalse);
      expect(infoPlist().contains('$testPublisher~'), isFalse);
    });

  });

  test('test inventory is still flagged as such', () {
    // Not an assertion that test ids are correct to ship — the opposite.
    // This is the hook a release check can hang on, so shipping Google's
    // demo ads to real users fails loudly instead of quietly earning zero.
    expect(AdService.usingTestAdUnits, isTrue,
        reason: 'if this now fails, real ad units have landed — good, but '
            'update this test and the release checklist in CLAUDE.md '
            'together so the flag keeps meaning something');
  });
}

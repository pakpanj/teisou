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
    const publisher = 'ca-app-pub-7168330620893919';
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
      const testPublisher = 'ca-app-pub-3940256099942544';
      expect(manifest().contains('$testPublisher~'), isFalse);
      expect(infoPlist().contains('$testPublisher~'), isFalse);
    });

    test('once real, ad units must belong to the same publisher', () {
      // Inert while the test units are in place, and self-arming the day
      // they are replaced: a unit id from another AdMob account, or from
      // Cash Teisou's app, would earn into the wrong place silently.
      if (AdService.usingTestAdUnits) return;
      for (final id in [
        AdService.bannerAdUnitId,
        AdService.interstitialAdUnitId,
        AdService.rewardedAdUnitId,
      ]) {
        expect(id.startsWith('$publisher/'), isTrue,
            reason: '"$id" does not belong to this publisher');
      }
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

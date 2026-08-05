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

  test('every release unit belongs to this publisher, on both platforms',
      () {
    // Both platforms went live 2026-08-05. A unit belonging to another
    // AdMob account — or to the Cash Teisou app that shares this one —
    // would still serve ads, just into the wrong place, so nothing about
    // the running app would look wrong.
    AdService.releaseAdUnitIds.forEach((slot, id) {
      expect(id.startsWith('$publisher/'), isTrue,
          reason: '$slot is "$id", which is not this publisher — a leftover '
              'test id looks like this too');
    });
  });

  test('the two platforms share no unit', () {
    // The failure this guards against is silent: AdMob returns no ad for a
    // wrong-platform unit rather than an error, so the only symptom is one
    // platform quietly earning nothing.
    Set<String> unitsFor(String platform) => {
          for (final e in AdService.releaseAdUnitIds.entries)
            if (e.key.startsWith('$platform/')) e.value,
        };

    final android = unitsFor('android');
    final ios = unitsFor('ios');
    expect(android.length, 3);
    expect(ios.length, 3);
    expect(android.intersection(ios), isEmpty);
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

  // The same three checks against the ids this build actually resolves are
  // deliberately absent: in a test run those are Google's own test units,
  // so asserting they are well formed and distinct tests Google's
  // constants rather than this app's configuration. What matters here is
  // the release set above, plus the debug/release switch just checked.

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

  // `usingTestAdUnits` used to be asserted here as a "have the real ids
  // landed yet" flag. Both platforms are live now and the ids no longer
  // depend on anyone swapping a constant, so that meaning is gone — what
  // the flag reports today is simply which build this is, which
  // 'development builds never request real inventory' above already covers
  // from the angle that matters.
}

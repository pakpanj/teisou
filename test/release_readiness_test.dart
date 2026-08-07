import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Things that only go wrong at the store, long after the code is right.
///
/// Every check here corresponds to something found by reading the project
/// before its first upload, and every one of them was invisible to
/// `flutter analyze`, to the test suite, and to a debug build on a
/// device. That is the pattern worth guarding: a release blocker does not
/// look like a bug, it looks like a default nobody changed.
void main() {
  String read(String path) => File(path).readAsStringSync();

  group('Android', () {
    test('the release build is not wired to the debug key', () {
      // What `flutter create` leaves behind, and what shipped here for
      // months. Play Console answers it with "You uploaded an APK or
      // Android App Bundle that was signed in debug mode" — after the
      // upload, after the build, with nothing local to hint at it.
      final gradle = read('android/app/build.gradle.kts');

      expect(gradle, contains('key.properties'),
          reason: 'the release signing config must come from a keystore');
      expect(
        gradle,
        contains(RegExp(r'signingConfigs\.getByName\("release"\)')),
        reason: 'no release signing config is referenced at all',
      );
    });

    test('the app is not named after its Dart package', () {
      // "kana_master", underscore and all, was what a learner saw under
      // the icon on their home screen.
      final manifest = read('android/app/src/main/AndroidManifest.xml');
      expect(manifest, isNot(contains('android:label="kana_master"')));
    });

    test('permissions the app never uses are removed', () {
      // None of these are declared by the app — they arrive through
      // manifest merging from the camera and ads plugins, and all of them
      // reached the shipped manifest. For an app aimed at children that
      // matters twice over: a kana app asking to record audio invites a
      // reviewer's question, and Play's Families policy forbids the
      // advertising ID outright.
      final manifest = read('android/app/src/main/AndroidManifest.xml');
      const mustBeRemoved = [
        'android.permission.RECORD_AUDIO',
        'com.google.android.gms.permission.AD_ID',
        'android.permission.ACCESS_ADSERVICES_AD_ID',
      ];

      for (final permission in mustBeRemoved) {
        expect(
          manifest,
          contains(RegExp('$permission"\\s+tools:node="remove"')),
          reason: '$permission would ship',
        );
      }
    });

    test('the launcher icon is not the Flutter logo', () {
      // The default from `flutter create`. Play accepts it; Apple has
      // rejected apps over placeholder art; and it is the first thing
      // anyone sees either way.
      //
      // Checked by size rather than by pixels: the stock icon is a few
      // hundred bytes of flat blue, and anything actually drawn is far
      // larger. A hash would have to be updated every time the art is
      // regenerated, which is the sort of check people delete.
      final icon =
          File('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png');
      expect(icon.existsSync(), isTrue);
      expect(icon.lengthSync(), greaterThan(5000),
          reason: 'this looks like the stock Flutter logo');
    });

    test('adaptive icon layers exist for Android 8 and up', () {
      // Without them a modern launcher draws a white plate around the
      // square icon, which reads as a bug rather than a choice.
      expect(
        File('android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml')
            .existsSync(),
        isTrue,
      );
      for (final density in ['hdpi', 'xxxhdpi']) {
        expect(
          File('android/app/src/main/res/mipmap-$density/'
                  'ic_launcher_foreground.png')
              .existsSync(),
          isTrue,
          reason: '$density is missing its adaptive foreground',
        );
      }
    });
  });

  group('iOS', () {
    test('a privacy manifest exists', () {
      // Required by Apple since May 2024 for any app touching a
      // "required reason API". shared_preferences uses UserDefaults,
      // which is one, so this app needs it and the upload is refused
      // without it.
      expect(File('ios/Runner/PrivacyInfo.xcprivacy').existsSync(), isTrue);
    });

    test('and is actually inside the bundle', () {
      // The quiet half. A manifest sitting in the folder but missing
      // from Copy Bundle Resources is not in the .ipa, and the rejection
      // is identical to never having written it.
      //
      // Looked for *inside* the resources phase, not anywhere in the
      // file. The first version searched the whole project for the
      // string "PrivacyInfo.xcprivacy in Resources" — which also appears
      // in the PBXBuildFile declaration, so deleting the file from the
      // phase left the test perfectly happy. Confirmed by doing exactly
      // that and watching it pass.
      final project = read('ios/Runner.xcodeproj/project.pbxproj');
      final phases = RegExp(
        r'isa = PBXResourcesBuildPhase;.*?runOnlyForDeploymentPostprocessing',
        dotAll: true,
      ).allMatches(project).map((m) => m.group(0)!);

      expect(
        phases.any((phase) => phase.contains('PrivacyInfo.xcprivacy')),
        isTrue,
        reason: 'the manifest is declared but never copied into the app',
      );
    });

    test('export compliance is answered in advance', () {
      // Not a rejection — just the same question by hand on every single
      // upload, holding the build until somebody answers it.
      expect(read('ios/Runner/Info.plist'),
          contains('ITSAppUsesNonExemptEncryption'));
    });

    test('the deployment target is high enough for the plugins in use', () {
      // CocoaPods refuses to resolve at all when a plugin needs a newer
      // iOS than the app targets, and its message names the plugin
      // rather than the setting: "google_mlkit_commons requires a higher
      // minimum iOS deployment version". The setting was 13.0 — the
      // Flutter template's default, never touched — while ML Kit has
      // wanted 15.5 for some time.
      //
      // Invisible locally in every way that matters. There is no Podfile
      // in this project (it builds through Swift Package Manager, and
      // CocoaPods only runs for the three plugins that have not adopted
      // it), so nothing on a Windows machine ever resolves a pod. It
      // surfaced on Codemagic's macOS runner and nowhere else.
      final project = read('ios/Runner.xcodeproj/project.pbxproj');
      final targets = RegExp(r'IPHONEOS_DEPLOYMENT_TARGET = ([\d.]+);')
          .allMatches(project)
          .map((match) => double.parse(match.group(1)!))
          .toList();

      expect(targets, isNotEmpty);
      for (final target in targets) {
        expect(target, greaterThanOrEqualTo(15.5),
            reason: 'pod install fails outright below this');
      }
    });

    test('the app icon set is filled in', () {
      final icon = File('ios/Runner/Assets.xcassets/AppIcon.appiconset/'
          'Icon-App-1024x1024@1x.png');
      expect(icon.existsSync(), isTrue);
      expect(icon.lengthSync(), greaterThan(20000),
          reason: 'this looks like the stock Flutter logo');
    });
  });

  group('build recipe', () {
    test('codemagic.yaml exists and builds both stores', () {
      final recipe = read('codemagic.yaml');
      expect(recipe, contains('flutter build appbundle --release'));
      expect(recipe, contains('flutter build ipa --release'));
    });

    test('CI runs the test suite the way this project needs', () {
      // A plain `flutter test` silently drops kanjivg_parser_test from
      // the report on this project — no error, no loading line, four
      // fewer passes. CI quietly skipping tests is worse than slow CI.
      expect(read('codemagic.yaml'), contains('flutter test --concurrency=1'));
    });
  });
}

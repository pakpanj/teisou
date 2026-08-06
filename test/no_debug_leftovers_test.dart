import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Temporary debugging code must not reach a build.
///
/// This exists because of a real morning's worth of near-misses. Checking
/// a loading screen, a voice picker or a keyed asset on a device often
/// needs a line that forces one branch, prints a value, or writes a file —
/// and each of those is invisible in `flutter analyze`, invisible in the
/// test suite, and catastrophic if it ships. A forced branch in
/// `main.dart` is an app that never leaves its loading screen.
///
/// **This does not guard the mistake that actually happened**, and it is
/// worth being clear about that. The repository was clean; the *device*
/// still had the previous build on it, because the temporary line was
/// deleted and the APK was never rebuilt. No source test can see that.
/// The rule that covers it is procedural: after removing temporary code,
/// rebuild and reinstall before reporting anything works. This file
/// covers the neighbouring case — code that was never removed at all.
void main() {
  /// Patterns that only ever appear in code written to be deleted.
  ///
  /// Deliberately narrow. A check that fires on ordinary code gets
  /// disabled the first time it cries wolf, and then guards nothing.
  const forbidden = <String, String>{
    'if (1 == 1)': 'a forced branch left in place',
    'if (true) return': 'a forced branch left in place',
    '// TEMP': 'a line marked temporary',
    'TEMP DEBUG': 'a block marked temporary',
    'synthesizeToFile': 'a debugging routine that writes audio to disk',
  };

  test('no temporary debugging code is left in lib/', () {
    final offences = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        for (final entry in forbidden.entries) {
          if (lines[i].contains(entry.key)) {
            offences.add('${entity.path}:${i + 1} — ${entry.value}');
          }
        }
      }
    }

    expect(offences, isEmpty,
        reason: 'these would ship:\n${offences.join('\n')}');
  });

  test('nothing in lib/ prints to the console', () {
    // `print` in shipped code is either a leftover probe or noise in a
    // user's logcat. Real logging goes through debugPrint, which the
    // framework can silence.
    final offences = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trimLeft();
        if (line.startsWith('print(') || line.contains(' print(')) {
          offences.add('${entity.path}:${i + 1}');
        }
      }
    }

    expect(offences, isEmpty,
        reason: 'use debugPrint, or remove:\n${offences.join('\n')}');
  });
}

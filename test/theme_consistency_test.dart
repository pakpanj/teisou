import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Dark mode breaks quietly. A hardcoded light grey looks perfectly fine
/// while you are developing in light mode, and only turns into an unusable
/// screen for whoever switched the theme — so nothing in normal use
/// surfaces it.
///
/// This is not a style rule. Every colour found by the sweep below had a
/// real consequence in dark mode: `Colors.grey.shade300` (#E0E0E0) behind a
/// `textNavy` icon that is #E8EAF0 in dark made the prev/next buttons on
/// five screens invisible, and `Colors.grey.shade100` (#F5F5F5) turned a
/// locked card into a glaring white block on a #121620 background.
void main() {
  /// Colours that carry no theme meaning and stay correct in both modes:
  /// white and black used deliberately on top of a coloured surface, and
  /// transparent.
  const allowed = {'Colors.white', 'Colors.black', 'Colors.transparent'};

  final hardcoded = RegExp(r'Colors\.[a-zA-Z]+');

  List<String> dartFilesUnder(String dir) {
    return Directory(dir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .map((f) => f.path.replaceAll(r'\', '/'))
        .toList();
  }

  test('no screen hardcodes a colour instead of using the palette', () {
    final offenders = <String>[];

    for (final path in dartFilesUnder('lib')) {
      // The palette itself is where literal colours are supposed to live.
      if (path.contains('/core/theme/')) continue;

      final lines = File(path).readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) continue;
        for (final match in hardcoded.allMatches(line)) {
          final token = match.group(0)!;
          // Colors.white70 and friends are still white.
          final base = RegExp(r'^(Colors\.[a-zA-Z]+?)\d*$').firstMatch(token);
          final normalised = base?.group(1) ?? token;
          if (allowed.contains(normalised)) continue;
          offenders.add('${path.replaceFirst('lib/', '')}:${i + 1}  $token');
        }
      }
    }

    expect(offenders, isEmpty,
        reason: 'these will not adapt to dark mode — use the matching '
            'context.palette token instead (mutedSurface for a disabled '
            'card, progressTrack for a track or neutral border, errorRed '
            'for an error):\n${offenders.join('\n')}');
  });
}

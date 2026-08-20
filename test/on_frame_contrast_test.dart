import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter/material.dart';

import 'package:kana_master/core/theme/app_palette.dart';
import 'package:kana_master/core/theme/app_theme.dart';
import 'package:kana_master/core/widgets/module_card_frame.dart';

/// Colour taken from the app's theme, painted onto a surface the theme does
/// not control.
///
/// `theme_consistency_test` sweeps for hardcoded colour literals and this
/// is invisible to it: every colour involved is a proper palette token. The
/// mistake is which palette. `frame_card_frame.png` and
/// `frame_title_plaque.png` are pale sakura pictures in both themes, so
/// `palette.textNavy` — near-white in dark — writes white on pink. Reported
/// from a screenshot of the Kanji level list, where the open level's title,
/// subtitle and badge had all but disappeared; every module home and the
/// whole Bab curriculum did the same.
void main() {
  Iterable<File> dartFiles(String dir) => Directory(dir)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  testWidgets('the frame palette follows the art, not the app', (tester) async {
    // The pairing that matters: while the art is pale in both themes, both
    // themes must colour their content from the light palette. Turning one
    // half theme-aware without the other reproduces the bug either way
    // round — near-white on pale pink, or dark ink on dark art.
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      late AppPalette seen;
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Builder(builder: (context) {
          seen = framePaletteOf(context);
          return const SizedBox.shrink();
        }),
      ));
      expect(
        seen.textNavy,
        kDarkFrameArt ? isNotNull : AppPalette.light.textNavy,
        reason: 'content on a pale frame stopped using the light palette',
      );
    }
  });

  test('the asset and the palette are switched by the same flag', () {
    // Two files, one decision. If these ever read different constants,
    // dropping in dark art would move one and not the other.
    final frame =
        File('lib/core/widgets/module_card_frame.dart').readAsStringSync();
    expect(frame.contains('kDarkFrameArt'), isTrue);
    // Both the asset chooser and the palette live behind it.
    expect(
      'kDarkFrameArt'.allMatches(frame).length,
      greaterThanOrEqualTo(3),
      reason: 'the flag no longer gates both the art and its palette',
    );
  });

  test('content drawn on a frame is coloured from the frame', () {
    final offenders = <String>[];
    final newline = String.fromCharCode(10);

    for (final file in dartFiles('lib')) {
      final source = file.readAsStringSync();
      // Only files that build the frame's *child* themselves. A screen
      // that merely passes a title to `ModuleTitlePlaque`, or a level to
      // `ModuleLevelCard`, hands over no colours at all and is none of
      // this test's business — flagging those was the first version of
      // this check and it named seven innocent files.
      if (!source.contains('ModuleCardFrame(')) continue;
      if (file.path.endsWith('module_card_frame.dart')) continue;

      // Comments stripped first. Searching the raw file for the name
      // passed on the mention inside this rule's own explanation, so
      // deleting the real use changed nothing — the second test in this
      // project fooled by a comment. Requiring `onFramePalette.` instead
      // was no better: binding it to a local and reading `surface.textNavy`
      // off that is the correct shape and contains no such dot. So: strip
      // the commentary, then look for the identifier in what is left.
      final code = source
          .split(newline)
          .where((line) => !line.trimLeft().startsWith('//'))
          .join(newline);
      if (!code.contains('framePaletteOf')) {
        offenders.add(file.path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'these draw inside a pale frame using the app theme, so their '
          'text turns white on pink in dark mode: ${offenders.join(", ")}',
    );
  });
}

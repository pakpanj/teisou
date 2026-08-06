import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/widgets/mascot_widget.dart';

/// Every mascot mood has to earn its drawing.
///
/// The cost of a mood is not a line of Dart, it is a piece of artwork
/// somebody sits down and makes. A mood the app never selects is that work
/// thrown away, and nothing else in the codebase would ever point it out —
/// the enum compiles, the switches are exhaustive, the app runs.
///
/// So this walks the source for the moods actually chosen anywhere and
/// fails on any that only exist in the enum.
void main() {
  /// Everything under lib/, minus the widget that defines the moods and
  /// necessarily names all of them.
  late final String appSource = (() {
    final buffer = StringBuffer();
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('mascot_widget.dart')) continue;
      buffer.write(entity.readAsStringSync());
    }
    return buffer.toString();
  })();

  test('every mood is selected somewhere in the app', () {
    final unused = MascotMood.values
        .where((mood) => !appSource.contains('MascotMood.${mood.name}'))
        .map((mood) => mood.name)
        .toList();

    expect(unused, isEmpty,
        reason: 'these moods are declared but never chosen, so their art '
            'would be drawn for nothing — either use them or drop them');
  });

  test('the prompt sheet covers every mood', () {
    // The sheet is what the art gets made from. A mood missing from it
    // simply never gets drawn, and the app quietly falls back to an emoji
    // in a place that was meant to have a character in it.
    final sheet = File('scripts/mascot_prompts.md').readAsStringSync();
    final missing = MascotMood.values
        .where((mood) => !sheet.contains('`${mood.name}`'))
        .map((mood) => mood.name)
        .toList();

    expect(missing, isEmpty,
        reason: 'no generation prompt exists for these moods');
  });

  test('a mood with no art falls back rather than failing', () {
    // The reason moods can be added before their PNGs exist. If this ever
    // stops being true, adding a mood becomes a broken screen instead of a
    // temporary emoji.
    final widget = File('lib/core/widgets/mascot_widget.dart').readAsStringSync();
    expect(widget, contains('errorBuilder'),
        reason: 'MascotWidget must survive a missing asset');
  });
}

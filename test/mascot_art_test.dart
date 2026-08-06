import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/widgets/mascot_widget.dart';

/// The mascot artwork on disk.
///
/// Both failures this guards actually happened while the set was being
/// drawn, and neither one breaks anything loudly:
///
/// A missing file falls back to that mood's emoji. The app keeps running,
/// the screen keeps rendering, and a 👋 sits where a character should be
/// until somebody happens to open that exact screen and notice.
///
/// A duplicated file is worse, because there is nothing to notice at all.
/// `encouraging.png` shipped as a byte-for-byte copy of `sad.png` — so the
/// face meant to reassure a child who got an answer wrong was the sad
/// face, which is the one thing that mood exists to avoid. Every screen
/// looked fine.
void main() {
  const dir = 'assets/mascot';

  test('every mood has its own artwork file', () {
    final missing = MascotMood.values
        .where((mood) => !File('$dir/${mood.name}.png').existsSync())
        .map((mood) => mood.name)
        .toList();

    expect(missing, isEmpty,
        reason: 'these moods fall back to an emoji, silently — run '
            'scripts/prepare_mascot.py for them');
  });

  test('no two moods share the same drawing', () {
    // Byte comparison rather than anything clever: a file copied to
    // stand in for a missing one is exactly what happened, and it is
    // identical, not merely similar.
    final byContent = <String, List<String>>{};
    for (final mood in MascotMood.values) {
      final file = File('$dir/${mood.name}.png');
      if (!file.existsSync()) continue;
      final digest = base64.encode(file.readAsBytesSync());
      byContent.putIfAbsent(digest, () => []).add(mood.name);
    }

    final shared = byContent.values.where((names) => names.length > 1).toList();
    expect(shared, isEmpty,
        reason: 'these moods are the same image, so they cannot express '
            'different things: $shared');
  });

  test('no file is small enough to be an empty canvas', () {
    // prepare_mascot.py warns when the keyed result is nearly empty —
    // which means the background colour was read wrong — but a warning
    // scrolls past. A near-empty PNG is tiny; a real one is ~150KB.
    for (final mood in MascotMood.values) {
      final file = File('$dir/${mood.name}.png');
      if (!file.existsSync()) continue;
      expect(file.lengthSync(), greaterThan(20000),
          reason: '${mood.name}.png looks empty — wrong --bg when keying?');
    }
  });

  test('nothing is in the folder that no mood claims', () {
    // A leftover from a renamed mood is dead weight in the APK, and
    // looks like working art to anyone browsing the folder.
    final known = MascotMood.values.map((m) => '${m.name}.png').toSet();
    final orphans = Directory(dir)
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((name) => name.endsWith('.png') && !known.contains(name))
        .toList();

    expect(orphans, isEmpty, reason: 'no mood uses these files');
  });
}

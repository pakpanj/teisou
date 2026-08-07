import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/data/repositories/kaiwa_repository.dart';

/// Parsing the big datasets must not stop the app.
///
/// The whole point of the startup loading screen is that something moves
/// while the app gets ready. It cannot if `json.decode` runs on the main
/// isolate: 10MB of dialogue holds it outright, so the progress bar jumps
/// between frozen states and the mascot's animation stops dead.
///
/// **The obvious test for this cannot be written here, and two attempts
/// proved it the hard way.** Measuring whether the event loop kept
/// running needs a timer on a real clock, and under
/// `TestWidgetsFlutterBinding` timers are driven by the test binding
/// rather than by wall time — a parse that blocked the isolate for
/// hundreds of milliseconds measured a stall of **0ms**. The first
/// version counted timer ticks, which the `await rootBundle.loadString`
/// before the parse kept healthy on its own; the second measured the
/// longest gap between ticks, which the fake clock flattened. Both passed
/// with the defect deliberately put back.
///
/// So what is checked here is what can be: that the heavy repositories
/// hand their parsing to `compute`, and — the part that would otherwise
/// go unnoticed — that the data survives the trip across the isolate
/// boundary intact. Whether the isolate hop actually keeps the screen
/// moving was confirmed on a device instead, by watching the loading
/// screen animate through the 10MB read.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Repositories whose datasets are large enough to be worth an isolate.
  ///
  /// Measured decode times on a desktop, which a phone multiplies several
  /// times over: kaiwa 185ms, kanji 53ms, dokkai 15ms, bunpou 11ms. The
  /// rest are 4ms or less, where spawning an isolate costs more than the
  /// parse it saves — so they are deliberately left alone, and this list
  /// is not "every repository".
  const heavy = <String>[
    'lib/data/repositories/kaiwa_repository.dart',
    'lib/data/repositories/kanji_repository.dart',
    'lib/data/repositories/bunpou_repository.dart',
    'lib/data/repositories/dokkai_repository.dart',
  ];

  for (final path in heavy) {
    test('${path.split('/').last} parses off the main isolate', () {
      final source = File(path).readAsStringSync();

      expect(source, contains('compute('),
          reason: 'this dataset is big enough that parsing it inline '
              'freezes every animation on the loading screen');

      // compute can only take a top-level or static function; a closure
      // is not sendable and fails at runtime, not at compile time.
      expect(source, contains(RegExp(r'^List<\w+> parse\w+\(', multiLine: true)),
          reason: 'the parse function must be top-level for compute');

      // The string still has to be read on the main isolate — rootBundle
      // goes through a platform channel — so finding the read inside the
      // isolate function would mean it cannot work at all.
      expect(source, contains('await rootBundle.loadString'));
    });
  }

  test('and still returns the whole dataset intact', () async {
    // An isolate hop copies everything across. Objects that do not
    // survive the copy come back wrong rather than throwing, so the
    // content is worth checking rather than just the count.
    final repository = KaiwaRepository();
    final all = await repository.getAll();

    expect(all.length, 1700);

    final first = all.first;
    expect(first.id, isNotEmpty);
    expect(first.title, isNotEmpty);
    expect(first.category, isNotEmpty);
    expect(first.lines, isNotEmpty);

    // Nested models, enums and nullable fields are the parts most likely
    // to be lost in translation across an isolate boundary.
    final npc = all
        .expand((e) => e.lines)
        .firstWhere((l) => !l.isUserTurn && l.npcLine != null);
    expect(npc.npcLine!.japanese, isNotEmpty);
    expect(npc.speaker, isNotEmpty);

    final userTurn =
        all.expand((e) => e.lines).firstWhere((l) => l.isUserTurn);
    expect(userTurn.options, isNotEmpty);
    expect(userTurn.options.where((o) => o.isCorrect).length, 1);
  });

  test('the second read is served from memory', () async {
    // The cache is what makes every module screen open instantly after
    // the preload. An isolate hop on every call would undo that.
    final repository = KaiwaRepository();
    await repository.getAll();

    final watch = Stopwatch()..start();
    await repository.getAll();
    watch.stop();

    expect(watch.elapsedMilliseconds, lessThan(50));
  });
}

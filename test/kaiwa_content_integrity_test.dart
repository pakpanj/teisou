import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/data/repositories/kaiwa_repository.dart';

/// Kaiwa is the largest content module — 1,700 dialogues, ~7,500 NPC lines,
/// ~23,000 answer options — and had no test at all. Its invariants are
/// enforced only by `generate_kaiwa_seed.py`, which runs when someone
/// regenerates, not when the app ships.
///
/// Two of these matter more than they look:
///  * A user turn with no correct option, or two correct ones, makes a
///    dialogue unwinnable or ambiguous. `KaiwaDialogueScreen` only advances
///    when the learner taps the option marked correct, so a child would tap
///    every button and simply be stuck, with nothing on screen explaining
///    why.
///  * An NPC line renders *only* its image — the Japanese is never written
///    on screen, only spoken. A missing `imagePath` therefore leaves a turn
///    with no visible content whatsoever.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every user turn has at least two options and exactly one correct',
      () async {
    final entries = await KaiwaRepository().getAll();
    expect(entries, isNotEmpty);

    final problems = <String>[];
    for (final entry in entries) {
      for (final line in entry.lines.where((l) => l.isUserTurn)) {
        if (line.options.length < 2) {
          problems.add('${entry.id}/${line.id}: '
              '${line.options.length} option(s)');
        }
        final correct = line.options.where((o) => o.isCorrect).length;
        if (correct != 1) {
          problems.add('${entry.id}/${line.id}: $correct correct options — '
              'the dialogue cannot be completed');
        }
      }
    }
    expect(problems, isEmpty);
  });

  test('every NPC turn has both a line to speak and an image to show',
      () async {
    final entries = await KaiwaRepository().getAll();
    final problems = <String>[];

    for (final entry in entries) {
      for (final line in entry.lines.where((l) => !l.isUserTurn)) {
        if (line.npcLine == null ||
            line.npcLine!.japanese.trim().isEmpty) {
          problems.add('${entry.id}/${line.id}: no Japanese to speak');
        }
        if (line.imagePath == null || line.imagePath!.trim().isEmpty) {
          problems.add('${entry.id}/${line.id}: no imagePath — the turn '
              'would render nothing at all');
        }
      }
    }
    expect(problems, isEmpty);
  });

  test('every dialogue has at least one NPC turn and one user turn',
      () async {
    final entries = await KaiwaRepository().getAll();
    final problems = <String>[];

    for (final entry in entries) {
      if (entry.lines.isEmpty) {
        problems.add('${entry.id} has no lines');
        continue;
      }
      if (!entry.lines.any((l) => !l.isUserTurn)) {
        problems.add('${entry.id} has no NPC turn');
      }
      if (!entry.lines.any((l) => l.isUserTurn)) {
        problems.add('${entry.id} has nothing for the learner to answer');
      }
    }
    expect(problems, isEmpty);
  });

  test('dialogue and line ids are unique', () async {
    final entries = await KaiwaRepository().getAll();
    final ids = entries.map((e) => e.id).toList();
    expect(ids.toSet().length, ids.length, reason: 'duplicate dialogue id');

    for (final entry in entries) {
      final lineIds = entry.lines.map((l) => l.id).toList();
      expect(lineIds.toSet().length, lineIds.length,
          reason: 'duplicate line id inside ${entry.id}');
    }
  });

  test('answer options are distinct within a turn', () async {
    final entries = await KaiwaRepository().getAll();
    final problems = <String>[];

    for (final entry in entries) {
      for (final line in entry.lines.where((l) => l.isUserTurn)) {
        final texts = line.options.map((o) => o.japanese).toList();
        if (texts.toSet().length != texts.length) {
          problems.add('${entry.id}/${line.id}: two options read the same, '
              'so one correct answer looks wrong');
        }
      }
    }
    expect(problems, isEmpty);
  });
}

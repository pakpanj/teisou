import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/data/models/jlpt_level.dart';
import 'package:kana_master/data/repositories/bunpou_level_repository.dart';
import 'package:kana_master/data/repositories/bunpou_repository.dart';
import 'package:kana_master/data/repositories/choukai_level_repository.dart';
import 'package:kana_master/data/repositories/choukai_repository.dart';
import 'package:kana_master/data/repositories/dokkai_repository.dart';
import 'package:kana_master/data/repositories/kanji_repository.dart';

/// Every module with a `_levels.json` shows the learner a count on its home
/// screen ("N3 / 187 pola"). That number lives in a separate file from the
/// data it describes, so the two can drift — and one silently did:
/// `bunpou/_levels.json` claimed 84 N5 patterns for some time while the
/// dataset held 89, because that file was hand-maintained while kanji,
/// kaiwa and dokkai generate theirs. Nothing failed; the home screen simply
/// lied.
///
/// These tests make the drift impossible to ship unnoticed. They are
/// deliberately about the *displayed* number rather than internal
/// structure: a wrong count is what a learner actually sees.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Bunpou level counts match the real pattern totals', () async {
    final levels = await BunpouLevelRepository().getAll();
    final all = await BunpouRepository().getAll();
    expect(levels, isNotEmpty);

    for (final level in levels) {
      final actual =
          all.where((e) => e.jlptLevel.key == level.id).length;
      expect(
        level.bunpouCount,
        actual,
        reason: 'bunpou/_levels.json says ${level.id} has '
            '${level.bunpouCount} patterns, dataset has $actual',
      );
    }
  });

  test('Choukai level counts match the real clip totals, and a level is '
      'only marked available when it actually has clips', () async {
    final levels = await ChoukaiLevelRepository().getAll();
    final all = await ChoukaiRepository().getAll();
    expect(levels, isNotEmpty);

    for (final level in levels) {
      final actual = all.where((c) => c.jlptLevel.key == level.id).length;
      expect(
        level.clipCount ?? 0,
        actual,
        reason: 'choukai/_levels.json says ${level.id} has '
            '${level.clipCount} clips, dataset has $actual',
      );
      expect(
        level.available,
        actual > 0,
        reason: '${level.id} is marked available=${level.available} but has '
            '$actual clips — an empty level must not look openable',
      );
    }
  });

  test('every JLPT level a module claims is one the app knows about',
      () async {
    final known = JlptLevel.values.map((l) => l.key).toSet();
    for (final id in (await BunpouLevelRepository().getAll()).map((l) => l.id)) {
      expect(known, contains(id));
    }
    for (final id
        in (await ChoukaiLevelRepository().getAll()).map((l) => l.id)) {
      expect(known, contains(id));
    }
  });

  test('Kanji and Dokkai cover all five levels with no empty level',
      () async {
    final kanji = await KanjiRepository().getAll();
    final dokkai = await DokkaiRepository().getAll();
    for (final level in JlptLevel.values) {
      expect(
        kanji.where((k) => k.jlptLevel == level),
        isNotEmpty,
        reason: 'kanji has no entries for ${level.key}',
      );
      expect(
        dokkai.where((d) => d.jlptLevel == level),
        isNotEmpty,
        reason: 'dokkai has no passages for ${level.key}',
      );
    }
  });
}

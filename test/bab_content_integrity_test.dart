import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/data/repositories/bab_repository.dart';
import 'package:kana_master/data/repositories/bunpou_repository.dart';
import 'package:kana_master/data/repositories/dokkai_repository.dart';
import 'package:kana_master/data/repositories/kaiwa_repository.dart';
import 'package:kana_master/data/repositories/kanji_repository.dart';
import 'package:kana_master/data/repositories/kotoba_repository.dart';
import 'package:kana_master/data/repositories/particle_repository.dart';

/// Defense-in-depth on top of `generate_bab_seed.py`'s own cross-reference
/// assertions: proves every id every Bab chapter references still resolves
/// to a real entry via that module's own repository. Catches drift if
/// `bab_data.json` is ever hand-edited, or a referenced dataset entry is
/// later renamed/deleted without regenerating Bab.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every Bab chapter\'s cross-module ids resolve to a real entry', () async {
    final chapters = await BabRepository().getAll();
    expect(chapters, isNotEmpty);

    final kotobaRepo = KotobaRepository();
    final kanjiRepo = KanjiRepository();
    final bunpouRepo = BunpouRepository();
    final particleRepo = ParticleRepository();
    final kaiwaRepo = KaiwaRepository();
    final dokkaiRepo = DokkaiRepository();

    final missing = <String>[];
    for (final bab in chapters) {
      for (final id in bab.kotobaIds) {
        if (await kotobaRepo.getById(id) == null) missing.add('${bab.id}: kotoba $id');
      }
      for (final id in bab.kanjiIds) {
        if (await kanjiRepo.getById(id) == null) missing.add('${bab.id}: kanji $id');
      }
      for (final id in bab.bunpouIds) {
        if (await bunpouRepo.getById(id) == null) missing.add('${bab.id}: bunpou $id');
      }
      for (final id in bab.particleIds) {
        if (await particleRepo.getById(id) == null) missing.add('${bab.id}: particle $id');
      }
      for (final id in bab.kaiwaIds) {
        if (await kaiwaRepo.getById(id) == null) missing.add('${bab.id}: kaiwa $id');
      }
      for (final id in bab.dokkaiIds) {
        if (await dokkaiRepo.getById(id) == null) missing.add('${bab.id}: dokkai $id');
      }
    }

    expect(missing, isEmpty,
        reason: 'dangling Bab reference ids — re-run '
            'scripts/generate_bab_seed.py after checking scripts/bab_lists.py: '
            '$missing');
  });

  test('Bab order is contiguous starting at 1, per level', () async {
    final chapters = await BabRepository().getAll();
    final ids = chapters.map((b) => b.id).toSet();
    expect(ids.length, chapters.length, reason: 'duplicate Bab id found');

    final orders = chapters.map((b) => b.order).toList()..sort();
    expect(orders, List.generate(chapters.length, (i) => i + 1),
        reason: 'Bab order must be contiguous starting at 1 across the '
            'whole curriculum');
  });
}

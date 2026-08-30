import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/data/repositories/kotoba_repository.dart';

/// Regression coverage for a real gap: `KotobaRepository.search()`/
/// `findExact()` only ever scanned `_loadAll()`'s ~30-entry legacy Batch 4
/// seed (`assets/data/kotoba_data.json`), never the real 1,682-word vocab
/// module spread across `assets/data/kotoba/{category}.json`. Since
/// `SearchScreen` (the app's main Kamus feature) calls `search()` directly,
/// this meant the vast majority of the app's own vocabulary was
/// unreachable through search — a functional, user-facing gap, not just a
/// data-completeness nitpick. `getById` was already fixed for the same
/// class of gap (needed for Bab curriculum lookups); `search`/`findExact`
/// never were, until this fix.
///
/// うなぎ (unagi, `kotoba_ikan_unagi`) is used as the probe because it's
/// confirmed to live only in the real vocab module (`assets/data/kotoba/
/// ikan.json`), never in the small legacy seed — the same word already
/// used elsewhere in this project's test suite for exactly this
/// "must come from the real module, not the legacy one" reason.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late KotobaRepository repo;

  setUp(() {
    repo = KotobaRepository();
  });

  test('search() finds a word that lives only in the real vocab module, '
      'not just the small legacy seed', () async {
    final results = await repo.search('unagi');
    expect(
      results.any((e) => e.id == 'kotoba_ikan_unagi'),
      isTrue,
      reason: 'うなぎ only exists in assets/data/kotoba/ikan.json (the real '
          '1,682-word module) — if search() regresses back to scanning '
          'only the legacy seed, this word becomes unfindable again',
    );
  });

  test('search() also still finds a word by its Japanese reading/kanji, '
      'not just romaji', () async {
    final results = await repo.search('うなぎ');
    expect(results.any((e) => e.id == 'kotoba_ikan_unagi'), isTrue);
  });

  test('findExact() resolves a word that lives only in the real vocab '
      'module', () async {
    final entry = await repo.findExact('うなぎ');
    expect(entry?.id, 'kotoba_ikan_unagi');
  });

  test('search() never returns the same id twice, even though the legacy '
      'seed and the vocab module are searched separately', () async {
    // A broad query likely to match many entries across both sources —
    // the dedup guard in search() must hold regardless of overlap.
    final results = await repo.search('a');
    final ids = results.map((e) => e.id).toList();
    expect(ids.length, ids.toSet().length,
        reason: 'search() must never list the same entry twice');
  });
}

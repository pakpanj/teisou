import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/providers.dart';
import 'package:kana_master/data/models/bab_entry.dart';
import 'package:kana_master/data/models/jlpt_level.dart';
import 'package:kana_master/features/bab/bab_providers.dart';

/// The curriculum's level gate: N4 opens only once every N5 chapter is
/// finished, N3 once N4 is, and so on — the chapter-to-chapter rule
/// `BabLevelScreen` already applies, lifted one level up.
///
/// Worth pinning in a test rather than trusting the screen: the rule is
/// cumulative, so an error at N5 silently unlocks all four levels above
/// it, and the only way to notice on a device would be to complete 52
/// chapters first.
///
/// Completed chapters are injected by overriding [babCompletedIdsProvider]
/// rather than by seeding SharedPreferences, because
/// `BabProgressRepository`'s constructor reaches for
/// `FirebaseFirestore.instance` eagerly and so cannot be built without a
/// live Firebase app. That is fine in the running app — the provider is
/// only ever read after `Firebase.initializeApp` — but it does mean the
/// storage layer is out of reach here. What is under test is the unlock
/// rule itself, which takes the completed-id set as its input, so the real
/// chapter dataset still flows through `babAllProvider` unmocked.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// A container in which the first N chapters of each named level are
  /// marked complete, taken in `order` so the set is always a real prefix
  /// of the curriculum rather than an arbitrary scatter.
  Future<ProviderContainer> containerWith(
    Map<JlptLevel, int> completedPerLevel,
  ) async {
    final all = await BabRepositoryForTest.all();
    final ids = <String>{};
    for (final entry in completedPerLevel.entries) {
      final chapters = all.where((b) => b.level == entry.key).toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      ids.addAll(chapters.take(entry.value).map((b) => b.id));
    }
    return ProviderContainer(
      overrides: [
        babCompletedIdsProvider.overrideWith((ref) async => ids),
      ],
    );
  }

  test('a fresh learner has N5 open and N4-N1 locked', () async {
    final container = await containerWith(const {});
    addTearDown(container.dispose);

    final levels = await container.read(babLevelProgressProvider.future);
    expect(levels.map((l) => l.level).toList(), JlptLevel.values);

    expect(levels[0].reachedByProgress, isTrue, reason: 'N5 always opens');
    for (final locked in levels.skip(1)) {
      expect(locked.reachedByProgress, isFalse,
          reason: '${locked.level.key} must stay locked');
      expect(locked.completed, 0);
    }
  });

  test('finishing all but one N5 chapter still leaves N4 locked', () async {
    final all = await BabRepositoryForTest.all();
    final n5Count = all.where((b) => b.level == JlptLevel.n5).length;
    expect(n5Count, greaterThan(1));

    final container = await containerWith({JlptLevel.n5: n5Count - 1});
    addTearDown(container.dispose);

    final levels = await container.read(babLevelProgressProvider.future);
    expect(levels[0].isComplete, isFalse);
    expect(levels[0].completed, n5Count - 1);
    expect(levels[1].reachedByProgress, isFalse,
        reason: 'one chapter short is still short');
  });

  test('finishing every N5 chapter opens N4 and only N4', () async {
    final all = await BabRepositoryForTest.all();
    final n5Count = all.where((b) => b.level == JlptLevel.n5).length;

    final container = await containerWith({JlptLevel.n5: n5Count});
    addTearDown(container.dispose);

    final levels = await container.read(babLevelProgressProvider.future);
    expect(levels[0].isComplete, isTrue);
    expect(levels[1].reachedByProgress, isTrue, reason: 'N4 unlocks');
    expect(levels[2].reachedByProgress, isFalse,
        reason: 'N3 must not unlock with N4 untouched');
    expect(levels[3].reachedByProgress, isFalse);
    expect(levels[4].reachedByProgress, isFalse);
  });

  test('the current level tracks the furthest level actually unlocked',
      () async {
    final all = await BabRepositoryForTest.all();
    final n5 = all.where((b) => b.level == JlptLevel.n5).length;
    final n4 = all.where((b) => b.level == JlptLevel.n4).length;

    final fresh = await containerWith(const {});
    addTearDown(fresh.dispose);
    expect((await fresh.read(babCurrentLevelProvider.future)).level,
        JlptLevel.n5);

    final midN4 = await containerWith({JlptLevel.n5: n5, JlptLevel.n4: 3});
    addTearDown(midN4.dispose);
    final current = await midN4.read(babCurrentLevelProvider.future);
    expect(current.level, JlptLevel.n4);
    expect(current.completed, 3);
    expect(current.total, n4);
  });

  test('progress inside a locked level cannot be counted as reaching it',
      () async {
    // Defensive: nothing in the UI can complete an N3 chapter before N4 is
    // done, but if stale Firestore data ever said otherwise, the gate must
    // still hold on N5/N4 being finished — not on N3 having entries.
    final container = await containerWith({JlptLevel.n3: 5});
    addTearDown(container.dispose);

    final levels = await container.read(babLevelProgressProvider.future);
    expect(levels[2].completed, 5, reason: 'the entries are still counted');
    expect(levels[2].reachedByProgress, isFalse,
        reason: 'but N3 stays locked while N5 and N4 are unfinished');
  });
}

/// Loads the shipped chapter list once for the expectations above.
class BabRepositoryForTest {
  static List<BabEntry>? _cache;

  static Future<List<BabEntry>> all() async {
    final cached = _cache;
    if (cached != null) return cached;
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return _cache = await container.read(babRepositoryProvider).getAll();
  }
}

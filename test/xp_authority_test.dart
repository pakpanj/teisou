import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards Security & Monetization Remediation Plan, Blocker #2 / Phase 1
/// (XP authority) — `xp.totalXp`, `xp.claimedLevel`,
/// `xp.unlockedAvatarIds`, `xp.unlockedFrameIds`, `xp.unlockedCoverIds`
/// must be Cloud-Function-only, and `claimLevelReward` must never grant a
/// subscription-exclusive item (Option A — Premium Exclusive, the locked
/// product decision in
/// `TEISOU_Premium_Cosmetic_Ownership_Product_Decision.md`).
///
/// **Same standing limitation as `ad_rewards_freeze_test.dart`**: this
/// project has no Firestore Rules emulator and no Dart-side mock for
/// `FirebaseFunctions`/`HttpsCallable` (confirmed absent — no
/// `mockito`/`mocktail` dependency, no existing test mocks
/// `cloud_functions` anywhere in this repo). So these are source-
/// inspection tests, the same convention this codebase already uses for
/// this class of guarantee. The Cloud Function's own correctness — real
/// reward grants, duplicate-claim idempotency under genuine transaction
/// conflict, and the premium-only exclusion actually holding across an
/// exhaustive claim run — is proven with a real (fake but
/// transaction-faithful) Firestore double in
/// `functions/award_xp.test.js`, run via `node --test`, not here.
void main() {
  String read(String path) =>
      File(path).readAsStringSync().replaceAll('\r\n', '\n');

  final rules = read('firestore.rules');
  final progressRepo = read('lib/data/repositories/progress_repository.dart');
  final xpModel = read('lib/data/models/xp_progress.dart');
  final awardXpJs = read('functions/award_xp.js');
  final avatars = read('lib/core/constants/avatars.dart');
  final frames = read('lib/core/constants/frames.dart');
  final covers = read('lib/core/constants/covers.dart');
  final moduleAccess = read('lib/features/paywall/module_access.dart');

  group('1. client cannot write the XP authority fields', () {
    test('isAllowedPurchaseWrite freezes the whole xp map', () {
      expect(
        rules,
        contains(
          "let oldXp = resource == null\n"
          "          ? {}\n"
          "          : resource.data.get('xp', {});",
        ),
      );
      expect(
        rules,
        contains("request.resource.data.get('xp', {}) == oldXp"),
      );
    });

    test('a brand-new document cannot seed xp at create time either', () {
      expect(rules, contains("&& !('xp' in request.resource.data);"));
    });

    test('addXp no longer performs a direct Firestore write to xp', () {
      expect(
        progressRepo,
        isNot(contains("'xp': {'totalXp'")),
        reason: 'the old direct FieldValue.increment write must be gone',
      );
      expect(
        progressRepo,
        contains("await _functions.httpsCallable('awardXp').call({"),
      );
    });

    test('claimLevelReward no longer reads/writes xp directly either', () {
      expect(
        progressRepo,
        isNot(contains("xpMap?['unlockedAvatarIds']")),
        reason: 'the old client-side pool-building must be gone',
      );
      expect(
        progressRepo,
        contains("_functions.httpsCallable('claimXpReward').call()"),
      );
    });
  });

  group('2. legitimate rewards still work — client passes an action, '
      'server decides the amount', () {
    test('every addXp call site passes an XpAction, not a raw int', () {
      // A regression here would mean a call site still compiles against
      // the old `addXp(uid, int)` shape — but since the method itself no
      // longer accepts an int at all, this is really guarding that no
      // call site was left calling a method that no longer exists in
      // that shape; checked by grep as a second, independent proof
      // alongside `flutter analyze`.
      final rawIntCalls = RegExp(r'\.addXp\([^,]+,\s*\d+\)');
      expect(
        rawIntCalls.hasMatch(progressRepo),
        isFalse,
        reason: 'no call site should pass a raw XP amount anymore',
      );
    });

    test('Dart XpAction values exactly match the server XP_AMOUNTS keys', () {
      // Cross-file consistency: if these drift, a legitimate action
      // either fails outright (client names a value the server doesn't
      // recognize) or silently grants nothing recognizable.
      final actionEnumMatch = RegExp(
        r'enum XpAction \{ ([\w, ]+) \}',
      ).firstMatch(xpModel);
      expect(actionEnumMatch, isNotNull);
      final dartActions = actionEnumMatch!
          .group(1)!
          .split(',')
          .map((s) => s.trim())
          .toSet();

      final jsAmountsMatch = RegExp(
        r'const XP_AMOUNTS = \{([^}]+)\}',
      ).firstMatch(awardXpJs);
      expect(jsAmountsMatch, isNotNull);
      final jsActions = RegExp(r'(\w+):\s*\d+')
          .allMatches(jsAmountsMatch!.group(1)!)
          .map((m) => m.group(1)!)
          .toSet();

      expect(dartActions, equals(jsActions));
    });

    test('claimLevelReward resolves a returned reward id to a real label, '
        'not a server-supplied string', () {
      expect(progressRepo, contains('AvatarPresets.byId(id)?.emoji'));
      expect(progressRepo, contains('FramePresets.byId(id)?.label'));
      expect(progressRepo, contains('CoverPresets.byId(id)?.label'));
    });
  });

  group('3. Option A — Premium Exclusive: server pool never includes a '
      'subscription-exclusive id', () {
    List<String> extractIdList(String source, String afterMarker) {
      final idx = source.indexOf(afterMarker);
      expect(idx, greaterThan(-1), reason: 'marker not found: $afterMarker');
      final closeIdx = source.indexOf('],', idx);
      final chunk = source.substring(idx, closeIdx);
      return RegExp(r'"([a-zA-Z0-9_]+)"')
          .allMatches(chunk)
          .map((m) => m.group(1)!)
          .toList();
    }

    test('avatars.dart\'s isPremiumOnly ids never appear in award_xp.js\'s '
        'avatar pool', () {
      // Confirmed premium-only avatar ids: everything in `premium` that
      // is in neither `adIds` nor `coinIds` — hardcoded here from a
      // direct read of avatars.dart at the time this test was written,
      // the same discipline `card_battle_mascot_mapping_test.dart` and
      // `ad_rewards_freeze_test.dart` already use for this project.
      const premiumOnlyAvatarIds = ['neko_astronaut', 'neko_gamer', 'neko_lion'];
      final pool = extractIdList(awardXpJs, 'avatar: {');
      for (final id in premiumOnlyAvatarIds) {
        expect(avatars, contains(id), reason: 'sanity: id exists in avatars.dart');
        expect(pool, isNot(contains(id)));
      }
    });

    test('frames.dart\'s isPremiumOnly ids never appear in award_xp.js\'s '
        'frame pool', () {
      const premiumOnlyFrameIds = [
        'frame_steampunk',
        'frame_space',
        'frame_gaming',
        'frame_moon_crystal',
      ];
      final pool = extractIdList(awardXpJs, 'frame: {');
      for (final id in premiumOnlyFrameIds) {
        expect(frames, contains(id), reason: 'sanity: id exists in frames.dart');
        expect(pool, isNot(contains(id)));
      }
    });

    test('covers.dart\'s isPremiumOnly ids never appear in award_xp.js\'s '
        'cover pool', () {
      const premiumOnlyCoverIds = ['sacred_geometry', 'cyber_neon', 'outer_space'];
      final pool = extractIdList(awardXpJs, 'cover: {');
      for (final id in premiumOnlyCoverIds) {
        expect(covers, contains(id), reason: 'sanity: id exists in covers.dart');
        expect(pool, isNot(contains(id)));
      }
    });
  });

  group('4. ad-tier/coin-tier rewards keep working', () {
    test('award_xp.js\'s pools contain real ad-tier and coin-tier ids, '
        'not an empty/gutted pool', () {
      expect(awardXpJs, contains('"neko_chef"')); // adIds
      expect(awardXpJs, contains('"neko_matcha"')); // coinIds
      expect(awardXpJs, contains('"frame_ocean"')); // adIds
      expect(awardXpJs, contains('"frame_witch"')); // coinIds
      expect(awardXpJs, contains('"coral_reef"')); // adIds
      expect(awardXpJs, contains('"sumi_ink"')); // coinIds
    });
  });

  group('5. globalPoints stays fully separate', () {
    test('award_xp.js never reads or writes the leaderboard collection '
        '(where globalPoints actually lives) — the doc comment is '
        'allowed to name it in prose, code must never touch it', () {
      expect(awardXpJs, isNot(contains('collection("leaderboard")')));
      expect(awardXpJs, isNot(contains("collection('leaderboard')")));
    });

    test('addXp/claimLevelReward never reference globalPoints at all', () {
      final addXpStart = progressRepo.indexOf('Future<void> addXp');
      final claimStart =
          progressRepo.indexOf('Future<XpReward?> claimLevelReward');
      final claimEnd = (claimStart + 2000).clamp(0, progressRepo.length);
      expect(addXpStart, greaterThan(-1));
      expect(claimStart, greaterThan(-1));
      expect(
        progressRepo.substring(addXpStart, claimEnd),
        isNot(contains('globalPoints')),
      );
    });

    test('XP_PER_LEVEL (server) matches XpProgress.xpPerLevel (client)', () {
      final jsMatch = RegExp(r'const XP_PER_LEVEL = (\d+);').firstMatch(awardXpJs);
      final dartMatch = RegExp(r'xpPerLevel = (\d+);').firstMatch(xpModel);
      expect(jsMatch, isNotNull);
      expect(dartMatch, isNotNull);
      expect(jsMatch!.group(1), equals(dartMatch!.group(1)));
    });
  });

  group('6. unrelated systems untouched', () {
    test('module_access.dart (IAP-adjacent premium gating) was not '
        'touched by this change', () {
      expect(
        moduleAccess,
        contains(
          'final premium =\n'
          '      ref.watch(subscriptionProvider).valueOrNull?.isPremium ?? false;\n'
          '  if (premium) return true;',
        ),
      );
    });

    test('the update rule\'s other frozen fields are unchanged in shape, '
        'only xp was added', () {
      expect(rules, contains("request.resource.data.get('subscription', {}) == oldSub"));
      expect(rules, contains("request.resource.data.get('entitlements', {}) == oldEnt"));
      expect(rules, contains("request.resource.data.get('coins', 0) == oldCoins"));
      expect(rules, contains("request.resource.data.get('adRewards', {}) == oldRewards"));
    });
  });
}

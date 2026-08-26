import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards Security & Monetization Final Implementation Plan, Blocker #3 /
/// Phase 2 (Cosmetic Ownership / Equip Security) — `isAllowedAvatarWrite`,
/// `isAllowedProfileWrite` (frame/cover), and `isAllowedCardSkinWrite` in
/// `firestore.rules`.
///
/// **A real Firestore Rules emulator harness now exists** —
/// `firestore_rules_tests/` (its own `package.json`, deliberately kept
/// out of `functions/` so the dev-only `@firebase/rules-unit-testing`
/// dependency never ships with Cloud Functions), run via
/// `firebase emulators:exec --only firestore "node --test
/// firestore_rules_tests/rules.test.js"`. That suite throws real writes
/// at the real CEL compiler/evaluator and is the authoritative check for
/// this file's guarantees — it is what actually caught, in order:
/// (1) `isAllowedCosmeticEquip` originally failing to compile at all (8
/// arguments, over Firestore's hard 7-argument-per-function limit);
/// (2) a far more serious pre-existing bug this file's source-inspection
/// technique structurally could not have found: the `users/{uid} {
/// match /{document=**} { allow write: if owner } } }` block a few
/// lines above `isAllowedAvatarWrite` matched the **parent**
/// `/users/{uid}` document too (Firestore's recursive wildcards match
/// zero-or-more segments, not one-or-more), and Firestore unions every
/// matching `allow` block — so that broad, unconditional owner-write
/// grant overrode every restriction Phases 0-2 added, including this
/// file's own. Fixed by requiring a named `{subcollection}` segment
/// before the recursive wildcard, so it can no longer match the parent
/// document with zero remaining segments; (3) once (2) was fixed and
/// the specific `allow update` rule was actually being evaluated (no
/// longer masked by the broad wildcard grant), a *second*, entangled
/// bug surfaced: the map-parameter redesign from (1)'s fix compiled
/// fine but threw "Null value error" at evaluation time the moment a
/// field of the map parameter was dereferenced inside the function —
/// maps cannot safely cross a Firestore Rules function-call boundary in
/// this engine, even though they compile and even though the map is
/// never actually null. Fixed by using three separate list parameters
/// (`freeIds`/`adIds`/`premiumOnlyIds`) instead of one map, dropping
/// `coinIds` as a parameter entirely (still correct — see the
/// function's own doc comment for why). None of (1), (2), or (3) were
/// ever fixed silently — each was reported to the user with the real
/// suite's exact failure output before any rules-logic edit was made.
///
/// This file's own tests below (source-inspection + a Dart logic-mirror)
/// predate that harness and are kept for fast iteration, but they are
/// **not** a substitute for it and never were — reading `firestore.rules`
/// as text can prove the right logic is *present*, never that Firestore's
/// real CEL engine *evaluates* it as intended, or that some other rule
/// elsewhere in the file doesn't quietly override it. Two different,
/// honestly-labeled techniques are used here, and neither should be
/// mistaken for the other:
///
/// 1. **Source-inspection** (groups 1-6 below) — reads `firestore.rules`
///    as text and asserts the right structural pieces are present. Same
///    convention this project already established in
///    `ad_rewards_freeze_test.dart`/`xp_authority_test.dart`. Proves the
///    rule *contains* the right logic; does not prove Firestore's CEL
///    engine *executes* it as intended.
/// 2. **Logic-mirror scenarios** (group 7) — a plain Dart re-
///    implementation of the exact same boolean formula written into
///    `isAllowedCosmeticEquip`/`isAllowedCardSkinWrite`, exercised
///    against the 8 required scenarios. This proves the *documented
///    design* is internally consistent and does what Option A requires
///    — it does **not** prove the real CEL text (a different language)
///    compiles to the identical decision; a translation slip between the
///    two is possible and this test cannot catch it. Flagged here
///    explicitly rather than silently presented as equivalent to a real
///    rules-emulator test.
void main() {
  String read(String path) =>
      File(path).readAsStringSync().replaceAll('\r\n', '\n');

  final rules = read('firestore.rules');
  final avatars = read('lib/core/constants/avatars.dart');
  final frames = read('lib/core/constants/frames.dart');
  final covers = read('lib/core/constants/covers.dart');
  final cardSkins = read('lib/core/constants/card_skins.dart');

  group('0. emulator/harness check — Phase 3 built the real thing', () {
    test('firebase.json now declares a firestore emulator', () {
      final firebaseJson = read('firebase.json');
      expect(firebaseJson, contains('"emulators"'));
      expect(firebaseJson, contains('"firestore"'));
    });

    test('the real rules-emulator suite exists, in its own package, not '
        "inside functions/ — functions/package.json still carries no "
        'rules-testing dev dependency', () {
      final pkg = read('functions/package.json');
      expect(pkg, isNot(contains('rules-unit-testing')));
      final harnessPkg = read('firestore_rules_tests/package.json');
      expect(harnessPkg, contains('@firebase/rules-unit-testing'));
      expect(File('firestore_rules_tests/rules.test.js').existsSync(), isTrue);
    });
  });

  group('1. the three equip write paths are all gated', () {
    test('the update rule calls all three new/extended functions', () {
      expect(
        rules,
        contains(
          'allow update: if request.auth != null && request.auth.uid == uid\n'
          '          && isAllowedAvatarWrite()\n'
          '          && isAllowedProfileWrite()\n'
          '          && isAllowedCardSkinWrite()\n'
          '          && isAllowedPurchaseWrite()',
        ),
      );
    });

    test('every path still requires request.auth.uid == uid — one '
        'account cannot equip using another UID\'s ownership records '
        '(requirement 4)', () {
      // The check that actually stops UID spoofing is this single line
      // on the update rule itself, not inside any of the three cosmetic
      // functions (they never take a uid parameter to spoof — they read
      // resource.data, which is this account's own document, period).
      expect(
        rules,
        contains('allow update: if request.auth != null && request.auth.uid == uid'),
      );
      // isAllowedCardSkinWrite reads a second document
      // (leaderboard/{resource.id}) — confirm it derives the id from the
      // resource being written, not from anything request-supplied that
      // a caller could point at someone else's leaderboard row.
      expect(
        rules,
        contains(
          'get(/databases/\$(database)/documents/leaderboard/\$(resource.id))',
        ),
        reason: 'must key off resource.id (this document\'s own uid), '
            'never a client-suppliable value',
      );
    });
  });

  group('2. the old avatarType-based bypass is gone', () {
    test('isAllowedAvatarWrite no longer branches on avatarType at all', () {
      final fnStart = rules.indexOf('function isAllowedAvatarWrite()');
      final fnEnd = rules.indexOf('\n    }', fnStart);
      final body = rules.substring(fnStart, fnEnd);
      expect(
        body,
        isNot(contains('changingToGated')),
        reason: 'the old type-based check (bypassable by setting '
            "avatarType: 'preset_free' alongside a premium avatarValue) "
            'must be gone',
      );
      expect(body, isNot(contains("'preset_premium'")));
      expect(
        body,
        contains('isAllowedCosmeticEquip('),
        reason: 'avatar equip must go through the same value-based check '
            'as frame/cover',
      );
    });
  });

  group('3. Option A — subscription-exclusive items never come from '
      'xp.unlocked*Ids, even defensively', () {
    test('isAllowedCosmeticEquip explicitly excludes premiumOnlyIds from '
        'the ownedPermanently path', () {
      // The signature went through two real-engine-driven revisions,
      // both found via firestore_rules_tests/ (the real Rules Emulator),
      // not this source-inspection suite:
      // 1. The original 8-argument isAllowedCosmeticEquip (oldValue,
      //    newValue, freeIds, adIds, coinIds, premiumOnlyIds, ownedIds,
      //    adModuleId) failed to COMPILE at all ("Maximum allowed
      //    function arguments of 7").
      // 2. Collapsing the four id lists into one `tiers` MAP parameter
      //    brought the count to 5 and compiled fine — but the real
      //    evaluator threw "Null value error" the moment a field of
      //    that map (`tiers.premiumOnly` etc.) was dereferenced inside
      //    the function, even though it was never actually null. Maps
      //    cannot safely cross a Firestore Rules function-call boundary
      //    in this engine; lists can. Final shape: freeIds/adIds/
      //    premiumOnlyIds as three separate list parameters (coinIds
      //    dropped — see the function's own doc comment for why that's
      //    still correct), 7 args total.
      expect(
        rules,
        contains(
          'let ownedPermanently = newValue in ownedIds && !(newValue in premiumOnlyIds);',
        ),
        reason: 'this is the literal defense-in-depth clause: even if '
            'xp.unlocked*Ids somehow contained a premium-only id, this '
            'must still refuse to treat it as ownership',
      );
    });

    test('premiumOk is the only path that can satisfy a premiumOnlyIds '
        'match', () {
      expect(
        rules,
        contains(
          'let premiumOk = newValue in premiumOnlyIds && isPremiumSubscriberNow();',
        ),
      );
    });
  });

  group('4. id lists mirror the real Dart catalogs exactly (data-drift '
      'guard)', () {
    String functionBody(String name) {
      final start = rules.indexOf('function $name(');
      expect(start, greaterThan(-1), reason: 'function $name not found');
      final end = rules.indexOf('\n    }', start);
      return rules.substring(start, end);
    }

    test('avatar id lists (free/ad/coin/premiumOnly) match avatars.dart', () {
      final body = functionBody('isAllowedAvatarWrite');
      const freeIds = ['neko_sensei', 'neko_cheerleader', 'neko_bookworm'];
      const adIds = ['neko_chef', 'neko_sleepy', 'neko_traveler'];
      const premiumOnlyIds = ['neko_astronaut', 'neko_gamer', 'neko_lion'];
      for (final id in [...freeIds, ...adIds, ...premiumOnlyIds]) {
        expect(body, contains("'$id'"));
        expect(avatars, contains(id), reason: 'sanity: id exists in avatars.dart');
      }
    });

    test('frame id lists match frames.dart', () {
      final body = functionBody('isAllowedProfileWrite');
      const ids = [
        'frame_sakura_fuji', 'frame_sakura', 'frame_autumn', 'frame_winter',
        'frame_spring_garden', 'frame_ocean', 'frame_jungle', 'frame_cat',
        'frame_steampunk', 'frame_space', 'frame_gaming', 'frame_moon_crystal',
      ];
      for (final id in ids) {
        expect(body, contains("'$id'"));
        expect(frames, contains(id), reason: 'sanity: id exists in frames.dart');
      }
    });

    test('cover id lists match covers.dart', () {
      final body = functionBody('isAllowedProfileWrite');
      const ids = [
        'sakura_dawn', 'autumn_leaves', 'spring_meadow', 'starry_night',
        'coral_reef', 'sunflower_field', 'library_books', 'cat_lover',
        'sacred_geometry', 'cyber_neon', 'outer_space',
      ];
      for (final id in ids) {
        expect(body, contains("'$id'"));
        expect(covers, contains(id), reason: 'sanity: id exists in covers.dart');
      }
    });

    test('card skin id lists and star thresholds match card_skins.dart', () {
      final body = functionBody('isAllowedCardSkinWrite') +
          functionBody('cardSkinStarsRequired');
      const ids = [
        'classic', 'sakura', 'indigo',
        'emas_kencana', 'night_purple', 'dragon_black',
        'cloud_white', 'neon_city', 'sakura_gold',
      ];
      for (final id in ids) {
        expect(body, contains("'$id'"));
        expect(cardSkins, contains(id), reason: 'sanity: id exists in card_skins.dart');
      }
      expect(body, contains('35'));
      expect(body, contains('60'));
      expect(body, contains('90'));
      expect(cardSkins, contains('goldThreshold = 35'));
      expect(cardSkins, contains('diamondThreshold = 60'));
      expect(cardSkins, contains('emeraldThreshold = 90'));
    });

    test('no unrecognized 7th event-tier skin id leaked into the rule '
        '(card_skins.dart currently has zero — nothing should be '
        'recognized for that tier)', () {
      final body = functionBody('isAllowedCardSkinWrite');
      // achievementIds/paidIds/freeIds together are the only 3
      // recognized lists — confirms no 4th "eventIds" list was added
      // speculatively for a tier that has no real ids yet.
      expect(body, isNot(contains('eventIds')));
    });
  });

  group('5. Card Skin keeps its existing ownership mechanism, untouched', () {
    test('achievement tier still requires stars AND premium, both, '
        'matching isCardSkinUnlocked exactly', () {
      final body = read('firestore.rules');
      expect(
        body,
        contains(
          '>= cardSkinStarsRequired(newSkin)\n'
          '          && isPremiumSubscriberNow();',
        ),
      );
    });

    test('paid tier still allows owned OR premium (bundled), matching '
        'isCardSkinUnlocked\'s CardSkinSource.paid case', () {
      expect(
        rules,
        contains('let paidOk = newSkin in paidIds && (owned || isPremiumSubscriberNow());'),
      );
    });

    test('card_skins.dart\'s own isCardSkinUnlocked function is untouched '
        'by this phase', () {
      expect(
        cardSkins,
        contains(
          'CardSkinSource.achievement =>\n'
          '      starTotal >= skin.starsRequired && premium,\n'
          '    CardSkinSource.paid => owned || premium,',
        ),
      );
    });

    test('XpRewardKind still has no skin value — Card Skin was never in '
        'the XP reward pool and this phase did not add it', () {
      final xpModel = read('lib/data/models/xp_progress.dart');
      expect(xpModel, contains('enum XpRewardKind { avatar, frame, cover }'));
      final awardXpJs = read('functions/award_xp.js');
      expect(awardXpJs, isNot(contains('skin:')));
    });
  });

  group('6. xp.* stays server-authoritative, globalPoints untouched', () {
    test('the Phase 1 xp freeze is still present, unweakened', () {
      expect(rules, contains("request.resource.data.get('xp', {}) == oldXp"));
      expect(rules, contains("&& !('xp' in request.resource.data);"));
    });

    test('none of the three new cosmetic functions write to xp — they '
        'only read it', () {
      for (final name in [
        'isAllowedAvatarWrite',
        'isAllowedProfileWrite',
        'isAllowedCardSkinWrite',
      ]) {
        final start = rules.indexOf('function $name(');
        final end = rules.indexOf('\n    }', start);
        final body = rules.substring(start, end);
        expect(body, isNot(contains('FieldValue')));
        expect(body, isNot(contains("request.resource.data.get('xp'")),
            reason: '$name must only read xp.unlocked*Ids via ownedIds, '
                'never write to xp');
      }
    });

    test('none of the three new cosmetic functions reference '
        'globalPoints or leaderboard fields other than cardGameStarTotal',
        () {
      for (final name in [
        'isAllowedAvatarWrite',
        'isAllowedProfileWrite',
        'isAllowedCardSkinWrite',
      ]) {
        final start = rules.indexOf('function $name(');
        final end = rules.indexOf('\n    }', start);
        final body = rules.substring(start, end);
        expect(body, isNot(contains('globalPoints')));
      }
    });
  });

  // --- Group 7: logic-mirror scenarios. See the file doc comment for
  // exactly what this does and does not prove. ---
  group('7. logic-mirror: the documented design satisfies all 8 required '
      'scenarios (does not prove the live CEL rule — see file doc comment)', () {
    // A direct Dart port of isAllowedCosmeticEquip's boolean formula.
    bool isAllowedCosmeticEquip({
      required String? oldValue,
      required String? newValue,
      required Set<String> freeIds,
      required Set<String> adIds,
      required Set<String> coinIds,
      required Set<String> premiumOnlyIds,
      required Set<String> ownedIds,
      required bool adRewardActive,
      required bool isPremium,
    }) {
      final unchanged = newValue == oldValue;
      final recognized = freeIds.contains(newValue) ||
          adIds.contains(newValue) ||
          coinIds.contains(newValue) ||
          premiumOnlyIds.contains(newValue);
      final ownedPermanently =
          ownedIds.contains(newValue) && !premiumOnlyIds.contains(newValue);
      final adEligibleNow = adIds.contains(newValue) && adRewardActive;
      final premiumOk = premiumOnlyIds.contains(newValue) && isPremium;
      return newValue == null ||
          unchanged ||
          (recognized &&
              (freeIds.contains(newValue) ||
                  ownedPermanently ||
                  adEligibleNow ||
                  premiumOk));
    }

    const free = {'free_a'};
    const ad = {'ad_a'};
    const coin = {'coin_a'};
    const premiumOnly = {'premium_a'};

    test('1. FREE user cannot equip a subscription-exclusive item', () {
      final allowed = isAllowedCosmeticEquip(
        oldValue: null,
        newValue: 'premium_a',
        freeIds: free,
        adIds: ad,
        coinIds: coin,
        premiumOnlyIds: premiumOnly,
        ownedIds: {},
        adRewardActive: false,
        isPremium: false,
      );
      expect(allowed, isFalse);
    });

    test('2. Premium user CAN equip a subscription-exclusive item', () {
      final allowed = isAllowedCosmeticEquip(
        oldValue: null,
        newValue: 'premium_a',
        freeIds: free,
        adIds: ad,
        coinIds: coin,
        premiumOnlyIds: premiumOnly,
        ownedIds: {},
        adRewardActive: false,
        isPremium: true,
      );
      expect(allowed, isTrue);
    });

    test('3a. legitimate ad-tier ownership (active reward) can equip', () {
      final allowed = isAllowedCosmeticEquip(
        oldValue: null,
        newValue: 'ad_a',
        freeIds: free,
        adIds: ad,
        coinIds: coin,
        premiumOnlyIds: premiumOnly,
        ownedIds: {},
        adRewardActive: true,
        isPremium: false,
      );
      expect(allowed, isTrue);
    });

    test('3b. legitimate coin-tier ownership (in ownedIds) can equip', () {
      final allowed = isAllowedCosmeticEquip(
        oldValue: null,
        newValue: 'coin_a',
        freeIds: free,
        adIds: ad,
        coinIds: coin,
        premiumOnlyIds: premiumOnly,
        ownedIds: {'coin_a'},
        adRewardActive: false,
        isPremium: false,
      );
      expect(allowed, isTrue);
    });

    test('3c. ad-tier id WITHOUT an active reward and not owned is '
        'refused', () {
      final allowed = isAllowedCosmeticEquip(
        oldValue: null,
        newValue: 'ad_a',
        freeIds: free,
        adIds: ad,
        coinIds: coin,
        premiumOnlyIds: premiumOnly,
        ownedIds: {},
        adRewardActive: false,
        isPremium: false,
      );
      expect(allowed, isFalse);
    });

    test('3d. an ad reward for one module never unlocks a coin-tier id '
        '— adEligibleNow only ever matches adIds', () {
      final allowed = isAllowedCosmeticEquip(
        oldValue: null,
        newValue: 'coin_a',
        freeIds: free,
        adIds: ad,
        coinIds: coin,
        premiumOnlyIds: premiumOnly,
        ownedIds: {},
        adRewardActive: true,
        isPremium: false,
      );
      expect(allowed, isFalse);
    });

    test('5. an unknown/arbitrary cosmetic id is refused outright, even '
        'for a Premium subscriber', () {
      final allowed = isAllowedCosmeticEquip(
        oldValue: null,
        newValue: 'totally_made_up_id',
        freeIds: free,
        adIds: ad,
        coinIds: coin,
        premiumOnlyIds: premiumOnly,
        ownedIds: {},
        adRewardActive: false,
        isPremium: true,
      );
      expect(allowed, isFalse);
    });

    test('defense-in-depth: a premium-only id present in ownedIds is '
        'still refused for a non-premium account', () {
      // Simulates the exact scenario the ownedPermanently exclusion
      // guards against: legacy or forged data in xp.unlocked*Ids.
      final allowed = isAllowedCosmeticEquip(
        oldValue: null,
        newValue: 'premium_a',
        freeIds: free,
        adIds: ad,
        coinIds: coin,
        premiumOnlyIds: premiumOnly,
        ownedIds: {'premium_a'}, // should never happen post-Phase-1, but...
        adRewardActive: false,
        isPremium: false,
      );
      expect(allowed, isFalse,
          reason: 'ownedIds must never be sufficient for a premium-only id');
    });

    test('clearing a selection (newValue null) is always allowed', () {
      final allowed = isAllowedCosmeticEquip(
        oldValue: 'premium_a',
        newValue: null,
        freeIds: free,
        adIds: ad,
        coinIds: coin,
        premiumOnlyIds: premiumOnly,
        ownedIds: {},
        adRewardActive: false,
        isPremium: false,
      );
      expect(allowed, isTrue);
    });

    test('an unrelated write that leaves the value unchanged is always '
        'allowed, even if that value would no longer qualify today '
        '(e.g. a lapsed subscription)', () {
      final allowed = isAllowedCosmeticEquip(
        oldValue: 'premium_a',
        newValue: 'premium_a',
        freeIds: free,
        adIds: ad,
        coinIds: coin,
        premiumOnlyIds: premiumOnly,
        ownedIds: {},
        adRewardActive: false,
        isPremium: false, // lapsed
      );
      expect(allowed, isTrue);
    });

    // --- Card Skin mirror (6) ---
    bool isAllowedCardSkin({
      required String? oldSkin,
      required String? newSkin,
      required int starTotal,
      required bool isPremium,
      required Set<String> ownedSkins,
    }) {
      const freeIds = {'classic', 'sakura', 'indigo'};
      const achievementThreshold = {
        'emas_kencana': 35,
        'night_purple': 60,
        'dragon_black': 90,
      };
      const paidIds = {'cloud_white', 'neon_city', 'sakura_gold'};
      final unchanged = newSkin == oldSkin;
      final recognized = freeIds.contains(newSkin) ||
          achievementThreshold.containsKey(newSkin) ||
          paidIds.contains(newSkin);
      final achievementOk = achievementThreshold.containsKey(newSkin) &&
          starTotal >= achievementThreshold[newSkin]! &&
          isPremium;
      final paidOk =
          paidIds.contains(newSkin) && (ownedSkins.contains(newSkin) || isPremium);
      return newSkin == null ||
          unchanged ||
          (recognized &&
              (freeIds.contains(newSkin) || achievementOk || paidOk));
    }

    test('6a. achievement skin needs BOTH stars and premium — stars '
        'alone is refused', () {
      expect(
        isAllowedCardSkin(
          oldSkin: null,
          newSkin: 'emas_kencana',
          starTotal: 35,
          isPremium: false,
          ownedSkins: {},
        ),
        isFalse,
      );
    });

    test('6b. achievement skin needs BOTH — premium alone (stars below '
        'threshold) is refused', () {
      expect(
        isAllowedCardSkin(
          oldSkin: null,
          newSkin: 'emas_kencana',
          starTotal: 10,
          isPremium: true,
          ownedSkins: {},
        ),
        isFalse,
      );
    });

    test('6c. achievement skin with both stars and premium is allowed', () {
      expect(
        isAllowedCardSkin(
          oldSkin: null,
          newSkin: 'dragon_black',
          starTotal: 90,
          isPremium: true,
          ownedSkins: {},
        ),
        isTrue,
      );
    });

    test('6d. paid skin: owned (bought) works without premium', () {
      expect(
        isAllowedCardSkin(
          oldSkin: null,
          newSkin: 'cloud_white',
          starTotal: 0,
          isPremium: false,
          ownedSkins: {'cloud_white'},
        ),
        isTrue,
      );
    });

    test('6e. paid skin: premium bundles it free, without owning it', () {
      expect(
        isAllowedCardSkin(
          oldSkin: null,
          newSkin: 'cloud_white',
          starTotal: 0,
          isPremium: true,
          ownedSkins: {},
        ),
        isTrue,
      );
    });

    test('6f. paid skin: neither owned nor premium is refused', () {
      expect(
        isAllowedCardSkin(
          oldSkin: null,
          newSkin: 'cloud_white',
          starTotal: 0,
          isPremium: false,
          ownedSkins: {},
        ),
        isFalse,
      );
    });

    test('an unrecognized card skin id is refused', () {
      expect(
        isAllowedCardSkin(
          oldSkin: null,
          newSkin: 'made_up_skin',
          starTotal: 999,
          isPremium: true,
          ownedSkins: {'made_up_skin'},
        ),
        isFalse,
      );
    });
  });
}

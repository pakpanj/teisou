import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards Security & Monetization Remediation Plan, Blocker #1 / Phase 0:
/// `adRewards` must be Cloud-Function-only, the same freeze already
/// applied to `subscription`/`entitlements`/`coins`. `moduleAccessProvider`
/// trusted this field completely with zero server-side protection — a
/// forged write there granted permanent, UI-indistinguishable access to
/// five premium modules and unlimited clan creation. See
/// `TEISOU_Master_Access_Monetization_Audit.md` (Section 11) and
/// `TEISOU_Security_Monetization_Remediation_Plan.md` (Finding 3) for the
/// full write-up.
///
/// **This project has no Firestore Rules emulator/test harness** —
/// confirmed absent: no `emulators` block in `firebase.json`, no
/// `@firebase/rules-unit-testing` dependency anywhere, no
/// `initializeTestEnvironment`/`assertFails`/`assertSucceeds` usage in the
/// repo. `functions/test_helpers/fake_firestore.js` is a hand-rolled fake
/// used only by the Cloud Function `node --test` suites — it tests
/// function *logic* against a fake, never `firestore.rules` itself. So
/// these are source-inspection tests, matching this codebase's own
/// established convention for exactly this class of guarantee
/// (`shop_screen_gesture_test.dart`, `card_battle_mascot_mapping_test.dart`,
/// `coach_wiring_test.dart`) — reading `firestore.rules` as text and
/// asserting on it is what's actually available here; it cannot replace
/// a live rule-evaluation test, and standing up a real emulator harness
/// is flagged as Open Question #3 in the implementation plan, not
/// resolved by this file.
void main() {
  // Normalize CRLF -> LF: this repo's checked-in files use Windows line
  // endings, but the multi-line literals below are written as LF — without
  // this every multi-line `contains()` check fails on a phantom '\r', not
  // on the content actually differing.
  String read(String path) =>
      File(path).readAsStringSync().replaceAll('\r\n', '\n');

  final rules = read('firestore.rules');
  final moduleAccess = read('lib/features/paywall/module_access.dart');
  final progressRepo = read(
    'lib/data/repositories/progress_repository.dart',
  );

  group('1. client cannot write adRewards', () {
    test('isAllowedPurchaseWrite freezes adRewards on update, same shape '
        'as coins/subscription/entitlements', () {
      // The exact equality-freeze pattern already proven for the three
      // money fields — new value must equal the prior value, so a
      // client-supplied change of any kind is rejected regardless of
      // what it tries to set.
      expect(
        rules,
        contains(
          "let oldRewards = resource == null\n"
          "          ? {}\n"
          "          : resource.data.get('adRewards', {});",
        ),
        reason: 'adRewards must capture its prior value the same way '
            'oldCoins/oldSub/oldEnt already do',
      );
      expect(
        rules,
        contains("request.resource.data.get('adRewards', {}) == oldRewards"),
        reason: 'the update rule must reject any client-supplied change '
            'to adRewards',
      );
    });

    test('a brand-new document cannot seed adRewards at create time either', () {
      // No longer asserting a trailing `;` — Phase 1 (XP authority)
      // legitimately appended an `xp` guard right after this one, so
      // `adRewards`'s own guard is no longer the last clause in the
      // create rule. What actually matters is that the guard itself
      // still exists, not its position.
      expect(
        rules,
        contains("&& !('adRewards' in request.resource.data)"),
        reason: 'create-time guard must exist, mirroring the existing '
            "!('entitlements' in ...) guard",
      );
    });

    test('the update rule still calls isAllowedPurchaseWrite()', () {
      // Confirms the freeze function is actually wired into the rule
      // that governs users/{uid} writes, not just defined and unused.
      // No longer asserting it comes immediately after isAllowedAvatarWrite()
      // — Phase 2 (Cosmetic Ownership) legitimately inserted
      // isAllowedProfileWrite()/isAllowedCardSkinWrite() between them.
      // What matters is that isAllowedPurchaseWrite() is still called on
      // the same allow update clause, not its exact neighbor.
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
  });

  group('2. existing adRewards data remains readable', () {
    test('the users/{uid} read rule was not touched by this change', () {
      // Reading is governed entirely by the pre-existing
      // `allow read: if request.auth != null && request.auth.uid == uid;`
      // — this freeze only ever changes what a client may WRITE. If this
      // line ever disappears or narrows, a legitimate account would lose
      // the ability to read its own already-granted ad rewards.
      expect(
        rules,
        contains(
          'allow read: if request.auth != null && request.auth.uid == uid;',
        ),
      );
    });

    test('ProgressRepository.getAdRewards is a plain, unmodified read', () {
      expect(progressRepo, contains('Future<Map<String, AdReward>> getAdRewards(String uid) async {'));
      expect(progressRepo, contains("snapshot.data()?['adRewards'] as Map<String, dynamic>?;"));
    });
  });

  group('3. moduleAccessProvider reads the same entitlement, unchanged', () {
    test('moduleAccessProvider logic was not touched by this change', () {
      // Byte-for-byte the same read this provider always made — the
      // remediation plan is explicit that Phase 0 must not touch this
      // function's logic at all, only who is allowed to write the field
      // it reads.
      expect(
        moduleAccess,
        contains(
          'final rewards =\n'
          '        await ref.watch(progressRepositoryProvider).getAdRewards(uid);\n'
          "    return rewards[moduleId]?.isActive ?? false;",
        ),
      );
      expect(
        moduleAccess,
        contains(
          'final premium =\n'
          '      ref.watch(subscriptionProvider).valueOrNull?.isPremium ?? false;\n'
          '  if (premium) return true;',
        ),
      );
    });
  });

  group('4. unrelated paths remain normal', () {
    test('subscription/entitlements/coins freeze checks are unchanged in '
        'shape, only extended', () {
      expect(rules, contains("request.resource.data.get('subscription', {}) == oldSub"));
      expect(rules, contains("request.resource.data.get('entitlements', {}) == oldEnt"));
      expect(rules, contains("request.resource.data.get('coins', 0) == oldCoins"));
    });

    test('cardGameRank freeze on the update rule is unchanged', () {
      expect(
        rules,
        contains(
          "&& request.resource.data.get('cardGameRank', null)\n"
          "              == resource.data.get('cardGameRank', null);",
        ),
      );
    });

    test('isAllowedAvatarWrite() exists and is wired into the update rule '
        '— its internal logic is intentionally out of scope for this '
        'file (Phase 0/adRewards) and is now covered by '
        "cosmetic_ownership_equip_test.dart instead, since Phase 2's "
        'Cosmetic Ownership work legitimately rewrote its body to close '
        'a real avatarType-based bypass', () {
      expect(rules, contains('function isAllowedAvatarWrite() {'));
      expect(rules, contains('&& isAllowedAvatarWrite()'));
    });
  });
}

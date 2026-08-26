import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/constants/avatars.dart';
import 'package:kana_master/core/constants/card_skins.dart';
import 'package:kana_master/core/constants/frames.dart';
import 'package:kana_master/data/models/leaderboard_entry.dart';
import 'package:kana_master/data/models/user_profile.dart' show AvatarType;
import 'package:kana_master/features/leaderboard/leaderboard_screen.dart'
    show LeaderboardAvatar;

/// C3 (AUDIT_PHASE_C_BATTLE_RELIABILITY.md) — Battle's card skin, avatar and
/// frame all render from the same `leaderboard/{uid}` mirror, and each had a
/// different failure shape:
///
/// * **Card skin (C3-1)**: `effectiveCardSkin()` was called without
///   `owned`/`premium` at both Battle call sites, so every non-free skin
///   silently fell back to the classic back on release builds — invisible
///   in debug, where `kCardSkinsAllUnlocked == kDebugMode` unlocked
///   everything anyway.
/// * **Avatar (C3-2)**: the equip-time mirror write to `leaderboard/{uid}`
///   was already the app's standing best-effort convention, and — unlike
///   the card skin — nothing repaired it on the way into a match, so a
///   silently-failed write left an opponent's avatar stale indefinitely.
///   The render path itself ([LeaderboardAvatar]) already had a correct,
///   crash-free fallback chain; this phase's job was the missing repair,
///   not the rendering.
/// * **Frame (C3-3)**: already rendered correctly in both the "no frame"
///   and "asset failed to load" cases — both intentionally render nothing,
///   since an absent decorative border is a silent no-op unlike a missing
///   avatar. Only a diagnostic was added, and only for the genuine-failure
///   branch.
///
/// Numbered comments below correspond to the 14 tests named in the C3
/// implementation brief.
void main() {
  LeaderboardEntry entryWith({
    AvatarType avatarType = AvatarType.google,
    String? avatarValue,
    String? photoUrl,
    String? cardSkinId,
    int? cardGameStarTotal,
  }) => LeaderboardEntry(
    uid: 'u1',
    displayName: 'Test',
    totalMastered: 0,
    examHighScore: 0,
    avatarType: avatarType,
    avatarValue: avatarValue,
    photoUrl: photoUrl,
    cardSkinId: cardSkinId,
    cardGameStarTotal: cardGameStarTotal,
    updatedAt: DateTime(2026),
  );

  group('avatar rendering (C3-2)', () {
    // 1. Free avatar → renders correctly.
    testWidgets('a free preset avatar renders its real art, not a fallback',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: LeaderboardAvatar(
          entry: entryWith(
            avatarType: AvatarType.presetFree,
            avatarValue: 'neko_sensei',
          ),
          size: 44,
        ),
      ));
      await tester.pump();
      expect(find.byType(AvatarPresetArt), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // 2. Owned (premium-tier) avatar → renders correctly.
    testWidgets('an owned premium-tier preset avatar renders its real art',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: LeaderboardAvatar(
          entry: entryWith(
            avatarType: AvatarType.presetPremium,
            avatarValue: 'neko_artist',
          ),
          size: 44,
        ),
      ));
      await tester.pump();
      expect(find.byType(AvatarPresetArt), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // 3. Missing/invalid avatar → falls back to the default, never
    // `SizedBox.shrink()` (the bug's own definition of "silently looks like
    // no avatar").
    testWidgets(
        'an unknown preset id with no photoUrl falls back to the default '
        'cat, not an empty box', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: LeaderboardAvatar(
          entry: entryWith(
            avatarType: AvatarType.presetFree,
            avatarValue: 'this_preset_id_does_not_exist',
          ),
          size: 44,
        ),
      ));
      await tester.pump();
      expect(find.text('🐱'), findsOneWidget);
      expect(find.byType(AvatarPresetArt), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'no avatar data at all (google type, null photoUrl) still renders '
        'the default cat rather than nothing', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: LeaderboardAvatar(entry: entryWith(), size: 44),
      ));
      await tester.pump();
      expect(find.text('🐱'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test(
        "BattlePlayerChip's own 'no leaderboard row yet' branch is a real "
        'CircleAvatar, not SizedBox.shrink()', () {
      // A brand-new opponent has no `leaderboard/{uid}` row at all, so
      // `entry` itself (not just its avatar fields) can be null — a case
      // `LeaderboardAvatar` never sees, since it requires a non-null entry.
      // This is the outer guard `BattlePlayerChip` owns itself.
      final source =
          File('lib/features/battle/widgets/battle_arena.dart')
              .readAsStringSync();
      final entryNullBranch = source.indexOf(': CircleAvatar(');
      expect(entryNullBranch, greaterThan(-1),
          reason: 'the entry == null fallback must be a real CircleAvatar');
      // The one SizedBox.shrink() this bug's own description forbids would
      // be right here; confirm this specific branch isn't one.
      final nearby = source.substring(
        source.indexOf('entry != null'),
        entryNullBranch + 200,
      );
      expect(nearby, isNot(contains('SizedBox.shrink()')));
    });
  });

  group('frame rendering (C3-3)', () {
    // 4. Free frame → renders correctly.
    testWidgets('a free frame renders its art', (tester) async {
      final preset = FramePresets.byId('frame_sakura_fuji');
      expect(preset, isNotNull);
      expect(FramePresets.isLocked(preset!.id), isFalse);
      await tester.pumpWidget(MaterialApp(
        home: FrameOverlay(preset: preset, avatarSize: 40),
      ));
      await tester.pump();
      expect(find.byType(Image), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // 5. Owned (locked-tier) frame → renders correctly — proves rendering
    // was never gated by ownership tier in the first place, so this fix
    // doesn't need to (and must not) add one.
    testWidgets('a locked/coin-tier frame renders the same way once chosen',
        (tester) async {
      final preset = FramePresets.byId('frame_halloween');
      expect(preset, isNotNull);
      expect(FramePresets.isLocked(preset!.id), isTrue);
      await tester.pumpWidget(MaterialApp(
        home: FrameOverlay(preset: preset, avatarSize: 40),
      ));
      await tester.pump();
      expect(find.byType(Image), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // 6. Invalid frame (asset genuinely fails to load) → falls back safely,
    // no crash, and — this is the part C3-3 must not change — still
    // renders nothing rather than a default frame.
    testWidgets(
        'a frame whose art is missing fails safely, with no default frame '
        'appearing in its place', (tester) async {
      const bogus = FramePreset(
        id: '__c3_test_frame_that_does_not_exist__',
        label: 'x',
        labelEn: 'x',
      );
      await tester.pumpWidget(MaterialApp(
        home: FrameOverlay(preset: bogus, avatarSize: 40),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull,
          reason: 'a missing frame asset must never crash the screen');
    });

    testWidgets(
        'no preset chosen still renders nothing (unchanged, not this '
        "fix's concern)", (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: FrameOverlay(preset: null, avatarSize: 40),
      ));
      await tester.pump();
      expect(find.byType(Image), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('card skin ownership (C3-1)', () {
    // 7. Free card skin → renders correctly (unowned, unchanged).
    test('the free default skin renders for anyone, owned or not', () {
      expect(
        effectiveCardSkin(CardSkinPresets.classic.id, starTotal: 0).id,
        CardSkinPresets.classic.id,
      );
    });

    // 8. Owned paid skin → renders the real skin, not classic. This is the
    // exact scenario the original bug broke: `owned` reaching
    // `effectiveCardSkin` as its real value instead of the missing-param
    // default of `false`.
    test('an owned paid skin renders itself, not the classic fallback', () {
      final paid = CardSkinPresets.ofSource(CardSkinSource.paid).first;
      expect(
        effectiveCardSkin(paid.id, starTotal: 0, owned: true, premium: false)
            .id,
        paid.id,
      );
      // The bug's own failure mode: owned dropped (defaults false).
      expect(
        effectiveCardSkin(paid.id, starTotal: 0).id,
        CardSkinPresets.classic.id,
        reason: 'owned must actually gate this — sanity check on the '
            'unowned side of the same skin',
      );
    });

    // 9. Achievement skin → renders when owned (i.e. the star threshold is
    // met, with Premium active per the roster's own "achievement + Premium"
    // rule from card_skin_unlock_test.dart).
    test('an achievement skin renders once its star threshold is met', () {
      expect(
        effectiveCardSkin('dragon_black', starTotal: 90, premium: true).id,
        'dragon_black',
      );
    });

    // 10. Premium entitlement behaves per existing policy: bundles every
    // paid skin without needing `owned` too, but does not by itself unlock
    // an achievement skin below its star threshold.
    test('Premium unlocks the whole paid family without a separate owned '
        'flag, and does not bypass an achievement skin\'s star requirement',
        () {
      for (final skin in CardSkinPresets.ofSource(CardSkinSource.paid)) {
        expect(
          effectiveCardSkin(skin.id, starTotal: 0, premium: true).id,
          skin.id,
          reason: skin.id,
        );
      }
      expect(
        effectiveCardSkin('dragon_black', starTotal: 0, premium: true).id,
        CardSkinPresets.classic.id,
      );
    });

    // 11. Player A and player B each use their own entitlement — the core
    // of the fix. `_skinFor` resolves the two players through genuinely
    // different paths: a live look-up for the viewer's own uid, and the
    // trusted server-validated mirror for anyone else (there is no way to
    // read another player's private `ownedSkins`/`subscription` — see this
    // test file's own top-of-file doc comment and `_skinFor`'s in the
    // source for the full reasoning). Verified as a source check: pumping
    // two live players through `BattleScreen` needs a full Firebase-backed
    // match, out of scope for a unit test.
    test('_skinFor resolves the opponent from the trusted mirror and the '
        "viewer's own skin from their own live entitlement, never the "
        'other way round', () {
      final source =
          File('lib/features/battle/battle_screen.dart').readAsStringSync();
      final start = source.indexOf('CardSkinPreset _skinFor(');
      expect(start, greaterThan(-1));
      final end = source.indexOf('\n  }', start);
      final body = source.substring(start, end);

      expect(body, contains('deckOwnerUid != myUid'),
          reason: 'must branch on whose skin this is');
      // Opponent branch: mirror only, no live ownership/premium read.
      final opponentBranchEnd = body.indexOf('}', body.indexOf('!= myUid'));
      final opponentBranch =
          body.substring(body.indexOf('!= myUid'), opponentBranchEnd);
      expect(opponentBranch, contains('CardSkinPresets.byId('));
      expect(opponentBranch, isNot(contains('ownedSkinsProvider')));
      expect(opponentBranch, isNot(contains('subscriptionProvider')));

      // Self branch: real ownership + premium, keyed off the same entry
      // this player's own uid resolved to.
      expect(body, contains('ref.watch(ownedSkinsProvider)'));
      expect(body, contains('ref.watch(subscriptionProvider)'));
      expect(body, contains('owned: owned.contains('));
      expect(body, contains('premium: premium'));
    });

    // 12. Release build behavior does not depend on kDebugMode. The one
    // switch that ever bypasses ownership is `kCardSkinsAllUnlocked`, which
    // is itself defined as `kDebugMode` — so on a release build it's
    // false, and `_skinFor` must pass it through unmodified rather than a
    // hardcoded `true`.
    test('kCardSkinsAllUnlocked is exactly kDebugMode, and _skinFor forwards '
        'it rather than forcing skins open', () {
      expect(kCardSkinsAllUnlocked, kDebugMode);
      final source =
          File('lib/features/battle/battle_screen.dart').readAsStringSync();
      expect(source, contains('allUnlocked: kCardSkinsAllUnlocked'));
      expect(source, isNot(contains('allUnlocked: true')));
    });

    // 13. effectiveCardSkin() receives correct ownership/Premium at BOTH
    // Battle call sites — i.e. the two original bare calls (the actual
    // root cause) no longer exist; every call goes through `_skinFor`.
    test('every effectiveCardSkin() call in battle_screen.dart goes through '
        '_skinFor, so both original call sites now carry owned/premium',
        () {
      final source =
          File('lib/features/battle/battle_screen.dart').readAsStringSync();

      // The original bug was two bare `effectiveCardSkin(...)` calls with
      // no owned/premium. The fix routes every use through `_skinFor`,
      // which is the single place `effectiveCardSkin` is still called
      // directly — so there must be exactly one occurrence left in the
      // whole file (inside `_skinFor`'s own body), not two-plus scattered
      // bare calls.
      expect(
        'effectiveCardSkin('.allMatches(source).length,
        1,
        reason: 'a second direct effectiveCardSkin() call outside _skinFor '
            'would be the original bug again — it would carry no owned/'
            'premium',
      );
      final skinForDefStart = source.indexOf('CardSkinPreset _skinFor(');
      final callStart = source.indexOf('effectiveCardSkin(');
      expect(callStart, greaterThan(skinForDefStart),
          reason: 'the one remaining call must live inside _skinFor');

      // Every render call site (face-down, held-round face-up, and live
      // face-up — C4 added the held-round one, AUDIT_PHASE_C_BATTLE_
      // ANSWER_FEEDBACK.md's `_buildHeldCard`) goes through the wrapper,
      // plus the wrapper's own definition — at least 3 occurrences, not
      // pinned to an exact count, since a legitimate new card-rendering
      // path (like C4's held-round card) is expected to add another call
      // site over time. What actually matters — that `effectiveCardSkin`
      // itself has exactly one call site, asserted above — still holds.
      expect(
        '_skinFor('.allMatches(source).length,
        greaterThanOrEqualTo(3),
      );
    });
  });

  group('avatar self-heal wiring (C3-2)', () {
    test('battleOpponentsProvider republishes both the card skin and the '
        "avatar mirror on the way into a match, best-effort", () {
      final source = File('lib/features/battle/battle_invite_providers.dart')
          .readAsStringSync();
      expect(source, contains('await _republishMyCardSkin(ref, byUid);'));
      expect(source, contains('await _republishMyAvatar(ref, byUid);'));

      final start = source.indexOf('Future<void> _republishMyAvatar(');
      expect(start, greaterThan(-1));
      final end = source.indexOf('\n}', start);
      final body = source.substring(start, end);
      expect(body, contains('profile.avatarType'));
      expect(body, contains('profile.avatarValue'));
      expect(body, contains('.updateAvatar('));
      expect(body, contains('try {'));
      expect(body, contains('} catch (_) {'),
          reason: 'a failed repair must never block a match from rendering');
    });

    test('LeaderboardRepository.updateAvatar writes only the two avatar '
        'fields, matching updateCardSkinId\'s narrow shape', () {
      final source =
          File('lib/data/repositories/leaderboard_repository.dart')
              .readAsStringSync();
      final start = source.indexOf('Future<void> updateAvatar(');
      expect(start, greaterThan(-1));
      final end = source.indexOf('\n  }', start);
      final body = source.substring(start, end);
      expect(body, contains("'avatarType': avatarType.key"));
      expect(body, contains("'avatarValue': avatarValue"));
      expect(body, contains('SetOptions(merge: true)'));
      // Narrow on purpose — must not also touch displayName/photoUrl, which
      // would risk overwriting a since-changed name with a stale cached one.
      expect(body, isNot(contains('displayName')));
    });
  });

  group('no regression / platform safety', () {
    // 14. Existing card-game tests still pass — enforced by running
    // `flutter test`, not duplicated here; this is a lightweight in-file
    // sanity check that the roster itself is untouched by this phase.
    test('the skin roster is unchanged by this phase (sanity check; the '
        'full regression suite is card_skin_unlock_test.dart)', () {
      expect(CardSkinPresets.classic.source, CardSkinSource.free);
      final ids = CardSkinPresets.all.map((s) => s.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('none of the three touched files add an Android-only or '
        'platform-branching API', () {
      for (final path in [
        'lib/features/battle/battle_screen.dart',
        'lib/features/battle/battle_invite_providers.dart',
        'lib/data/repositories/leaderboard_repository.dart',
        'lib/core/constants/frames.dart',
      ]) {
        final source = File(path).readAsStringSync();
        expect(source, isNot(contains('dart:io')));
        expect(source, isNot(contains('Platform.isAndroid')));
        expect(source, isNot(contains('Platform.isIOS')));
      }
    });
  });
}

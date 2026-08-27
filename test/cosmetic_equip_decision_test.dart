import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/constants/avatars.dart';
import 'package:kana_master/core/constants/card_skins.dart';
import 'package:kana_master/core/constants/covers.dart';
import 'package:kana_master/core/constants/frames.dart';
import 'package:kana_master/core/providers.dart';
import 'package:kana_master/data/models/ad_reward.dart';
import 'package:kana_master/data/models/subscription.dart';
import 'package:kana_master/data/models/user_profile.dart';
import 'package:kana_master/data/repositories/progress_repository.dart';
import 'package:kana_master/features/battle/card_skin_picker_screen.dart';
import 'package:kana_master/features/leaderboard/leaderboard_providers.dart';
import 'package:kana_master/features/paywall/paywall_screen.dart';
import 'package:kana_master/features/profile/widgets/avatar_picker_sheet.dart';
import 'package:kana_master/features/profile/widgets/cover_picker_sheet.dart';

/// Regression coverage for F1 (AUDIT_COSMETIC_PROFILE_SHOP.md): the exact
/// tap-to-equip *decision path* in all four cosmetic pickers — Avatar,
/// Frame, Cover, Card Skin — the thing that broke for Frame ("owned/free
/// tapped -> Paywall opened instead of equipping") and had **no** test
/// anywhere to catch it.
///
/// **What this file does NOT do, on purpose**: it never calls
/// `isLocked`/`frameIdUnlocked`/`isCardSkinUnlocked` etc. directly — those
/// pure functions are already covered by `cosmetic_tier_test.dart`/
/// `card_skin_unlock_test.dart`, and the whole point of the Frame bug is
/// that the widget's own tap handler stopped calling the *right* one of
/// them. Every test below drives the real, rendered picker widget with
/// `tester.tap()` on the exact tile a learner would tap, then asserts on
/// the two externally-observable effects that decision actually has: did
/// the equip write reach the repository (the picker's own definition of
/// "equipped" — `profile.avatarType`/`avatarValue`/`frameId`/`coverId`/
/// `cardSkinId` is *only* ever set by that write), and did a
/// [PaywallScreen] appear. A live [_ProfileHub] additionally feeds the
/// exact same write back into an overridden `userProfileProvider`, so a
/// successful equip is also visible as the tile's own check-mark moving —
/// not just an isolated repository-call assertion.
void main() {
  // GridViews here are `shrinkWrap: true` inside a plain
  // `SingleChildScrollView` (no Sliver-clipped viewport), so a tap on a
  // preset far down the catalog (e.g. avatar #18 of 20) only hit-tests
  // correctly if the whole thing actually fits in the test surface — a
  // default 800x600 surface clips it. Enlarged for every test in this
  // file and restored after, the standard fix for "tap on a widget below
  // the fold" in flutter_test.
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  Future<void> withTallSurface(
    WidgetTester tester,
    Future<void> Function() body,
  ) async {
    tester.view.physicalSize = const Size(1200, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await body();
  }

  group('Avatar picker', () {
    testWidgets('free avatar: tap equips, no Paywall, tile becomes selected', (
      tester,
    ) async {
      await withTallSurface(tester, () async {
        final hub = _ProfileHub(_profile());
        final repo = _FakeProgressRepository(hub);
        await tester.pumpWidget(
          await _harness(
            hub: hub,
            repo: repo,
            child: const AvatarPickerBody(popOnSelect: false, shopMode: true),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Guru')); // neko_sensei, free
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(repo.calls, contains('updateAvatar:preset_free:neko_sensei'));
        expect(
          find.byType(PaywallScreen),
          findsNothing,
          reason:
              'a free avatar must equip directly, never open the '
              'paywall — this is the exact shape of the Frame bug',
        );
        expect(hub.profile.avatarType, AvatarType.presetFree);
        expect(hub.profile.avatarValue, 'neko_sensei');
        _expectTileSelected(tester, 'Guru');
      });
    });

    testWidgets('premium-only avatar: tap opens Paywall, never equips', (
      tester,
    ) async {
      await withTallSurface(tester, () async {
        final hub = _ProfileHub(_profile());
        final repo = _FakeProgressRepository(hub);
        await tester.pumpWidget(
          await _harness(
            hub: hub,
            repo: repo,
            child: const AvatarPickerBody(popOnSelect: false, shopMode: true),
          ),
        );
        await tester.pumpAndSettle();

        expect(AvatarPresets.isPremiumOnly('neko_astronaut'), isTrue);
        await tester.tap(find.text('Astronot')); // neko_astronaut
        // Not pumpAndSettle: PaywallScreen may run a periodic poll
        // (`_pollForGrant`) that reschedules frames forever, which would
        // make pumpAndSettle hang — a bounded number of plain pumps is
        // enough for the push transition to complete.
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          find.byType(PaywallScreen),
          findsOneWidget,
          reason: 'a premium-only, unowned avatar must route to Premium',
        );
        expect(
          repo.calls,
          isEmpty,
          reason:
              'nothing must be written until the paywall is actually '
              'cleared',
        );
        expect(hub.profile.avatarValue, isNot('neko_astronaut'));
      });
    });

    testWidgets(
      'ad-reward-unlocked avatar: equips directly, no Paywall, reward '
      'consumed',
      (tester) async {
        await withTallSurface(tester, () async {
          final hub = _ProfileHub(_profile());
          final repo = _FakeProgressRepository(hub)
            ..adRewards = {
              'avatar_premium': AdReward.unlockNow('avatar_premium'),
            };
          await tester.pumpWidget(
            await _harness(
              hub: hub,
              repo: repo,
              child: const AvatarPickerBody(popOnSelect: false, shopMode: true),
            ),
          );
          await tester
              .pumpAndSettle(); // let _refreshAdRewardStatus's Futures settle

          expect(AvatarPresets.isAdUnlockable('neko_chef'), isTrue);
          await tester.tap(find.text('Koki')); // neko_chef, ad-tier
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(repo.calls, contains('updateAvatar:preset_premium:neko_chef'));
          expect(find.byType(PaywallScreen), findsNothing);
          expect(
            repo.consumedRewards,
            contains('avatar_premium'),
            reason: 'a single-use ad reward must be spent once acted on',
          );
        });
      },
    );

    testWidgets('coin/level-reward-unlocked avatar (xp.unlockedAvatarIds already '
        'has it): equips directly, no Paywall', (tester) async {
      // Deliberately the SAME assertion shape for both grants — `getUnlockedAvatarIds`
      // can't tell a coin purchase from a level-up reward apart (both land in
      // the identical `xp.unlockedAvatarIds` field, confirmed against
      // `spend_coins.js`/`award_xp.js`), so one test covers both mechanisms.
      await withTallSurface(tester, () async {
        final hub = _ProfileHub(_profile());
        final repo = _FakeProgressRepository(hub)
          ..unlockedAvatarIds = {'neko_artist'};
        await tester.pumpWidget(
          await _harness(
            hub: hub,
            repo: repo,
            child: const AvatarPickerBody(popOnSelect: false, shopMode: true),
          ),
        );
        await tester.pumpAndSettle();

        expect(AvatarPresets.isCoinUnlockable('neko_artist'), isTrue);
        await tester.tap(find.text('Seniman')); // neko_artist
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(repo.calls, contains('updateAvatar:preset_premium:neko_artist'));
        expect(find.byType(PaywallScreen), findsNothing);
      });
    });
  });

  group('Frame picker', () {
    // This is the exact scenario that was broken: `frameIdUnlocked` alone
    // (without `!FramePresets.isLocked` first) always says "no" for a free
    // frame, since a free id is never added to `_unlockedFrameIds`.
    testWidgets('free frame: tap equips, no Paywall, tile becomes selected', (
      tester,
    ) async {
      await withTallSurface(tester, () async {
        final hub = _ProfileHub(_profile());
        final repo = _FakeProgressRepository(hub);
        await tester.pumpWidget(
          await _harness(
            hub: hub,
            repo: repo,
            child: const FramePickerBody(popOnSelect: false, shopMode: true),
          ),
        );
        await tester.pumpAndSettle();

        expect(FramePresets.isLocked('frame_sakura_fuji'), isFalse);
        await tester.tap(find.text('Sakura & Fuji'));
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(repo.calls, contains('updateFrame:frame_sakura_fuji'));
        expect(
          find.byType(PaywallScreen),
          findsNothing,
          reason:
              'this is the bug that shipped: a free frame must never '
              'reach the paywall',
        );
        expect(hub.profile.frameId, 'frame_sakura_fuji');
        _expectTileSelected(tester, 'Sakura & Fuji');
      });
    });

    testWidgets('premium-only frame: tap opens Paywall, never equips', (
      tester,
    ) async {
      await withTallSurface(tester, () async {
        final hub = _ProfileHub(_profile());
        final repo = _FakeProgressRepository(hub);
        await tester.pumpWidget(
          await _harness(
            hub: hub,
            repo: repo,
            child: const FramePickerBody(popOnSelect: false, shopMode: true),
          ),
        );
        await tester.pumpAndSettle();

        expect(FramePresets.isPremiumOnly('frame_space'), isTrue);
        await tester.tap(find.text('Antariksa')); // frame_space
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(PaywallScreen), findsOneWidget);
        expect(repo.calls, isEmpty);
        expect(hub.profile.frameId, isNot('frame_space'));
      });
    });

    testWidgets('ad-reward-unlocked frame: equips directly, no Paywall, reward '
        'consumed', (tester) async {
      await withTallSurface(tester, () async {
        final hub = _ProfileHub(_profile());
        final repo = _FakeProgressRepository(hub)
          ..adRewards = {'frame_premium': AdReward.unlockNow('frame_premium')};
        await tester.pumpWidget(
          await _harness(
            hub: hub,
            repo: repo,
            child: const FramePickerBody(popOnSelect: false, shopMode: true),
          ),
        );
        await tester.pumpAndSettle();

        expect(FramePresets.isAdUnlockable('frame_ocean'), isTrue);
        await tester.tap(find.text('Bawah Laut')); // frame_ocean
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(repo.calls, contains('updateFrame:frame_ocean'));
        expect(find.byType(PaywallScreen), findsNothing);
        expect(repo.consumedRewards, contains('frame_premium'));
      });
    });

    testWidgets(
      'coin/level-reward-unlocked frame (xp.unlockedFrameIds already has '
      'it): equips directly, no Paywall',
      (tester) async {
        await withTallSurface(tester, () async {
          final hub = _ProfileHub(_profile());
          final repo = _FakeProgressRepository(hub)
            ..unlockedFrameIds = {'frame_halloween'};
          await tester.pumpWidget(
            await _harness(
              hub: hub,
              repo: repo,
              child: const FramePickerBody(popOnSelect: false, shopMode: true),
            ),
          );
          await tester.pumpAndSettle();

          expect(FramePresets.isCoinUnlockable('frame_halloween'), isTrue);
          await tester.tap(find.text('Halloween'));
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(repo.calls, contains('updateFrame:frame_halloween'));
          expect(find.byType(PaywallScreen), findsNothing);
        });
      },
    );
  });

  group('Cover picker', () {
    testWidgets('free cover: tap equips, no Paywall, tile becomes selected', (
      tester,
    ) async {
      await withTallSurface(tester, () async {
        final hub = _ProfileHub(_profile());
        final repo = _FakeProgressRepository(hub);
        await tester.pumpWidget(
          await _harness(
            hub: hub,
            repo: repo,
            child: const CoverPickerBody(popOnSelect: false, shopMode: true),
          ),
        );
        await tester.pumpAndSettle();

        expect(CoverPresets.isLocked('spring_meadow'), isFalse);
        await tester.tap(find.text('Padang Bunga')); // spring_meadow, free
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(repo.calls, contains('updateCover:spring_meadow'));
        expect(find.byType(PaywallScreen), findsNothing);
        expect(hub.profile.coverId, 'spring_meadow');
        _expectTileSelected(tester, 'Padang Bunga');
      });
    });

    testWidgets('premium-only cover: tap opens Paywall, never equips', (
      tester,
    ) async {
      await withTallSurface(tester, () async {
        final hub = _ProfileHub(_profile());
        final repo = _FakeProgressRepository(hub);
        await tester.pumpWidget(
          await _harness(
            hub: hub,
            repo: repo,
            child: const CoverPickerBody(popOnSelect: false, shopMode: true),
          ),
        );
        await tester.pumpAndSettle();

        expect(CoverPresets.isPremiumOnly('outer_space'), isTrue);
        await tester.tap(find.text('Antariksa')); // outer_space
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(PaywallScreen), findsOneWidget);
        expect(repo.calls, isEmpty);
        expect(hub.profile.coverId, isNot('outer_space'));
      });
    });

    testWidgets('ad-reward-unlocked cover: equips directly, no Paywall, reward '
        'consumed', (tester) async {
      await withTallSurface(tester, () async {
        final hub = _ProfileHub(_profile());
        final repo = _FakeProgressRepository(hub)
          ..adRewards = {'cover_premium': AdReward.unlockNow('cover_premium')};
        await tester.pumpWidget(
          await _harness(
            hub: hub,
            repo: repo,
            child: const CoverPickerBody(popOnSelect: false, shopMode: true),
          ),
        );
        await tester.pumpAndSettle();

        expect(CoverPresets.isAdUnlockable('coral_reef'), isTrue);
        await tester.tap(find.text('Terumbu Karang'));
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(repo.calls, contains('updateCover:coral_reef'));
        expect(find.byType(PaywallScreen), findsNothing);
        expect(repo.consumedRewards, contains('cover_premium'));
      });
    });

    testWidgets(
      'coin/level-reward-unlocked cover (xp.unlockedCoverIds already has '
      'it): equips directly, no Paywall',
      (tester) async {
        await withTallSurface(tester, () async {
          final hub = _ProfileHub(_profile());
          final repo = _FakeProgressRepository(hub)
            ..unlockedCoverIds = {'jungle_canopy'};
          await tester.pumpWidget(
            await _harness(
              hub: hub,
              repo: repo,
              child: const CoverPickerBody(popOnSelect: false, shopMode: true),
            ),
          );
          await tester.pumpAndSettle();

          expect(CoverPresets.isCoinUnlockable('jungle_canopy'), isTrue);
          await tester.tap(find.text('Rimba Tropis'));
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(repo.calls, contains('updateCover:jungle_canopy'));
          expect(find.byType(PaywallScreen), findsNothing);
        });
      },
    );
  });

  group('Card Skin picker', () {
    testWidgets(
      'free skin: tap switches to it, no Paywall, tile becomes selected',
      (tester) async {
        await withTallSurface(tester, () async {
          // Start on `classic` (also free) and switch to `sakura` — a real
          // change, not a no-op re-tap of the already-equipped skin.
          final hub = _ProfileHub(_profile(cardSkinId: 'classic'));
          final repo = _FakeProgressRepository(hub);
          await tester.pumpWidget(
            await _harness(
              hub: hub,
              repo: repo,
              child: const CardSkinPickerBody(),
            ),
          );
          await tester.pumpAndSettle();

          final sakura = CardSkinPresets.all.firstWhere(
            (s) => s.id == 'sakura' && s.source == CardSkinSource.free,
          );
          await tester.tap(find.text(sakura.label));
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(repo.calls, contains('updateCardSkin:sakura'));
          expect(
            find.byType(PaywallScreen),
            findsNothing,
            reason:
                'CardSkinPickerBody never pushes a Paywall route at '
                'all — a locked skin shows a requirement SnackBar instead '
                '(see the skipped test below); asserted here as a '
                'not-a-paywall sanity check on the free path',
          );
          expect(hub.profile.cardSkinId, 'sakura');
          _expectTileSelected(tester, sakura.label);
        });
      },
    );

    // **Honest scope note, not just a passing test**: this proves the
    // mechanical tap-to-equip wiring works for a *non-free-tier* tile
    // (`CardSkinPresets.ofSource(paid)`, id passed through to
    // `updateCardSkin` correctly) — it does **not** prove ownership
    // gating is enforced, because `kCardSkinsAllUnlocked` (== `kDebugMode`,
    // confirmed `true` under `flutter test`) makes every skin render and
    // behave as unlocked regardless of `ownedSkins`. Passing `ownedSkins:
    // {paid.id}` here documents the *intended* real-world precondition for
    // a reader, even though the widget doesn't actually need it to reach
    // this branch in this test environment. The gap this leaves — proving
    // an *unowned* paid skin is refused — is exactly the blocked test
    // right below.
    testWidgets(
      'a paid-tier skin still equips correctly through the same tap path '
      '(mechanical wiring, not an ownership-gating proof — see note '
      'above)',
      (tester) async {
        await withTallSurface(tester, () async {
          final hub = _ProfileHub(_profile(cardSkinId: 'classic'));
          final repo = _FakeProgressRepository(hub);
          final paid = CardSkinPresets.ofSource(CardSkinSource.paid).first;
          await tester.pumpWidget(
            await _harness(
              hub: hub,
              repo: repo,
              ownedSkins: {paid.id},
              child: const CardSkinPickerBody(),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.text(paid.label));
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(repo.calls, contains('updateCardSkin:${paid.id}'));
          // No SnackBar assertion here on purpose: unlike Avatar/Frame/
          // Cover, CardSkinPickerBody._select shows one on the *success*
          // path too (`s.cardSkinSaved`), not only when locked — so "a
          // SnackBar appeared" doesn't distinguish equip-succeeded from
          // equip-refused for this picker. `repo.calls`,
          // `hub.profile.cardSkinId`, and the moved check-mark below are
          // what actually prove the write happened.
          expect(hub.profile.cardSkinId, paid.id);
          _expectTileSelected(tester, paid.label);
        });
      },
    );

    // Documented architectural blocker, not a passing/faked test — see
    // AUDIT_COSMETIC_PROFILE_SHOP.md's F1 report. `CardSkinPickerBody`
    // computes `unlocked` from `isCardSkinUnlocked(..., allUnlocked:
    // kCardSkinsAllUnlocked)`, and `kCardSkinsAllUnlocked` is hardwired to
    // `kDebugMode` with no injection point — confirmed empirically that
    // `kDebugMode == true` under `flutter test`, so in *this* test
    // environment every skin renders and behaves as unlocked regardless of
    // star total / ownership / premium. There is no way to drive
    // `CardSkinPickerBody`'s real widget through its locked branch without
    // either running under a genuinely non-debug test harness (not
    // available for `flutter test`) or adding a test-only override to
    // production code — which this task explicitly forbids
    // ("jangan membuat production API baru hanya demi testing"). The
    // underlying decision function (`isCardSkinUnlocked` with
    // `allUnlocked: false`) is already covered thoroughly by
    // `card_skin_unlock_test.dart`; what is *not* covered, and cannot be
    // without a production change, is proving the real widget's tap
    // handler actually honors that function's answer in a build where
    // `kCardSkinsAllUnlocked` is false.
    test('the environmental fact behind the gap above: kCardSkinsAllUnlocked '
        'really is true in this test runner, not a hypothetical', () {
      // A real, passing assertion — not the blocked scenario itself. If a
      // future Flutter/test-runner change ever made `kDebugMode` false
      // under `flutter test`, this would start failing, which is exactly
      // the signal that the skipped test below could finally be un-skipped.
      expect(kCardSkinsAllUnlocked, isTrue);
    });

    // Left as a real, unabridged widget test (not a stub) — flipping
    // `skip` to `false` alone is enough to try it again if
    // `kCardSkinsAllUnlocked`'s wiring is ever revisited.
    //
    // Skip reason (`testWidgets`' `skip` only takes a bool, unlike
    // `test`'s): architectural blocker — `CardSkinPickerBody` computes
    // `unlocked` from `isCardSkinUnlocked(..., allUnlocked:
    // kCardSkinsAllUnlocked)`, and `kCardSkinsAllUnlocked` is hardwired to
    // `kDebugMode` with no injection point. Confirmed empirically (the
    // passing fact-check test above) that `kDebugMode == true` under
    // `flutter test`, so every skin renders/behaves as unlocked in this
    // environment regardless of star total, ownership, or premium — there
    // is no way to drive the real widget through its locked branch
    // without either a non-debug flutter test harness (not available) or
    // a test-only override added to production code (out of scope for
    // this task per its own instructions). `isCardSkinUnlocked` itself,
    // with `allUnlocked: false`, is already covered by
    // `card_skin_unlock_test.dart` — what is missing, and stays missing
    // until that production wiring changes, is proof that the real
    // widget honors it.
    testWidgets(
      'BLOCKED: unowned/below-threshold skin -> must not equip, must show '
      'a requirement message, never a Paywall',
      (tester) async {
        await withTallSurface(tester, () async {
          final hub = _ProfileHub(_profile(cardSkinId: 'classic'));
          final repo = _FakeProgressRepository(hub);
          final achievement = CardSkinPresets.ofSource(
            CardSkinSource.achievement,
          ).first;
          await tester.pumpWidget(
            await _harness(
              hub: hub,
              repo: repo,
              child: const CardSkinPickerBody(),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.text(achievement.label));
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(repo.calls, isEmpty);
          expect(
            find.byType(PaywallScreen),
            findsNothing,
            reason:
                'card skins never push a Paywall route; a locked one '
                'shows a requirement SnackBar instead',
          );
          expect(find.byType(SnackBar), findsOneWidget);
          expect(hub.profile.cardSkinId, isNot(achievement.id));
        });
      },
      skip: true,
    );
  });
}

// ---------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------

/// Builds a **pre-warmed** [ProviderContainer] and hands it to the widget
/// tree via [UncontrolledProviderScope], rather than letting `pumpWidget`
/// create a fresh `ProviderScope`/container on the fly.
///
/// **This is load-bearing, not a style choice — found by debugging real
/// test failures, not decided up front.** `CardSkinPickerBody` never
/// `ref.watch`es `appStartupProvider` in its own `build()` (only
/// `AvatarPickerBody`/`FramePickerBody`/`CoverPickerBody` do); it only
/// `ref.read`s it lazily inside `_select`, at tap time. Likewise, every
/// picker's `initState` (`_refreshAdRewardStatus`) fires *before* its own
/// first `build()`. A plain `ProviderScope` only starts resolving a
/// `FutureProvider` the moment something first reads it — so without this,
/// `appStartupProvider` is still `AsyncLoading` (`uid == null`) at the
/// exact synchronous instant either of those methods runs, and both bail
/// out silently (`if (uid == null) return;`) with no exception, no
/// SnackBar, and no repository call — which read, in an early version of
/// this file, exactly like a broken equip path, for entirely different
/// reasons than the Frame bug this file exists to catch. In the real app
/// this never happens (`appStartupProvider` is already resolved, cached,
/// long before any picker can be reached — every screen gates on it
/// first), so this is purely a widget-test artifact, not a production
/// bug — but it has to be worked around for these tests to mean anything.
/// A "pump a placeholder child first, then swap in the real widget"
/// two-step was tried and does **not** fix it: each `pumpWidget` call
/// building the overrides list fresh makes Riverpod treat it as a changed
/// override and reset the provider back to `AsyncLoading` anyway. Owning
/// the [ProviderContainer] directly and `await`ing
/// `container.read(appStartupProvider.future)` *before* the first
/// `pumpWidget` is the one approach that actually keeps the resolved
/// state — confirmed against both `AvatarPickerBody` and
/// `CardSkinPickerBody` before this went in.
Future<Widget> _harness({
  required _ProfileHub hub,
  required _FakeProgressRepository repo,
  required Widget child,
  Set<String> ownedSkins = const {},
}) async {
  final container = ProviderContainer(
    overrides: [
      appStartupProvider.overrideWith((ref) async => _FakeUser()),
      userProfileProvider.overrideWith((ref) => hub.stream),
      subscriptionProvider.overrideWith(
        (ref) => Stream.value(Subscription(tier: SubscriptionTier.free)),
      ),
      progressRepositoryProvider.overrideWithValue(repo),
      ownedSkinsProvider.overrideWith((ref) => Stream.value(ownedSkins)),
      selfLeaderboardEntryProvider.overrideWith((ref) async => null),
    ],
  );
  addTearDown(container.dispose);
  await container.read(appStartupProvider.future);

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: Scaffold(
        // No SingleChildScrollView here on purpose: `CardSkinPickerBody`
        // builds its own root `ListView` (it's normally the full-screen
        // content of Card Battle's Skin tab, not a sub-widget meant to
        // nest inside another scrollable) — wrapping it in one more
        // scrollable gives it an unbounded height and crashes
        // ("Vertical viewport was given unbounded height"). `Scaffold`'s
        // body already provides bounded constraints (matched to
        // `withTallSurface`'s huge test viewport below), which every one
        // of the four pickers' own content comfortably fits inside
        // without needing an extra scroll wrapper — the three
        // `Column`-rooted ones don't need a scrollable ancestor at all.
        body: child,
      ),
    ),
  );
}

UserProfile _profile({String? cardSkinId}) => UserProfile(
  isAnonymous: true,
  linkedGoogle: false,
  currentStreak: 0,
  cardSkinId: cardSkinId,
);

/// Asserts exactly one selected check-mark exists, and it belongs to the
/// tile whose caption is [label] — i.e. the equip write in [_ProfileHub]
/// actually flowed back through the overridden `userProfileProvider` and
/// moved the picker's own "Equipped" indicator, not just that a repository
/// method happened to be called.
void _expectTileSelected(WidgetTester tester, String label) {
  final tile = find
      .ancestor(of: find.text(label), matching: find.byType(InkWell))
      .first;
  expect(
    find.descendant(of: tile, matching: find.byIcon(Icons.check_circle)),
    findsOneWidget,
    reason:
        '$label must show as the picker\'s own Equipped indicator '
        'after a successful equip',
  );
}

class _ProfileHub {
  _ProfileHub(this.profile) {
    _controller.add(profile);
  }

  UserProfile profile;
  final _controller = StreamController<UserProfile>.broadcast();

  Stream<UserProfile> get stream => _controller.stream;

  void set(UserProfile Function(UserProfile) update) {
    profile = update(profile);
    _controller.add(profile);
  }
}

/// Real [ProgressRepository] surface, faked just for the handful of
/// methods each picker's `initState`/equip path actually calls — every
/// other member falls through to [noSuchMethod], which is never invoked
/// because these four widgets never call anything else on it. This is
/// deliberately an `implements`, not an `extends`: the real class's
/// constructor eagerly touches `FirebaseFirestore.instance`/
/// `FirebaseFunctions.instance` (there is no Firebase app in a widget
/// test), so subclassing it would throw before this object even exists.
class _FakeProgressRepository implements ProgressRepository {
  _FakeProgressRepository(this._hub);

  final _ProfileHub _hub;
  final List<String> calls = [];
  final List<String> consumedRewards = [];
  Map<String, AdReward> adRewards = {};
  Set<String> unlockedAvatarIds = {};
  Set<String> unlockedFrameIds = {};
  Set<String> unlockedCoverIds = {};

  @override
  Future<void> updateAvatar(String uid, AvatarType type, String? value) async {
    calls.add('updateAvatar:${type.key}:$value');
    _hub.set(
      (p) => UserProfile(
        displayName: p.displayName,
        isAnonymous: p.isAnonymous,
        linkedGoogle: p.linkedGoogle,
        currentStreak: p.currentStreak,
        customDisplayName: p.customDisplayName,
        avatarType: type,
        avatarValue: value,
        coverId: p.coverId,
        frameId: p.frameId,
        cardSkinId: p.cardSkinId,
        lastNameChangeAt: p.lastNameChangeAt,
        userId: p.userId,
      ),
    );
  }

  @override
  Future<void> updateFrame(String uid, String? frameId) async {
    calls.add('updateFrame:$frameId');
    _hub.set(
      (p) => UserProfile(
        displayName: p.displayName,
        isAnonymous: p.isAnonymous,
        linkedGoogle: p.linkedGoogle,
        currentStreak: p.currentStreak,
        customDisplayName: p.customDisplayName,
        avatarType: p.avatarType,
        avatarValue: p.avatarValue,
        coverId: p.coverId,
        frameId: frameId,
        cardSkinId: p.cardSkinId,
        lastNameChangeAt: p.lastNameChangeAt,
        userId: p.userId,
      ),
    );
  }

  @override
  Future<void> updateCover(String uid, String? coverId) async {
    calls.add('updateCover:$coverId');
    _hub.set(
      (p) => UserProfile(
        displayName: p.displayName,
        isAnonymous: p.isAnonymous,
        linkedGoogle: p.linkedGoogle,
        currentStreak: p.currentStreak,
        customDisplayName: p.customDisplayName,
        avatarType: p.avatarType,
        avatarValue: p.avatarValue,
        coverId: coverId,
        frameId: p.frameId,
        cardSkinId: p.cardSkinId,
        lastNameChangeAt: p.lastNameChangeAt,
        userId: p.userId,
      ),
    );
  }

  @override
  Future<void> updateCardSkin(String uid, String? cardSkinId) async {
    calls.add('updateCardSkin:$cardSkinId');
    _hub.set(
      (p) => UserProfile(
        displayName: p.displayName,
        isAnonymous: p.isAnonymous,
        linkedGoogle: p.linkedGoogle,
        currentStreak: p.currentStreak,
        customDisplayName: p.customDisplayName,
        avatarType: p.avatarType,
        avatarValue: p.avatarValue,
        coverId: p.coverId,
        frameId: p.frameId,
        cardSkinId: cardSkinId,
        lastNameChangeAt: p.lastNameChangeAt,
        userId: p.userId,
      ),
    );
  }

  @override
  Future<Map<String, AdReward>> getAdRewards(String uid) async => adRewards;

  @override
  Future<Set<String>> getUnlockedAvatarIds(String uid) async =>
      unlockedAvatarIds;

  @override
  Future<Set<String>> getUnlockedFrameIds(String uid) async => unlockedFrameIds;

  @override
  Future<Set<String>> getUnlockedCoverIds(String uid) async => unlockedCoverIds;

  @override
  Future<void> consumeAdReward(String uid, String moduleId) async {
    consumedRewards.add(moduleId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Minimal [User] double — only the four getters any of the four pickers
/// (or `PaywallScreen`) ever read are implemented; everything else falls
/// through to [noSuchMethod], same reasoning as [_FakeProgressRepository].
class _FakeUser implements User {
  @override
  String get uid => 'test-uid';
  @override
  bool get isAnonymous => true;
  @override
  String? get displayName => null;
  @override
  String? get photoURL => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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
import 'package:kana_master/data/models/unlocked_cosmetics.dart';
import 'package:kana_master/data/models/user_profile.dart';
import 'package:kana_master/data/repositories/progress_repository.dart';
import 'package:kana_master/features/battle/card_skin_picker_screen.dart';
import 'package:kana_master/features/leaderboard/leaderboard_providers.dart';
import 'package:kana_master/features/paywall/paywall_screen.dart';
import 'package:kana_master/features/profile/widgets/avatar_picker_sheet.dart';
import 'package:kana_master/features/profile/widgets/cover_picker_sheet.dart';

/// Regression coverage for two things found auditing the cosmetic
/// ownership/equip flow (AUDIT_COSMETIC_PROFILE_SHOP.md):
///
/// - **F1**: the tap-to-equip *decision path* in all four cosmetic
///   pickers — Avatar, Frame, Cover, Card Skin — the thing that broke for
///   Frame ("owned/free tapped -> Paywall opened instead of equipping")
///   and had no test anywhere to catch it.
/// - **BUG-1**: Toko's copies of the Avatar/Frame/Cover pickers are kept
///   alive for the app's whole session (`HomeScreen`'s `_KeepAlivePage`),
///   and used to load ownership once via a one-shot `Future` fetch in
///   `initState` — so a level-up reward granted through a different
///   screen (Home's "Klaim hadiah") never reached an already-mounted
///   Toko picker until the app restarted. See the `BUG-1 regression`
///   group below, and `unlockedCosmeticsProvider`'s own doc comment for
///   the production-side fix.
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
/// not just an isolated repository-call assertion. The BUG-1 group
/// similarly drives a live [_UnlockedCosmeticsHub] to simulate a
/// server-side grant landing mid-session, on the exact same widget
/// instance, with no `tester.pumpWidget` re-mount in between.
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
          final repo = _FakeProgressRepository(hub);
          final cosmetics = _UnlockedCosmeticsHub(
            adRewards: {'avatar_premium': AdReward.unlockNow('avatar_premium')},
          );
          await tester.pumpWidget(
            await _harness(
              hub: hub,
              repo: repo,
              cosmetics: cosmetics,
              child: const AvatarPickerBody(popOnSelect: false, shopMode: true),
            ),
          );
          await tester.pumpAndSettle();

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

    testWidgets(
      'coin/level-reward-unlocked avatar (xp.unlockedAvatarIds already '
      'has it): equips directly, no Paywall',
      (tester) async {
        // Deliberately the SAME assertion shape for both grants — the
        // provider can't tell a coin purchase from a level-up reward apart
        // (both land in the identical `xp.unlockedAvatarIds` field,
        // confirmed against `spend_coins.js`/`award_xp.js`), so one test
        // covers both mechanisms. This also stands as the "after a restart"
        // contrast case for BUG-1: ownership already present *at mount
        // time* (as it would be after a fresh app launch that re-reads
        // Firestore from scratch) always worked correctly — see the
        // `BUG-1 regression` group below for the case that was actually
        // broken (ownership changing *while already mounted*).
        await withTallSurface(tester, () async {
          final hub = _ProfileHub(_profile());
          final repo = _FakeProgressRepository(hub);
          final cosmetics = _UnlockedCosmeticsHub(avatarIds: {'neko_artist'});
          await tester.pumpWidget(
            await _harness(
              hub: hub,
              repo: repo,
              cosmetics: cosmetics,
              child: const AvatarPickerBody(popOnSelect: false, shopMode: true),
            ),
          );
          await tester.pumpAndSettle();

          expect(AvatarPresets.isCoinUnlockable('neko_artist'), isTrue);
          await tester.tap(find.text('Seniman')); // neko_artist
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(
            repo.calls,
            contains('updateAvatar:preset_premium:neko_artist'),
          );
          expect(find.byType(PaywallScreen), findsNothing);
        });
      },
    );
  });

  group('Frame picker', () {
    // This is the exact scenario that was broken: `frameIdUnlocked` alone
    // (without `!FramePresets.isLocked` first) always says "no" for a free
    // frame, since a free id is never added to `unlocked.frameIds`.
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
        final repo = _FakeProgressRepository(hub);
        final cosmetics = _UnlockedCosmeticsHub(
          adRewards: {'frame_premium': AdReward.unlockNow('frame_premium')},
        );
        await tester.pumpWidget(
          await _harness(
            hub: hub,
            repo: repo,
            cosmetics: cosmetics,
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
          final repo = _FakeProgressRepository(hub);
          final cosmetics = _UnlockedCosmeticsHub(
            frameIds: {'frame_halloween'},
          );
          await tester.pumpWidget(
            await _harness(
              hub: hub,
              repo: repo,
              cosmetics: cosmetics,
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
        final repo = _FakeProgressRepository(hub);
        final cosmetics = _UnlockedCosmeticsHub(
          adRewards: {'cover_premium': AdReward.unlockNow('cover_premium')},
        );
        await tester.pumpWidget(
          await _harness(
            hub: hub,
            repo: repo,
            cosmetics: cosmetics,
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
          final repo = _FakeProgressRepository(hub);
          final cosmetics = _UnlockedCosmeticsHub(coverIds: {'jungle_canopy'});
          await tester.pumpWidget(
            await _harness(
              hub: hub,
              repo: repo,
              cosmetics: cosmetics,
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

  // -------------------------------------------------------------------
  // BUG-1 regression: Toko's kept-alive Avatar/Frame/Cover pickers must
  // refresh ownership after a level-up reward, without ever remounting.
  // -------------------------------------------------------------------
  group('BUG-1 regression — kept-alive picker refresh without remount', () {
    testWidgets('Avatar: a level-reward granted while the picker stays mounted '
        'unlocks the tile live — no remount, no Paywall, equip works after', (
      tester,
    ) async {
      await withTallSurface(tester, () async {
        final hub = _ProfileHub(_profile());
        final repo = _FakeProgressRepository(hub);
        final cosmetics = _UnlockedCosmeticsHub(); // nothing granted yet
        await tester.pumpWidget(
          await _harness(
            hub: hub,
            repo: repo,
            cosmetics: cosmetics,
            // shopMode: true — this is exactly Toko's own copy of the
            // widget, the one that is kept alive for the app's whole
            // session (`HomeScreen`'s `_KeepAlivePage`) and is the
            // instance BUG-1 was actually about.
            child: const AvatarPickerBody(popOnSelect: false, shopMode: true),
          ),
        );
        await tester.pumpAndSettle();

        // 1-2. Mounted, and ownership as it stood at mount time: still
        // locked, coin-tier padlock, exactly the state before any
        // reward was ever claimed.
        expect(AvatarPresets.isCoinUnlockable('neko_artist'), isTrue);
        expect(find.text('Seniman'), findsOneWidget); // renders locked too
        await tester.tap(find.text('Seniman'));
        await tester.pumpAndSettle();
        expect(
          find.byType(AlertDialog),
          findsOneWidget,
          reason:
              'tapping a genuinely-locked coin-tier tile must show the '
              'buy confirmation, not equip it — confirms the picker '
              'really did start out treating this id as locked',
        );
        Navigator.of(
          tester.element(find.byType(AlertDialog)),
        ).pop(false); // dismiss without buying
        await tester.pumpAndSettle();
        expect(repo.calls, isEmpty);

        // 3-4. Simulate the server granting `neko_artist` via
        // `claimLevelReward` (called from Home, a completely different
        // screen) — this is exactly what a real `xp.unlockedAvatarIds`
        // `arrayUnion` write would cause the real Firestore listener
        // behind `watchUnlockedCosmetics` to emit. The SAME widget
        // instance from above is still mounted; nothing is re-pumped
        // with a new tree.
        cosmetics.grantAvatar('neko_artist');
        await tester.pumpAndSettle();

        // 5. Without dispose/restart/remount: the tile is unlocked now.
        // Tapping it must equip directly, not show the buy dialog again.
        await tester.tap(find.text('Seniman'));
        await tester.pumpAndSettle();

        expect(
          find.byType(AlertDialog),
          findsNothing,
          reason:
              'BUG-1: before the fix, this already-mounted picker never '
              'learned about the grant, so the tile stayed locked and '
              'this tap would have reopened the buy dialog again',
        );
        // 6-7. Equip actually went through, and no Paywall was ever
        // involved for what is now a genuinely-owned id.
        expect(repo.calls, contains('updateAvatar:preset_premium:neko_artist'));
        expect(find.byType(PaywallScreen), findsNothing);
        expect(hub.profile.avatarValue, 'neko_artist');
        _expectTileSelected(tester, 'Seniman');
      });
    });

    testWidgets('Frame: a level-reward granted while the picker stays mounted '
        'unlocks the tile live — no remount, no Paywall, equip works after', (
      tester,
    ) async {
      await withTallSurface(tester, () async {
        final hub = _ProfileHub(_profile());
        final repo = _FakeProgressRepository(hub);
        final cosmetics = _UnlockedCosmeticsHub();
        await tester.pumpWidget(
          await _harness(
            hub: hub,
            repo: repo,
            cosmetics: cosmetics,
            child: const FramePickerBody(popOnSelect: false, shopMode: true),
          ),
        );
        await tester.pumpAndSettle();

        expect(FramePresets.isCoinUnlockable('frame_halloween'), isTrue);
        await tester.tap(find.text('Halloween'));
        await tester.pumpAndSettle();
        expect(
          find.byType(AlertDialog),
          findsOneWidget,
          reason: 'starts genuinely locked, same as the Avatar case above',
        );
        Navigator.of(tester.element(find.byType(AlertDialog))).pop(false);
        await tester.pumpAndSettle();
        expect(repo.calls, isEmpty);

        // Simulated server grant, same widget instance, no remount.
        cosmetics.grantFrame('frame_halloween');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Halloween'));
        await tester.pumpAndSettle();

        expect(
          find.byType(AlertDialog),
          findsNothing,
          reason:
              'BUG-1: this is the exact frame-picker shape of the same '
              'staleness bug — an already-mounted Toko Frame tab kept '
              'showing a just-granted frame as locked',
        );
        expect(repo.calls, contains('updateFrame:frame_halloween'));
        expect(find.byType(PaywallScreen), findsNothing);
        expect(hub.profile.frameId, 'frame_halloween');
        _expectTileSelected(tester, 'Halloween');
      });
    });

    testWidgets('Cover: a level-reward granted while the picker stays mounted '
        'unlocks the tile live — no remount, no Paywall, equip works after', (
      tester,
    ) async {
      await withTallSurface(tester, () async {
        final hub = _ProfileHub(_profile());
        final repo = _FakeProgressRepository(hub);
        final cosmetics = _UnlockedCosmeticsHub();
        await tester.pumpWidget(
          await _harness(
            hub: hub,
            repo: repo,
            cosmetics: cosmetics,
            child: const CoverPickerBody(popOnSelect: false, shopMode: true),
          ),
        );
        await tester.pumpAndSettle();

        expect(CoverPresets.isCoinUnlockable('jungle_canopy'), isTrue);
        await tester.tap(find.text('Rimba Tropis'));
        await tester.pumpAndSettle();
        expect(
          find.byType(AlertDialog),
          findsOneWidget,
          reason: 'starts genuinely locked, same as the Avatar case above',
        );
        Navigator.of(tester.element(find.byType(AlertDialog))).pop(false);
        await tester.pumpAndSettle();
        expect(repo.calls, isEmpty);

        cosmetics.grantCover('jungle_canopy');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Rimba Tropis'));
        await tester.pumpAndSettle();

        expect(
          find.byType(AlertDialog),
          findsNothing,
          reason: 'BUG-1: the cover-picker shape of the same staleness bug',
        );
        expect(repo.calls, contains('updateCover:jungle_canopy'));
        expect(find.byType(PaywallScreen), findsNothing);
        expect(hub.profile.coverId, 'jungle_canopy');
        _expectTileSelected(tester, 'Rimba Tropis');
      });
    });

    // The explicit "after a restart" contrast LANGKAH 6 asked for: a
    // *fresh* mount where the grant already happened before this widget
    // ever existed (exactly what a real app relaunch looks like — the
    // provider's very first Firestore read already reflects the grant).
    // This was never actually broken — it's the already-mounted case
    // above that BUG-1 was about — but it's worth pinning explicitly so
    // the distinction is a test, not just a claim in a report. This is
    // the same shape as the pre-existing "coin/level-reward-unlocked"
    // tests in the three groups above; kept here too as one dedicated,
    // explicitly-named contrast case right next to the bug it's
    // contrasted with.
    testWidgets(
      'contrast: a fresh mount with the grant already present (simulating '
      'app restart) shows it unlocked immediately — this path was never '
      'broken',
      (tester) async {
        await withTallSurface(tester, () async {
          final hub = _ProfileHub(_profile());
          final repo = _FakeProgressRepository(hub);
          final cosmetics = _UnlockedCosmeticsHub(
            frameIds: {'frame_halloween'},
          );
          await tester.pumpWidget(
            await _harness(
              hub: hub,
              repo: repo,
              cosmetics: cosmetics,
              child: const FramePickerBody(popOnSelect: false, shopMode: true),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.text('Halloween'));
          await tester.pumpAndSettle();

          expect(find.byType(AlertDialog), findsNothing);
          expect(repo.calls, contains('updateFrame:frame_halloween'));
          expect(find.byType(PaywallScreen), findsNothing);
        });
      },
    );
  });

  // RISK-1: rapid/double tap on Avatar/Frame/Cover's own equip write —
  // AUDIT_COSMETIC_PROFILE_SHOP.md. Proven for real before any production
  // code changed here, not assumed from reading `handleTap`: a widget test
  // driving the *unguarded* pickers with a realistic double-tap (tap, one
  // frame, tap again — and separately, with literally zero frames between
  // the two taps) fired `updateAvatar`/`updateFrame`/`updateCover` twice
  // every time, on every one of the three pickers, since nothing stood
  // between one tap's `InkWell.onTap` and the next.
  //
  // Fixed the same way `CardSkinPickerBody._saving` already fixes the
  // identical shape of bug there: a `bool _saving` set for the duration of
  // the write, plus one `AbsorbPointer` wrapping the whole grid, so a
  // second tap anywhere in the grid is silently dropped at the pointer
  // level (never even reaches `handleTap`) until the first write's
  // `finally` clears the flag.
  //
  // **Why the tests below use `repo.gate`, not a plain double-`tap()`**:
  // the fake `updateAvatar`/`updateFrame`/`updateCover` resolve within a
  // single microtask by default, with no real delay at all. Against that,
  // `_select`'s entire body — write, best-effort mirrors, and the
  // `finally` that resets `_saving` back to `false` — can finish inside
  // one `tester.pump()`, before a second `tester.tap()` even runs. That
  // made the very first version of these tests pass or fail by luck: a
  // plain double-tap kept showing 2 calls **even after the guard was
  // implemented correctly**, because the guard's true-for-real-milliseconds
  // window (measured against the actual Firestore/Cloud-Function round
  // trips `updateAvatar`/`consumeAdReward` are in production) had already
  // closed by the time this fake's synchronous write resolved. `repo.gate`
  // holds the write open on a `Completer` the test controls directly,
  // reproducing that real timing instead of guessing at a `Duration` —
  // see `_FakeProgressRepository.gate`'s own doc comment for the full
  // reasoning. Every other test in this file leaves `gate` unset and is
  // completely unaffected by its existence.
  group('RISK-1 — reentrancy guard against double/rapid tap', () {
    testWidgets(
      'Avatar: double-tap on a free tile while the first write is still '
      'in flight does not start a second write',
      (tester) async {
        await withTallSurface(tester, () async {
          final hub = _ProfileHub(_profile());
          final repo = _FakeProgressRepository(hub);
          final gate = Completer<void>();
          repo.gate = () => gate.future;
          await tester.pumpWidget(
            await _harness(
              hub: hub,
              repo: repo,
              child: const AvatarPickerBody(popOnSelect: false, shopMode: true),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.text('Guru')); // neko_sensei, free
          await tester.pump(); // lets `_saving` flip true and rebuild
          expect(
            repo.calls,
            hasLength(1),
            reason: 'the first tap must start exactly one write',
          );

          // The write above is still gated (not resolved) — exactly the
          // window a real Firestore round trip leaves open. A second tap
          // on the same tile right now is the bug this guards against.
          await tester.tap(find.text('Guru'), warnIfMissed: false);
          await tester.pump();
          expect(
            repo.calls,
            hasLength(1),
            reason:
                'RISK-1: a second tap while the first write is still in '
                'flight must not reach `_select` again',
          );

          gate.complete();
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(repo.calls, hasLength(1));
          expect(hub.profile.avatarType, AvatarType.presetFree);
          expect(hub.profile.avatarValue, 'neko_sensei');
          _expectTileSelected(tester, 'Guru');
        });
      },
    );

    testWidgets(
      'Avatar: an ad-tier tile double-tapped mid-write equips once and '
      'consumes the reward exactly once, not twice',
      (tester) async {
        await withTallSurface(tester, () async {
          final hub = _ProfileHub(_profile());
          final repo = _FakeProgressRepository(hub);
          final gate = Completer<void>();
          repo.gate = () => gate.future;
          final cosmetics = _UnlockedCosmeticsHub(
            adRewards: {'avatar_premium': AdReward.unlockNow('avatar_premium')},
          );
          await tester.pumpWidget(
            await _harness(
              hub: hub,
              repo: repo,
              cosmetics: cosmetics,
              child: const AvatarPickerBody(popOnSelect: false, shopMode: true),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.text('Koki')); // neko_chef, ad-tier
          await tester.pump();
          await tester.tap(find.text('Koki'), warnIfMissed: false);
          await tester.pump();
          expect(
            repo.calls,
            hasLength(1),
            reason: 'RISK-1: the second tap must not start a second write',
          );

          gate.complete();
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(repo.calls, hasLength(1));
          expect(
            repo.consumedRewards,
            equals(['avatar_premium']),
            reason:
                'the single-use ad reward must be consumed exactly once, '
                'never twice, regardless of how many taps landed',
          );
        });
      },
    );

    testWidgets(
      'Frame: double-tap on a free tile while the first write is still '
      'in flight does not start a second write',
      (tester) async {
        await withTallSurface(tester, () async {
          final hub = _ProfileHub(_profile());
          final repo = _FakeProgressRepository(hub);
          final gate = Completer<void>();
          repo.gate = () => gate.future;
          await tester.pumpWidget(
            await _harness(
              hub: hub,
              repo: repo,
              child: const FramePickerBody(popOnSelect: false, shopMode: true),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(
            find.text('Sakura & Fuji'),
          ); // frame_sakura_fuji, free
          await tester.pump();
          expect(repo.calls, hasLength(1));

          await tester.tap(find.text('Sakura & Fuji'), warnIfMissed: false);
          await tester.pump();
          expect(
            repo.calls,
            hasLength(1),
            reason:
                'RISK-1: same guard, applied to the Frame picker — the '
                'be6a6d8 equip-decision fix stays untouched, this only adds '
                'a reentrancy guard around its already-correct decision',
          );

          gate.complete();
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(repo.calls, hasLength(1));
          expect(hub.profile.frameId, 'frame_sakura_fuji');
          _expectTileSelected(tester, 'Sakura & Fuji');
        });
      },
    );

    testWidgets(
      'Frame: an ad-tier tile double-tapped mid-write equips once and '
      'consumes the reward exactly once, not twice',
      (tester) async {
        await withTallSurface(tester, () async {
          final hub = _ProfileHub(_profile());
          final repo = _FakeProgressRepository(hub);
          final gate = Completer<void>();
          repo.gate = () => gate.future;
          final cosmetics = _UnlockedCosmeticsHub(
            adRewards: {'frame_premium': AdReward.unlockNow('frame_premium')},
          );
          await tester.pumpWidget(
            await _harness(
              hub: hub,
              repo: repo,
              cosmetics: cosmetics,
              child: const FramePickerBody(popOnSelect: false, shopMode: true),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.text('Bawah Laut')); // frame_ocean, ad-tier
          await tester.pump();
          await tester.tap(find.text('Bawah Laut'), warnIfMissed: false);
          await tester.pump();
          expect(repo.calls, hasLength(1));

          gate.complete();
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(repo.calls, hasLength(1));
          expect(repo.consumedRewards, equals(['frame_premium']));
        });
      },
    );

    testWidgets(
      'Cover: double-tap on a free tile while the first write is still '
      'in flight does not start a second write',
      (tester) async {
        await withTallSurface(tester, () async {
          final hub = _ProfileHub(_profile());
          final repo = _FakeProgressRepository(hub);
          final gate = Completer<void>();
          repo.gate = () => gate.future;
          await tester.pumpWidget(
            await _harness(
              hub: hub,
              repo: repo,
              child: const CoverPickerBody(popOnSelect: false, shopMode: true),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.text('Padang Bunga')); // spring_meadow, free
          await tester.pump();
          expect(repo.calls, hasLength(1));

          await tester.tap(find.text('Padang Bunga'), warnIfMissed: false);
          await tester.pump();
          expect(repo.calls, hasLength(1));

          gate.complete();
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(repo.calls, hasLength(1));
          expect(hub.profile.coverId, 'spring_meadow');
          _expectTileSelected(tester, 'Padang Bunga');
        });
      },
    );

    testWidgets(
      'Cover: an ad-tier tile double-tapped mid-write equips once and '
      'consumes the reward exactly once, not twice',
      (tester) async {
        await withTallSurface(tester, () async {
          final hub = _ProfileHub(_profile());
          final repo = _FakeProgressRepository(hub);
          final gate = Completer<void>();
          repo.gate = () => gate.future;
          final cosmetics = _UnlockedCosmeticsHub(
            adRewards: {'cover_premium': AdReward.unlockNow('cover_premium')},
          );
          await tester.pumpWidget(
            await _harness(
              hub: hub,
              repo: repo,
              cosmetics: cosmetics,
              child: const CoverPickerBody(popOnSelect: false, shopMode: true),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.text('Terumbu Karang')); // coral_reef, ad-tier
          await tester.pump();
          await tester.tap(find.text('Terumbu Karang'), warnIfMissed: false);
          await tester.pump();
          expect(repo.calls, hasLength(1));

          gate.complete();
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(repo.calls, hasLength(1));
          expect(repo.consumedRewards, equals(['cover_premium']));
        });
      },
    );

    // Documented, not just claimed: `_saving` deliberately does not also
    // wrap `_buyWithCoins`/`_openPaywall` — see `_AvatarPickerBodyState
    // ._saving`'s own doc comment. These two tests are the proof that
    // decision was safe *before* writing a single line of the guard, by
    // double-tapping the exact tiles that reach those two functions and
    // confirming only one dialog/route ever appears — the confirm
    // dialog's own modal barrier, and the paywall's own full-screen route
    // push, already make the grid beneath them un-tappable the instant
    // either appears. No `repo.gate` needed here: this isn't timing
    // against a write, it's confirming a *second tap physically cannot
    // reach the grid tile again* once either overlay exists — true (or
    // not) regardless of how long anything underneath takes.
    testWidgets('Avatar: double-tap on a locked coin-tier tile never stacks a '
        'second confirm dialog (already single-flight, no guard added here)', (
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

        // No pump between the two taps — the tightest window there is,
        // before the dialog's own barrier has had a single frame to
        // render and intercept a second tap at the same position.
        await tester.tap(find.text('Seniman')); // neko_artist, coin-tier
        await tester.tap(find.text('Seniman'), warnIfMissed: false);
        await tester.pump();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(repo.calls, isEmpty);
      });
    });

    testWidgets(
      'Avatar: double-tap on a locked premium-only tile never stacks a '
      'second Paywall push (already single-flight, no guard added here)',
      (tester) async {
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
          await tester.tap(find.text('Astronot'));
          await tester.tap(find.text('Astronot'), warnIfMissed: false);
          // Not pumpAndSettle: PaywallScreen may run a periodic poll that
          // reschedules frames forever — see the F1 "premium-only avatar"
          // test above for the same note.
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.byType(PaywallScreen), findsOneWidget);
          expect(repo.calls, isEmpty);
        });
      },
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
/// `ref.read`s it lazily inside `_select`, at tap time. A plain
/// `ProviderScope` only starts resolving a `FutureProvider` the moment
/// something first reads it — so without this, `appStartupProvider` is
/// still `AsyncLoading` (`uid == null`) at the exact synchronous instant
/// `_select` runs, and it bails out silently (`if (uid == null) return;`)
/// with no exception, no SnackBar, and no repository call. In the real
/// app this never happens (`appStartupProvider` is already resolved,
/// cached, long before any picker can be reached), so this is purely a
/// widget-test artifact, not a production bug — but it has to be worked
/// around for these tests to mean anything. A "pump a placeholder child
/// first, then swap in the real widget" two-step was tried and does
/// **not** fix it: each `pumpWidget` call building the overrides list
/// fresh makes Riverpod treat it as a changed override and reset the
/// provider back to `AsyncLoading` anyway. Owning the [ProviderContainer]
/// directly and `await`ing `container.read(appStartupProvider.future)`
/// *before* the first `pumpWidget` is the one approach that actually
/// keeps the resolved state.
Future<Widget> _harness({
  required _ProfileHub hub,
  required _FakeProgressRepository repo,
  required Widget child,
  _UnlockedCosmeticsHub? cosmetics,
  Set<String> ownedSkins = const {},
}) async {
  final cosmeticsHub = cosmetics ?? _UnlockedCosmeticsHub();
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
      // The BUG-1 fix's own live provider — see its doc comment in
      // `lib/core/providers.dart` for why Avatar/Frame/Cover watch this
      // instead of a one-shot fetch. Overridden with a controllable
      // stream (not `repo.getAdRewards`/`getUnlockedXIds`, which remain
      // implemented on the fake only because `PaywallScreen`'s own
      // `_pollForGrant` still calls `getAdRewards` after a real ad
      // watch — a path these tests never exercise) so a test can push a
      // fresh value into the *same, already-mounted* widget tree.
      unlockedCosmeticsProvider.overrideWith((ref) => cosmeticsHub.stream),
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
  _ProfileHub(this.profile);

  UserProfile profile;
  final _controller = StreamController<UserProfile>.broadcast();

  // A plain broadcast `StreamController` drops anything `add()`-ed before
  // a listener subscribes — there is no replay/buffering. Riverpod only
  // subscribes to this the first time `userProfileProvider` is watched,
  // which happens inside the picker's own `build()`, well *after* this
  // hub is constructed by the test — so seeding the controller in the
  // constructor (as an earlier version of this file did) silently lost
  // the seed value for every test that never called `set(...)` again, and
  // the picker saw `valueOrNull == null` for its entire run. Yielding
  // [profile] first, on every subscription, fixes it the same way a real
  // Firestore `.snapshots()` listener always delivers the current cached
  // state immediately on subscribe.
  Stream<UserProfile> get stream async* {
    yield profile;
    yield* _controller.stream;
  }

  void set(UserProfile Function(UserProfile) update) {
    profile = update(profile);
    _controller.add(profile);
  }
}

/// Live [UnlockedCosmetics] test double — the thing that actually
/// reproduces BUG-1's lifecycle. A real `ProviderContainer`/widget test
/// can't fire a genuine Firestore snapshot event, so this stands in for
/// "the server just wrote `xp.unlockedFrameIds`/`adRewards` and the
/// client's `.snapshots()` listener just delivered it" — [grantAvatar]/
/// [grantFrame]/[grantCover] push a new value into the exact same stream
/// [_harness] wires `unlockedCosmeticsProvider` to, on the already-built
/// widget tree, with no `tester.pumpWidget` call (no remount) in between.
class _UnlockedCosmeticsHub {
  _UnlockedCosmeticsHub({
    Set<String> avatarIds = const {},
    Set<String> frameIds = const {},
    Set<String> coverIds = const {},
    Map<String, AdReward> adRewards = const {},
  }) : value = UnlockedCosmetics(
         avatarIds: avatarIds,
         frameIds: frameIds,
         coverIds: coverIds,
         adRewards: adRewards,
       );

  UnlockedCosmetics value;
  final _controller = StreamController<UnlockedCosmetics>.broadcast();

  // Same "yield the current value on every subscription" fix as
  // `_ProfileHub.stream` — see its doc comment. This one matters even
  // more here: every "already-unlocked via ad-reward/coin" test seeds
  // [value] once at construction and never calls a mutator again, so
  // without this, `unlockedCosmeticsProvider` would never see anything
  // but its own empty default for the whole test.
  Stream<UnlockedCosmetics> get stream async* {
    yield value;
    yield* _controller.stream;
  }

  void _set(UnlockedCosmetics next) {
    value = next;
    _controller.add(value);
  }

  void grantAvatar(String id) => _set(
    UnlockedCosmetics(
      avatarIds: {...value.avatarIds, id},
      frameIds: value.frameIds,
      coverIds: value.coverIds,
      adRewards: value.adRewards,
    ),
  );

  void grantFrame(String id) => _set(
    UnlockedCosmetics(
      avatarIds: value.avatarIds,
      frameIds: {...value.frameIds, id},
      coverIds: value.coverIds,
      adRewards: value.adRewards,
    ),
  );

  void grantCover(String id) => _set(
    UnlockedCosmetics(
      avatarIds: value.avatarIds,
      frameIds: value.frameIds,
      coverIds: {...value.coverIds, id},
      adRewards: value.adRewards,
    ),
  );
}

/// Real [ProgressRepository] surface, faked just for the handful of
/// methods each picker's equip path actually calls — every other member
/// falls through to [noSuchMethod], which is never invoked because these
/// four widgets never call anything else on it. This is deliberately an
/// `implements`, not an `extends`: the real class's constructor eagerly
/// touches `FirebaseFirestore.instance`/`FirebaseFunctions.instance`
/// (there is no Firebase app in a widget test), so subclassing it would
/// throw before this object even exists.
class _FakeProgressRepository implements ProgressRepository {
  _FakeProgressRepository(this._hub);

  final _ProfileHub _hub;
  final List<String> calls = [];
  final List<String> consumedRewards = [];

  /// RISK-1 double-tap tests only: when set, every write method below
  /// awaits this before touching [_hub] — the real `updateAvatar`/
  /// `updateFrame`/`updateCover` are genuine Firestore round trips (tens
  /// to hundreds of milliseconds at least), but this fake's default
  /// behavior resolves within a single microtask with no real delay at
  /// all. That gap matters here specifically: a `_saving` reentrancy
  /// guard's whole job is to stay `true` for the *duration* of an
  /// in-flight write, and against a same-microtask fake, `_select`'s
  /// entire body (write, best-effort mirrors, and the `finally` that
  /// resets `_saving` back to `false`) can complete inside one
  /// `tester.pump()` — before a second `tester.tap()` even runs — making
  /// the guard's window invisible to the test even though it is genuinely
  /// open for real, measurable time in production. Setting this to a
  /// `Completer`-backed gate the test controls directly reproduces that
  /// real-world timing instead of guessing at a `Duration`. `calls.add`
  /// still happens *before* the gate (see each method below) so a guard
  /// failure — a second write actually starting while the first is still
  /// gated — is recorded the instant it happens, not only once the gate
  /// later opens.
  Future<void> Function()? gate;

  @override
  Future<void> updateAvatar(String uid, AvatarType type, String? value) async {
    calls.add('updateAvatar:${type.key}:$value');
    if (gate != null) await gate!();
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
    if (gate != null) await gate!();
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
    if (gate != null) await gate!();
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

  // Still implemented (returning empty/default) purely because
  // `PaywallScreen._pollForGrant` calls `getAdRewards` after a real ad
  // watch — a path no test in this file exercises, since none of them
  // actually trigger `AdService.loadAndShowRewarded`. Ownership itself no
  // longer flows through these for Avatar/Frame/Cover — see
  // `_UnlockedCosmeticsHub`/`unlockedCosmeticsProvider` above.
  @override
  Future<Map<String, AdReward>> getAdRewards(String uid) async => const {};

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

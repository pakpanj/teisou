import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/constants/avatars.dart';
import 'package:kana_master/core/constants/covers.dart';
import 'package:kana_master/core/constants/frames.dart';
import 'package:kana_master/core/providers.dart';
import 'package:kana_master/core/services/coin_spend_service.dart';
import 'package:kana_master/data/models/subscription.dart';
import 'package:kana_master/data/models/unlocked_cosmetics.dart';
import 'package:kana_master/data/models/user_profile.dart';
import 'package:kana_master/data/repositories/progress_repository.dart';
import 'package:kana_master/features/leaderboard/leaderboard_providers.dart';
import 'package:kana_master/features/profile/widgets/avatar_picker_sheet.dart';
import 'package:kana_master/features/profile/widgets/cover_picker_sheet.dart';

/// RISK-5 regression coverage: the coin-purchase confirm-and-buy flow on
/// Avatar/Frame/Cover pickers is now guarded (`_buyingWithCoins`) the
/// same way `ShopTab._buyingWithCoins` already guarded card skins.
///
/// **The gap this closes**: the confirm dialog's own modal barrier only
/// ever protected the window BEFORE the dialog opens (a second tap can't
/// reach the tile while the dialog shows) — proven safe for that window
/// in `cosmetic_equip_decision_test.dart`'s RISK-1 group. It said nothing
/// about the window AFTER the dialog closes, while
/// `CoinSpendService.buy()` is still in flight and the tile is still
/// locked as far as Firestore's snapshot has reported — that window had
/// no guard at all before this fix, and a realistic tap-confirm-tap-
/// confirm sequence opened a second dialog and fired a second concurrent
/// `buy()` call (proven in the RISK-5 audit's own reproduction test,
/// folded into this file).
///
/// **Why `repo.gate`-shaped `Completer`s, not a plain double-tap**: same
/// reasoning as RISK-1's own tests — the fake `CoinSpendService.buy()`
/// would otherwise resolve within a single microtask, closing the guard's
/// window before a second `tester.tap()` even runs. Holding it open on a
/// `Completer` the test controls directly reproduces the real, measurable
/// in-flight window a genuine Cloud Function round trip leaves open.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  group('Avatar coin-buy reentrancy', () {
    testWidgets(
      'tap -> confirm -> tap again while buy() is in-flight: no second '
      'dialog, buy() called exactly once',
      (tester) async {
        await withTallSurface(tester, () async {
          final coinService = _FakeCoinSpendService();
          final gate = Completer<void>();
          coinService.gate = () => gate.future;

          await tester.pumpWidget(
            await _harness(
              coinService: coinService,
              child: const AvatarPickerBody(popOnSelect: false, shopMode: true),
            ),
          );
          await tester.pumpAndSettle();

          expect(AvatarPresets.isCoinUnlockable('neko_artist'), isTrue);

          await tester.tap(find.text('Seniman'));
          await tester.pumpAndSettle();
          expect(find.byType(AlertDialog), findsOneWidget);

          await tester.tap(find.text('Beli'));
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(coinService.calls, hasLength(1));
          expect(find.byType(AlertDialog), findsNothing);

          // The second tap while buy() is still gated in-flight — the
          // exact window RISK-5 found unguarded.
          await tester.tap(find.text('Seniman'), warnIfMissed: false);
          await tester.pump();
          await tester.pump();

          expect(
            find.byType(AlertDialog),
            findsNothing,
            reason:
                'FIX: a second tap while the first coin purchase is '
                'in-flight must not open a second confirm dialog',
          );
          expect(
            coinService.calls,
            hasLength(1),
            reason:
                'FIX: and must not reach CoinSpendService.buy() a second '
                'time either',
          );

          gate.complete();
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(coinService.calls, hasLength(1));
        });
      },
    );

    testWidgets(
      'after the first purchase settles, the guard lifts and a genuinely '
      'new attempt can open the dialog and buy again',
      (tester) async {
        await withTallSurface(tester, () async {
          final coinService = _FakeCoinSpendService();
          final gate = Completer<void>();
          coinService.gate = () => gate.future;

          await tester.pumpWidget(
            await _harness(
              coinService: coinService,
              child: const AvatarPickerBody(popOnSelect: false, shopMode: true),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.text('Seniman'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Beli'));
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(coinService.calls, hasLength(1));

          gate.complete();
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          // A genuinely new attempt (e.g. the first one failed with "not
          // enough coins" and the learner tries a different tile, or just
          // tries again) must not be permanently blocked by the guard.
          await tester.tap(find.text('Seniman'));
          await tester.pumpAndSettle();
          expect(
            find.byType(AlertDialog),
            findsOneWidget,
            reason:
                'the guard must not have wedged the tile permanently '
                'unresponsive after the first purchase settled',
          );
          await tester.tap(find.text('Beli'));
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(coinService.calls, hasLength(2));
        });
      },
    );
  });

  group('Frame coin-buy reentrancy', () {
    testWidgets(
      'tap -> confirm -> tap again while buy() is in-flight: no second '
      'dialog, buy() called exactly once',
      (tester) async {
        await withTallSurface(tester, () async {
          final coinService = _FakeCoinSpendService();
          final gate = Completer<void>();
          coinService.gate = () => gate.future;

          await tester.pumpWidget(
            await _harness(
              coinService: coinService,
              child: const FramePickerBody(popOnSelect: false, shopMode: true),
            ),
          );
          await tester.pumpAndSettle();

          expect(FramePresets.isCoinUnlockable('frame_halloween'), isTrue);

          await tester.tap(find.text('Halloween'));
          await tester.pumpAndSettle();
          expect(find.byType(AlertDialog), findsOneWidget);

          await tester.tap(find.text('Beli'));
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(coinService.calls, hasLength(1));

          await tester.tap(find.text('Halloween'), warnIfMissed: false);
          await tester.pump();
          await tester.pump();

          expect(find.byType(AlertDialog), findsNothing);
          expect(coinService.calls, hasLength(1));

          gate.complete();
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(coinService.calls, hasLength(1));
        });
      },
    );

    testWidgets(
      'after the first purchase settles, the guard lifts and a genuinely '
      'new attempt can buy again',
      (tester) async {
        await withTallSurface(tester, () async {
          final coinService = _FakeCoinSpendService();
          final gate = Completer<void>();
          coinService.gate = () => gate.future;

          await tester.pumpWidget(
            await _harness(
              coinService: coinService,
              child: const FramePickerBody(popOnSelect: false, shopMode: true),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.text('Halloween'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Beli'));
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(coinService.calls, hasLength(1));

          gate.complete();
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          await tester.tap(find.text('Halloween'));
          await tester.pumpAndSettle();
          expect(find.byType(AlertDialog), findsOneWidget);
          await tester.tap(find.text('Beli'));
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(coinService.calls, hasLength(2));
        });
      },
    );
  });

  group('Cover coin-buy reentrancy', () {
    testWidgets(
      'tap -> confirm -> tap again while buy() is in-flight: no second '
      'dialog, buy() called exactly once',
      (tester) async {
        await withTallSurface(tester, () async {
          final coinService = _FakeCoinSpendService();
          final gate = Completer<void>();
          coinService.gate = () => gate.future;

          await tester.pumpWidget(
            await _harness(
              coinService: coinService,
              child: const CoverPickerBody(popOnSelect: false, shopMode: true),
            ),
          );
          await tester.pumpAndSettle();

          expect(CoverPresets.isCoinUnlockable('jungle_canopy'), isTrue);

          await tester.tap(find.text('Rimba Tropis'));
          await tester.pumpAndSettle();
          expect(find.byType(AlertDialog), findsOneWidget);

          await tester.tap(find.text('Beli'));
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(coinService.calls, hasLength(1));

          await tester.tap(find.text('Rimba Tropis'), warnIfMissed: false);
          await tester.pump();
          await tester.pump();

          expect(find.byType(AlertDialog), findsNothing);
          expect(coinService.calls, hasLength(1));

          gate.complete();
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(coinService.calls, hasLength(1));
        });
      },
    );

    testWidgets(
      'after the first purchase settles, the guard lifts and a genuinely '
      'new attempt can buy again',
      (tester) async {
        await withTallSurface(tester, () async {
          final coinService = _FakeCoinSpendService();
          final gate = Completer<void>();
          coinService.gate = () => gate.future;

          await tester.pumpWidget(
            await _harness(
              coinService: coinService,
              child: const CoverPickerBody(popOnSelect: false, shopMode: true),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.text('Rimba Tropis'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Beli'));
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(coinService.calls, hasLength(1));

          gate.complete();
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          await tester.tap(find.text('Rimba Tropis'));
          await tester.pumpAndSettle();
          expect(find.byType(AlertDialog), findsOneWidget);
          await tester.tap(find.text('Beli'));
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(coinService.calls, hasLength(2));
        });
      },
    );
  });

  group('CONTRAST: card skin coin-buy already guarded (ShopTab, untouched '
      'by this fix)', () {
    // ShopTab's own `_buyingWithCoins` guard is the pattern this fix
    // mirrors — its own coverage lives in shop_screen_gesture_test.dart's
    // "heavier dependency" note and this project's wider IAP suite; not
    // duplicated here since ShopTab requires the IAP platform-channel
    // harness (see premium_purchase_reentrancy_test.dart), not this
    // file's lighter provider-only harness. Documented here so a reader
    // of this file knows the fourth coin-buy path was already covered by
    // the RISK-5 audit's own code reading, not overlooked.
    test('nothing to run here — see comment above', () {});
  });
}

// ---------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------

/// Mirrors `cosmetic_equip_decision_test.dart`'s own `_harness` — a
/// pre-warmed `ProviderContainer` handed to the tree via
/// `UncontrolledProviderScope`, since `appStartupProvider` needs to have
/// already resolved before the first `pumpWidget` for these pickers'
/// `handleTap` (`ref.read` at tap time, not `ref.watch` in build) to see
/// a real uid.
Future<Widget> _harness({
  required Widget child,
  required _FakeCoinSpendService coinService,
}) async {
  final container = ProviderContainer(
    overrides: [
      appStartupProvider.overrideWith((ref) async => _FakeUser()),
      userProfileProvider.overrideWith(
        (ref) => Stream.value(
          UserProfile(isAnonymous: true, linkedGoogle: false, currentStreak: 0),
        ),
      ),
      subscriptionProvider.overrideWith(
        (ref) => Stream.value(Subscription(tier: SubscriptionTier.free)),
      ),
      progressRepositoryProvider.overrideWithValue(_FakeProgressRepository()),
      coinSpendServiceProvider.overrideWithValue(coinService),
      // Never reports the purchase as landed — deliberate: this test
      // holds the "still locked from the picker's point of view" window
      // open indefinitely via `gate`, to observe what a second tap does
      // inside it, the same way real Firestore propagation delay would.
      unlockedCosmeticsProvider.overrideWith(
        (ref) => Stream.value(UnlockedCosmetics.empty),
      ),
      selfLeaderboardEntryProvider.overrideWith((ref) async => null),
    ],
  );
  addTearDown(container.dispose);
  await container.read(appStartupProvider.future);

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

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

class _FakeCoinSpendService implements CoinSpendService {
  final List<String> calls = [];
  Future<void> Function()? gate;

  @override
  Future<bool> buy(CoinSpendKind kind, String id) async {
    calls.add('${kind.name}:$id');
    if (gate != null) await gate!();
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Only the methods the coin-buy path can reach are implemented — the
/// pickers' free-tile equip path (`_select`/`_selectFrame`) is never
/// exercised by these tests, but `progressRepositoryProvider` still needs
/// a safe override since the real `ProgressRepository` eagerly touches
/// Firebase in its constructor.
class _FakeProgressRepository implements ProgressRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

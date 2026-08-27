import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';

import 'package:kana_master/core/constants/iap_products.dart';
import 'package:kana_master/core/providers.dart';
import 'package:kana_master/data/models/subscription.dart';
import 'package:kana_master/features/paywall/paywall_screen.dart';
import 'package:kana_master/features/profile/widgets/premium_card.dart';
import 'package:kana_master/features/onboarding/plan_intro_screen.dart';

/// RISK-4 regression coverage: rapid/double-tap on the Premium purchase
/// button (AUDIT report, this session). `PremiumPurchaseFlow.buy()` and
/// `IapService.buy()` are both deliberately stateless (see their own doc
/// comments) — nothing in that shared chain ever tracked an in-flight
/// purchase, so before this fix a double-tap on `PaywallScreen` or
/// `_ComparePage` (plan_intro_screen.dart) started TWO real store
/// purchase sheets, proven by an earlier version of this file
/// (`_audit_premium_reentrancy_test.dart`, now folded in here).
///
/// The guard added lives entirely in each screen's own `State` — a
/// `_buying` bool set for the duration of the `PremiumPurchaseFlow.buy()`
/// call and reset in a `finally` — the exact pattern
/// `premium_card.dart`'s `_busy` already used and that this file's
/// PremiumCard group below still pins as a contrast case. Nothing about
/// `PremiumPurchaseFlow`/`IapService`/`functions/iap.js` was touched.
///
/// **Strategy**: swap the real `InAppPurchasePlatform.instance` (the
/// actual plugin boundary every platform implementation — Android, iOS —
/// ultimately delegates to) for a fake that records every
/// `buyNonConsumable` call and can hold one open on a `Completer` — same
/// "gate" technique `_FakeProgressRepository.gate` uses in
/// `cosmetic_equip_decision_test.dart` to reproduce the real-world
/// in-flight window a genuine Play Billing round trip leaves open (a
/// fake that resolves in a single microtask would let a guard's window
/// close before a second `tester.tap()` even runs). Nothing about
/// `IapService`/`PremiumPurchaseFlow` is mocked — only the lowest
/// platform boundary — so the entire real production call chain
/// (screen -> PremiumPurchaseFlow.buy -> IapService.buy ->
/// InAppPurchase.buyNonConsumable -> InAppPurchasePlatform.instance
/// .buyNonConsumable) runs for real in every test below.
///
/// **Gotcha, worth keeping this comment if this file is ever touched
/// again**: `InAppPurchase.instance` (the plugin FACADE singleton,
/// distinct from `InAppPurchasePlatform.instance`) is lazy —
/// `_getOrCreateInstance()` registers the REAL platform
/// (`InAppPurchaseAndroidPlatform.registerPlatform()`, which overwrites
/// `InAppPurchasePlatform.instance`) the first time `InAppPurchase
/// .instance` is read in the whole process, then never does it again.
/// Setting a fake before that first read gets silently clobbered — no
/// exception, the call just quietly never reaches the fake. Forcing that
/// one-time registration to target a platform `InAppPurchase` has no
/// real implementation for (`TargetPlatform.fuchsia`, briefly, in
/// [setUpAll] below) makes `_getOrCreateInstance()` skip constructing a
/// real `BillingClient`/StoreKit bridge entirely — so the one-time touch
/// is genuinely inert instead of leaking a late, unhandled
/// `PlatformException` from a real `BillingClientManager` trying (and
/// failing, no platform channel exists in a host test) to connect.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    final original = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
    // ignore: unnecessary_statements
    InAppPurchase.instance; // spend the one-time registration, inertly
    debugDefaultTargetPlatformOverride = original;
  });

  group('PaywallScreen — Premium buy button reentrancy guard', () {
    testWidgets(
      'double-tap while the first purchase is in-flight starts exactly '
      'one buyNonConsumable, and the flow completes cleanly once '
      'released',
      (tester) async {
        final platform = _FakeIapPlatform();
        final gate = Completer<void>();
        platform.gate = () => gate.future;

        await tester.pumpWidget(
          await _harness(
            tester: tester,
            platform: platform,
            child: const PaywallScreen(moduleId: 'kanji', moduleTitle: 'Kanji'),
          ),
        );
        await _settle(tester);

        final buyButton = _findPaywallBuyButton();
        expect(buyButton, findsOneWidget, reason: 'sanity: button must exist');
        // Captured before the first tap: once `_buying` flips true, the
        // guard swaps the button's child from the price Text to a
        // CircularProgressIndicator (same as PremiumCard's own `_busy`),
        // so a finder keyed on that text would find nothing on a second
        // lookup. Tapping the same physical location again is the
        // correct simulation of a real rapid double-tap.
        final tapPoint = tester.getCenter(buyButton);

        // 1-3. Tap once; the fake's buyNonConsumable records the call
        // immediately (before awaiting the gate), so this confirms the
        // first purchase really is in-flight before the second tap.
        await tester.tap(buyButton);
        await tester.pump();
        await tester.pump();
        await tester.pump();
        expect(
          platform.buyCalls,
          hasLength(1),
          reason: 'the first tap must start exactly one buyNonConsumable call',
        );

        // 4-5. Second tap on the same physical spot while the first is
        // still gated — this is the exact window the RISK-4 bug
        // reproduced in.
        await tester.tapAt(tapPoint);
        await tester.pump();
        await tester.pump();
        await tester.pump();
        expect(
          platform.buyCalls,
          hasLength(1),
          reason:
              'FIX: the second tap must not reach IapService.buy again '
              'while the first purchase is still in-flight',
        );

        // 6-7. Release the gate; the flow must resolve without error and
        // the guard must have already been lifted by then.
        gate.complete();
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        expect(platform.buyCalls, hasLength(1));
      },
    );

    testWidgets(
      'after a completed purchase attempt, the button is usable again for '
      'a legitimate second attempt (the guard does not stay stuck)',
      (tester) async {
        final platform = _FakeIapPlatform();
        final gate = Completer<void>();
        platform.gate = () => gate.future;

        await tester.pumpWidget(
          await _harness(
            tester: tester,
            platform: platform,
            child: const PaywallScreen(moduleId: 'kanji', moduleTitle: 'Kanji'),
          ),
        );
        await _settle(tester);

        final buyButton = _findPaywallBuyButton();
        await tester.tap(buyButton);
        await tester.pump();
        await tester.pump();
        await tester.pump();
        expect(platform.buyCalls, hasLength(1));

        // First purchase attempt resolves — the guard's job ends here,
        // not when a purchase eventually completes server-side (that can
        // take hours, e.g. parental approval — see IapOutcome's own doc
        // comments), so the button must already be usable again.
        gate.complete();
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final buyButtonAgain = _findPaywallBuyButton();
        expect(
          buyButtonAgain,
          findsOneWidget,
          reason: 'the button must not have vanished/stayed disabled forever',
        );
        await tester.tap(buyButtonAgain);
        await tester.pump();
        await tester.pump();
        await tester.pump();
        expect(
          platform.buyCalls,
          hasLength(2),
          reason:
              'a genuinely new tap after the first attempt finished must '
              'be allowed to start a fresh purchase — the guard must not '
              'have wedged the button permanently disabled',
        );
      },
    );

    testWidgets(
      'if the store call throws, the guard still resets and a retry can '
      'start a fresh purchase',
      (tester) async {
        final platform = _FakeIapPlatform();
        platform.throwOnNextBuy = true;

        await tester.pumpWidget(
          await _harness(
            tester: tester,
            platform: platform,
            child: const PaywallScreen(moduleId: 'kanji', moduleTitle: 'Kanji'),
          ),
        );
        await _settle(tester);

        final buyButton = _findPaywallBuyButton();
        // A button's `onPressed` is fire-and-forget — nothing in the
        // framework awaits the Future `_buy()` returns, so a throw
        // inside it becomes an uncaught async error on its own schedule,
        // arriving too late for `tester.takeException()` to reliably
        // retrieve within this same test body (confirmed empirically: a
        // plain pump() loop, and even `runAsync` + a zero-delay Future,
        // both left it surfacing after the test had already finished).
        // `runZonedGuarded` intercepts it directly instead of relying on
        // that timing.
        Object? caught;
        await runZonedGuarded(() async {
          await tester.tap(buyButton);
          await _settle(tester, ticks: 10);
        }, (error, stack) => caught = error);

        // The exception is real and expected here — captured by the zone
        // guard above instead of failing the test, then asserted on.
        expect(caught, isNotNull, reason: 'sanity: the fake really threw');
        expect(platform.buyCalls, hasLength(1));

        final retryButton = _findPaywallBuyButton();
        expect(
          retryButton,
          findsOneWidget,
          reason:
              'FIX: the guard must reset in a finally, not only on the '
              'happy path — a thrown exception must not leave the button '
              'permanently disabled',
        );
        await tester.tap(retryButton);
        await tester.pump();
        await tester.pump();
        await tester.pump();
        expect(
          platform.buyCalls,
          hasLength(2),
          reason: 'a retry after the failure must be able to start a new '
              'purchase, not be silently blocked by a guard stuck true',
        );
      },
    );
  });

  group('_ComparePage (plan_intro_screen) — Premium buy button reentrancy '
      'guard', () {
    testWidgets(
      'double-tap while the first purchase is in-flight starts exactly '
      'one buyNonConsumable, and the flow completes cleanly once '
      'released',
      (tester) async {
        final platform = _FakeIapPlatform();
        final gate = Completer<void>();
        platform.gate = () => gate.future;

        await tester.pumpWidget(
          await _harness(
            tester: tester,
            platform: platform,
            child: const PlanIntroFlow(),
          ),
        );
        await _settle(tester);
        await tester.tap(find.text('Lanjutkan'));
        await _settle(tester, ticks: 10);

        final buyButton = _findPlanIntroBuyButton();
        expect(buyButton, findsOneWidget);

        await tester.tap(buyButton);
        await tester.pump();
        await tester.pump();
        await tester.pump();
        expect(platform.buyCalls, hasLength(1));

        await tester.tap(buyButton, warnIfMissed: false);
        await tester.pump();
        await tester.pump();
        await tester.pump();
        expect(
          platform.buyCalls,
          hasLength(1),
          reason:
              'FIX: _ComparePage must not reach IapService.buy a second '
              'time while the first purchase is still in-flight',
        );

        gate.complete();
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        expect(platform.buyCalls, hasLength(1));
      },
    );

    testWidgets(
      'after a completed purchase attempt, the button is usable again for '
      'a legitimate second attempt',
      (tester) async {
        final platform = _FakeIapPlatform();
        final gate = Completer<void>();
        platform.gate = () => gate.future;

        await tester.pumpWidget(
          await _harness(
            tester: tester,
            platform: platform,
            child: const PlanIntroFlow(),
          ),
        );
        await _settle(tester);
        await tester.tap(find.text('Lanjutkan'));
        await _settle(tester, ticks: 10);

        final buyButton = _findPlanIntroBuyButton();
        await tester.tap(buyButton);
        await tester.pump();
        await tester.pump();
        await tester.pump();
        expect(platform.buyCalls, hasLength(1));

        gate.complete();
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final buyButtonAgain = _findPlanIntroBuyButton();
        expect(buyButtonAgain, findsOneWidget);
        await tester.tap(buyButtonAgain);
        await tester.pump();
        await tester.pump();
        await tester.pump();
        expect(
          platform.buyCalls,
          hasLength(2),
          reason: 'the guard must not have wedged this button either',
        );
      },
    );

    testWidgets(
      'if the store call throws, the guard still resets and a retry can '
      'start a fresh purchase',
      (tester) async {
        final platform = _FakeIapPlatform();
        platform.throwOnNextBuy = true;

        await tester.pumpWidget(
          await _harness(
            tester: tester,
            platform: platform,
            child: const PlanIntroFlow(),
          ),
        );
        await _settle(tester);
        await tester.tap(find.text('Lanjutkan'));
        await _settle(tester, ticks: 10);

        final buyButton = _findPlanIntroBuyButton();
        // See the identical PaywallScreen test's comment: `runZonedGuarded`
        // reliably intercepts the fire-and-forget throw instead of racing
        // `tester.takeException()`'s own timing.
        Object? caught;
        await runZonedGuarded(() async {
          await tester.tap(buyButton);
          await _settle(tester, ticks: 10);
        }, (error, stack) => caught = error);

        expect(caught, isNotNull, reason: 'sanity: the fake really threw');
        expect(platform.buyCalls, hasLength(1));

        final retryButton = _findPlanIntroBuyButton();
        expect(retryButton, findsOneWidget);
        await tester.tap(retryButton);
        await tester.pump();
        await tester.pump();
        await tester.pump();
        expect(platform.buyCalls, hasLength(2));
      },
    );
  });

  group('PremiumCard — already-guarded, contrast case (pre-existing '
      '_busy guard, untouched by this fix)', () {
    testWidgets(
      'double-tap fires buyNonConsumable only once',
      (tester) async {
        final platform = _FakeIapPlatform();
        final gate = Completer<void>();
        platform.gate = () => gate.future;

        await tester.pumpWidget(
          await _harness(
            tester: tester,
            platform: platform,
            child: const Scaffold(body: PremiumCard()),
          ),
        );
        await _settle(tester);

        final buyButton = find.textContaining('Upgrade Premium —').hitTestable();
        expect(buyButton, findsOneWidget);
        // Captured before the first tap: `_busy` swaps the button's
        // child from the price Text to a CircularProgressIndicator, so a
        // finder keyed on the price text would find nothing on a second
        // lookup — tapping the same physical location again is the
        // correct simulation of a real rapid double-tap.
        final tapPoint = tester.getCenter(buyButton);

        await tester.tap(buyButton);
        await tester.pump();
        await tester.pump();
        await tester.pump();
        expect(platform.buyCalls, hasLength(1));

        await tester.tapAt(tapPoint);
        await tester.pump();
        await tester.pump();
        await tester.pump();

        gate.complete();
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          platform.buyCalls,
          hasLength(1),
          reason: "PremiumCard's pre-existing _busy guard must still hold "
              '— this file does not touch premium_card.dart',
        );
      },
    );
  });
}

// ---------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------

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

/// Records every `buyNonConsumable` call and can hold each one open on a
/// gate, or throw once — exactly reproducing both the real-world in-flight
/// window a genuine Play Billing round trip leaves open, and a genuine
/// store-side failure.
class _FakeIapPlatform extends InAppPurchasePlatform {
  final List<String> buyCalls = [];
  final _purchaseController = StreamController<List<PurchaseDetails>>.broadcast();

  /// When set, every buyNonConsumable call awaits this before returning —
  /// same technique as `_FakeProgressRepository.gate` in
  /// cosmetic_equip_decision_test.dart.
  Future<void> Function()? gate;

  /// When true, the NEXT buyNonConsumable call throws instead of
  /// returning — consumed (reset to false) the moment it fires, so only
  /// that one call fails.
  bool throwOnNextBuy = false;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _purchaseController.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) async {
    return ProductDetailsResponse(
      productDetails: [
        ProductDetails(
          id: IapProducts.premiumMonthly,
          title: 'Teisou Premium',
          description: 'desc',
          price: 'Rp19.000',
          rawPrice: 19000,
          currencyCode: 'IDR',
        ),
      ],
      notFoundIDs: const [],
    );
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    // Recorded BEFORE the gate/throw — a guard failure (a second call
    // starting while the first is still gated) must be visible the
    // instant it happens, not only once the gate later opens.
    buyCalls.add(purchaseParam.applicationUserName ?? '<no-uid>');
    if (throwOnNextBuy) {
      throwOnNextBuy = false;
      throw Exception('simulated store failure');
    }
    if (gate != null) await gate!();
    return true;
  }
}

Future<Widget> _harness({
  required WidgetTester tester,
  required Widget child,
  required _FakeIapPlatform platform,
}) async {
  // A realistic phone-sized surface — the default 800x600 test surface
  // leaves the buy button below the visible viewport on every one of
  // these screens (SingleChildScrollView sizes to full content height
  // regardless of viewport), same gotcha plan_intro_screen_test.dart's
  // own `pump()` helper documents.
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  InAppPurchasePlatform.instance = platform;
  final container = ProviderContainer(
    overrides: [
      appStartupProvider.overrideWith((ref) async => _FakeUser()),
      subscriptionProvider.overrideWith(
        (ref) => Stream.value(Subscription(tier: SubscriptionTier.free)),
      ),
    ],
  );
  addTearDown(container.dispose);
  await container.read(appStartupProvider.future);

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(home: child),
  );
}

/// Not pumpAndSettle: MascotWidget's idle pose animation loops
/// continuously by design (see plan_intro_screen_test.dart's own note) —
/// a handful of bounded pumps is enough for loadPrice's setState / page
/// transitions to land.
Future<void> _settle(WidgetTester tester, {int ticks = 6}) async {
  for (var i = 0; i < ticks; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// PaywallScreen's/PremiumCard's shared button text
/// (`s.upgradePremiumButton`) is "Upgrade Premium" before the store has
/// answered with a price, or "Upgrade Premium — {price}" once it has one
/// — PaywallScreen also renders a plain "Upgrade ke Premium" label
/// elsewhere on the page (`s.profilePremiumUpgradeTitle`, the premium
/// chest's caption), so the finder must not match that too.
Finder _findPaywallBuyButton() =>
    find.textContaining('Upgrade Premium').hitTestable();

Finder _findPlanIntroBuyButton() => find.text('Mulai Premium').hitTestable();

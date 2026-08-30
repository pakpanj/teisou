import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';

import 'package:kana_master/core/constants/iap_products.dart';
import 'package:kana_master/core/providers.dart';
import 'package:kana_master/core/services/coin_spend_service.dart';
import 'package:kana_master/core/services/iap_service.dart';
import 'package:kana_master/features/battle/shop_tab.dart';
import 'package:kana_master/features/shop/widgets/coin_top_up_sheet.dart';

/// Regression coverage for the coin-purchase UX pass:
///
/// **Root cause fixed**: `IapService.outcomes` is one app-wide broadcast
/// stream shared by every purchase this app sells. `ShopTab` subscribes
/// to it for as long as it's alive — which, inside `ShopScreen`'s
/// `IndexedStack`, is the whole screen's lifetime, not just while the
/// Toko/skins sub-tab is showing. `CoinTopUpSheet` (opened from the same
/// `ShopScreen`, via `CoinBalanceBar`) subscribes to the identical
/// stream while its sheet is open. A coin Top Up completing therefore
/// used to fire **both** listeners: `CoinTopUpSheet`'s own (a polished
/// success message + closing the sheet) and `ShopTab`'s (an unrelated,
/// generic "Pembelian aktif" SnackBar for a purchase `ShopTab` never
/// initiated). Fixed by gating `ShopTab._onOutcome` on `_buying != null`
/// — it only reacts to an outcome while it is actually waiting on one of
/// its own purchases.
///
/// **Strategy**: fake `IapService`/`CoinSpendService` themselves (not
/// the lower Play Billing/Cloud Functions platform layers
/// `premium_purchase_reentrancy_test.dart` fakes) — this bug is entirely
/// about which *widgets* react to an outcome once it arrives, not about
/// how the outcome gets produced, so faking one level higher keeps the
/// real production `ShopTab`/`CoinTopUpSheet` state-machine code under
/// test while sidestepping an unrelated, much larger harness.
/// `_ScriptedIapService.productFor` always answers with a real (fake)
/// price, so every buy button in both widgets renders enabled — with the
/// real `IapService`, a `null` price hides/disables the button
/// entirely, which would make it untappable in this harness for no
/// reason relevant to the bug under test here.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // CoinPurchaseFlow.buy calls the real InAppPurchase.instance
    // .isAvailable() directly, bypassing IapService (and this file's
    // _ScriptedIapService) entirely for that one pre-check. Same
    // one-time-registration gotcha premium_purchase_reentrancy_test.dart
    // already documents: InAppPurchase.instance registers a REAL
    // platform the first time it's read in the whole process, so a fake
    // platform has to be installed before that read, targeting a
    // TargetPlatform InAppPurchase has no real implementation for so the
    // one-time registration stays inert.
    final original = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
    // ignore: unnecessary_statements
    InAppPurchase.instance;
    debugDefaultTargetPlatformOverride = original;
  });

  setUp(() {
    InAppPurchasePlatform.instance = _MinimalIapPlatform();
  });

  group('the duplicate-listener bug (ShopTab reacting to an unrelated '
      'Top Up)', () {
    testWidgets(
      'a coin Top Up completing while ShopTab is alive underneath must '
      'not also show ShopTab\'s own generic purchase message',
      (tester) async {
        final iap = _ScriptedIapService();
        final harness = await _harness(tester: tester, iap: iap);
        await tester.pumpWidget(harness.widget);
        await _settle(tester);

        // Open Top Up the same way CoinBalanceBar does — as a modal sheet
        // on top of the still-mounted ShopTab underneath.
        await _openCoinTopUpSheet(tester);
        await _tapPackBuyButton(tester, packIndex: 0); // 100-coin pack
        await _settle(tester);
        expect(iap.buyCoinPackCalls, [IapProducts.coinPack100]);

        // The store granting the purchase — the one event both listeners
        // observe.
        iap.emit(IapOutcome.delivered);
        await _settle(tester);

        final s = harness.container.read(appStringsProvider);
        expect(
          find.text(s.purchaseDelivered),
          findsNothing,
          reason:
              'FIX: ShopTab must stay silent for a purchase it never '
              'initiated — this exact text is what its old, unguarded '
              '_onOutcome used to show',
        );
        expect(
          find.text(s.coinTopUpSuccess(100)),
          findsOneWidget,
          reason: 'the sheet\'s own, single success message must still '
              'appear',
        );
        expect(
          find.byType(CoinTopUpSheet),
          findsNothing,
          reason: 'the sheet must still close itself on a real delivery',
        );
      },
    );

    testWidgets(
      'ShopTab still reacts to its own purchase outcome once it has one '
      'in flight',
      (tester) async {
        final iap = _ScriptedIapService();
        final harness = await _harness(tester: tester, iap: iap);
        await tester.pumpWidget(harness.widget);
        await _settle(tester);

        // The first FilledButton inside ShopTab is "Awan Putih"
        // (cloud_white)'s real-money buy button — the first paid,
        // not-owned skin.
        await tester.tap(
          find
              .descendant(
                of: find.byType(ShopTab),
                matching: find.byType(FilledButton),
              )
              .first,
        );
        await _settle(tester);
        expect(iap.buyCalls, [IapProducts.productIdForSkin('cloud_white')]);

        iap.emit(IapOutcome.cancelled);
        await _settle(tester);

        final s = harness.container.read(appStringsProvider);
        expect(
          find.text(s.purchaseCancelled),
          findsOneWidget,
          reason:
              'the guard must only suppress outcomes ShopTab did not '
              'start — its own in-flight purchase must still be reported',
        );
      },
    );
  });

  group('Top Up: exactly one success feedback path', () {
    testWidgets(
      'buying a pack shows the polished success message once, then '
      'closes the sheet',
      (tester) async {
        final iap = _ScriptedIapService();
        final harness = await _harness(
          tester: tester,
          iap: iap,
          includeShopTab: false,
        );
        await tester.pumpWidget(harness.widget);
        await _settle(tester);
        await _openCoinTopUpSheet(tester);

        await _tapPackBuyButton(tester, packIndex: 3); // 500-coin pack
        await _settle(tester);
        expect(iap.buyCoinPackCalls, [IapProducts.coinPack500]);

        iap.emit(IapOutcome.delivered);
        await _settle(tester);

        final s = harness.container.read(appStringsProvider);
        expect(find.text(s.coinTopUpSuccess(500)), findsOneWidget);
        expect(find.byType(CoinTopUpSheet), findsNothing);
      },
    );
  });

  group('coin item purchase: exactly one success feedback path', () {
    testWidgets(
      'buying a skin with coins shows the polished success message '
      'exactly once',
      (tester) async {
        final iap = _ScriptedIapService();
        final coinSpend = _ScriptedCoinSpendService();
        final harness = await _harness(
          tester: tester,
          iap: iap,
          coinSpend: coinSpend,
        );
        await tester.pumpWidget(harness.widget);
        await _settle(tester);

        // "Awan Putih" (cloud_white) is the first paid, not-owned skin —
        // its coin-buy button is the first monetization_on icon.
        await tester.tap(find.byIcon(Icons.monetization_on).first);
        await _settle(tester);

        final s = harness.container.read(appStringsProvider);
        await tester.tap(find.text(s.coinBuyConfirmButton));
        await _settle(tester);

        expect(coinSpend.calls, [(CoinSpendKind.skin, 'cloud_white')]);
        expect(find.text(s.coinBuySuccess), findsOneWidget);
      },
    );
  });

  group(
    'a purchase completing does not touch the app-wide startup gate',
    () {
      test(
        'neither CoinTopUpSheet nor ShopTab\'s outcome handling reads or '
        'refreshes appStartupProvider — the exact provider whose refresh '
        'used to bounce the whole app back to the Home tab (see '
        'global_refresh_glitch_test.dart)',
        () {
          final coinTopUpSource = File(
            'lib/features/shop/widgets/coin_top_up_sheet.dart',
          ).readAsStringSync();
          final shopTabSource = File(
            'lib/features/battle/shop_tab.dart',
          ).readAsStringSync();
          for (final source in [coinTopUpSource, shopTabSource]) {
            expect(source.contains('ref.refresh(appStartupProvider'), isFalse);
            expect(
              source.contains('ref.invalidate(appStartupProvider'),
              isFalse,
            );
          }
        },
      );
    },
  );

  group('the current shop tab stays mounted through a purchase', () {
    testWidgets(
      'ShopTab is not torn down/remounted by a Top Up completing above it',
      (tester) async {
        final iap = _ScriptedIapService();
        final harness = await _harness(tester: tester, iap: iap);
        await tester.pumpWidget(harness.widget);
        await _settle(tester);

        final beforeState = tester.state<State<ShopTab>>(
          find.byType(ShopTab),
        );

        await _openCoinTopUpSheet(tester);
        await _tapPackBuyButton(tester, packIndex: 0);
        await _settle(tester);
        iap.emit(IapOutcome.delivered);
        await _settle(tester);

        expect(
          find.byType(ShopTab),
          findsOneWidget,
          reason: 'ShopTab must still be on screen after the sheet closes',
        );
        expect(
          identical(
            tester.state<State<ShopTab>>(find.byType(ShopTab)),
            beforeState,
          ),
          isTrue,
          reason:
              'the exact same State instance must have survived — a '
              'fresh one would mean the tab was torn down and rebuilt, '
              'the "bounced to Home" bug\'s own signature',
        );
      },
    );
  });

  group(
    'existing purchase outcomes (success/failure/cancelled/pending) '
    'remain intact',
    () {
      for (final outcome in [
        IapOutcome.cancelled,
        IapOutcome.unavailable,
        IapOutcome.failed,
        IapOutcome.pendingVerification,
        IapOutcome.accountMismatch,
      ]) {
        testWidgets(
          'CoinTopUpSheet still shows the unchanged message for $outcome',
          (tester) async {
            final iap = _ScriptedIapService();
            final harness = await _harness(
              tester: tester,
              iap: iap,
              includeShopTab: false,
            );
            await tester.pumpWidget(harness.widget);
            await _settle(tester);
            await _openCoinTopUpSheet(tester);

            await _tapPackBuyButton(tester, packIndex: 0);
            await _settle(tester);

            iap.emit(outcome);
            await _settle(tester);

            final s = harness.container.read(appStringsProvider);
            final expected = switch (outcome) {
              IapOutcome.delivered => s.purchaseDelivered,
              IapOutcome.cancelled => s.purchaseCancelled,
              IapOutcome.unavailable => s.storeUnavailable,
              IapOutcome.failed => s.purchaseFailed,
              IapOutcome.pendingVerification => s.purchasePendingVerification,
              IapOutcome.accountMismatch => s.purchaseAccountMismatch,
            };
            expect(find.text(expected), findsOneWidget);
            // None of these are a "delivered" outcome, so the sheet must
            // stay open — only `delivered` pops it.
            expect(find.byType(CoinTopUpSheet), findsOneWidget);
          },
        );
      }
    },
  );
}

// ---------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------

/// Satisfies `CoinPurchaseFlow.buy`'s direct `InAppPurchase.instance
/// .isAvailable()` pre-check — see the `setUpAll`/`setUp` comments
/// above. Nothing else in this file's scenarios ever reaches this
/// platform layer: every actual purchase call goes through
/// `_ScriptedIapService` via `iapServiceProvider`.
class _MinimalIapPlatform extends InAppPurchasePlatform {
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => const Stream.empty();

  @override
  Future<bool> isAvailable() async => true;
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

/// Fakes `IapService` at its own public API, not the Play Billing
/// platform layer underneath it — this bug is about outcome-stream
/// routing between widgets, not about how a store purchase actually
/// completes, so this is the right altitude to fake at (see the file
/// doc comment above).
class _ScriptedIapService implements IapService {
  final _controller = StreamController<IapOutcome>.broadcast();
  final List<String> buyCalls = [];
  final List<String> buyCoinPackCalls = [];

  void emit(IapOutcome outcome) => _controller.add(outcome);

  @override
  Stream<IapOutcome> get outcomes => _controller.stream;

  @override
  Future<void> load(Set<String> ids) async {}

  @override
  Future<bool> buy(String productId, {required String uid}) async {
    buyCalls.add(productId);
    return true;
  }

  @override
  Future<bool> buyCoinPack(String productId, {required String uid}) async {
    buyCoinPackCalls.add(productId);
    return true;
  }

  @override
  Future<void> restore() async {}

  @override
  void notePremiumConfirmed() {}

  @override
  void dispose() {}

  @override
  bool get isAvailable => true;

  // Always non-null so every buy button in both widgets renders enabled
  // — with the real IapService a null price hides/disables the button,
  // which has nothing to do with the bug under test here.
  @override
  ProductDetails? productFor(String id) => ProductDetails(
        id: id,
        title: id,
        description: id,
        price: 'Rp-test',
        rawPrice: 1,
        currencyCode: 'IDR',
      );

  @override
  final Set<String> missingProducts = {};

  @override
  FirebaseFunctions? get functionsOverride => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ScriptedCoinSpendService implements CoinSpendService {
  final List<(CoinSpendKind, String)> calls = [];

  @override
  Future<bool> buy(CoinSpendKind kind, String id) async {
    calls.add((kind, id));
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Harness {
  _Harness(this.widget, this.container);
  final Widget widget;
  final ProviderContainer container;
}

/// [includeShopTab] false isolates CoinTopUpSheet's own behaviour from
/// the cross-widget scenario the first group exercises.
Future<_Harness> _harness({
  required WidgetTester tester,
  required _ScriptedIapService iap,
  CoinSpendService? coinSpend,
  bool includeShopTab = true,
}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(
    overrides: [
      appStartupProvider.overrideWith((ref) async => _FakeUser()),
      iapServiceProvider.overrideWithValue(iap),
      if (coinSpend != null)
        coinSpendServiceProvider.overrideWithValue(coinSpend),
      ownedSkinsProvider.overrideWith((ref) => Stream.value(const <String>{})),
    ],
  );
  addTearDown(container.dispose);
  await container.read(appStartupProvider.future);

  final widget = UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: Scaffold(
        body: includeShopTab ? const ShopTab() : const SizedBox.shrink(),
      ),
    ),
  );
  return _Harness(widget, container);
}

Future<void> _openCoinTopUpSheet(WidgetTester tester) async {
  final context = tester.element(find.byType(Scaffold).first);
  unawaited(
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CoinTopUpSheet(),
    ),
  );
  await _settle(tester);
}

/// Taps the [packIndex]-th (0-based, in `IapProducts.coinPackAmounts`'
/// own order: 100/200/350/500/700/1000) pack's buy button — scoped to
/// `CoinTopUpSheet` specifically, since `ShopTab` may also be mounted
/// in the same tree with its own `FilledButton`s.
Future<void> _tapPackBuyButton(
  WidgetTester tester, {
  required int packIndex,
}) async {
  final buttons = find.descendant(
    of: find.byType(CoinTopUpSheet),
    matching: find.byType(FilledButton),
  );
  await tester.tap(buttons.at(packIndex));
}

Future<void> _settle(WidgetTester tester, {int ticks = 8}) async {
  for (var i = 0; i < ticks; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

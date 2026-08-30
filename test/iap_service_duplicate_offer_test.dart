import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';

import 'package:kana_master/core/constants/iap_products.dart';
import 'package:kana_master/core/services/iap_service.dart';

/// AUDIT_PLAY_ITEM_UNAVAILABLE.md §5's finding: `IapService.load()` keys
/// `_products` by plain product id — but a Play Console subscription with
/// more than one base plan/offer returns one `ProductDetails` PER
/// base-plan/offer combination, all sharing the same `id`. Before this
/// fix, the `Map<String, ProductDetails>` construction silently kept
/// whichever entry Play happened to list last, with nothing to
/// distinguish "an offer was silently dropped" from "there was only ever
/// one". This test pins the current, deliberate behavior (last-wins,
/// unchanged — there's no UI to pick an offer, so last-wins is still the
/// only reasonable default) and, separately, that a duplicate is now
/// something a future session can actually notice.
///
/// **Setup mirrors `premium_purchase_reentrancy_test.dart`'s own proven
/// pattern** for faking `InAppPurchasePlatform.instance` — see that
/// file's doc comment for why `debugDefaultTargetPlatformOverride =
/// TargetPlatform.fuchsia` in [setUpAll] is required (the plugin facade
/// registers a REAL platform the first time it's read in the whole
/// process; targeting a platform with no real implementation makes that
/// one-time registration inert instead of leaking a real BillingClient
/// connection attempt).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    final original = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
    InAppPurchase.instance; // force the one-time lazy registration now
    debugDefaultTargetPlatformOverride = original;
  });

  test('a product id returned more than once (multiple base plans/offers) '
      'keeps exactly one entry, not a crash or a silently empty result',
      () async {
    final platform = _FakeIapPlatform([
      ProductDetails(
        id: IapProducts.premiumMonthly,
        title: 'Teisou Premium (offer A)',
        description: 'first offer',
        price: 'Rp9.000',
        rawPrice: 9000,
        currencyCode: 'IDR',
      ),
      ProductDetails(
        id: IapProducts.premiumMonthly,
        title: 'Teisou Premium (offer B)',
        description: 'second offer, listed last',
        price: 'Rp19.000',
        rawPrice: 19000,
        currencyCode: 'IDR',
      ),
    ]);
    InAppPurchasePlatform.instance = platform;

    final service = IapService();
    await service.load({IapProducts.premiumMonthly});

    final resolved = service.productFor(IapProducts.premiumMonthly);
    expect(resolved, isNotNull);
    // Documents the deliberate current behavior — the LAST entry in the
    // store's response wins, same as before this fix. What changed is
    // that this is no longer silent (see the debugPrint in load()) —
    // this test can't easily assert on a debugPrint call, so it exists
    // to keep the resulting *behavior* pinned instead.
    expect(resolved!.rawPrice, 19000,
        reason: 'last offer in the response should be the one kept');
  });

  test('a single, non-duplicated product id is completely unaffected',
      () async {
    final platform = _FakeIapPlatform([
      ProductDetails(
        id: IapProducts.premiumMonthly,
        title: 'Teisou Premium',
        description: 'only offer',
        price: 'Rp19.000',
        rawPrice: 19000,
        currencyCode: 'IDR',
      ),
    ]);
    InAppPurchasePlatform.instance = platform;

    final service = IapService();
    await service.load({IapProducts.premiumMonthly});

    expect(service.productFor(IapProducts.premiumMonthly)?.rawPrice, 19000);
  });
}

class _FakeIapPlatform extends InAppPurchasePlatform {
  _FakeIapPlatform(this._products);

  final List<ProductDetails> _products;
  final _purchaseController = StreamController<List<PurchaseDetails>>.broadcast();

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _purchaseController.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async {
    return ProductDetailsResponse(
      productDetails: _products,
      notFoundIDs: const [],
    );
  }
}

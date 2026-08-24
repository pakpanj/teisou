import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../constants/iap_products.dart';
import '../localization/app_strings.dart';
import '../providers.dart';
import 'iap_service.dart';

/// The "top up coins" dance — [PremiumPurchaseFlow]'s sibling, kept as a
/// separate class rather than a second method there because a coin pack
/// buys through [IapService.buyCoinPack] (consumable), not [IapService
/// .buy] (non-consumable), and the two must never be interchangeable —
/// see [IapService.buyCoinPack]'s own doc comment for exactly why an
/// auto-consumed purchase would break verification.
class CoinPurchaseFlow {
  CoinPurchaseFlow(this._ref);

  final WidgetRef _ref;

  IapService get _iap => _ref.read(iapServiceProvider);

  Stream<IapOutcome> get outcomes => _iap.outcomes;

  /// Asks the store what every coin pack costs. Safe to call from
  /// `initState`: a no-op while purchases are switched off, and safe to
  /// call more than once.
  Future<void> loadPrices() =>
      _iap.load(IapProducts.coinPackAmounts.keys.toSet());

  /// The store's own localised price for [productId], or null before
  /// [loadPrices] answers.
  String? priceFor(String productId) => _iap.productFor(productId)?.price;

  /// Opens the store's purchase sheet for one coin pack. Shows its own
  /// snackbar on every early-exit path, mirroring
  /// [PremiumPurchaseFlow.buy] exactly.
  Future<void> buy(BuildContext context, AppStrings s, String productId) async {
    final available = await InAppPurchase.instance.isAvailable();
    if (!context.mounted) return;
    if (!available) {
      _snack(context, s.storeUnavailable);
      return;
    }

    await loadPrices();
    if (!context.mounted) return;

    if (_iap.productFor(productId) == null) {
      _snack(context, s.purchaseNotSetUp);
      return;
    }
    final uid = _ref.read(appStartupProvider).valueOrNull?.uid;
    if (uid == null) {
      _snack(context, s.purchaseFailed);
      return;
    }
    await _iap.buyCoinPack(productId, uid: uid);
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

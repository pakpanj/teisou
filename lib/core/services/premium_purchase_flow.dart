import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../constants/iap_products.dart';
import '../localization/app_strings.dart';
import '../providers.dart';
import 'iap_service.dart';

/// The "buy Teisou Premium" dance, written once.
///
/// **Three screens now need this**: the module paywall
/// (`PaywallScreen`), the profile premium card, and the plan-intro
/// screen shown right after the age question. Each used to hand-roll
/// its own load/buy/restore/listen-for-outcome sequence — harmless
/// duplication while there was only one, a real risk of drift now that
/// there are three, since the one rule that actually matters (never buy
/// without binding the purchase to `uid`, see `IapService.buy`'s own
/// doc comment) would then need remembering correctly in three places
/// instead of one.
///
/// Deliberately a plain class, not a Riverpod provider: it holds no
/// state of its own beyond the [WidgetRef] it was built with, and each
/// screen's own `State` is what actually needs to react to outcomes
/// (show a snackbar, pop, refresh) — that reaction is different per
/// screen, so it stays with the caller instead of being centralised
/// here too.
class PremiumPurchaseFlow {
  PremiumPurchaseFlow(this._ref);

  final WidgetRef _ref;

  IapService get _iap => _ref.read(iapServiceProvider);

  /// The store's own result stream — a purchase can be approved by a
  /// parent hours later, or restored on a different phone entirely, so
  /// nothing here ever waits on [buy] itself to know what happened.
  Stream<IapOutcome> get outcomes => _iap.outcomes;

  /// Asks the store what Premium costs. Safe to call from `initState`:
  /// a no-op while [IapProducts.purchasesEnabled] is off, and safe to
  /// call more than once.
  Future<void> loadPrice() => _iap.load(IapProducts.all(const []));

  /// The store's own localised price, or null before [loadPrice]
  /// answers (or while purchases are switched off). Never hardcoded —
  /// see `shop_tab.dart`'s own doc comment for why.
  String? get price => _iap.productFor(IapProducts.premiumMonthly)?.price;

  /// Opens the store's purchase sheet for the one subscription this app
  /// sells. Shows its own snackbar on every early-exit path, so a
  /// caller only needs to await this and otherwise do nothing.
  Future<void> buy(BuildContext context, AppStrings s) async {
    final available = await InAppPurchase.instance.isAvailable();
    if (!context.mounted) return;
    if (!available) {
      _snack(context, s.storeUnavailable);
      return;
    }

    await loadPrice();
    if (!context.mounted) return;

    // A product the store has never heard of is not an error to show
    // as a failure — it means nobody has created it in Play Console
    // yet, which is a different sentence and a different person's job.
    if (_iap.productFor(IapProducts.premiumMonthly) == null) {
      _snack(context, s.purchaseNotSetUp);
      return;
    }
    final uid = _ref.read(appStartupProvider).valueOrNull?.uid;
    if (uid == null) {
      _snack(context, s.purchaseFailed);
      return;
    }
    await _iap.buy(IapProducts.premiumMonthly, uid: uid);
  }

  /// Re-delivers anything already bought — a new phone, a reinstall.
  Future<void> restore() => _iap.restore();

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

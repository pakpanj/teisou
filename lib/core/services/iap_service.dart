import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../constants/iap_products.dart';


/// What happened to a purchase attempt, in terms the UI can act on.
enum IapOutcome {
  /// Bought and granted. The entitlement is on the server by the time
  /// this is reported.
  delivered,

  /// The learner backed out of the store sheet. Not an error, and must
  /// not be shown as one.
  cancelled,

  /// The store refused, or the network failed, or verification said no.
  failed,

  /// The store is not available at all — an emulator without Play
  /// services, a device signed out of the store.
  unavailable,
}

/// Buying things, and the one rule that makes it worth doing.
///
/// **The client never grants what it just bought.** It hands the store's
/// purchase token to a Cloud Function, which asks Google whether that
/// token is real and writes the entitlement with admin privileges;
/// `firestore.rules` forbids the client from writing `subscription` or
/// `entitlements` at all. Without that split the whole flow is theatre —
/// anyone who can run a modified client would simply write
/// `tier: premium` themselves, which until now they could.
///
/// Purchases arrive on a **stream, not as the result of the buy call**.
/// That is not an inconvenience to work around: a purchase can complete
/// while the app is closed, be restored on a new device, or be approved
/// hours later by a parent. So the stream is listened to for the app's
/// whole life and delivery is idempotent — verifying the same token
/// twice grants the same thing once.
class IapService {
  IapService({
    InAppPurchase? store,
    FirebaseFunctions? functions,
  })  : _store = store ?? InAppPurchase.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final InAppPurchase _store;
  final FirebaseFunctions _functions;

  StreamSubscription<List<PurchaseDetails>>? _sub;
  final _outcomes = StreamController<IapOutcome>.broadcast();

  /// Reported per purchase, so a screen can show its own result without
  /// having to guess which of several in-flight buys finished.
  Stream<IapOutcome> get outcomes => _outcomes.stream;

  final Map<String, ProductDetails> _products = {};
  bool _available = false;

  /// Ids the store did not recognise. Surfaced rather than swallowed:
  /// this is the difference between "nothing is for sale" and "somebody
  /// has not created these in Play Console yet", and the two look
  /// identical in the UI otherwise.
  final Set<String> missingProducts = {};

  bool get isAvailable => _available;

  ProductDetails? productFor(String id) => _products[id];

  /// Starts listening and asks the store what [ids] cost.
  ///
  /// Safe to call more than once; the listener is only attached once.
  Future<void> load(Set<String> ids) async {
    // The master switch, enforced here rather than at the call sites, so
    // that no screen can reach a store by forgetting to check it. With
    // purchases off nothing is asked of the store at all — not even
    // whether it exists — so `isAvailable` stays false and every shop
    // surface reads as "not open yet" on its own.
    if (!IapProducts.purchasesEnabled) return;
    _available = await _store.isAvailable();
    if (!_available) return;

    _sub ??= _store.purchaseStream.listen(
      _onPurchases,
      onError: (_) => _outcomes.add(IapOutcome.failed),
    );

    final response = await _store.queryProductDetails(ids);
    _products
      ..clear()
      ..addEntries(response.productDetails.map((p) => MapEntry(p.id, p)));
    missingProducts
      ..clear()
      ..addAll(response.notFoundIDs);
    if (missingProducts.isNotEmpty) {
      debugPrint(
        'IAP: these ids do not exist in the store yet: $missingProducts',
      );
    }
  }

  /// Opens the store's own purchase sheet. The result arrives on
  /// [outcomes], not from this call — see the class comment.
  ///
  /// [uid] is attached to the purchase as the store's obfuscated account
  /// id, and **the server refuses any token that does not carry it**.
  /// Without it one real purchase token replays for every account that
  /// sends it: one payment, unlimited premium, and nothing that looks
  /// wrong from either side. See `functions/iap_states.js`.
  Future<bool> buy(String productId, {required String uid}) async {
    if (!IapProducts.purchasesEnabled) {
      _outcomes.add(IapOutcome.unavailable);
      return false;
    }
    final product = _products[productId];
    if (product == null) {
      _outcomes.add(_available ? IapOutcome.failed : IapOutcome.unavailable);
      return false;
    }
    final param = PurchaseParam(
      productDetails: product,
      applicationUserName: uid,
    );
    // A subscription is non-consumable; so is a skin, which is bought
    // once and owned forever. Nothing here is consumable, so nothing is
    // ever bought twice.
    return _store.buyNonConsumable(purchaseParam: param);
  }

  /// Re-delivers anything already bought — a new phone, a reinstall, a
  /// wipe. Stores require this to exist, and a learner who paid and lost
  /// it has no other way back.
  Future<void> restore() async {
    if (!IapProducts.purchasesEnabled || !_available) {
      _outcomes.add(IapOutcome.unavailable);
      return;
    }
    await _store.restorePurchases();
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          // Deliberately silent. A pending purchase is normal — parental
          // approval, a slow bank — and saying anything here would
          // either promise something that has not happened or report a
          // failure that has not happened either.
          break;
        case PurchaseStatus.canceled:
          _outcomes.add(IapOutcome.cancelled);
        case PurchaseStatus.error:
          _outcomes.add(IapOutcome.failed);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final granted = await _verify(purchase);
          _outcomes.add(granted ? IapOutcome.delivered : IapOutcome.failed);
      }

      // **Always completed, even when verification failed.** An
      // incomplete purchase is redelivered by the store on every launch
      // forever, and on iOS blocks every later purchase. A token that
      // failed verification is not lost by completing it — `restore()`
      // brings it back, and the server can be asked again.
      if (purchase.pendingCompletePurchase) {
        await _store.completePurchase(purchase);
      }
    }
  }

  /// Hands the token to the server and lets it decide.
  Future<bool> _verify(PurchaseDetails purchase) async {
    try {
      final result = await _functions.httpsCallable('verifyPurchase').call({
        'productId': purchase.productID,
        'purchaseToken':
            purchase.verificationData.serverVerificationData,
        'platform': defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android',
      });
      final data = result.data;
      return data is Map && data['granted'] == true;
    } catch (_) {
      // A verification that cannot be reached is not a grant. The
      // purchase is not lost — the store still has it, and restore asks
      // again — but nothing opens until the server says so.
      return false;
    }
  }

  void dispose() {
    _sub?.cancel();
    _outcomes.close();
  }
}

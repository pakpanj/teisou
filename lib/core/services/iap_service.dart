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

  /// The store genuinely refused, or verification came back with a
  /// definitive rejection (the purchase is cancelled/expired, or bought
  /// by a different account). Distinct from [pendingVerification], which
  /// is what a purchase that is real but not yet provably real gets
  /// instead — see that value's own doc comment for why the two must
  /// never be shown the same way.
  failed,

  /// The store already took the money — `PurchaseStatus.purchased`
  /// really happened — but the server could not yet confirm it grants,
  /// and the failure looked like Play still catching up on a purchase
  /// that just happened rather than a real rejection (see
  /// `functions/iap_states.js`'s `isRetryablePlayState`). The server
  /// already retried a few times on its own before reporting this; by
  /// the time it reaches here, further retrying from the client would
  /// just be guessing at the same race again.
  ///
  /// **Must never be shown as "gagal" / "failed"** — the transaction
  /// already succeeded from the buyer's side, telling them otherwise
  /// after money changed hands is the exact bug this value exists to
  /// close. The one real recovery path: `IapService.notePremiumConfirmed`
  /// watches `subscription.tier` live and emits a real [delivered] the
  /// moment Firestore says premium — however that entitlement actually
  /// lands (a later retry, an RTDN reconciliation, or a manual restore),
  /// nothing here has to guess which — so a screen only ever needs to
  /// already handle [delivered] correctly; this state is a waiting room,
  /// not a dead end.
  pendingVerification,

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
    this.functionsOverride,
  }) : _store = store ?? InAppPurchase.instance;

  final InAppPurchase _store;

  // Deliberately not resolved in the constructor: `FirebaseFunctions
  // .instance` needs `Firebase.initializeApp()` to have already run,
  // and this class is now built eagerly — `PaywallScreen`/`ShopTab`
  // both load prices in `initState`, which happens the moment either
  // screen mounts. Resolving it lazily, only when a purchase is
  // actually verified, means constructing an `IapService` (or loading
  // prices, buying, or restoring) never requires Firebase to exist —
  // only completing a real purchase does. A widget test that mounts
  // either screen without a live Firebase app depends on this staying
  // lazy.
  final FirebaseFunctions? functionsOverride;
  FirebaseFunctions? _functions;
  FirebaseFunctions get _fx =>
      _functions ??= functionsOverride ?? FirebaseFunctions.instance;

  StreamSubscription<List<PurchaseDetails>>? _sub;
  final _outcomes = StreamController<IapOutcome>.broadcast();

  /// Whether a purchase is currently sitting in [IapOutcome.pendingVerification]
  /// waiting for the truth to catch up — the one thing [notePremiumConfirmed]
  /// checks before turning a Firestore update into a synthetic
  /// [IapOutcome.delivered]. Without this guard, *any* live subscription
  /// change (a renewal, an unrelated RTDN reconciliation, opening the app
  /// on a device that was already premium) would fire a "purchase
  /// delivered!" outcome at every screen currently listening, which is
  /// wrong outside of an actual pending purchase recovering.
  bool _awaitingPendingConfirmation = false;

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
    // once and owned forever.
    return _store.buyNonConsumable(purchaseParam: param);
  }

  /// Same shape as [buy], for a coin pack — the one thing this app sells
  /// that's meant to be bought again. **`autoConsume: false`
  /// deliberately** — the plugin's own auto-consume calls
  /// `BillingClient.consumeAsync` on the device right after purchase,
  /// which marks the purchase consumed on Play's servers almost
  /// immediately. If that happened before `_verify` below ran,
  /// `functions/iap.js`'s `purchases.products.get` would see
  /// `consumptionState: 1` and refuse to grant coins for a purchase that
  /// was completely real — the exact failure `productGrants` (in
  /// `functions/iap_states.js`) exists to catch for a *replay*, now
  /// firing on the first legitimate attempt instead. So the app leaves
  /// the purchase unconsumed locally; the server consumes it (via the
  /// Play Developer API, after granting) once verification actually
  /// succeeds, and only then can the pack be bought again.
  Future<bool> buyCoinPack(String productId, {required String uid}) async {
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
    return _store.buyConsumable(purchaseParam: param, autoConsume: false);
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
          _awaitingPendingConfirmation = false;
          _outcomes.add(IapOutcome.cancelled);
        case PurchaseStatus.error:
          _awaitingPendingConfirmation = false;
          _outcomes.add(IapOutcome.failed);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final result = await _verify(purchase);
          if (result.granted) {
            _awaitingPendingConfirmation = false;
            _outcomes.add(IapOutcome.delivered);
          } else if (result.retryable) {
            // The store already took the money; the server already
            // retried a few times on its own (see functions/iap.js's
            // verifyWithPlay) and still could not confirm it grants.
            // notePremiumConfirmed picks this up the moment Firestore
            // says otherwise — see that method and IapOutcome
            // .pendingVerification's own doc comments for the full
            // recovery path.
            _awaitingPendingConfirmation = true;
            _outcomes.add(IapOutcome.pendingVerification);
          } else {
            _awaitingPendingConfirmation = false;
            _outcomes.add(IapOutcome.failed);
          }
      }

      // **Always completed, even when verification failed or is still
      // pending.** An incomplete purchase is redelivered by the store on
      // every launch forever, and on iOS blocks every later purchase.
      // Completing it does not lose the purchase either way: on Android
      // this is `BillingClient.acknowledgePurchase`, which does not
      // consume or remove ownership — `restorePurchases()`'s own
      // `queryPurchases` call returns a purchase regardless of its
      // acknowledged state, confirmed by reading the installed
      // `in_app_purchase_android` package source directly rather than
      // assumed. So a purchase that is still `pendingVerification` stays
      // fully recoverable via restore/a later retry either way, while
      // *not* completing it risks Play auto-refunding an unacknowledged
      // purchase after 3 days for no benefit.
      if (purchase.pendingCompletePurchase) {
        await _store.completePurchase(purchase);
      }
    }
  }

  /// Hands the token to the server and lets it decide.
  ///
  /// [retryable] on a non-grant distinguishes a purchase the server is
  /// still trying to confirm (Play propagation lag — see
  /// `functions/iap_states.js`'s `isRetryablePlayState`) from one it has
  /// definitively rejected. The server already retried internally before
  /// answering; this is read off `FirebaseFunctionsException.details`,
  /// not decided here.
  Future<({bool granted, bool retryable})> _verify(
    PurchaseDetails purchase,
  ) async {
    // Correlates this attempt's client and server log lines without ever
    // sending or logging the verification token itself — Play's own
    // purchase id is already a non-sensitive, already-available value,
    // so nothing new (like a uuid package) is needed just for this.
    final requestId = purchase.purchaseID ??
        'local_${DateTime.now().microsecondsSinceEpoch}';
    try {
      final result = await _fx.httpsCallable('verifyPurchase').call({
        'productId': purchase.productID,
        'purchaseToken':
            purchase.verificationData.serverVerificationData,
        'platform': defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android',
        'requestId': requestId,
      });
      final data = result.data;
      final granted = data is Map && data['granted'] == true;
      debugPrint(
        'IAP verify requestId=$requestId productId=${purchase.productID} '
        'status=${purchase.status} granted=$granted',
      );
      return (granted: granted, retryable: false);
    } on FirebaseFunctionsException catch (e) {
      final retryable =
          e.details is Map && (e.details as Map)['retryable'] == true;
      debugPrint(
        'IAP verify requestId=$requestId productId=${purchase.productID} '
        'status=${purchase.status} granted=false code=${e.code} '
        'retryable=$retryable message=${e.message}',
      );
      return (granted: false, retryable: retryable);
    } catch (e) {
      // A verification that cannot be reached at all (no network, an
      // unexpected client-side error) is not a grant, and not something
      // the server ever weighed in on — so it is not eligible for the
      // pendingVerification recovery path either, only a plain retry via
      // restore() once connectivity comes back.
      debugPrint(
        'IAP verify requestId=$requestId productId=${purchase.productID} '
        'status=${purchase.status} granted=false unexpected '
        'error=${e.runtimeType}',
      );
      return (granted: false, retryable: false);
    }
  }

  /// The recovery path for [IapOutcome.pendingVerification] — called from
  /// `iapServiceProvider`'s own live watch of `subscriptionProvider`
  /// (Firestore's `subscription.tier`, the actual source of truth) rather
  /// than from anything this class does on its own, since entitlement can
  /// land from any of several places: a later client retry, an RTDN
  /// reconciliation (`functions/subscription_notifications.js`), or a
  /// manual restore. None of those need their own bespoke "now unblock
  /// the UI" code — they all eventually write `subscription.tier:
  /// 'premium'`, and this is the one place that turns that into a real
  /// [IapOutcome.delivered] on the same stream every purchase screen
  /// already listens to.
  ///
  /// A no-op unless something is actually waiting — see
  /// [_awaitingPendingConfirmation]'s own doc comment for why that guard
  /// exists.
  void notePremiumConfirmed() {
    if (!_awaitingPendingConfirmation) return;
    _awaitingPendingConfirmation = false;
    _outcomes.add(IapOutcome.delivered);
  }

  void dispose() {
    _sub?.cancel();
    _outcomes.close();
  }
}

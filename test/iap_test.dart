import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/constants/card_skins.dart';
import 'package:kana_master/core/constants/iap_products.dart';

/// The money path.
///
/// **Every failure here is silent and expensive.** A product id typed
/// differently in two places sells nothing and looks like an empty shop;
/// a client that can write its own entitlement makes verification
/// pointless without any symptom at all. None of it crashes, and none of
/// it looks wrong in a screenshot.
void main() {
  group('product ids', () {
    /// Store product ids can never be renamed or reused once created,
    /// and a learner who bought one must still own it years later. So
    /// the round trip is pinned rather than trusted to two string
    /// operations that happen to agree today.
    test('a skin id survives the round trip through its product id', () {
      for (final skin in CardSkinPresets.ofSource(CardSkinSource.paid)) {
        final productId = IapProducts.productIdForSkin(skin.id);
        expect(IapProducts.skinIdFor(productId), skin.id);
      }
    });

    test('a non-skin product is not mistaken for a skin', () {
      expect(IapProducts.skinIdFor(IapProducts.premiumMonthly), isNull);
    });

    /// The set asked of the store is built from the shop's own list, so
    /// a skin added to the shop is asked for automatically. If this ever
    /// became a hand-typed list, a new skin would show "Segera" for ever
    /// and nobody would know why.
    test('every paid skin is asked for by name', () {
      final paid =
          CardSkinPresets.ofSource(CardSkinSource.paid).map((s) => s.id);
      final asked = IapProducts.all(paid);
      expect(asked, contains(IapProducts.premiumMonthly));
      for (final id in paid) {
        expect(asked, contains(IapProducts.productIdForSkin(id)));
      }
      for (final id in IapProducts.coinPackAmounts.keys) {
        expect(asked, contains(id));
      }
      // Premium + every paid skin + every coin pack, nothing extra.
      expect(
        asked.length,
        paid.length + 1 + IapProducts.coinPackAmounts.length,
      );
    });

    /// Event skins are handed out, never sold. One appearing in the
    /// store list would mean selling something whose whole point is that
    /// it cannot be bought.
    test('nothing outside the paid family is ever offered for sale', () {
      final asked = IapProducts.all(
        CardSkinPresets.ofSource(CardSkinSource.paid).map((s) => s.id),
      );
      for (final skin in CardSkinPresets.all) {
        if (skin.source == CardSkinSource.paid) continue;
        expect(
          asked.contains(IapProducts.productIdForSkin(skin.id)),
          isFalse,
          reason: '${skin.id} is ${skin.source.name}, not for sale',
        );
      }
    });
  });

  group('the client cannot grant itself anything', () {
    final rules = File('firestore.rules').readAsStringSync();

    /// The rule that makes server verification worth doing. Without it
    /// the Cloud Function is theatre: anyone running a modified client
    /// writes `tier: premium` themselves, exactly as they could before
    /// anything was for sale.
    test('subscription and entitlements are refused on update', () {
      // The **call**, not the definition. Checking only that the
      // function exists passes happily while nothing invokes it, which
      // is exactly the state this test was first written in — deleting
      // the call site left it green.
      expect(
        rules.contains('&& isAllowedPurchaseWrite()'),
        isTrue,
        reason: 'the rule is defined but never applied to a write',
      );
      expect(
        rules.contains("request.resource.data.get('subscription', {}) == oldSub"),
        isTrue,
        reason: 'subscription is not actually frozen',
      );
      expect(
        rules.contains("request.resource.data.get('entitlements', {}) == oldEnt"),
        isTrue,
        reason: 'entitlements is not actually frozen',
      );
      expect(
        rules.contains("request.resource.data.get('coins', 0) == oldCoins"),
        isTrue,
        reason: 'coins is not actually frozen — a client could top itself '
            'up for free',
      );
    });

    /// A new user document is written by the client, so it has to be
    /// allowed through — but only carrying the free tier it is created
    /// with. Otherwise the gate is simply moved: delete the document,
    /// recreate it premium.
    test('a fresh document cannot be created already premium', () {
      expect(
        rules.contains("request.resource.data.get('subscription', {})"),
        isTrue,
      );
      expect(rules.contains("!('entitlements' in request.resource.data)"), isTrue);
    });

    test('a fresh document cannot be created already holding coins', () {
      expect(
        rules.contains("request.resource.data.get('coins', 0) == 0"),
        isTrue,
      );
    });
  });

  group('the server decides', () {
    final iap = File('functions/iap.js').readAsStringSync();

    /// Failing closed is the whole design. If verification is not
    /// configured the function must refuse — a paywall that opens for
    /// everyone during setup is discovered in the revenue figures months
    /// later, where one that opens for nobody is discovered the first
    /// time it is tested.
    test('an unverifiable purchase is refused, not granted', () {
      expect(iap.contains('failed-precondition'), isTrue);
      // The refusal has to come before the write, or it refuses nothing.
      // `.set(patch` itself no longer appears literally — the entitlement
      // write moved inside the processed-token transaction added for
      // coin packs — so this checks for the transaction's own patch
      // write instead, still positioned after the config check.
      expect(
        iap.indexOf('playConfigured()') <
            iap.indexOf('tx.set(userRef, patch'),
        isTrue,
        reason: 'the entitlement is written before the check',
      );
    });

    test('a coin pack increments rather than replaces the balance', () {
      expect(iap.contains('FieldValue.increment(COIN_PACKS[productId])'),
          isTrue);
    });

    test('a purchase token can only ever grant once, even on replay', () {
      // The safeguard `increment` specifically needs, unlike the
      // set-merge/arrayUnion patches subscriptions and skins already used
      // — see this file's own comment for why a coin pack can't rely on
      // that same idempotency.
      expect(iap.contains('processedPurchaseTokens'), isTrue);
      expect(iap.contains('if (tokenSnap.exists) return;'), isTrue);
    });

    test('a coin pack is consumed after granting, not before or never', () {
      final consumeIndex = iap.indexOf('purchases.products.consume');
      final transactionIndex = iap.indexOf('db.runTransaction');
      expect(consumeIndex, greaterThan(-1));
      expect(
        transactionIndex < consumeIndex,
        isTrue,
        reason: 'consuming before the grant lands would let a crash '
            'between the two burn the purchase for nothing',
      );
    });

    test('an unknown product is refused rather than ignored', () {
      expect(iap.contains('Unknown product'), isTrue);
    });
  });

  /// The client half of the account binding. The server refuses a token
  /// that does not carry the buyer's uid, so a call site that forgets to
  /// send one sells nothing — and the symptom is a purchase that takes
  /// the money and then reports failure, which is the worst possible
  /// way to find out.
  ///
  /// **Two shapes now, not one.** `shop_tab.dart` still calls
  /// `IapService.buy` directly for skin purchases. Every "buy Premium"
  /// site (`paywall_screen.dart`, the profile premium card, the
  /// plan-intro screen) instead goes through `PremiumPurchaseFlow.buy`
  /// — written once specifically so the uid-binding rule only has to be
  /// correct in one place (`premium_purchase_flow.dart`) rather than
  /// re-verified in every screen that offers Premium. Checking each
  /// call site directly for `uid: uid` again would just re-introduce
  /// the duplication the refactor removed; checking the shared helper
  /// once, and that every Premium call site actually routes through it,
  /// is the real invariant here.
  group('purchases are bound to an account', () {
    test('the shop still binds its direct skin purchases to a uid', () {
      final source = File('lib/features/battle/shop_tab.dart').readAsStringSync();
      // Scoped to `IapService.buy` specifically, not every `.buy(` in the
      // file — `shop_tab.dart` also calls `CoinSpendService.buy` (added
      // 2026-08-24, the skins' coin-purchase path), which has no uid
      // parameter to bind at all: the Cloud Function it calls already
      // scopes the spend to whoever is signed in server-side, the same
      // way every other `CoinSpendService.buy` call site in this app
      // (avatar/frame/cover pickers) works. A blanket `.buy(` count would
      // wrongly demand a `uid:` argument that call was never meant to
      // have.
      final calls = RegExp(r'iapServiceProvider\)\s*\.buy\(')
          .allMatches(source)
          .length;
      expect(calls, greaterThan(0), reason: 'shop_tab.dart buys nothing');
      expect(
        RegExp(r'uid: uid').allMatches(source).length,
        greaterThanOrEqualTo(calls),
        reason: 'shop_tab.dart buys without binding the purchase to an account',
      );
    });

    test('PremiumPurchaseFlow — the one place Premium is actually '
        'bought — binds the purchase to a uid', () {
      final source =
          File('lib/core/services/premium_purchase_flow.dart').readAsStringSync();
      expect(
        RegExp(r'\.buy\([^)]*uid: uid', dotAll: true).hasMatch(source),
        isTrue,
        reason: 'PremiumPurchaseFlow.buy no longer binds a uid — every '
            'Premium call site trusts this one place to do it',
      );
    });

    test('every Premium call site routes through PremiumPurchaseFlow '
        'rather than calling IapService directly', () {
      for (final path in [
        'lib/features/paywall/paywall_screen.dart',
        'lib/features/profile/widgets/premium_card.dart',
        'lib/features/onboarding/plan_intro_screen.dart',
      ]) {
        final source = File(path).readAsStringSync();
        expect(
          source.contains('PremiumPurchaseFlow'),
          isTrue,
          reason: '$path offers Premium without going through '
              'PremiumPurchaseFlow — the uid-binding guarantee only '
              'holds if every call site actually uses it',
        );
        // Never IapService.buy called directly here — that would bypass
        // the shared wrapper this whole group exists to trust.
        expect(
          RegExp(r'\biap\.buy\(|iapServiceProvider\)\.buy\(').hasMatch(source),
          isFalse,
          reason: '$path calls IapService.buy directly, bypassing '
              'PremiumPurchaseFlow',
        );
      }
    });
  });

  /// The kill switch. The whole purchase flow stays compiled and tested
  /// while nothing is on sale, which is only safe if "off" really means
  /// off — a switch that merely hides buttons leaves every other path to
  /// the store open, and the one that gets forgotten is the one that
  /// takes somebody's money for a product that does not exist.
  group('purchases can be switched off without deleting the code', () {
    test('the switch is enforced inside the service, not at call sites', () {
      final source =
          File('lib/core/services/iap_service.dart').readAsStringSync();
      for (final entry in ['load', 'buy', 'buyCoinPack', 'restore']) {
        // Each entry point must consult the switch itself. Sliced to the
        // real method body — a fixed character window read past the end
        // of one method into the next, which would let an unguarded
        // method pass on its neighbour's check.
        final start = source.indexOf('> $entry(');
        expect(start, greaterThan(-1), reason: '$entry is gone');
        final rest = source.substring(start);
        final end = rest.indexOf('  /// ', 1);
        final body = end == -1 ? rest : rest.substring(0, end);
        expect(
          body.contains('IapProducts.purchasesEnabled'),
          isTrue,
          reason: '$entry can reach the store with purchases switched off',
        );
      }
    });

    test('nothing is offered for sale while the switch is off', () {
      // Guards the pairing rather than the value: if selling is ever
      // turned on, this test does nothing and the buttons come back.
      if (IapProducts.purchasesEnabled) return;
      final paywall =
          File('lib/features/paywall/paywall_screen.dart').readAsStringSync();
      expect(
        paywall.contains('if (IapProducts.purchasesEnabled)'),
        isTrue,
        reason: 'the paywall offers a purchase that cannot complete',
      );
      // ...and the way through must survive, or a gated module becomes a
      // dead end for everyone.
      expect(paywall.contains('_watchAdForPreview'), isTrue);
    });
  });

  /// The 25 Aug 2026 bug: Google/DANA charged real money, the purchase
  /// really did complete, and the app still told the buyer "Kamu tidak
  /// ditagih" (you have not been charged) because a temporary
  /// verification failure was shown identically to a real rejection.
  /// `IapOutcome.pendingVerification` exists specifically so a purchase
  /// that succeeded on the buyer's side is never told otherwise — this
  /// group pins that every screen that can show a purchase result
  /// actually handles the new state, and that the client-side logging
  /// added alongside it never puts the verification token where it could
  /// be read back out and replayed.
  group('a purchase that succeeded is never told it failed', () {
    final iapService =
        File('lib/core/services/iap_service.dart').readAsStringSync();

    test('IapOutcome has a state between delivered and failed', () {
      expect(iapService.contains('pendingVerification'), isTrue);
    });

    test('a retryable non-grant is read from the server, not decided by '
        'guessing on the client', () {
      expect(iapService.contains('e.details is Map'), isTrue);
      expect(iapService.contains("['retryable'] == true"), isTrue);
    });

    /// Without this, the only way out of `pendingVerification` would be
    /// closing the app and hoping — see `iapServiceProvider` in
    /// `providers.dart` for the other half (the live Firestore watch
    /// that actually calls this).
    test('there is a real way out of pendingVerification once entitlement '
        'lands, however it lands', () {
      expect(iapService.contains('void notePremiumConfirmed()'), isTrue);
      expect(
        iapService.contains('_outcomes.add(IapOutcome.delivered)'),
        isTrue,
      );
    });

    test('a purchase is always completed, pendingVerification included — '
        'never left to auto-refund or nag on every launch', () {
      // `completePurchase` sits after the whole status switch, not
      // inside any one branch — otherwise pendingVerification (or any
      // other newly-added branch) could silently skip it.
      final switchIndex = iapService.indexOf('switch (purchase.status)');
      final completeIndex = iapService.indexOf(
        'await _store.completePurchase(purchase)',
      );
      expect(switchIndex, greaterThan(-1));
      expect(completeIndex, greaterThan(switchIndex));
    });

    test('nothing client-side ever logs the verification token', () {
      final calls =
          RegExp(r'debugPrint\([\s\S]*?\);').allMatches(iapService);
      expect(calls.isNotEmpty, isTrue, reason: 'no debugPrint calls found — did logging get removed?');
      for (final match in calls) {
        final call = match.group(0)!;
        expect(
          call.contains('serverVerificationData') ||
              call.contains('purchaseToken'),
          isFalse,
          reason: 'a debugPrint call mentions the token: $call',
        );
      }
    });

    /// The correlation id doubles as proof nothing invented a new
    /// sensitive value just to log something — Play's own purchase id is
    /// already there and already safe to log.
    test('logs correlate by purchase id, not by inventing a new id', () {
      expect(iapService.contains('purchase.purchaseID'), isTrue);
    });

    test('the live entitlement watch that recovers pendingVerification is '
        'wired in providers.dart, not left to poll on its own', () {
      final providers = File('lib/core/providers.dart').readAsStringSync();
      expect(providers.contains('ref.listen(subscriptionProvider'), isTrue);
      expect(providers.contains('service.notePremiumConfirmed()'), isTrue);
    });

    test('every screen offering a purchase result handles '
        'pendingVerification, not just delivered/cancelled/failed', () {
      for (final path in [
        'lib/features/onboarding/plan_intro_screen.dart',
        'lib/features/paywall/paywall_screen.dart',
        'lib/features/profile/widgets/premium_card.dart',
        'lib/features/battle/shop_tab.dart',
        'lib/features/shop/widgets/coin_top_up_sheet.dart',
      ]) {
        final source = File(path).readAsStringSync();
        expect(
          source.contains('IapOutcome.pendingVerification'),
          isTrue,
          reason: '$path has an outcome switch that does not handle '
              'pendingVerification — this is exactly the compile error '
              'Dart\'s exhaustive switch is supposed to catch, so seeing '
              'this fail means that guarantee itself broke somehow',
        );
      }
    });

    test('the retry that fixed this is scoped to Play propagation lag, '
        'never a blind retry-everything', () {
      final iap = File('functions/iap.js').readAsStringSync();
      expect(iap.contains('isRetryablePlayState'), isTrue);
      expect(
        iap.contains('subscriptionGrants(response.data, uid)') ||
            iap.contains('subscriptionGrants(last.data'),
        isTrue,
        reason: 'the grant decision itself must still come from '
            'subscriptionGrants — retrying must never change what counts '
            'as a grant',
      );
    });
  });
}

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
      expect(asked.length, paid.length + 1);
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
      expect(
        iap.indexOf('playConfigured()') < iap.indexOf('.set(patch'),
        isTrue,
        reason: 'the entitlement is written before the check',
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
  group('purchases are bound to an account', () {
    test('every buy call site passes a uid', () {
      for (final path in [
        'lib/features/paywall/paywall_screen.dart',
        'lib/features/battle/shop_tab.dart',
      ]) {
        final source = File(path).readAsStringSync();
        final calls = RegExp(r'\.buy\(').allMatches(source).length;
        expect(calls, greaterThan(0), reason: '$path buys nothing');
        expect(
          RegExp(r'uid: uid').allMatches(source).length,
          greaterThanOrEqualTo(calls),
          reason: '$path buys without binding the purchase to an account',
        );
      }
    });
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/constants/avatars.dart';
import 'package:kana_master/core/constants/covers.dart';
import 'package:kana_master/core/constants/frames.dart';

/// Every locked avatar/frame/cover now falls into exactly one of three
/// tiers — ad, coin, or subscription-only — added 2026-08-24. Getting
/// this wrong is silent in exactly the way this project has been bitten
/// by before: an id that falls through every tier's set reads as
/// "subscription-only" by default (see each `isPremiumOnly`'s own
/// fallback-through-elimination logic), which is the safe direction to
/// fail in, but an id listed in *two* tiers at once (ad and coin, say)
/// would be a real, silent bug — a learner would see one lock reason in
/// the UI while the other tier's unlock path also worked.
void main() {
  group('avatar tiers', () {
    final locked = AvatarPresets.premium.map((p) => p.id).toSet();

    test('every locked avatar is exactly one tier', () {
      for (final id in locked) {
        final inAd = AvatarPresets.adIds.contains(id);
        final inCoin = AvatarPresets.coinIds.contains(id);
        final premiumOnly = AvatarPresets.isPremiumOnly(id);
        final tierCount =
            (inAd ? 1 : 0) + (inCoin ? 1 : 0) + (premiumOnly ? 1 : 0);
        expect(tierCount, 1, reason: '$id is in $tierCount tiers, not 1');
      }
    });

    test('every tier id is a real locked avatar', () {
      for (final id in [...AvatarPresets.adIds, ...AvatarPresets.coinIds]) {
        expect(locked, contains(id), reason: '$id is not a premium preset');
      }
    });

    test('the three tiers partition every locked avatar', () {
      final premiumOnlyIds =
          locked.where(AvatarPresets.isPremiumOnly).toSet();
      expect(
        AvatarPresets.adIds.length +
            AvatarPresets.coinIds.length +
            premiumOnlyIds.length,
        locked.length,
      );
    });
  });

  group('frame tiers', () {
    final locked =
        FramePresets.all.map((f) => f.id).where(FramePresets.isLocked).toSet();

    test('every locked frame is exactly one tier', () {
      for (final id in locked) {
        final inAd = FramePresets.adIds.contains(id);
        final inCoin = FramePresets.coinIds.contains(id);
        final premiumOnly = FramePresets.isPremiumOnly(id);
        final tierCount =
            (inAd ? 1 : 0) + (inCoin ? 1 : 0) + (premiumOnly ? 1 : 0);
        expect(tierCount, 1, reason: '$id is in $tierCount tiers, not 1');
      }
    });

    test('the three tiers partition all 16 locked frames', () {
      final premiumOnlyIds = locked.where(FramePresets.isPremiumOnly).toSet();
      expect(
        FramePresets.adIds.length +
            FramePresets.coinIds.length +
            premiumOnlyIds.length,
        locked.length,
      );
    });
  });

  group('cover tiers', () {
    final locked =
        CoverPresets.all.map((c) => c.id).where(CoverPresets.isLocked).toSet();

    test('every locked cover is exactly one tier', () {
      for (final id in locked) {
        final inAd = CoverPresets.adIds.contains(id);
        final inCoin = CoverPresets.coinIds.contains(id);
        final premiumOnly = CoverPresets.isPremiumOnly(id);
        final tierCount =
            (inAd ? 1 : 0) + (inCoin ? 1 : 0) + (premiumOnly ? 1 : 0);
        expect(tierCount, 1, reason: '$id is in $tierCount tiers, not 1');
      }
    });

    test('the three tiers partition all 15 locked covers', () {
      final premiumOnlyIds = locked.where(CoverPresets.isPremiumOnly).toSet();
      expect(
        CoverPresets.adIds.length +
            CoverPresets.coinIds.length +
            premiumOnlyIds.length,
        locked.length,
      );
    });
  });

  group('the server mirrors the same coin-buyable ids', () {
    final spendCoins = File('functions/spend_coins.js').readAsStringSync();

    /// `functions/spend_coins.js`'s `COIN_IDS` is what actually decides
    /// whether a purchase is allowed — the Dart-side `coinIds` sets only
    /// decide what the UI offers. If the two ever disagreed, either a
    /// learner could be shown a coin-buy button the server refuses (an
    /// error where a purchase should have worked), or worse, the server
    /// could accept a spend for something the client never listed as
    /// coin-tier — silently letting a "premium-only" item be bought
    /// with coins instead.
    test('every Dart coinIds id appears in the JS mirror', () {
      for (final id in [
        ...AvatarPresets.coinIds,
        ...FramePresets.coinIds,
        ...CoverPresets.coinIds,
      ]) {
        expect(
          spendCoins.contains('"$id"'),
          isTrue,
          reason: '$id is coin-buyable in Dart but missing from '
              'functions/spend_coins.js\'s COIN_IDS',
        );
      }
    });

    test('the coin price agrees between Dart and the server', () {
      expect(AvatarPresets.coinPrice, FramePresets.coinPrice);
      expect(FramePresets.coinPrice, CoverPresets.coinPrice);
      expect(
        spendCoins.contains('const COIN_PRICE = ${AvatarPresets.coinPrice};'),
        isTrue,
      );
    });
  });
}

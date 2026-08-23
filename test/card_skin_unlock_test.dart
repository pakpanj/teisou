import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/constants/card_skins.dart';

/// The skin families decide two things a screenshot cannot show: what a
/// player may wear, and what happens to a skin they have already chosen
/// when the season takes their stars back. Both are silent when wrong —
/// a locked skin that keeps rendering looks perfectly fine right up
/// until it turns out nobody ever had to earn anything.
void main() {
  CardSkinPreset skinOf(String id) => CardSkinPresets.byId(id);

  group('who may wear what', () {
    test('free skins need nothing', () {
      for (final skin in CardSkinPresets.ofSource(CardSkinSource.free)) {
        expect(
          isCardSkinUnlocked(skin, starTotal: 0),
          isTrue,
          reason: skin.id,
        );
      }
    });

    test('achievement skins open exactly at their tier boundary', () {
      final gold = skinOf('emas_kencana');
      expect(isCardSkinUnlocked(gold, starTotal: 34), isFalse);
      expect(isCardSkinUnlocked(gold, starTotal: 35), isTrue);

      final diamond = skinOf('night_purple');
      expect(isCardSkinUnlocked(diamond, starTotal: 59), isFalse);
      expect(isCardSkinUnlocked(diamond, starTotal: 60), isTrue);

      final emerald = skinOf('dragon_black');
      expect(isCardSkinUnlocked(emerald, starTotal: 89), isFalse);
      expect(isCardSkinUnlocked(emerald, starTotal: 90), isTrue);
    });

    test('paid skins are not reachable by stars, however many', () {
      // The whole point of the split: no amount of climbing buys the
      // shop, and no amount of money earns the ladder.
      for (final skin in CardSkinPresets.ofSource(CardSkinSource.paid)) {
        expect(
          isCardSkinUnlocked(skin, starTotal: 9999),
          isFalse,
          reason: skin.id,
        );
        expect(isCardSkinUnlocked(skin, starTotal: 0, owned: true), isTrue);
      }
    });

    test('paid skins are also unlocked by a Premium subscription, without '
        'needing to be owned too', () {
      // The subscription's "Skin Battle Card eksklusif" benefit bundles
      // the whole paid family in for free — a subscriber should never
      // have to buy cloud_white/neon_city/sakura_gold on top of the
      // monthly fee.
      for (final skin in CardSkinPresets.ofSource(CardSkinSource.paid)) {
        expect(
          isCardSkinUnlocked(skin, starTotal: 0, premium: true),
          isTrue,
          reason: skin.id,
        );
      }
    });

    test('premium does not unlock achievement or event skins — only the '
        'paid family', () {
      final gold = skinOf('emas_kencana');
      expect(isCardSkinUnlocked(gold, starTotal: 0, premium: true), isFalse);
      final event = CardSkinPresets.ofSource(CardSkinSource.event).first;
      expect(isCardSkinUnlocked(event, starTotal: 0, premium: true), isFalse);
    });

    test('achievement skins are not reachable by owning them', () {
      // Guards the other direction of the same rule: if a future shop
      // ever marked one as owned, stars must still be what decides.
      final gold = skinOf('emas_kencana');
      expect(isCardSkinUnlocked(gold, starTotal: 0, owned: true), isFalse);
    });

    test('the debug override opens everything, and only it does', () {
      for (final skin in CardSkinPresets.all) {
        expect(
          isCardSkinUnlocked(skin, starTotal: 0, allUnlocked: true),
          isTrue,
          reason: skin.id,
        );
      }
    });
  });

  group('a skin that locks again mid-season', () {
    test('falls back to the default rather than staying on display', () {
      // 90 stars carried at 70% is 63 — the real number a player lands
      // on the season after reaching Emerald.
      expect(
        effectiveCardSkin('dragon_black', starTotal: 90).id,
        'dragon_black',
      );
      expect(
        effectiveCardSkin('dragon_black', starTotal: 63).id,
        CardSkinPresets.classic.id,
      );
    });

    test('the tier below survives the same reset', () {
      // Which is what makes the top skin worth chasing again: at 63 the
      // Diamond one still holds and only the Emerald one is gone.
      expect(effectiveCardSkin('night_purple', starTotal: 63).id,
          'night_purple');
    });

    test('comes back on its own once the stars return', () {
      // The stored choice is never cleared, so nothing has to be
      // re-picked — the skin simply reappears.
      expect(effectiveCardSkin('dragon_black', starTotal: 90).id,
          'dragon_black');
    });

    test('a paid skin re-locks the moment premium is no longer true, same '
        'as a lapsed achievement', () {
      expect(
        effectiveCardSkin('cloud_white', starTotal: 0, premium: true).id,
        'cloud_white',
      );
      expect(
        effectiveCardSkin('cloud_white', starTotal: 0, premium: false).id,
        CardSkinPresets.classic.id,
      );
    });

    test('an unknown or missing id resolves to the default', () {
      expect(effectiveCardSkin(null, starTotal: 0).id,
          CardSkinPresets.classic.id);
      expect(effectiveCardSkin('deleted_skin', starTotal: 99).id,
          CardSkinPresets.classic.id);
    });
  });

  group('the roster itself', () {
    test('has exactly three achievement skins, one per tier boundary', () {
      final achievement =
          CardSkinPresets.ofSource(CardSkinSource.achievement).toList();
      expect(achievement.length, 3);
      expect(
        achievement.map((s) => s.starsRequired).toList()..sort(),
        [
          CardSkinPresets.goldThreshold,
          CardSkinPresets.diamondThreshold,
          CardSkinPresets.emeraldThreshold,
        ],
      );
    });

    test('the default is free, so a new install is never broken', () {
      expect(CardSkinPresets.classic.source, CardSkinSource.free);
    });

    test('no two skins share an id', () {
      final ids = CardSkinPresets.all.map((s) => s.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('only achievement skins carry a star requirement', () {
      for (final skin in CardSkinPresets.all) {
        if (skin.source != CardSkinSource.achievement) {
          expect(skin.starsRequired, 0, reason: skin.id);
        } else {
          expect(skin.starsRequired, greaterThan(0), reason: skin.id);
        }
      }
    });
  });
}

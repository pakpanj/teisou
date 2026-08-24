import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/constants/card_game_rank_art.dart';
import 'package:kana_master/core/constants/card_skins.dart';
import 'package:kana_master/data/models/card_game_rank.dart';

/// Card Game Mode's art, checked the way the mascot's already is.
///
/// **Every one of these images fails silently when it is missing.** A
/// card skin falls back to its painted pattern, a rank badge to a drawn
/// shield, a nav icon to a Material glyph — all deliberate, so a broken
/// file can never leave a hole in a screen. The cost of that kindness is
/// that a typo'd filename, a file left out of `pubspec.yaml`, or an
/// asset nobody remembered to copy looks *almost* right, and only
/// someone who knew what the art was supposed to be would notice.
///
/// Being declared in `pubspec.yaml` is checked separately from existing
/// on disk, because those fail identically at runtime and for completely
/// different reasons.
void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();

  void expectBundled(String path, {required String what}) {
    expect(
      File(path).existsSync(),
      isTrue,
      reason: '$what: $path is missing from disk',
    );
    final folder = '${path.substring(0, path.lastIndexOf('/'))}/';
    expect(
      pubspec.contains('- $folder') || pubspec.contains('- $path'),
      isTrue,
      reason: '$what: $folder is not declared in pubspec.yaml, so the file '
          'ships nowhere and every lookup falls back silently',
    );
  }

  group('card skins', () {
    test('every skin that claims art has it', () {
      for (final skin in CardSkinPresets.all.where((s) => s.illustrated)) {
        expectBundled(skin.assetPath, what: 'skin ${skin.id}');
      }
    });

    /// The three free skins are painted, and that difference is the
    /// point — see [CardSkinPreset.illustrated]. If art quietly appeared
    /// for one of them, the families would stop looking different and
    /// the earned ones would stop meaning anything.
    test('the free skins are painted, not illustrated', () {
      final free = CardSkinPresets.ofSource(CardSkinSource.free);
      expect(free, isNotEmpty);
      for (final skin in free) {
        expect(skin.illustrated, isFalse, reason: skin.id);
      }
    });

    /// `darkFace` decides whether the character drawn on the card is
    /// white or navy. Get it wrong and the glyph is black on black —
    /// invisible, on the one thing the player has to read.
    test('every illustrated skin says whether its middle is dark', () {
      // Measured from the art itself, not guessed: every event skin came
      // back light-centred, so only these three carry a light glyph.
      const dark = {'night_purple', 'dragon_black', 'neon_city'};
      for (final skin in CardSkinPresets.all.where((s) => s.illustrated)) {
        expect(
          skin.darkFace,
          dark.contains(skin.id),
          reason: '${skin.id} would draw its glyph in the wrong colour',
        );
      }
    });
  });

  group('rank badges', () {
    test('every tier has a badge', () {
      for (final tier in CardGameTier.values) {
        expectBundled(tier.crestAsset, what: 'tier ${tier.name}');
      }
    });
  });

  group('bottom nav icons', () {
    test('every tab has an icon', () {
      // 'nav_toko' is deliberately not here any more — the shop moved out
      // to the app's main bottom nav (see ShopScreen), and Card Battle's
      // own shell is back down to four tabs.
      const icons = [
        'nav_beranda',
        'nav_deck',
        'nav_battle',
        'nav_skin',
      ];
      for (final icon in icons) {
        expectBundled('assets/icons/$icon.png', what: 'nav icon');
      }
      // The shell has four tabs; an icon list that fell out of step with
      // it would leave one tab on its Material fallback, looking like a
      // rendering bug rather than a missing file.
      final shell =
          File('lib/features/battle/card_game_shell.dart').readAsStringSync();
      for (final icon in icons) {
        expect(shell.contains("'$icon'"), isTrue, reason: icon);
      }
      expect(shell.contains("'nav_toko'"), isFalse,
          reason: "the shop tab should be gone from Card Battle's own nav");
    });
  });
}

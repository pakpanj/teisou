/// Illustrated icon badges for the Premium redesign — generated
/// 2026-08-24 to match the app's own mascot art style (see
/// `scripts/mascot_prompts.md`'s character sheet and
/// `scripts/prepare_premium_icons.py`, which cuts these out of their
/// raw magenta-background source the same way mascot art is prepared).
///
/// Each badge already carries its own cream circular backdrop baked
/// into the artwork — unlike a plain `Icon`, these don't need a theme
/// colour or a container behind them, and render identically in light
/// and dark mode for the same reason the mascot's own mood art does:
/// they're self-contained stickers, not tinted glyphs.
class PremiumIcons {
  PremiumIcons._();

  /// Skin Battle Card eksklusif.
  static const skin = 'assets/premium_icons/icon_skin.png';

  /// Materi pembelajaran lengkap.
  static const kanji = 'assets/premium_icons/icon_kanji.png';

  /// Latihan soal premium (Kaiwa/Partikel/Choukai).
  static const kaiwa = 'assets/premium_icons/icon_kaiwa.png';

  /// Bebas iklan.
  static const noAds = 'assets/premium_icons/icon_noads.png';

  /// The current (Free) plan, in the mini plan-comparison strip.
  static const chestFree = 'assets/premium_icons/chest_free.png';

  /// The offered (Premium) plan, in the same strip.
  static const chestPremium = 'assets/premium_icons/chest_premium.png';
}

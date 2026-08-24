import 'package:flutter/material.dart';

import '../../data/models/app_language.dart';

/// One selectable avatar preset. Real art is a bundled PNG at [assetPath];
/// the emoji placeholder rendering only ever shows if that file isn't
/// present in the asset bundle yet (see [AvatarPresetArt]), so presets keep
/// working before art is dropped in and after, with no caller changes.
class AvatarPreset {
  final String id;
  final String emoji;
  final bool premium;

  /// Indonesian name shown as a caption below the tile in the picker — see
  /// `AvatarPickerSheet`'s `_PresetTile`. Every avatar shows one now; there
  /// used to be none at all, unlike [CoverPreset] (which always had a name)
  /// and [FramePreset] (which had one but never rendered it).
  final String label;

  /// English counterpart, shown when the app language is English — same
  /// `labelFor(AppLanguage)` pattern as [CoverPreset], kept beside the art
  /// id rather than as 20 decorative `AppStrings` getters.
  final String labelEn;

  const AvatarPreset({
    required this.id,
    required this.emoji,
    required this.premium,
    required this.label,
    required this.labelEn,
  });

  String labelFor(AppLanguage language) =>
      language == AppLanguage.english ? labelEn : label;

  /// Where this preset's PNG art lives once supplied — filename must match
  /// [id] exactly (e.g. `mood_happy` -> `assets/avatars/mood_happy.png`) so
  /// dropping files in never needs a separate mapping table.
  String get assetPath => 'assets/avatars/$id.png';
}

/// Renders a preset's real PNG art, falling back to its emoji placeholder on
/// any load failure (art not supplied yet, decode error, etc.) — same
/// never-crash contract as [KotobaImage]/[KaiwaImage], just for a bundled
/// asset instead of an on-demand Storage download.
class AvatarPresetArt extends StatelessWidget {
  final AvatarPreset preset;
  final double imageSize;
  final double emojiFontSize;
  final BoxFit fit;

  const AvatarPresetArt({
    super.key,
    required this.preset,
    required this.imageSize,
    required this.emojiFontSize,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      preset.assetPath,
      width: imageSize,
      height: imageSize,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Center(
        child: Text(preset.emoji, style: TextStyle(fontSize: emojiFontSize)),
      ),
    );
  }
}

/// Definitions for all 20 avatar presets (8 free + 12 premium), keyed by id
/// so they can be added to or edited here without touching picker UI code.
/// Real PNG art for all 20 (`neko_circles` set) lives in `assets/avatars/`
/// — every image is already a complete circular illustration with its own
/// backdrop baked in, so presets carry no separate background color; render
/// sites just size/clip the image itself (see [AvatarPresetArt] callers).
class AvatarPresets {
  AvatarPresets._();

  static const free = [
    AvatarPreset(id: 'neko_sensei', emoji: '🧑‍🏫', premium: false, label: 'Guru', labelEn: 'Teacher'),
    AvatarPreset(id: 'neko_cheerleader', emoji: '📣', premium: false, label: 'Pemandu Sorak', labelEn: 'Cheerleader'),
    AvatarPreset(id: 'neko_bookworm', emoji: '📚', premium: false, label: 'Kutu Buku', labelEn: 'Bookworm'),
    AvatarPreset(id: 'neko_artist', emoji: '🎨', premium: false, label: 'Seniman', labelEn: 'Artist'),
    AvatarPreset(id: 'neko_graduate', emoji: '🎓', premium: false, label: 'Wisudawan', labelEn: 'Graduate'),
    AvatarPreset(id: 'neko_ninja', emoji: '🥷', premium: false, label: 'Ninja', labelEn: 'Ninja'),
    AvatarPreset(id: 'neko_samurai', emoji: '⚔️', premium: false, label: 'Samurai', labelEn: 'Samurai'),
    AvatarPreset(id: 'neko_kimono', emoji: '🎋', premium: false, label: 'Kimono', labelEn: 'Kimono'),
  ];

  static const premium = [
    AvatarPreset(id: 'neko_matcha', emoji: '🍵', premium: true, label: 'Matcha', labelEn: 'Matcha'),
    AvatarPreset(id: 'neko_chef', emoji: '👨‍🍳', premium: true, label: 'Koki', labelEn: 'Chef'),
    AvatarPreset(id: 'neko_sailor', emoji: '⚓', premium: true, label: 'Pelaut', labelEn: 'Sailor'),
    AvatarPreset(id: 'neko_detective', emoji: '🔍', premium: true, label: 'Detektif', labelEn: 'Detective'),
    AvatarPreset(id: 'neko_astronaut', emoji: '🚀', premium: true, label: 'Astronot', labelEn: 'Astronaut'),
    AvatarPreset(id: 'neko_musician', emoji: '🎵', premium: true, label: 'Musisi', labelEn: 'Musician'),
    AvatarPreset(id: 'neko_gamer', emoji: '🎮', premium: true, label: 'Gamer', labelEn: 'Gamer'),
    AvatarPreset(id: 'neko_winter', emoji: '❄️', premium: true, label: 'Musim Dingin', labelEn: 'Winter'),
    AvatarPreset(id: 'neko_traveler', emoji: '🧳', premium: true, label: 'Petualang', labelEn: 'Traveler'),
    AvatarPreset(id: 'neko_lion', emoji: '🦁', premium: true, label: 'Singa', labelEn: 'Lion'),
    AvatarPreset(id: 'neko_forest', emoji: '🌲', premium: true, label: 'Hutan', labelEn: 'Forest'),
    AvatarPreset(id: 'neko_sleepy', emoji: '😴', premium: true, label: 'Mengantuk', labelEn: 'Sleepy'),
  ];

  static const all = [...free, ...premium];

  static AvatarPreset? byId(String? id) {
    if (id == null) return null;
    for (final preset in all) {
      if (preset.id == id) return preset;
    }
    return null;
  }

  /// Of the 12 locked presets, the 3 reachable with a single-use
  /// rewarded ad — a taster tier, per the 2026-08-24 split between
  /// "watch an ad", "spend coins", and "subscribe". Everything in
  /// [premium] that is in neither this set nor [coinIds] is
  /// subscription-only — see [isPremiumOnly].
  static const adIds = {
    'neko_chef',
    'neko_sleepy',
    'neko_traveler',
  };

  /// The 6 permanently buyable with coins (see `CoinSpendService`), at a
  /// flat [coinPrice] each — deliberately not priced per-item; that
  /// would be a second economy-balancing decision layered on top of the
  /// tier split itself.
  static const coinIds = {
    'neko_matcha',
    'neko_sailor',
    'neko_detective',
    'neko_musician',
    'neko_winter',
    'neko_forest',
  };

  static const coinPrice = 150;

  static bool isAdUnlockable(String id) => adIds.contains(id);
  static bool isCoinUnlockable(String id) => coinIds.contains(id);

  /// The remaining 3 (`neko_astronaut`, `neko_gamer`, `neko_lion`) —
  /// reachable only by subscribing, never by an ad watch or a coin
  /// spend. Computed from [premium] rather than listed a third time, so
  /// a preset can never silently fall through every tier's set and end
  /// up neither ad- nor coin- nor explicitly premium-locked.
  static bool isPremiumOnly(String id) =>
      premium.any((p) => p.id == id) &&
      !adIds.contains(id) &&
      !coinIds.contains(id);
}

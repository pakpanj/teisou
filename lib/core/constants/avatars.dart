import 'package:flutter/material.dart';

/// One selectable avatar preset. Real art is a bundled PNG at [assetPath];
/// the emoji-over-colored-circle rendering only ever shows if that file
/// isn't present in the asset bundle yet (see [AvatarPresetArt]), so presets
/// keep working before art is dropped in and after, with no caller changes.
class AvatarPreset {
  final String id;
  final String emoji;
  final Color background;
  final bool premium;

  const AvatarPreset({
    required this.id,
    required this.emoji,
    required this.background,
    required this.premium,
  });

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

  const AvatarPresetArt({
    super.key,
    required this.preset,
    required this.imageSize,
    required this.emojiFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      preset.assetPath,
      width: imageSize,
      height: imageSize,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          Text(preset.emoji, style: TextStyle(fontSize: emojiFontSize)),
    );
  }
}

/// Definitions for all 16 avatar presets (6 free + 10 premium), keyed by id
/// so they can be added to or edited here without touching picker UI code.
class AvatarPresets {
  AvatarPresets._();

  static const free = [
    AvatarPreset(
      id: 'mood_happy',
      emoji: '😸',
      background: Color(0xFFFEEDEC),
      premium: false,
    ),
    AvatarPreset(
      id: 'mood_excited',
      emoji: '🐱',
      background: Color(0xFFF4667A),
      premium: false,
    ),
    AvatarPreset(
      id: 'mood_proud',
      emoji: '😻',
      background: Color(0xFFE8B84B),
      premium: false,
    ),
    AvatarPreset(
      id: 'mood_cheering',
      emoji: '🙌🐾',
      background: Color(0xFFE8F5E9),
      premium: false,
    ),
    AvatarPreset(
      id: 'neko_sakura',
      emoji: '🌸🐈',
      background: Color(0xFFFBD9DD),
      premium: false,
    ),
    AvatarPreset(
      id: 'neko_kimono',
      emoji: '🎋🐈',
      background: Color(0xFFF7EDE3),
      premium: false,
    ),
  ];

  static const premium = [
    AvatarPreset(
      id: 'neko_samurai',
      emoji: '⚔️🐈',
      background: Color(0xFF1E2A47),
      premium: true,
    ),
    AvatarPreset(
      id: 'neko_ninja',
      emoji: '🥷🐈',
      background: Color(0xFF2B2B2B),
      premium: true,
    ),
    AvatarPreset(
      id: 'neko_bushi',
      emoji: '🎌🐈',
      background: Color(0xFFC62828),
      premium: true,
    ),
    AvatarPreset(
      id: 'neko_geisha',
      emoji: '💃🐈',
      background: Color(0xFFAD1457),
      premium: true,
    ),
    AvatarPreset(
      id: 'neko_sumo',
      emoji: '🥋🐈',
      background: Color(0xFF6D4C41),
      premium: true,
    ),
    AvatarPreset(
      id: 'neko_onmyoji',
      emoji: '🔮🐈',
      background: Color(0xFF6A1B9A),
      premium: true,
    ),
    AvatarPreset(
      id: 'neko_ronin',
      emoji: '🗡️🐈',
      background: Color(0xFF757575),
      premium: true,
    ),
    AvatarPreset(
      id: 'neko_shogun',
      emoji: '👑🐈',
      background: Color(0xFFC9A227),
      premium: true,
    ),
    AvatarPreset(
      id: 'neko_batik',
      emoji: '🇮🇩🐈',
      background: Color(0xFFD2B48C),
      premium: true,
    ),
    AvatarPreset(
      id: 'neko_astronaut',
      emoji: '🚀🐈',
      background: Color(0xFF283593),
      premium: true,
    ),
  ];

  static const all = [...free, ...premium];

  static AvatarPreset? byId(String? id) {
    if (id == null) return null;
    for (final preset in all) {
      if (preset.id == id) return preset;
    }
    return null;
  }
}

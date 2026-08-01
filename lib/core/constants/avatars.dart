import 'package:flutter/material.dart';

/// One selectable avatar preset. Real art is a bundled PNG at [assetPath];
/// the emoji placeholder rendering only ever shows if that file isn't
/// present in the asset bundle yet (see [AvatarPresetArt]), so presets keep
/// working before art is dropped in and after, with no caller changes.
class AvatarPreset {
  final String id;
  final String emoji;
  final bool premium;

  const AvatarPreset({
    required this.id,
    required this.emoji,
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
    AvatarPreset(id: 'neko_sensei', emoji: '🧑‍🏫', premium: false),
    AvatarPreset(id: 'neko_cheerleader', emoji: '📣', premium: false),
    AvatarPreset(id: 'neko_bookworm', emoji: '📚', premium: false),
    AvatarPreset(id: 'neko_artist', emoji: '🎨', premium: false),
    AvatarPreset(id: 'neko_graduate', emoji: '🎓', premium: false),
    AvatarPreset(id: 'neko_ninja', emoji: '🥷', premium: false),
    AvatarPreset(id: 'neko_samurai', emoji: '⚔️', premium: false),
    AvatarPreset(id: 'neko_kimono', emoji: '🎋', premium: false),
  ];

  static const premium = [
    AvatarPreset(id: 'neko_matcha', emoji: '🍵', premium: true),
    AvatarPreset(id: 'neko_chef', emoji: '👨‍🍳', premium: true),
    AvatarPreset(id: 'neko_sailor', emoji: '⚓', premium: true),
    AvatarPreset(id: 'neko_detective', emoji: '🔍', premium: true),
    AvatarPreset(id: 'neko_astronaut', emoji: '🚀', premium: true),
    AvatarPreset(id: 'neko_musician', emoji: '🎵', premium: true),
    AvatarPreset(id: 'neko_gamer', emoji: '🎮', premium: true),
    AvatarPreset(id: 'neko_winter', emoji: '❄️', premium: true),
    AvatarPreset(id: 'neko_traveler', emoji: '🧳', premium: true),
    AvatarPreset(id: 'neko_lion', emoji: '🦁', premium: true),
    AvatarPreset(id: 'neko_forest', emoji: '🌲', premium: true),
    AvatarPreset(id: 'neko_sleepy', emoji: '😴', premium: true),
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

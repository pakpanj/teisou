import 'package:flutter/material.dart';

/// One selectable avatar preset. Placeholder rendering is an emoji over a
/// colored circle — swap [emoji] usage for `SvgPicture.asset` per id once
/// real SVG art lands, without touching callers of [UserAvatar].
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

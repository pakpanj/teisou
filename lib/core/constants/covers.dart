import 'package:flutter/material.dart';

/// One selectable Profile-header cover/background. Real art is a bundled
/// PNG at [assetPath] (filename must match [id], e.g. `sakura_dawn` ->
/// `assets/covers/sakura_dawn.png`) — same "drop the file in, no mapping
/// table to update" contract as [AvatarPreset]. Until that file exists,
/// [CoverArt] falls back to [emoji] over [background], so the picker is
/// fully usable before any art is supplied.
class CoverPreset {
  final String id;
  final String label;
  final String emoji;
  final Color background;

  const CoverPreset({
    required this.id,
    required this.label,
    required this.emoji,
    required this.background,
  });

  String get assetPath => 'assets/covers/$id.png';
}

/// Renders a preset's real PNG art, falling back to its emoji-over-color
/// placeholder on any load failure (art not supplied yet, decode error,
/// etc.) — same never-crash contract as [AvatarPresetArt]/[KotobaImage].
class CoverArt extends StatelessWidget {
  final CoverPreset preset;
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const CoverArt({
    super.key,
    required this.preset,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final content = Image.asset(
      preset.assetPath,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: height,
        color: preset.background,
        alignment: Alignment.center,
        child: Text(preset.emoji, style: TextStyle(fontSize: height * 0.4)),
      ),
    );
    if (borderRadius == null) return content;
    return ClipRRect(borderRadius: borderRadius!, child: content);
  }
}

/// Locked list of the 10 selectable covers — add art by dropping a PNG at
/// `assets/covers/{id}.png`, no other code changes needed.
class CoverPresets {
  CoverPresets._();

  static const all = [
    CoverPreset(
      id: 'sakura_dawn',
      label: 'Sakura Pagi',
      emoji: '🌸',
      background: Color(0xFFFBD9DD),
    ),
    CoverPreset(
      id: 'fuji_sunset',
      label: 'Fuji Senja',
      emoji: '🗻',
      background: Color(0xFFF3C6C6),
    ),
    CoverPreset(
      id: 'torii_path',
      label: 'Jalan Torii',
      emoji: '⛩️',
      background: Color(0xFFF6D9DD),
    ),
    CoverPreset(
      id: 'autumn_leaves',
      label: 'Momiji Musim Gugur',
      emoji: '🍁',
      background: Color(0xFFFCEEDB),
    ),
    CoverPreset(
      id: 'summer_festival',
      label: 'Festival Musim Panas',
      emoji: '🏮',
      background: Color(0xFFFBD3B0),
    ),
    CoverPreset(
      id: 'winter_snow',
      label: 'Salju Musim Dingin',
      emoji: '❄️',
      background: Color(0xFFE8F0FE),
    ),
    CoverPreset(
      id: 'bamboo_forest',
      label: 'Hutan Bambu',
      emoji: '🎋',
      background: Color(0xFFE3F1E6),
    ),
    CoverPreset(
      id: 'ocean_wave',
      label: 'Ombak Laut',
      emoji: '🌊',
      background: Color(0xFFDCEBFB),
    ),
    CoverPreset(
      id: 'starry_night',
      label: 'Malam Berbintang',
      emoji: '🌌',
      background: Color(0xFFD9D6ED),
    ),
    CoverPreset(
      id: 'sakura_night',
      label: 'Sakura Malam',
      emoji: '🌙',
      background: Color(0xFFE7D6E8),
    ),
  ];

  static CoverPreset? byId(String? id) {
    if (id == null) return null;
    for (final preset in all) {
      if (preset.id == id) return preset;
    }
    return null;
  }
}

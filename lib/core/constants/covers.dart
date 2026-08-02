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

/// Locked list of the 19 selectable covers — add art by dropping a PNG at
/// `assets/covers/{id}.png`, no other code changes needed.
///
/// All 19 have real art. Each is stored at 1280x853 as a 128-colour palette
/// PNG (~7.5MB total, against ~19MB for full-colour PNGs); the header card
/// renders at 995x623 on a Moto G52J, so 1280 covers it with headroom, and
/// the quantisation is invisible once the header's 62% white scrim lands on
/// top. [background]/[emoji] therefore never actually show — they stay as
/// [CoverArt]'s never-crash fallback, with [background] sampled from each
/// image's own centre so a failure degrades to roughly the right tone.
///
/// This list replaced an earlier 10 that were pure placeholders — no art was
/// ever supplied for them, and the art that did arrive covered different
/// themes. Only `sakura_dawn`, `autumn_leaves` and `starry_night` carried
/// over by id; `fuji_sunset`, `torii_path`, `summer_festival`,
/// `winter_snow`, `bamboo_forest`, `ocean_wave` and `sakura_night` are gone.
/// A profile still holding one of those ids resolves to null in [byId] and
/// falls back to the default header scene — see `_HeaderBackground`.
class CoverPresets {
  CoverPresets._();

  static const all = [
    CoverPreset(
      id: 'sakura_dawn',
      label: 'Sakura Pagi',
      emoji: '🌸',
      background: Color(0xFFFCE0B8),
    ),
    CoverPreset(
      id: 'autumn_leaves',
      label: 'Momiji Musim Gugur',
      emoji: '🍁',
      background: Color(0xFFFBD995),
    ),
    CoverPreset(
      id: 'spring_meadow',
      label: 'Padang Bunga',
      emoji: '🌷',
      background: Color(0xFFD2ECFC),
    ),
    CoverPreset(
      id: 'coral_reef',
      label: 'Terumbu Karang',
      emoji: '🐠',
      background: Color(0xFF44ADEB),
    ),
    CoverPreset(
      id: 'jungle_canopy',
      label: 'Rimba Tropis',
      emoji: '🌴',
      background: Color(0xFFBCD37A),
    ),
    CoverPreset(
      id: 'starry_night',
      label: 'Malam Berbintang',
      emoji: '🌌',
      background: Color(0xFF091D5E),
    ),
    CoverPreset(
      id: 'sunflower_field',
      label: 'Ladang Bunga Matahari',
      emoji: '🌻',
      background: Color(0xFFA1D1F9),
    ),
    CoverPreset(
      id: 'enchanted_forest',
      label: 'Hutan Ajaib',
      emoji: '🍄',
      background: Color(0xFF174C34),
    ),
    CoverPreset(
      id: 'magic_castle',
      label: 'Istana Sihir',
      emoji: '🏰',
      background: Color(0xFF2A1B75),
    ),
    CoverPreset(
      id: 'zodiac_night',
      label: 'Malam Zodiak',
      emoji: '🔮',
      background: Color(0xFF081340),
    ),
    CoverPreset(
      id: 'art_studio',
      label: 'Studio Seni',
      emoji: '🎨',
      background: Color(0xFFFCEEDE),
    ),
    CoverPreset(
      id: 'pixel_game',
      label: 'Game Piksel',
      emoji: '🎮',
      background: Color(0xFF1D195D),
    ),
    CoverPreset(
      id: 'sumi_ink',
      label: 'Tinta Sumi',
      emoji: '🖌️',
      background: Color(0xFFF2EBE5),
    ),
    CoverPreset(
      id: 'sacred_geometry',
      label: 'Geometri Sakral',
      emoji: '🔯',
      background: Color(0xFF0D1543),
    ),
    CoverPreset(
      id: 'cyber_neon',
      label: 'Neon Siber',
      emoji: '💻',
      background: Color(0xFF070128),
    ),
    CoverPreset(
      id: 'library_books',
      label: 'Perpustakaan',
      emoji: '📚',
      background: Color(0xFFFDEBCF),
    ),
    CoverPreset(
      id: 'cat_lover',
      label: 'Pencinta Kucing',
      emoji: '🐱',
      background: Color(0xFFFDECD4),
    ),
    CoverPreset(
      id: 'steampunk_brass',
      label: 'Steampunk',
      emoji: '⚙️',
      background: Color(0xFFF4D6A9),
    ),
    CoverPreset(
      id: 'outer_space',
      label: 'Antariksa',
      emoji: '🚀',
      background: Color(0xFF120E50),
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

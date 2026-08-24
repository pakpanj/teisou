import 'package:flutter/material.dart';

/// One selectable avatar frame/border overlay. Real art is a transparent-
/// center PNG at [assetPath] (filename must match [id], e.g. `frame_gold`
/// -> `assets/frames/frame_gold.png`), drawn centered over the avatar and
/// larger than it so the frame's ring shows past the avatar's own edge —
/// same "drop the file in, no mapping table to update" contract as
/// [AvatarPreset]/[CoverPreset]. Unlike those, there's no meaningful emoji
/// placeholder for a border overlay, so a frame with no art yet (or a load
/// failure) just renders nothing — see [FrameOverlay] — rather than a
/// stand-in graphic.
class FramePreset {
  final String id;
  final String label;

  const FramePreset({required this.id, required this.label});

  String get assetPath => 'assets/frames/$id.png';
}

/// Draws [preset]'s frame art centered over an avatar of [avatarSize],
/// itself sized to [avatarSize] * [scale] so the ring extends past the
/// avatar's edge instead of just tracing it. Renders nothing — not a
/// placeholder — when [preset] is null or its art fails to load, since an
/// absent decorative border is a silent no-op, unlike a missing avatar/
/// cover (which always needs to show *something*).
class FrameOverlay extends StatelessWidget {
  final FramePreset? preset;
  final double avatarSize;
  final double scale;

  const FrameOverlay({
    super.key,
    required this.preset,
    required this.avatarSize,
    this.scale = 1.25,
  });

  @override
  Widget build(BuildContext context) {
    final preset = this.preset;
    if (preset == null) return const SizedBox.shrink();
    final size = avatarSize * scale;
    return IgnorePointer(
      child: Image.asset(
        preset.assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      ),
    );
  }
}

/// Locked list of selectable frames. Add a [FramePreset] here (id must match
/// the PNG dropped into `assets/frames/`) and it shows up in the picker
/// automatically, no other code changes needed — same convention as
/// [AvatarPresets]/[CoverPresets].
///
/// All 20 have real art now: kawaii circular line-art wreaths, transparent
/// center, sourced at 1024x1024 and downscaled to 384x384 on the way in
/// (~2.9MB total). 384 is deliberate, not arbitrary — the largest render is
/// 100dp (`UserAvatar(radius: 40)` -> 80dp avatar x `_frameScale` 1.25), so
/// 384 still oversamples that at 4x density while cutting the source's 35MB
/// by 92%. Re-cut from the originals if a bigger avatar is ever introduced.
///
/// [FramePreset.label] is not rendered anywhere today — `_FrameGrid` shows
/// each frame as art only, and just the "no frame" tile carries text — so
/// these stay plain Indonesian strings. If a label ever becomes visible,
/// give [FramePreset] a `labelEn` + `labelFor(language)` pair the way
/// [CoverPreset] does (its labels *are* rendered, and shipped untranslated
/// into the English picker until that was added); don't ship these as-is.
class FramePresets {
  FramePresets._();

  static const all = <FramePreset>[
    FramePreset(id: 'frame_sakura_fuji', label: 'Sakura & Fuji'),
    FramePreset(id: 'frame_halloween', label: 'Halloween'),
    FramePreset(id: 'frame_sakura', label: 'Sakura'),
    FramePreset(id: 'frame_autumn', label: 'Musim Gugur'),
    FramePreset(id: 'frame_winter', label: 'Musim Dingin'),
    FramePreset(id: 'frame_spring_garden', label: 'Taman Musim Semi'),
    FramePreset(id: 'frame_ocean', label: 'Bawah Laut'),
    FramePreset(id: 'frame_night_sky', label: 'Langit Malam'),
    FramePreset(id: 'frame_jungle', label: 'Rimba Tropis'),
    FramePreset(id: 'frame_mushroom_fairy', label: 'Peri Jamur'),
    FramePreset(id: 'frame_fairytale', label: 'Negeri Dongeng'),
    FramePreset(id: 'frame_witch', label: 'Penyihir'),
    FramePreset(id: 'frame_steampunk', label: 'Steampunk'),
    FramePreset(id: 'frame_space', label: 'Antariksa'),
    FramePreset(id: 'frame_music', label: 'Musik & Seni'),
    FramePreset(id: 'frame_cat', label: 'Kucing'),
    FramePreset(id: 'frame_gaming', label: 'Gaming'),
    FramePreset(id: 'frame_retro_pc', label: 'Komputer Retro'),
    FramePreset(id: 'frame_moon_crystal', label: 'Bulan & Kristal'),
    FramePreset(id: 'frame_calligraphy', label: 'Kaligrafi'),
  ];

  static FramePreset? byId(String? id) {
    if (id == null) return null;
    for (final preset in all) {
      if (preset.id == id) return preset;
    }
    return null;
  }

  /// The 4 frames that stay free — every other one of the 20 is locked
  /// behind a single-use rewarded ad (see `AvatarPickerSheet`'s
  /// `frame_premium` module id). Expressed as the free set rather than the
  /// locked one, same reasoning as [CoverPresets.freeIds]: a frame added
  /// to [all] later is locked by default unless it's added here too. The
  /// "no frame" tile itself isn't part of [all] at all and stays free
  /// unconditionally — handled separately in `AvatarPickerSheet`'s
  /// `_FrameGrid`, not by this set.
  static const freeIds = {
    'frame_sakura_fuji',
    'frame_sakura',
    'frame_autumn',
    'frame_winter',
  };

  static bool isLocked(String id) => !freeIds.contains(id);

  /// Of the 16 locked frames, the 4 reachable with a single-use rewarded
  /// ad — mirrors [AvatarPresets.adIds]'s three-tier split (ad / coin /
  /// premium-only), added 2026-08-24.
  static const adIds = {
    'frame_spring_garden',
    'frame_ocean',
    'frame_jungle',
    'frame_cat',
  };

  /// The 8 permanently buyable with coins (see `CoinSpendService`), flat
  /// [coinPrice] each — same "not priced per-item" reasoning as
  /// [AvatarPresets.coinPrice].
  static const coinIds = {
    'frame_halloween',
    'frame_night_sky',
    'frame_mushroom_fairy',
    'frame_fairytale',
    'frame_witch',
    'frame_music',
    'frame_retro_pc',
    'frame_calligraphy',
  };

  static const coinPrice = 150;

  static bool isAdUnlockable(String id) => adIds.contains(id);
  static bool isCoinUnlockable(String id) => coinIds.contains(id);

  /// The remaining 4 (`frame_steampunk`, `frame_space`, `frame_gaming`,
  /// `frame_moon_crystal`) — subscription-only, computed from [isLocked]
  /// rather than listed a third time so a frame can never silently fall
  /// through every tier's set.
  static bool isPremiumOnly(String id) =>
      isLocked(id) && !adIds.contains(id) && !coinIds.contains(id);
}

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

/// Locked list of selectable frames — empty until real art is supplied.
/// Add a [FramePreset] here (id must match the PNG dropped into
/// `assets/frames/`) and it shows up in the picker automatically, no other
/// code changes needed — same convention as [AvatarPresets]/[CoverPresets].
class FramePresets {
  FramePresets._();

  static const all = <FramePreset>[];

  static FramePreset? byId(String? id) {
    if (id == null) return null;
    for (final preset in all) {
      if (preset.id == id) return preset;
    }
    return null;
  }
}

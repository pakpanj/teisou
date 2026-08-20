import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// A nine-patch sakura-corner card border —
/// `assets/module_frames/frame_card_frame.png` (see
/// `scripts/module_frame_asset_prompts.md` prompt #2/#3: this file's actual
/// shape — a plain, evenly-bordered square with four identical corner
/// flowers — is what that prompt doc's #3 `frame_card_box` asked for, even
/// though the generator returned it under the #2 title-plaque prompt; kept
/// under a name matching what it actually is, see [ModuleTitlePlaque] for
/// the matching correction on the other file).
///
/// Wraps [child] in an `Image.asset(centerSlice: ...)` so the border and
/// corner flowers stay crisp at their native size while the flat pink
/// middle stretches to fit whatever content is inside — the standard
/// nine-patch contract, and why the source art was specced with a
/// completely flat, textureless interior.
/// Whether the dark-theme frame art exists yet.
///
/// **One switch for two things that must move together.** The frame art is
/// a picture, not a surface the theme repaints, so whatever is drawn on it
/// takes its colour from the art — not from the app. Flip only this, and
/// only once `*_dark.png` exists for every frame: turning the palette
/// theme-aware while the art stays pale would put dark ink on pale pink,
/// and swapping the art without the palette would put near-white on it.
/// Either half alone reproduces the bug this pairing exists to prevent
/// (reported as a Kanji level list whose open card was almost blank).
const bool kDarkFrameArt = false;

/// The frame asset [name], in the theme's own version when one exists.
///
/// [name] is the file's stem, e.g. `frame_card_frame`.
String frameAsset(BuildContext context, String name) {
  final dark = kDarkFrameArt &&
      Theme.of(context).brightness == Brightness.dark;
  return 'assets/module_frames/$name${dark ? '_dark' : ''}.png';
}

/// The palette to colour anything drawn *on* a frame.
///
/// Light while the art is light, whatever the app's theme — see
/// [kDarkFrameArt]. The general rule it encodes outlives the flag: **take
/// your colour from the surface behind you, not from the app.**
AppPalette framePaletteOf(BuildContext context) {
  if (!kDarkFrameArt) return AppPalette.light;
  return Theme.of(context).brightness == Brightness.dark
      ? AppPalette.dark
      : AppPalette.light;
}

class ModuleCardFrame extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;

  const ModuleCardFrame({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
  });

  /// `centerSlice` corners render at the image's *native* pixel size —
  /// they are never scaled down, only the edges/centre stretch. The art
  /// originally shipped at 1209x1196 (an AI-generator's native output
  /// size), which meant a "safe" 190px inset was 190 native pixels drawn
  /// 1:1 onto the canvas — comfortably taller than an entire list row, so
  /// the corners alone consumed more space than the whole card and the
  /// nine-patch collapsed to nothing (confirmed on a physical device: no
  /// border, no fill, nothing painted at all). A first fix shrank the
  /// source to 320x317 (inset 50) — still not enough: a `ModuleLevelCard`
  /// row is roughly 95 logical px tall, and 50+50 (top+bottom corners)
  /// still exceeds that, so it collapsed again, confirmed on-device a
  /// second time. Shrunk further to 130x129 (inset ~20) so both corners
  /// combined (40) sit comfortably under a typical row's height, leaving
  /// a real stretchable band in between.
  static const _inset = 20.0;
  static const _sourceWidth = 130.0;
  static const _sourceHeight = 129.0;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: Image.asset(
              frameAsset(context, 'frame_card_frame'),
              centerSlice: const Rect.fromLTRB(
                _inset,
                _inset,
                _sourceWidth - _inset,
                _sourceHeight - _inset,
              ),
              fit: BoxFit.fill,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

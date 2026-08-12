import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// A small ornamental plaque behind a module screen's AppBar title (e.g.
/// "Bunpou", "Kaiwa") — `assets/module_frames/frame_title_plaque.png`, see
/// `scripts/module_frame_asset_prompts.md` prompt #2/#3 (the two came back
/// swapped from what their prompts asked for: this file's actual shape is
/// the wide ornate signboard originally spec'd as the *card* frame, while
/// `frame_card_frame.png` is the plain even-bordered square originally
/// spec'd as the *title* frame — kept under names that match what they
/// actually are rather than what they were asked to be).
///
/// A fixed-size decoration, not nine-patch — every module title in this
/// app is one short word, so there's no long-content case that needs the
/// middle to stretch; `BoxFit.fill` onto a fixed-aspect box reads cleanly
/// across the narrow width range "Bunpou".."Choukai" actually spans.
class ModuleTitlePlaque extends StatelessWidget {
  final String title;

  const ModuleTitlePlaque({super.key, required this.title});

  /// Source art is 1711x816 (~2.1:1) after trimming.
  static const _aspectRatio = 1711 / 816;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: 48 * _aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/module_frames/frame_title_plaque.png',
            fit: BoxFit.fill,
            errorBuilder: (context, error, stackTrace) => DecoratedBox(
              decoration: BoxDecoration(
                color: context.palette.cardWhite,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
            // Shrinks rather than truncates — the English strings this
            // plaque carries ("Particle", "Grammar") run noticeably longer
            // than their Indonesian counterparts, and an ellipsis on a
            // one-word title plaque reads as broken art, not a scroll cue.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                maxLines: 1,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: context.palette.textNavy,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

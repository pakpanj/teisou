import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// The colours a keyboard is drawn in.
///
/// Its own object rather than loose parameters because the point of it is
/// to be swapped whole: a skin is a set of colours that agree with each
/// other, and passing them separately invites half a skin.
///
/// Every field is nullable and every null means "use the theme", so a
/// skin that only names a couple of colours still gets a keyboard that
/// works in dark mode and stays legible.
class KeyboardLook {
  const KeyboardLook({this.panel, this.face, this.mutedFace, this.text});

  /// The tray the keys sit on. See [KeyboardPanel].
  final Color? panel;

  /// A letter key.
  final Color? face;

  /// A key that acts on what is typed rather than adding to it —
  /// backspace, ゛, 小.
  final Color? mutedFace;

  final Color? text;
}

/// The tray a keyboard's keys sit on.
///
/// **Both keyboards used to have none**, so the keys floated directly on
/// whatever the screen behind them happened to be — in Card Game Mode a
/// photograph of Fuji and drifting sakura, straight between the letters.
/// A keyboard reads as one object you type on; without something behind
/// them the keys read as sixteen separate buttons scattered over the
/// artwork.
///
/// Deliberately a [DecoratedBox] rather than a [Material]: it must not
/// clip, because the kana keyboard's flick preview deliberately draws
/// outside the row it belongs to, and a Material here would also be
/// picked up by every `find.byType(Material)` that means "a key".
class KeyboardPanel extends StatelessWidget {
  const KeyboardPanel({super.key, required this.look, required this.child});

  final KeyboardLook look;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        // A step back from the keys themselves, so the tray reads as
        // behind them rather than as a very large key.
        color: look.panel ?? palette.mutedSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        border: Border(top: BorderSide(color: palette.divider)),
      ),
      child: Padding(
        // Room for the keys' own 3px margins to sit inside the tray
        // rather than flush against its edge.
        padding: const EdgeInsets.fromLTRB(5, 7, 5, 5),
        child: child,
      ),
    );
  }
}

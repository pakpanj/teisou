import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// The app's own romaji keyboard, for the cards that ask for a reading in
/// latin letters.
///
/// **Why not the system keyboard, which already works.** Three reasons,
/// in the order they matter:
///
/// 1. It is somebody else's keyboard. It arrives with autocorrect,
///    predictions and a numeric row, all of which are noise on a card
///    that wants `shi`, and one of which — a prediction bar offering the
///    answer — is worse than noise on a timed question.
/// 2. It covers the screen it is typed on, and how much of it varies by
///    phone and by which keyboard app the family installed. The card
///    being answered has to stay visible.
/// 3. Half of this mode already types on a keyboard we drew ([KanaKeyboard]).
///    Switching between ours and the phone's between one card and the
///    next makes the app feel like two apps.
///
/// Deliberately the same shape of component as [KanaKeyboard]: `value` +
/// `onChanged`, no submit button of its own, needs bounded height from
/// its caller. Around 180dp; below about 140 the rows stop being
/// finger-sized.
///
/// ## What is not on it
///
/// No space bar, no numbers, no punctuation, no shift. Every answer it
/// can be asked for is one lowercase word — `tsu`, `hayashi` — so the
/// keys that cannot contribute to one are left off rather than drawn
/// dead. That buys three rows of comfortably large letters in the height
/// a phone keyboard would spend on five cramped ones.
class RomajiKeyboard extends StatelessWidget {
  const RomajiKeyboard({
    super.key,
    required this.value,
    required this.onChanged,
    this.look = const KeyboardLook(),
  });

  final String value;
  final ValueChanged<String> onChanged;

  /// How the keys are painted.
  ///
  /// A parameter rather than a hardcoded palette read so a keyboard can
  /// be dressed differently per player later — the one thing an opponent
  /// watches you use, the same argument `CardSkinPreset` makes about
  /// card backs. Nothing supplies a non-default look yet; adding one is
  /// a preset list and a picker, not a change here.
  final KeyboardLook look;

  /// QWERTY, not alphabetical.
  ///
  /// A learner typing `shi` here is learning where those letters live on
  /// every other keyboard they will ever use. An ABC layout would be
  /// marginally easier for a five-year-old on day one and wrong
  /// everywhere else.
  static const rows = <String>['qwertyuiop', 'asdfghjkl', 'zxcvbnm'];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++)
          Expanded(
            child: Row(
              children: [
                // The short rows are centred by half-width gaps rather
                // than by stretching their keys, so every letter on the
                // keyboard is the same size and lands where the eye
                // expects from any other keyboard.
                if (i == 1) const Spacer(flex: 1),
                for (final letter in rows[i].split(''))
                  Expanded(
                    flex: 2,
                    child: _Key(
                      label: letter,
                      look: look,
                      palette: palette,
                      onTap: () => onChanged(value + letter),
                    ),
                  ),
                if (i == 1) const Spacer(flex: 1),
                if (i == 2) ...[
                  const Spacer(flex: 1),
                  Expanded(
                    flex: 4,
                    child: _Key(
                      icon: Icons.backspace_outlined,
                      look: look,
                      palette: palette,
                      muted: true,
                      onTap: value.isEmpty
                          ? null
                          : () =>
                                onChanged(value.substring(0, value.length - 1)),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// The colours a keyboard is drawn in.
///
/// Its own object rather than four loose parameters because the point of
/// it is to be swapped whole: a skin is a set of colours that agree with
/// each other, and passing them separately invites half a skin.
class KeyboardLook {
  const KeyboardLook({this.face, this.mutedFace, this.text});

  /// Null means "use the theme", which is what every caller does today
  /// and what any skinned keyboard should still fall back to for
  /// anything its own palette does not name.
  final Color? face;
  final Color? mutedFace;
  final Color? text;
}

class _Key extends StatelessWidget {
  const _Key({
    this.label,
    this.icon,
    required this.look,
    required this.palette,
    required this.onTap,
    this.muted = false,
  });

  final String? label;
  final IconData? icon;
  final KeyboardLook look;
  final AppPalette palette;
  final VoidCallback? onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final text = look.text ?? palette.textNavy;
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Material(
        color: muted
            ? (look.mutedFace ?? palette.mutedSurface)
            : (look.face ?? palette.cardWhite),
        borderRadius: BorderRadius.circular(10),
        elevation: enabled ? 1 : 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Center(
            child: icon != null
                ? Icon(
                    icon,
                    size: 20,
                    color: enabled ? text : text.withValues(alpha: 0.3),
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label!,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: enabled ? text : text.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

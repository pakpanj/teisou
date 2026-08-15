import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/kana_character.dart';
import '../../data/models/kana_type.dart';
import '../providers.dart';
import '../services/kana_keyboard_input.dart';
import '../theme/app_palette.dart';

/// A self-contained hiragana input keyboard, **three rows tall**: a row of
/// gojūon group keys (あかさたなはまやらわん), the selected group's own five
/// characters, and a modifier row (tenten/maru/small-y/sokuon/backspace).
/// Deliberately a plain controlled component (`value` + `onChanged`, no
/// submit button of its own — see `NOTES_CARD_GAME_MODE.md`'s "mandiri,
/// tidak terikat konteks pertandingan" decision) so it can be dropped into
/// any screen that needs kana text entry. Card Game Mode's answer field is
/// the first caller, but nothing here depends on match/battle state.
///
/// **It used to lay all 46 characters out at once, and that was the bug.**
/// Twelve stacked rows need roughly 500dp to stay legible; the battle
/// screen had 220dp to give, so every key came out about twelve pixels
/// tall with an eighteen-point character spilling out of it. Rows of a
/// phone keyboard cannot be made shorter than a fingertip, so the fix is
/// fewer rows rather than smaller ones.
///
/// Two taps per character instead of one is the price, and it is paid
/// openly: both rows stay on screen the whole time, with the selected
/// group highlighted, so nothing is hidden behind a long-press or a flick
/// gesture a child would have to be taught. No popup either — a popup over
/// a timed game is one more thing that can be mis-tapped or left open.
///
/// The grid's shape — which of the 5 columns holds a real character in each
/// group, and which are gaps (や's i/e, わ's i/u/e, ん's four) — is read
/// straight from [KanaCharacter.row]/[KanaCharacter.column], not hand-laid
/// out, so a future kana added to the dataset places itself automatically
/// instead of needing this widget edited too. Same reasoning
/// [KanaKeyboardInput] itself was built on.
///
/// **This widget needs bounded height from its caller** — its three rows
/// are flexed, so wrap it in a `SizedBox`/`Expanded` rather than placing it
/// directly inside something that sizes to its children. Around 160dp
/// looks right; below about 120 the characters start to crowd again.
class KanaKeyboard extends ConsumerStatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const KanaKeyboard({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  ConsumerState<KanaKeyboard> createState() => _KanaKeyboardState();
}

class _KanaKeyboardState extends ConsumerState<KanaKeyboard> {
  /// Which gojūon group the second row is showing. Starts on あ so the
  /// keyboard never opens in an empty-looking state.
  int _group = 0;

  @override
  Widget build(BuildContext context) {
    final kanaAsync = ref.watch(kanaListProvider(KanaType.hiragana));
    final inputAsync = ref.watch(kanaKeyboardInputProvider);

    if (!kanaAsync.hasValue || !inputAsync.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }

    final baseGrid = <(int, int), KanaCharacter>{
      for (final k in kanaAsync.requireValue)
        if (k.row <= 10) (k.row, k.column): k,
    };
    final groups = <int>[
      for (var row = 0; row <= 10; row++)
        if (baseGrid.containsKey((row, 0))) row,
    ];
    final input = inputAsync.requireValue;

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              for (final row in groups)
                Expanded(
                  child: _KeyButton(
                    label: baseGrid[(row, 0)]!.character,
                    selected: row == _group,
                    onTap: () => setState(() => _group = row),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              for (var col = 0; col < 5; col++)
                Expanded(
                  child: switch (baseGrid[(_group, col)]) {
                    final kana? => _KeyButton(
                      label: kana.character,
                      onTap: () =>
                          widget.onChanged(widget.value + kana.character),
                    ),
                    // A gap, not a shrink: keeping the empty column's
                    // width means い stays under い everywhere, so わ's
                    // を does not slide across to where う sits in every
                    // other group.
                    null => const SizedBox.shrink(),
                  },
                ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              _modifierKey(label: '゛', result: input.applyTenten(widget.value)),
              _modifierKey(label: '゜', result: input.applyMaru(widget.value)),
              _modifierKey(
                label: 'ゃ',
                result: input.applySmallY(widget.value, 'ゃ'),
              ),
              _modifierKey(
                label: 'ゅ',
                result: input.applySmallY(widget.value, 'ゅ'),
              ),
              _modifierKey(
                label: 'ょ',
                result: input.applySmallY(widget.value, 'ょ'),
              ),
              _modifierKey(
                label: 'っ',
                result: input.applySokuon(widget.value),
              ),
              Expanded(
                child: _KeyButton(
                  icon: Icons.backspace_outlined,
                  onTap: widget.value.isEmpty
                      ? null
                      : () => widget.onChanged(input.backspace(widget.value)),
                  muted: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _modifierKey({required String label, required String? result}) {
    return Expanded(
      child: _KeyButton(
        label: label,
        onTap: result == null ? null : () => widget.onChanged(result),
        muted: true,
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool muted;
  final bool selected;

  const _KeyButton({
    this.label,
    this.icon,
    this.onTap,
    this.muted = false,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final enabled = onTap != null;
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: selected
            ? palette.primaryCoral
            : muted
                ? palette.mutedSurface
                : palette.cardWhite,
        borderRadius: BorderRadius.circular(8),
        elevation: enabled ? 1 : 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: icon != null
                ? Icon(
                    icon,
                    size: 18,
                    color: enabled
                        ? palette.textNavy
                        : palette.textNavy.withValues(alpha: 0.3),
                  )
                // Shrinks rather than clips: eleven group keys on a narrow
                // phone leave little room, and a character that has been
                // cut in half is worse than one that is small.
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label!,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? Colors.white
                            : enabled
                                ? palette.textNavy
                                : palette.textNavy.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

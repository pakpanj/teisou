import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/kana_character.dart';
import '../../data/models/kana_type.dart';
import '../providers.dart';
import '../services/kana_keyboard_input.dart';
import '../theme/app_palette.dart';

/// A self-contained hiragana input keyboard: the 46 base characters laid
/// out in the real gojūon grid, plus a modifier row for tenten/maru/small-y/
/// sokuon/backspace. Deliberately a plain controlled component (`value` +
/// `onChanged`, no submit button of its own — see
/// `NOTES_CARD_GAME_MODE.md`'s "mandiri, tidak terikat konteks
/// pertandingan" decision) so it can be dropped into any screen that needs
/// kana text entry. Card Game Mode's answer field is the first caller, but
/// nothing here depends on match/battle state.
///
/// The base grid's shape — which of the 5 columns holds a real character in
/// each of the 11 rows, and which are gaps (や's i/e, わ's i/u/e) — is read
/// straight from [KanaCharacter.row]/[KanaCharacter.column], not hand-laid
/// out, so a future kana added to the dataset places itself automatically
/// instead of needing this widget edited too. Same reasoning
/// [KanaKeyboardInput] itself was built on.
///
/// **This widget needs bounded height from its caller** — it fills
/// available space with 12 flexed rows (11 base rows + 1 modifier row), so
/// wrap it in a `SizedBox`/`Expanded`/`AspectRatio` rather than placing it
/// directly inside something that sizes to its children (a plain `Column`,
/// a `ListView`).
class KanaKeyboard extends ConsumerWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const KanaKeyboard({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kanaAsync = ref.watch(kanaListProvider(KanaType.hiragana));
    final inputAsync = ref.watch(kanaKeyboardInputProvider);

    if (!kanaAsync.hasValue || !inputAsync.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }

    final baseGrid = <(int, int), KanaCharacter>{
      for (final k in kanaAsync.requireValue)
        if (k.row <= 10) (k.row, k.column): k,
    };
    final input = inputAsync.requireValue;

    return Column(
      children: [
        for (var row = 0; row <= 10; row++)
          Expanded(
            child: Row(
              children: [
                for (var col = 0; col < 5; col++)
                  Expanded(
                    child: switch (baseGrid[(row, col)]) {
                      final kana? => _KeyButton(
                        label: kana.character,
                        onTap: () => onChanged(value + kana.character),
                      ),
                      null => const SizedBox.shrink(),
                    },
                  ),
              ],
            ),
          ),
        Expanded(
          child: Row(
            children: [
              _modifierKey(
                label: '゛',
                result: input.applyTenten(value),
              ),
              _modifierKey(label: '゜', result: input.applyMaru(value)),
              _modifierKey(
                label: 'ゃ',
                result: input.applySmallY(value, 'ゃ'),
              ),
              _modifierKey(
                label: 'ゅ',
                result: input.applySmallY(value, 'ゅ'),
              ),
              _modifierKey(
                label: 'ょ',
                result: input.applySmallY(value, 'ょ'),
              ),
              _modifierKey(label: 'っ', result: input.applySokuon(value)),
              Expanded(
                child: _KeyButton(
                  icon: Icons.backspace_outlined,
                  onTap: value.isEmpty
                      ? null
                      : () => onChanged(input.backspace(value)),
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
        onTap: result == null ? null : () => onChanged(result),
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

  const _KeyButton({this.label, this.icon, this.onTap, this.muted = false});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final enabled = onTap != null;
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Material(
        color: muted ? palette.mutedSurface : palette.cardWhite,
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
                    color: enabled
                        ? palette.textNavy
                        : palette.textNavy.withValues(alpha: 0.3),
                  )
                : Text(
                    label!,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: enabled
                          ? palette.textNavy
                          : palette.textNavy.withValues(alpha: 0.3),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

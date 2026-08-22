import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/kana_character.dart';
import '../../data/models/kana_type.dart';
import '../providers.dart';
import '../services/kana_keyboard_input.dart';
import '../theme/app_palette.dart';
import 'keyboard_look.dart';

/// A self-contained hiragana input keyboard in the **flick layout every
/// Japanese phone uses**: a 4x4 block where each key owns a whole gojūon
/// group, and which of its five characters you get depends on the
/// direction you flick.
///
/// Tap あ for あ; flick left for い, up for う, right for え, down for お.
/// That mapping is not invented here — it is the one iOS and Gboard both
/// ship, so a learner who gets used to this keyboard is getting used to
/// the real one rather than to ours.
///
/// ## Tapping again instead of flicking
///
/// Every vowel is also reachable by tapping the same key repeatedly —
/// あ, ああ→い, again→う — which is Japanese phones' other input mode
/// (ケータイ入力, the one inherited from numeric keypads). Both are
/// offered because they suit different hands: a flick is faster once
/// learned, but it is a gesture a child has to be taught, and a keyboard
/// that only answers to gestures is unusable for anyone who has not
/// discovered them yet. The two do not conflict — a flick is a drag, a
/// repeat is a tap.
///
/// A repeat *replaces* the character it typed rather than adding one, so
/// the buffer never briefly shows あい on the way to い. It only counts
/// as a repeat while [_multiTapWindow] has not run out and the character
/// last typed is still the one at the end of the buffer; after that the
/// same key starts a new character, which is how ああ is typed.
///
/// Deliberately a plain controlled component (`value` + `onChanged`, no
/// submit button of its own — see `NOTES_CARD_GAME_MODE.md`'s "mandiri,
/// tidak terikat konteks pertandingan" decision) so it can be dropped into
/// any screen that needs kana text entry. Card Game Mode's answer field is
/// the first caller, but nothing here depends on match/battle state.
///
/// ## Why it is not a grid of all 46
///
/// It used to be, and that was a real bug: eleven gojūon rows plus a
/// modifier row need roughly 500dp to stay legible, the battle screen had
/// 220dp to give, and every key came out about twelve pixels tall with an
/// eighteen-point character spilling out of it. Rows of a phone keyboard
/// cannot be shorter than a fingertip, so the count of rows had to come
/// down. Sixteen big keys reach all 46 characters in one gesture each;
/// a two-tap group-then-character board reached them in two.
///
/// ## Why the flick is previewed
///
/// A flick keyboard nobody has been taught is a keyboard that only
/// produces あかさたな. So pressing a key opens a small cross showing that
/// group's five characters in their four directions, and the one your
/// finger is currently pointing at is highlighted. Nothing is hidden and
/// nothing has to be memorised — drag around, watch it change, let go.
/// It is also how a child discovers the mapping without being told.
///
/// ## What is derived rather than written down
///
/// Which character sits in which direction comes from
/// [KanaCharacter.row]/[KanaCharacter.column] in the bundled dataset, not
/// a hand-laid table, so a kana added to the data places itself. The one
/// genuine exception is ん, which every real flick keyboard puts on わ's
/// up-flick even though the dataset files it in its own row — see
/// [_groupChars].
///
/// **This widget needs bounded height from its caller** — its four rows
/// are flexed, so wrap it in a `SizedBox`/`Expanded` rather than placing
/// it inside something that sizes to its children. Around 210dp looks
/// right; below about 160 the keys stop being finger-sized.
class KanaKeyboard extends ConsumerStatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;

  /// Test seam. Multi-tap is defined by how quickly two taps follow each
  /// other, and a widget test's taps all land at the same instant on the
  /// fake clock, so the window can only be exercised by handing the
  /// keyboard a clock the test controls.
  final DateTime Function() clock;

  /// How the keys are painted. See [KeyboardLook] — shared with
  /// [RomajiKeyboard] so a skin dresses both halves of the game, not
  /// whichever one the current card happens to use.
  final KeyboardLook look;

  const KanaKeyboard({
    super.key,
    required this.value,
    required this.onChanged,
    this.clock = DateTime.now,
    this.look = const KeyboardLook(),
  });

  @override
  ConsumerState<KanaKeyboard> createState() => _KanaKeyboardState();
}

/// Where a finger is pointing, in the order a flick keyboard lays its
/// characters out: centre first, then left/up/right/down.
enum _Flick { centre, left, up, right, down }

class _KanaKeyboardState extends ConsumerState<KanaKeyboard> {
  /// Below this the gesture is a tap, not a flick. Small enough that a
  /// deliberate short flick still registers, large enough that a finger
  /// rolling on a key does not turn あ into え.
  static const _flickThreshold = 16.0;

  /// The key currently under a finger, and where that finger has moved
  /// since it went down. Both null between gestures; kept together so the
  /// preview and the character that is finally typed can never disagree.
  int? _pressedRow;
  Offset _dragged = Offset.zero;

  /// How long a key stays "the key you are still tapping".
  ///
  /// 900ms is the same order as a phone keypad's own, and the trade is
  /// visible from both ends: too short and a child typing あ, い, う by
  /// repeat has to hurry; too long and typing ああ means waiting around.
  static const _multiTapWindow = Duration(milliseconds: 900);

  /// The key being tapped repeatedly, how far through its characters the
  /// taps have got, and when the last one landed. All three are cleared
  /// together — a half-remembered cycle is what would type い when the
  /// learner meant あ.
  int? _cycleId;
  int _cycleIndex = 0;
  DateTime? _cycleAt;

  _Flick get _direction {
    if (_dragged.distance < _flickThreshold) return _Flick.centre;
    return _dragged.dx.abs() > _dragged.dy.abs()
        ? (_dragged.dx < 0 ? _Flick.left : _Flick.right)
        : (_dragged.dy < 0 ? _Flick.up : _Flick.down);
  }

  void _resetCycle() {
    _cycleId = null;
    _cycleIndex = 0;
    _cycleAt = null;
  }

  /// Whether a tap on [id] right now continues the run of taps already
  /// under way, rather than starting a new character.
  ///
  /// The buffer is checked, not just the clock: anything else typed in
  /// between — a ゛, a backspace, text set by the caller — means the
  /// character this cycle was walking through is no longer the one at the
  /// end, and replacing whatever *is* there would eat it.
  bool _continuesCycle(int id, List<String> options) {
    final at = _cycleAt;
    return _cycleId == id &&
        at != null &&
        widget.clock().difference(at) < _multiTapWindow &&
        _cycleIndex < options.length &&
        widget.value.endsWith(options[_cycleIndex]);
  }

  /// A tap — as opposed to a flick — on a group key.
  ///
  /// [canStart] is false for a key that cannot legally type its first
  /// character right now (小 with nothing to attach to). Such a key can
  /// still be tapped *again* mid-cycle, because that swaps the small kana
  /// it just added rather than adding another.
  void _typeByTap(int id, List<String?> chars, {required bool canStart}) {
    final options = chars.whereType<String>().toList();
    if (options.isEmpty) return;

    if (_continuesCycle(id, options)) {
      final previous = options[_cycleIndex];
      final next = (_cycleIndex + 1) % options.length;
      setState(() {
        _cycleIndex = next;
        _cycleAt = widget.clock();
      });
      widget.onChanged(
        widget.value.substring(0, widget.value.length - previous.length) +
            options[next],
      );
      return;
    }

    if (!canStart) return;
    setState(() {
      _cycleId = id;
      _cycleIndex = 0;
      _cycleAt = widget.clock();
    });
    widget.onChanged(widget.value + options.first);
  }

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
    final input = inputAsync.requireValue;

    // Laid out like the phone keyboard it copies: the ten gojūon groups
    // in the **middle three columns**, the keys that act on what you have
    // already typed down the outer two.
    //
    // Centring the kana is not cosmetic. A flick preview appears one key
    // away in the direction of the flick, so a group key hard against the
    // left edge has nowhere to put its い — it lands back on top of the
    // key you are pressing, hidden under your own thumb. That is exactly
    // what happened to あ, た and ま while they were in column zero. With
    // a column of modifiers either side, every direction has a key's
    // width of room to open into.
    final layout = <List<_Key>>[
      [
        _KeyModifier('゛', input.applyTenten(widget.value)),
        _group(0, baseGrid),
        _group(1, baseGrid),
        _group(2, baseGrid),
        _KeyBackspace(),
      ],
      [
        _KeyModifier('゜', input.applyMaru(widget.value)),
        _group(3, baseGrid),
        _group(4, baseGrid),
        _group(5, baseGrid),
        _KeyBlank(),
      ],
      [
        _smallYKey(input),
        _group(6, baseGrid),
        _group(7, baseGrid),
        _group(8, baseGrid),
        _KeyBlank(),
      ],
      [
        _KeyModifier('っ', input.applySokuon(widget.value)),
        _KeyBlank(),
        _group(9, baseGrid),
        _KeyBlank(),
        _KeyBlank(),
      ],
    ];

    return KeyboardPanel(
      look: widget.look,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final keyWidth = constraints.maxWidth / layout.first.length;
          final keyHeight = constraints.maxHeight / layout.length;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  for (final row in layout)
                    Expanded(
                      child: Row(
                        children: [
                          for (final key in row) Expanded(child: _build(key)),
                        ],
                      ),
                    ),
                ],
              ),
              if (_pressedRow != null)
                ..._previewFor(layout, keyWidth, keyHeight, constraints),
            ],
          );
        },
      ),
    );
  }

  // --- key definitions -----------------------------------------------

  _Key _group(int row, Map<(int, int), KanaCharacter> grid) =>
      _KeyFlick(id: row, chars: _groupChars(row, grid));

  /// A group's five characters in flick order (centre, left, up, right,
  /// down), with `null` for the directions that hold nothing — や has no
  /// い or え column, わ has only を left of it.
  ///
  /// ん is the one hand-placed character in the whole widget. The dataset
  /// files it as its own row 10 because that is what it is
  /// linguistically, but no phone keyboard gives it a key of its own; it
  /// lives on わ's up-flick, and matching that matters more here than
  /// matching the data's shape.
  List<String?> _groupChars(int row, Map<(int, int), KanaCharacter> grid) {
    String? at(int col) => grid[(row, col)]?.character;
    if (row == 9) return [at(0), at(4), grid[(10, 0)]?.character, null, null];
    return [at(0), at(1), at(2), at(3), at(4)];
  }

  /// The 小 key. Same flick gesture as a group key so there is only one
  /// thing to learn, and it stays disabled until the buffer actually ends
  /// in a character that forms youon — が or ん cannot take a small ゃ,
  /// and offering it there would teach the wrong thing.
  ///
  /// Its three characters sit on centre/up/right rather than the usual
  /// centre/left/up/right/down, because this key lives in the outermost
  /// left column: a left-flick here would open its preview off the edge
  /// of the keyboard, where it can only land back on the key under the
  /// thumb.
  _Key _smallYKey(KanaKeyboardInput input) {
    const chars = ['ゃ', null, 'ゅ', 'ょ', null];
    final canStart = input.applySmallY(widget.value, 'ゃ') != null;
    // Still live while it is being tapped through, even though the ゃ it
    // just typed is not itself something a small kana can follow —
    // otherwise the key greys out under the finger after the first tap
    // and ゅ/ょ are unreachable by repeat.
    final live = canStart || _continuesCycle(-1, ['ゃ', 'ゅ', 'ょ']);
    return _KeyFlick(
      id: -1,
      chars: live ? chars : [null, null, null, null, null],
      label: '小',
      muted: true,
      canStart: canStart,
    );
  }

  // --- rendering ------------------------------------------------------

  Widget _build(_Key key) {
    return switch (key) {
      _KeyBlank() => const SizedBox.shrink(),
      _KeyBackspace() => _KeyButton(
        icon: Icons.backspace_outlined,
        muted: true,
        onTap: widget.value.isEmpty
            ? null
            : () {
                _resetCycle();
                widget.onChanged(
                  ref
                      .read(kanaKeyboardInputProvider)
                      .requireValue
                      .backspace(widget.value),
                );
              },
      ),
      _KeyModifier(:final label, :final result) => _KeyButton(
        label: label,
        muted: true,
        onTap: result == null
            ? null
            : () {
                // ゛ rewrites the character a run of taps was walking
                // through (か becomes が), so the run is over.
                _resetCycle();
                widget.onChanged(result);
              },
      ),
      _KeyFlick(
        :final id,
        :final chars,
        :final label,
        :final muted,
        :final canStart,
      ) =>
        _FlickKeyButton(
          label: label ?? chars.first ?? '',
          muted: muted,
          look: widget.look,
          enabled: chars.first != null,
          pressed: _pressedRow == id,
          onDown: () => setState(() {
            _pressedRow = id;
            _dragged = Offset.zero;
          }),
          onMove: (delta) => setState(() => _dragged += delta),
          onUp: () {
            final direction = _direction;
            final picked = chars[direction.index];
            setState(() {
              _pressedRow = null;
              _dragged = Offset.zero;
            });
            if (direction == _Flick.centre) {
              _typeByTap(id, chars, canStart: canStart);
              return;
            }
            // A flick says exactly which character is wanted, so it ends
            // any run of taps rather than being counted as one of them.
            _resetCycle();
            // A flick into an empty direction types nothing rather than
            // falling back to the centre character: silently giving や
            // when the finger clearly went left would be worse than
            // giving nothing, because nothing is obviously a miss.
            if (picked != null) widget.onChanged(widget.value + picked);
          },
          onCancel: () => setState(() {
            _pressedRow = null;
            _dragged = Offset.zero;
          }),
        ),
    };
  }

  /// The flick preview: the pressed key's other characters, floating in
  /// the direction that produces them, with the current one highlighted.
  List<Widget> _previewFor(
    List<List<_Key>> layout,
    double keyWidth,
    double keyHeight,
    BoxConstraints constraints,
  ) {
    int? gridRow;
    int? gridCol;
    List<String?>? chars;
    for (var r = 0; r < layout.length; r++) {
      for (var c = 0; c < layout[r].length; c++) {
        final key = layout[r][c];
        if (key is _KeyFlick && key.id == _pressedRow) {
          gridRow = r;
          gridCol = c;
          chars = key.chars;
        }
      }
    }
    if (chars == null || gridRow == null || gridCol == null) return const [];

    final centreX = (gridCol + 0.5) * keyWidth;
    final centreY = (gridRow + 0.5) * keyHeight;
    final current = _direction;

    final bubbles = <Widget>[];
    for (var i = 0; i < chars.length; i++) {
      final char = chars[i];
      if (char == null) continue;
      final offset = switch (_Flick.values[i]) {
        _Flick.centre => Offset.zero,
        _Flick.left => Offset(-keyWidth, 0),
        _Flick.up => Offset(0, -keyHeight),
        _Flick.right => Offset(keyWidth, 0),
        _Flick.down => Offset(0, keyHeight),
      };
      bubbles.add(
        Positioned(
          // Clamped to the keyboard's own width so a flick preview on the
          // left-hand column does not hang off the edge of the screen.
          left: (centreX + offset.dx - keyWidth / 2).clamp(
            0.0,
            constraints.maxWidth - keyWidth,
          ),
          top: centreY + offset.dy - keyHeight / 2,
          width: keyWidth,
          height: keyHeight,
          child: _PreviewBubble(
            char: char,
            active: _Flick.values[i] == current,
          ),
        ),
      );
    }
    return bubbles;
  }
}

// --- key model --------------------------------------------------------

sealed class _Key {
  const _Key();
}

class _KeyBlank extends _Key {}

class _KeyBackspace extends _Key {}

class _KeyModifier extends _Key {
  final String label;

  /// The buffer this key would produce, or `null` when it does not apply
  /// to what has been typed — which is also what greys the key out.
  final String? result;

  _KeyModifier(this.label, this.result);
}

class _KeyFlick extends _Key {
  final int id;
  final List<String?> chars;
  final String? label;
  final bool muted;

  /// Whether this key may type its first character right now. False only
  /// for 小 with nothing to attach a small kana to — a gojūon key can
  /// always start a character.
  final bool canStart;

  _KeyFlick({
    required this.id,
    required this.chars,
    this.label,
    this.muted = false,
    this.canStart = true,
  });
}

// --- widgets ----------------------------------------------------------

/// A key that reports the raw pointer rather than using a tap or pan
/// recogniser. Both of those go through the gesture arena, and a flick is
/// exactly the kind of short drag the arena hands to whatever scrollable
/// happens to be an ancestor — which would make the keyboard work in
/// isolation and silently stop working the moment a caller wrapped it in
/// a scroll view.
class _FlickKeyButton extends StatelessWidget {
  final String label;
  final KeyboardLook look;
  final bool muted;
  final bool enabled;
  final bool pressed;
  final VoidCallback onDown;
  final ValueChanged<Offset> onMove;
  final VoidCallback onUp;
  final VoidCallback onCancel;

  const _FlickKeyButton({
    required this.label,
    required this.look,
    required this.muted,
    required this.enabled,
    required this.pressed,
    required this.onDown,
    required this.onMove,
    required this.onUp,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    if (!enabled) {
      return _KeyButton(label: label, muted: muted, onTap: null, look: look);
    }
    return Listener(
      onPointerDown: (_) => onDown(),
      onPointerMove: (e) => onMove(e.delta),
      onPointerUp: (_) => onUp(),
      onPointerCancel: (_) => onCancel(),
      child: _KeyButton(
        label: label,
        muted: muted,
        look: look,
        // Pressed keys darken rather than lift: the preview is already
        // doing the work of showing where the finger is.
        highlighted: pressed,
        // The gesture is owned by the Listener above; giving InkWell a
        // callback too would fire twice.
        onTap: () {},
        colorOverride: pressed ? palette.primaryCoral : null,
      ),
    );
  }
}

class _PreviewBubble extends StatelessWidget {
  final String char;
  final bool active;

  const _PreviewBubble({required this.char, required this.active});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Material(
          color: active ? palette.primaryCoral : palette.cardWhite,
          borderRadius: BorderRadius.circular(8),
          elevation: 6,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                char,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : palette.textNavy,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool muted;
  final bool highlighted;
  final Color? colorOverride;
  final KeyboardLook look;

  const _KeyButton({
    this.label,
    this.icon,
    this.onTap,
    this.muted = false,
    this.highlighted = false,
    this.colorOverride,
    this.look = const KeyboardLook(),
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final enabled = onTap != null;
    final text = look.text ?? palette.textNavy;
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Material(
        color:
            colorOverride ??
            (muted
                ? (look.mutedFace ?? palette.mutedSurface)
                : (look.face ?? palette.cardWhite)),
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
                        color: highlighted
                            ? Colors.white
                            : enabled
                            ? text
                            : text.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

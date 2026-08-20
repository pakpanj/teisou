import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import 'widgets/battle_arena.dart';

/// Choosing which card to send, on a screen of its own.
///
/// It used to be a strip along the bottom of the arena: six cards wide,
/// scrolled sideways, beneath everything else on the screen. That works
/// for a hand of six and stops working for a hand of twenty — the player
/// cannot see what they hold, and the ten-second clock runs while they
/// drag through it. A full screen shows the hand as a grid and gives the
/// choice the room it deserves.
///
/// **The pop value is the chosen card id, or null.** The caller plays the
/// card; this screen never writes to the match. One place decides what a
/// choice means, and this stays a picker.
///
/// Two ways out other than choosing: the close button, and [deadline].
///
/// The clock is this screen's own, ticking from an absolute time rather
/// than counting down a number the caller passes in. A pushed route does
/// not rebuild when the screen underneath it does, so a per-second value
/// handed over at push time would freeze at whatever it was — and the
/// window would appear to stop while it was in fact still running out.
class BattleCardPickerScreen extends ConsumerStatefulWidget {
  const BattleCardPickerScreen({
    super.key,
    required this.cards,
    required this.totalCards,
    required this.deadline,
    this.clock = DateTime.now,
  });

  /// Prompt text per card, in hand order, paired with its card id.
  final List<({String cardId, String prompt})> cards;

  /// What the hand was dealt, for the `left / total` counter. A hand only
  /// ever shrinks, so "6" on its own reads as a small hand rather than a
  /// nearly spent one.
  final int totalCards;

  /// When the choosing window closes.
  final DateTime deadline;

  /// Reads the current time.
  ///
  /// Injectable for one reason: `testWidgets` runs its timers on a fake
  /// clock while `DateTime.now` keeps returning the real one, so a test
  /// that pumps past the deadline fires the tick and then finds the
  /// window still open. That mismatch is what this parameter exists for,
  /// and production never passes it.
  @visibleForTesting
  final DateTime Function() clock;

  @override
  ConsumerState<BattleCardPickerScreen> createState() =>
      _BattleCardPickerScreenState();
}

class _BattleCardPickerScreenState
    extends ConsumerState<BattleCardPickerScreen> {
  String? _selected;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      // Closing itself at zero, rather than leaving that to the player at
      // the very moment the choice stopped being theirs. The round's
      // dealt card goes out on its own then, so staying open would hide
      // what had already happened.
      if (_secondsLeft <= 0) {
        _tick?.cancel();
        Navigator.of(context).maybePop();
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  int get _secondsLeft {
    final left = widget.deadline.difference(widget.clock());
    if (left.isNegative) return 0;
    // Rounded up, not truncated-then-incremented. Both agree on the
    // fraction of a second this always is in a real match, and they
    // differ by one on a whole number — which is exactly what a test
    // hands it, and would have been read as the test being wrong.
    return (left.inMilliseconds / 1000).ceil();
  }

  /// Cycled by position, so the hand looks like a hand of cards rather
  /// than a grid of identical buttons — and a card keeps its colour as
  /// the ones around it are played.
  List<Color> _tints(AppPalette palette) => [
        palette.hiraganaCardBg,
        palette.katakanaCardBg,
        palette.tertiaryAmberCardBg,
        palette.mutedSurface,
      ];

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final palette = context.palette;
    final tints = _tints(palette);

    return Scaffold(
      body: BattleBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              _Header(strings: s, palette: palette),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: _HandPanel(
                    palette: palette,
                    title: s.battleHandTitle,
                    counter: s.battleHandRemaining(
                      widget.cards.length,
                      widget.totalCards,
                    ),
                    secondsLeft: _secondsLeft,
                    children: [
                      for (var i = 0; i < widget.cards.length; i++)
                        _PickerCard(
                          prompt: widget.cards[i].prompt,
                          tint: tints[i % tints.length],
                          selected: _selected == widget.cards[i].cardId,
                          onTap: () => setState(
                            () => _selected = widget.cards[i].cardId,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              _Footer(
                palette: palette,
                hint: s.battleCardPickerHint,
                label: s.battleCardPickerSend,
                // Nothing to send until something is picked. Disabled
                // rather than hidden: a button that appears on tap moves
                // the thing the player is already reaching for.
                onSend: _selected == null
                    ? null
                    : () => Navigator.of(context).pop(_selected),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.strings, required this.palette});

  final AppStrings strings;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CloseButton(palette: palette),
          Expanded(
            child: Column(
              children: [
                Text(
                  strings.battleCardPickerTitle,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: palette.textNavy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  strings.battleChooseInstruction,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: palette.textNavy.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          // Balances the close button, so the title is centred on the
          // screen rather than on what is left of it.
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(context).pop(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: const Icon(Icons.close, size: 24, color: Colors.white),
        ),
      ),
    );
  }
}

/// The framed panel the cards sit in, with its own heading.
class _HandPanel extends StatelessWidget {
  const _HandPanel({
    required this.palette,
    required this.title,
    required this.counter,
    required this.secondsLeft,
    required this.children,
  });

  final AppPalette palette;
  final String title;
  final String counter;
  final int secondsLeft;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: palette.primaryCoral.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Petal(palette: palette),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: palette.textNavy,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _Petal(palette: palette),
                const SizedBox(width: 10),
                _Pill(palette: palette, text: counter),
                const SizedBox(width: 10),
                // The clock is not in the mockup and has to be here
                // anyway: the window closes on its own, and a screen
                // that vanishes mid-decision with no warning reads as a
                // crash rather than as a rule.
                //
                // Sized like something that matters, not like a caption.
                // It ran at eleven points beside the card counter first
                // and was missed on the device — which is the whole
                // point of showing it.
                _Countdown(palette: palette, secondsLeft: secondsLeft),
              ],
            ),
          ),
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
              crossAxisCount: 3,
              mainAxisSpacing: 14,
              crossAxisSpacing: 12,
              childAspectRatio: 0.72,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _Petal extends StatelessWidget {
  const _Petal({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.local_florist, size: 14, color: palette.primaryCoral);
  }
}

class _Countdown extends StatelessWidget {
  const _Countdown({required this.palette, required this.secondsLeft});

  final AppPalette palette;
  final int secondsLeft;

  @override
  Widget build(BuildContext context) {
    final urgent = secondsLeft <= 3;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: urgent
            ? palette.errorRed
            : Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: urgent
              ? Colors.white.withValues(alpha: 0.8)
              : palette.primaryCoral.withValues(alpha: 0.7),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 20, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            '${secondsLeft}s',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.palette, required this.text});

  final AppPalette palette;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

class _PickerCard extends StatelessWidget {
  const _PickerCard({
    required this.prompt,
    required this.tint,
    required this.selected,
    required this.onTap,
  });

  final String prompt;
  final Color tint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: tint,
      borderRadius: BorderRadius.circular(14),
      elevation: selected ? 6 : 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? palette.primaryCoral
                      : palette.secondaryBlue.withValues(alpha: 0.5),
                  width: selected ? 3 : 2,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: palette.primaryCoral.withValues(alpha: 0.6),
                          blurRadius: 16,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      prompt,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: palette.textNavy,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (selected)
              Positioned(
                top: -8,
                left: -8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: palette.primaryCoral,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.check, size: 16, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.palette,
    required this.hint,
    required this.label,
    required this.onSend,
  });

  final AppPalette palette;
  final String hint;
  final String label;
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      // A ground for the button to sit on. The backdrop is at its
      // brightest right here — torii, lanterns, the lit water — and a
      // translucent coral button laid straight over it vanished into the
      // artwork, which looked like a failure to draw rather than a
      // button waiting to be enabled. Seen on the device; the same
      // button reads fine over the dark upper half.
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0),
            Colors.black.withValues(alpha: 0.55),
            Colors.black.withValues(alpha: 0.8),
          ],
          stops: const [0, 0.45, 1],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 15,
                color: palette.primaryCoral,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  hint,
                  style: TextStyle(
                    fontSize: 13,
                    color: palette.textNavy.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: palette.primaryCoral,
                // Muted, but still plainly a button. At 0.35 over the
                // night backdrop the fill all but disappeared and the
                // label sat on the artwork looking like a rendering
                // fault rather than like something waiting on the
                // player — checked on a device, not guessed.
                disabledBackgroundColor:
                    palette.primaryCoral.withValues(alpha: 0.55),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
              ),
              onPressed: onSend,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

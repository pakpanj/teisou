import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/kaiwa_expressions.dart';
import '../../core/localization/app_strings.dart';
import '../../core/providers.dart';
import '../../core/services/furigana_dictionary.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/furigana_text.dart';
import '../../core/widgets/swipe_navigator.dart';
import '../../data/models/jlpt_level.dart';
import '../../data/models/kaiwa_answer_option.dart';
import '../../data/models/kaiwa_entry.dart';
import '../../data/models/kaiwa_line.dart';
import '../../data/models/xp_progress.dart';
import 'kaiwa_providers.dart';
import 'widgets/kaiwa_image.dart';
import '../../core/services/japanese_voices.dart';

/// Interactive practice screen for one Kaiwa dialogue — reveals NPC lines
/// (image + speak button only, no visible text) automatically and pauses
/// at each user turn until the learner **taps** the correct multiple-choice
/// option (no typing or speech input — that was the source of the crashes
/// this screen used to have; see CLAUDE.md). Next/prev pages between
/// dialogues in [entries], same convention as `ParticleDetailScreen`; the
/// outer [SingleChildScrollView] is keyed on the dialogue id from the start
/// so paging resets scroll position — a real bug found in
/// `BunpouDetailScreen` (fixed for Partikel afterward), applied here from
/// day one instead of repeating it.
class KaiwaDialogueScreen extends ConsumerStatefulWidget {
  final List<KaiwaEntry> entries;
  final int initialIndex;
  final String categoryName;
  final JlptLevel level;

  const KaiwaDialogueScreen({
    super.key,
    required this.entries,
    required this.initialIndex,
    required this.categoryName,
    required this.level,
  });

  @override
  ConsumerState<KaiwaDialogueScreen> createState() =>
      _KaiwaDialogueScreenState();
}

class _KaiwaDialogueScreenState extends ConsumerState<KaiwaDialogueScreen> {
  late int _index = widget.initialIndex;
  late int _revealedCount;
  final Map<int, KaiwaAnswerOption> _answered = {};

  /// Shuffled display order (indices into that line's `options` list) per
  /// user-turn line index — computed once when the turn is revealed, not
  /// on every rebuild, so option positions don't jitter after a wrong tap.
  final Map<int, List<int>> _optionOrder = {};

  /// Original-list index of the option most recently tapped incorrectly,
  /// for a brief red-flash; cleared automatically, no attempt limit and no
  /// score penalty — the learner can keep trying any option.
  int? _wrongOptionIndex;

  bool _togglingLearned = false;

  final _scrollController = ScrollController();

  KaiwaEntry get _entry => widget.entries[_index];

  @override
  void initState() {
    super.initState();
    _resetForEntry();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _resetForEntry() {
    _revealedCount = 0;
    _answered.clear();
    _optionOrder.clear();
    _wrongOptionIndex = null;
    _revealNext();
  }

  void _revealNext() {
    final lines = _entry.lines;
    while (_revealedCount < lines.length) {
      final lineIndex = _revealedCount;
      final line = lines[lineIndex];
      _revealedCount++;
      if (line.isUserTurn) {
        _optionOrder[lineIndex] = List.generate(line.options.length, (i) => i)
          ..shuffle();
        break;
      }
    }
    _scrollToBottomSoon();
  }

  void _scrollToBottomSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _selectOption(
    int lineIndex,
    int originalIndex,
    KaiwaAnswerOption option,
  ) {
    if (option.isCorrect) {
      setState(() {
        _answered[lineIndex] = option;
        _wrongOptionIndex = null;
        _revealNext();
      });
      return;
    }
    setState(() => _wrongOptionIndex = originalIndex);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _wrongOptionIndex = null);
    });
  }

  Future<void> _toggleLearned() async {
    final uid = ref.read(appStartupProvider).valueOrNull?.uid;
    if (uid == null) return;
    setState(() => _togglingLearned = true);
    try {
      final repo = ref.read(kaiwaProgressRepositoryProvider);
      final learnedIds =
          ref.read(kaiwaLearnedIdsProvider).valueOrNull ?? const <String>{};
      if (learnedIds.contains(_entry.id)) {
        await repo.unmarkLearned(uid, _entry.id);
      } else {
        await repo.markLearned(uid, _entry.id, _entry.category);
        // Only on the way to learned, never on unmark — toggling back and
        // forth must not farm XP.
        await ref
            .read(progressRepositoryProvider)
            .addXp(uid, XpAction.wordLearned);
        ref.invalidate(xpProgressProvider);
      }
      ref.invalidate(kaiwaLearnedIdsProvider);
    } finally {
      // The screen owns this spinner, so it clears it whatever
      // happens. The repositories below do swallow their own
      // mirror-write failures today, but that is their promise to
      // keep and not this screen's to lean on — an await added here
      // later must not be able to strand the button.
      if (mounted) setState(() => _togglingLearned = false);
    }
  }

  /// The line the big card shows: the most recent npc turn revealed.
  ///
  /// Not simply "the last revealed line". While the learner is choosing
  /// a reply, the last revealed line is their own unanswered turn — and
  /// what they need in front of them is the thing being replied to.
  /// Returns -1 for a dialogue that opens with the learner speaking,
  /// where nothing has been said yet.
  int _speakingIndex(List<KaiwaLine> lines) {
    for (var i = _revealedCount - 1; i >= 0; i--) {
      if (!lines[i].isUserTurn) return i;
    }
    return -1;
  }

  void _goNext() {
    if (_index >= widget.entries.length - 1) return;
    setState(() {
      _index++;
      _resetForEntry();
    });
  }

  void _goPrev() {
    if (_index <= 0) return;
    setState(() {
      _index--;
      _resetForEntry();
    });
  }

  @override
  Widget build(BuildContext context) {
    final learnedIds =
        ref.watch(kaiwaLearnedIdsProvider).valueOrNull ?? const <String>{};
    final isLearned = learnedIds.contains(_entry.id);
    final s = ref.watch(appStringsProvider);
    final lines = _entry.lines;
    final lastIsUnansweredUserTurn =
        _revealedCount > 0 &&
        lines[_revealedCount - 1].isUserTurn &&
        !_answered.containsKey(_revealedCount - 1);
    final dialogueComplete =
        _revealedCount >= lines.length && !lastIsUnansweredUserTurn;
    final showFurigana = showFuriganaFor(widget.level);
    final furiganaDictionary = showFurigana
        ? ref.watch(furiganaDictionaryProvider).valueOrNull
        : null;

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: Text(_entry.localizedTitle(s.language))),
      body: Column(
        children: [
          Expanded(
            // Swipe is only wired up once dialogueComplete — same
            // condition that shows the _CompletionBar's next/prev
            // buttons — so a horizontal swipe mid-dialogue can't be used
            // to skip past an unanswered user turn. hasNext/hasPrev mirror
            // the buttons' own disabled-state logic exactly.
            child: SwipeNavigator(
              onSwipeLeft:
                  dialogueComplete && _index < widget.entries.length - 1
                  ? _goNext
                  : null,
              onSwipeRight: dialogueComplete && _index > 0 ? _goPrev : null,
              // Centred in whatever room is left, and scrollable when
              // there is not enough. One card on a tall phone used to
              // sit against the top with two thirds of the screen blank
              // under it; the card is the only thing being read, so it
              // belongs where the eye already is.
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                key: ValueKey(_entry.id),
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 32,
                  ),
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _entry.localizedDescription(s.language),
                      style: TextStyle(
                        fontSize: 13,
                        color: context.palette.textNavy.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Everything before the turn being played, kept as a
                    // slim trail rather than dropped. The learner needs
                    // to see how the conversation got here — especially
                    // their own answers, which are the only text in the
                    // whole exchange.
                    for (var i = 0; i < _speakingIndex(lines); i++)
                      _TrailRow(
                        key: ValueKey('trail-${lines[i].id}'),
                        line: lines[i],
                        answer: _answered[i],
                      ),
                    // The turn itself, full width. One card at a time:
                    // this is the only thing the learner is being asked
                    // to understand, and a stack of past bubbles pushed
                    // it into a corner.
                    if (_speakingIndex(lines) >= 0)
                      _LineBubble(
                        dialogueId: _entry.id,
                        category: _entry.category,
                        key: ValueKey(lines[_speakingIndex(lines)].id),
                        line: lines[_speakingIndex(lines)],
                        answer: _answered[_speakingIndex(lines)],
                        strings: s,
                        furiganaDictionary: furiganaDictionary,
                      ),
                  ],
                ),
                ),
              ),
              ),
            ),
          ),
          if (lastIsUnansweredUserTurn)
            _AnswerOptions(
              options: lines[_revealedCount - 1].options,
              order: _optionOrder[_revealedCount - 1] ?? const [],
              wrongOptionIndex: _wrongOptionIndex,
              strings: s,
              onSelect: (originalIndex, option) =>
                  _selectOption(_revealedCount - 1, originalIndex, option),
              furiganaDictionary: furiganaDictionary,
            )
          else if (dialogueComplete)
            _CompletionBar(
              learned: isLearned,
              toggling: _togglingLearned,
              strings: s,
              onToggleLearned: _toggleLearned,
              hasNext: _index < widget.entries.length - 1,
              hasPrev: _index > 0,
              onNext: _goNext,
              onPrev: _goPrev,
            ),
        ],
      ),
    );
  }
}

/// Keyed on `line.id` (not just positional) — a real bug found on-device:
/// when a dialogue starts with a user turn, answering it correctly can
/// reveal *two* new bubbles at once (the npc line plus the next user
/// prompt, since `_revealNext` only pauses at user turns). Without an
/// explicit key, Flutter's default position-based element reuse could
/// leave the freshly-inserted npc bubble's `KaiwaImage` state confused
/// with whatever widget previously occupied that Column slot, so its
/// image never rendered — visible only on the *first* such multi-bubble
/// reveal in a dialogue, which is why some dialogues looked fine while
/// others (the ones starting with a user turn) didn't.
class _LineBubble extends StatelessWidget {
  final KaiwaLine line;
  final KaiwaAnswerOption? answer;
  final AppStrings strings;
  final FuriganaDictionary? furiganaDictionary;

  /// Only used to keep a genderless speaker's voice stable — see
  /// [voiceForSpeaker].
  final String dialogueId;

  /// Chooses the card's painted backdrop — see [_SpeakingCard].
  final String category;

  const _LineBubble({
    super.key,
    required this.line,
    this.answer,
    required this.strings,
    required this.dialogueId,
    required this.category,
    this.furiganaDictionary,
  });

  @override
  Widget build(BuildContext context) {
    if (!line.isUserTurn) return _npcBubble(context);
    if (answer != null) return _answeredBubble(context, answer!);
    return _promptBubble(context);
  }

  /// The speaking card: a round portrait beside the speaker's name.
  ///
  /// Round rather than square, and wide rather than tall, for one
  /// reason that is not taste: **the frame is drawn here, not in the
  /// picture.** The ring, the background and the name plate are Flutter
  /// widgets, so the only thing an artist has to supply is the cat on a
  /// transparent background — and one such portrait serves every line
  /// where that character wears that expression. A full-bleed
  /// illustration would look richer and would need a unique drawing for
  /// each of the module's 7,468 npc lines instead of a few hundred.
  ///
  /// There is deliberately no waveform, no elapsed time and no scrub
  /// bar. The voice is TTS ([_SpeakButton]) — there is no audio file to
  /// scrub, no duration known before it speaks, and a progress bar that
  /// cannot be dragged is a control that lies.
  Widget _npcBubble(BuildContext context) {
    final npc = line.npcLine;
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _SpeakingCard(
        category: category,
        child: Row(
          children: [
            _PortraitRing(imagePath: line.imagePath, palette: palette),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          line.speaker,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: palette.primaryCoral,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.local_florist,
                          size: 14,
                          color: palette.primaryCoral.withValues(alpha: 0.8)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    strings.kaiwaSpeakingNow,
                    style: TextStyle(
                      fontSize: 12,
                      color: palette.textNavy.withValues(alpha: 0.55),
                    ),
                  ),
                  if (npc != null) ...[
                    const SizedBox(height: 10),
                    _SpeakButton(
                      text: npc.japanese,
                      label: strings.kaiwaListen,
                      // Never null: most speakers here are roles the
                      // content deliberately leaves genderless, and
                      // passing that through meant every one of them
                      // came out of the same default female voice.
                      gender: voiceForSpeaker(
                        dialogueId: dialogueId,
                        speaker: line.speaker,
                        authored: line.gender,
                      ),
                      // A teacher and a classmate are not the same
                      // person and should not share a voice.
                      register: registerForSpeaker(line.speaker),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _answeredBubble(BuildContext context, KaiwaAnswerOption chosen) {
    final emoji = kaiwaExpressionEmoji[chosen.expressionTag];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 48),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.palette.primaryCoral.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (emoji != null) ...[
                        Text(emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: furiganaDictionary != null
                            ? FuriganaSentence(
                                text: chosen.japanese,
                                dictionary: furiganaDictionary!,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: context.palette.textNavy,
                                ),
                              )
                            : Text(
                                chosen.japanese,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: context.palette.textNavy,
                                ),
                              ),
                      ),
                    ],
                  ),
                  if (chosen.romaji != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      chosen.romaji!,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: context.palette.textNavy.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    chosen.localizedTranslation(strings.language),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.palette.textNavy.withValues(alpha: 0.7),
                    ),
                  ),
                  if (chosen.note != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      chosen.note!,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.palette.secondaryBlue,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _promptBubble(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: context.palette.mutedSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              strings.yourTurnPickAnswer,
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: context.palette.textNavy.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One turn that has already happened, in a single slim row.
///
/// Deliberately small and quiet. It exists so the conversation still
/// reads as a conversation, not so anyone studies it again — the turn
/// being played is the one with the big card.
class _TrailRow extends StatelessWidget {
  const _TrailRow({super.key, required this.line, this.answer});

  final KaiwaLine line;
  final KaiwaAnswerOption? answer;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final chosen = answer;

    if (!line.isUserTurn) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            KaiwaImage(
              imagePath: line.imagePath,
              size: 26,
              borderRadius: const BorderRadius.all(Radius.circular(26)),
            ),
            const SizedBox(width: 8),
            Text(
              line.speaker,
              style: TextStyle(
                fontSize: 12,
                color: palette.textNavy.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      );
    }

    // An unanswered user turn never reaches the trail — only the turn
    // being played can be unanswered, and that one is not in it.
    if (chosen == null) return const SizedBox.shrink();
    final emoji = kaiwaExpressionEmoji[chosen.expressionTag];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Text(
              chosen.japanese,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: palette.primaryCoral.withValues(alpha: 0.75),
              ),
            ),
          ),
          if (emoji != null) ...[
            const SizedBox(width: 4),
            Text(emoji, style: const TextStyle(fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

/// The decorated plate the speaking turn sits on.
///
/// Night sky, drifting petals and a gold hairline — the ornament the
/// design called for, drawn here rather than baked into a picture. That
/// is the whole reason it is code: one painted card would have to be
/// redrawn for every character and every mood, while this one is the
/// same behind all of them and costs nothing per line.
///
/// The palette flips with the theme rather than staying dark in both.
/// A night card on a bright screen reads as a hole, which is the
/// mistake the module-frame art was written to avoid.
class _SpeakingCard extends StatelessWidget {
  const _SpeakingCard({required this.category, required this.child});

  /// The dialogue's theme id, which chooses the painted backdrop.
  final String category;

  final Widget child;

  /// Themes repeat at every JLPT level under suffixed ids, and a
  /// restaurant is the same restaurant at N5 and at N1 — so the suffix
  /// is dropped and seventeen files cover all eighty-five.
  static String assetFor(String category) {
    final base = category.replaceFirst(RegExp(r'_n[1-5]$'), '');
    return 'assets/kaiwa_bg/kaiwa_bg_$base.png';
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final palette = context.palette;
    final top = dark ? const Color(0xFF241B3A) : const Color(0xFFFDE8EF);
    final bottom = dark ? const Color(0xFF3B2140) : const Color(0xFFF7D9E6);
    final gold = dark ? const Color(0xFFD8B15A) : const Color(0xFFC79A3F);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [top, bottom],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gold.withValues(alpha: 0.55), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Stack(
          children: [
            // Painted art when the theme has any, and the drawn petals
            // when it does not. The fallback is not a placeholder to
            // replace later — it is what this card looked like before
            // the art existed, so the seventeen files can arrive one at
            // a time and a theme still waiting for its own looks
            // finished rather than broken.
            Positioned.fill(
              child: IgnorePointer(
                child: Image.asset(
                  assetFor(category),
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, _) => CustomPaint(
                    painter: _PetalPainter(palette.primaryCoral),
                  ),
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

/// A handful of petals drifting behind the card's contents.
///
/// Placed from a fixed list rather than at random: a repaint that moves
/// them would make the card twitch every time the countdown or the
/// speaker name changed.
class _PetalPainter extends CustomPainter {
  const _PetalPainter(this.color);

  final Color color;

  static const _spots = <(double, double, double)>[
    (0.08, 0.18, 4), (0.22, 0.72, 3), (0.46, 0.12, 3.5),
    (0.63, 0.82, 4.5), (0.78, 0.28, 3), (0.90, 0.62, 4),
    (0.34, 0.44, 2.5), (0.70, 0.52, 2.5),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.22);
    for (final (fx, fy, r) in _spots) {
      canvas.drawCircle(Offset(size.width * fx, size.height * fy), r, paint);
    }
  }

  @override
  bool shouldRepaint(_PetalPainter old) => old.color != color;
}

/// The round portrait, and the ring the artist does not have to draw.
class _PortraitRing extends StatelessWidget {
  const _PortraitRing({required this.imagePath, required this.palette});

  final String? imagePath;
  final AppPalette palette;

  static const _size = 132.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.cardWhite,
        // Gold, not coral: the ring is the ornament the mockup framed
        // the character with, and coral on a coral-tinted card
        // disappeared into it.
        border: Border.all(color: const Color(0xFFD8B15A), width: 3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD8B15A).withValues(alpha: 0.35),
            blurRadius: 12,
          ),
        ],
      ),
      child: KaiwaImage(
        imagePath: imagePath,
        size: _size,
        borderRadius: const BorderRadius.all(Radius.circular(_size)),
      ),
    );
  }
}

/// Says the line aloud.
///
/// Labelled rather than a bare icon: this is the only way to hear the
/// sentence, on a screen aimed at children, and a lone speaker glyph
/// asks them to guess.
class _SpeakButton extends ConsumerWidget {
  final String text;
  final String label;
  final KaiwaGender? gender;
  final VoiceRegister register;

  const _SpeakButton({
    required this.text,
    required this.label,
    this.gender,
    this.register = VoiceRegister.peer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    return Material(
      color: palette.secondaryBlue,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => ref
            .read(ttsServiceProvider)
            .speak(text, gender: gender, register: register),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.volume_up, size: 18, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnswerOptions extends StatelessWidget {
  final List<KaiwaAnswerOption> options;
  final List<int> order;
  final int? wrongOptionIndex;
  final AppStrings strings;
  final void Function(int originalIndex, KaiwaAnswerOption option) onSelect;
  final FuriganaDictionary? furiganaDictionary;

  const _AnswerOptions({
    required this.options,
    required this.order,
    required this.wrongOptionIndex,
    required this.strings,
    required this.onSelect,
    this.furiganaDictionary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: context.palette.cardWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.pickCorrectAnswer,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: context.palette.textNavy.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 10),
          for (final originalIndex in order) ...[
            _OptionButton(
              option: options[originalIndex],
              isWrongFlash: wrongOptionIndex == originalIndex,
              onTap: () => onSelect(originalIndex, options[originalIndex]),
              furiganaDictionary: furiganaDictionary,
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final KaiwaAnswerOption option;
  final bool isWrongFlash;
  final VoidCallback onTap;
  final FuriganaDictionary? furiganaDictionary;

  const _OptionButton({
    required this.option,
    required this.isWrongFlash,
    required this.onTap,
    this.furiganaDictionary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isWrongFlash
              ? context.palette.errorRed.withValues(alpha: 0.15)
              : context.palette.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isWrongFlash
                ? context.palette.errorRed
                : context.palette.secondaryBlue.withValues(alpha: 0.3),
            width: isWrongFlash ? 2 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: furiganaDictionary != null
                  ? FuriganaSentence(
                      text: option.japanese,
                      dictionary: furiganaDictionary!,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.palette.textNavy,
                      ),
                    )
                  : Text(
                      option.japanese,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.palette.textNavy,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompletionBar extends StatelessWidget {
  final bool learned;
  final bool toggling;
  final AppStrings strings;
  final VoidCallback onToggleLearned;
  final bool hasNext;
  final bool hasPrev;
  final VoidCallback onNext;
  final VoidCallback onPrev;

  const _CompletionBar({
    required this.learned,
    required this.toggling,
    required this.strings,
    required this.onToggleLearned,
    required this.hasNext,
    required this.hasPrev,
    required this.onNext,
    required this.onPrev,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.cardWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: hasPrev ? onPrev : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: toggling ? null : onToggleLearned,
              icon: Icon(
                learned ? Icons.check_circle : Icons.check_circle_outline,
              ),
              label: Text(
                learned ? strings.markedLearned : strings.markAsLearned,
              ),
            ),
          ),
          IconButton(
            onPressed: hasNext ? onNext : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

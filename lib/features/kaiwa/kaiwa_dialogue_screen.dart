import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/kaiwa_expressions.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/swipe_navigator.dart';
import '../../data/models/kaiwa_answer_option.dart';
import '../../data/models/kaiwa_entry.dart';
import '../../data/models/kaiwa_line.dart';
import 'kaiwa_providers.dart';
import 'widgets/kaiwa_image.dart';

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

  const KaiwaDialogueScreen({
    super.key,
    required this.entries,
    required this.initialIndex,
    required this.categoryName,
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
    setState(() => _togglingLearned = true);
    final uid = ref.read(appStartupProvider).valueOrNull?.uid;
    final repo = ref.read(kaiwaProgressRepositoryProvider);
    final learnedIds =
        ref.read(kaiwaLearnedIdsProvider).valueOrNull ?? const <String>{};
    if (learnedIds.contains(_entry.id)) {
      await repo.unmarkLearned(_entry.id, uid: uid);
    } else {
      await repo.markLearned(_entry.id, _entry.category, uid: uid);
    }
    ref.invalidate(kaiwaLearnedIdsProvider);
    if (mounted) setState(() => _togglingLearned = false);
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
    final lines = _entry.lines;
    final lastIsUnansweredUserTurn =
        _revealedCount > 0 &&
        lines[_revealedCount - 1].isUserTurn &&
        !_answered.containsKey(_revealedCount - 1);
    final dialogueComplete =
        _revealedCount >= lines.length && !lastIsUnansweredUserTurn;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(_entry.title)),
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
              child: SingleChildScrollView(
                key: ValueKey(_entry.id),
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _entry.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textNavy.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (var i = 0; i < _revealedCount; i++)
                      _LineBubble(
                        key: ValueKey(lines[i].id),
                        line: lines[i],
                        answer: _answered[i],
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (lastIsUnansweredUserTurn)
            _AnswerOptions(
              options: lines[_revealedCount - 1].options,
              order: _optionOrder[_revealedCount - 1] ?? const [],
              wrongOptionIndex: _wrongOptionIndex,
              onSelect: (originalIndex, option) =>
                  _selectOption(_revealedCount - 1, originalIndex, option),
            )
          else if (dialogueComplete)
            _CompletionBar(
              learned: isLearned,
              toggling: _togglingLearned,
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

  const _LineBubble({super.key, required this.line, this.answer});

  @override
  Widget build(BuildContext context) {
    if (!line.isUserTurn) return _npcBubble();
    if (answer != null) return _answeredBubble(answer!);
    return _promptBubble();
  }

  Widget _npcBubble() {
    final npc = line.npcLine;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                line.speaker,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textNavy.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 4),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  KaiwaImage(imagePath: line.imagePath),
                  if (npc != null)
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: _SpeakButton(
                        text: npc.japanese,
                        gender: line.gender,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _answeredBubble(KaiwaAnswerOption chosen) {
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
                color: AppColors.primaryCoral.withValues(alpha: 0.15),
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
                      Text(
                        chosen.japanese,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textNavy,
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
                        color: AppColors.textNavy.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    chosen.translation,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textNavy.withValues(alpha: 0.7),
                    ),
                  ),
                  if (chosen.note != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      chosen.note!,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.secondaryBlue,
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

  Widget _promptBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Giliranmu — pilih jawaban di bawah',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: AppColors.textNavy.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeakButton extends ConsumerWidget {
  final String text;
  final KaiwaGender? gender;

  const _SpeakButton({required this.text, this.gender});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => ref.read(ttsServiceProvider).speak(text, gender: gender),
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(
            Icons.volume_up,
            size: 20,
            color: AppColors.secondaryBlue,
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
  final void Function(int originalIndex, KaiwaAnswerOption option) onSelect;

  const _AnswerOptions({
    required this.options,
    required this.order,
    required this.wrongOptionIndex,
    required this.onSelect,
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
        color: AppColors.cardWhite,
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
            'Pilih jawaban yang tepat:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textNavy.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 10),
          for (final originalIndex in order) ...[
            _OptionButton(
              option: options[originalIndex],
              isWrongFlash: wrongOptionIndex == originalIndex,
              onTap: () => onSelect(originalIndex, options[originalIndex]),
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

  const _OptionButton({
    required this.option,
    required this.isWrongFlash,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isWrongFlash
              ? AppColors.errorRed.withValues(alpha: 0.15)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isWrongFlash
                ? AppColors.errorRed
                : AppColors.secondaryBlue.withValues(alpha: 0.3),
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
              child: Text(
                option.japanese,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textNavy,
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
  final VoidCallback onToggleLearned;
  final bool hasNext;
  final bool hasPrev;
  final VoidCallback onNext;
  final VoidCallback onPrev;

  const _CompletionBar({
    required this.learned,
    required this.toggling,
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
        color: AppColors.cardWhite,
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
                learned ? 'Sudah Dipelajari' : 'Tandai Sudah Dipelajari',
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

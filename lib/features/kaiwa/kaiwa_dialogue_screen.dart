import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/kaiwa_expressions.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/kaiwa_accepted_answer.dart';
import '../../data/models/kaiwa_entry.dart';
import '../../data/models/kaiwa_line.dart';
import 'kaiwa_providers.dart';
import 'services/kaiwa_answer_matcher.dart';

/// Interactive practice screen for one Kaiwa dialogue — reveals NPC lines
/// automatically and pauses at each user turn until the learner types or
/// speaks a matching answer, checked offline by [KaiwaAnswerMatcher] (no
/// network/LLM call). Next/prev pages between dialogues in [entries], same
/// convention as `ParticleDetailScreen`; the outer [SingleChildScrollView]
/// is keyed on the dialogue id from the start so paging resets scroll
/// position — a real bug found in `BunpouDetailScreen` (fixed for Partikel
/// afterward), applied here from day one instead of repeating it.
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
  static const _matcher = KaiwaAnswerMatcher();

  late int _index = widget.initialIndex;
  late int _revealedCount;
  final Map<int, KaiwaAcceptedAnswer> _answered = {};
  int _wrongAttempts = 0;
  bool _showHint = false;
  bool _togglingLearned = false;
  bool _listening = false;

  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  KaiwaEntry get _entry => widget.entries[_index];

  @override
  void initState() {
    super.initState();
    _resetForEntry();
  }

  @override
  void dispose() {
    // Stop any in-flight recognition session so it doesn't keep the mic
    // open (and later call back into a disposed widget's closures) after
    // the user has already navigated away.
    if (ref.read(speechToTextServiceProvider).isListening) {
      ref.read(speechToTextServiceProvider).stop();
    }
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _resetForEntry() {
    // Same reasoning as dispose(): without this, listening while paging
    // to the next/prev dialogue left the old session's onResult/onDone
    // closures pointing at a line index that no longer means the same
    // thing, so a late recognition result could land on the wrong turn.
    if (ref.read(speechToTextServiceProvider).isListening) {
      ref.read(speechToTextServiceProvider).stop();
    }
    _listening = false;
    _revealedCount = 0;
    _answered.clear();
    _wrongAttempts = 0;
    _showHint = false;
    _inputController.clear();
    _revealNext();
  }

  void _revealNext() {
    final lines = _entry.lines;
    while (_revealedCount < lines.length) {
      final line = lines[_revealedCount];
      _revealedCount++;
      if (line.isUserTurn) break;
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

  void _submit(String rawInput) {
    if (rawInput.trim().isEmpty) return;
    final lineIndex = _revealedCount - 1;
    final line = _entry.lines[lineIndex];
    final result = _matcher.check(rawInput, line.acceptedAnswers);
    if (result.isCorrect) {
      setState(() {
        _answered[lineIndex] = result.matchedAnswer!;
        _wrongAttempts = 0;
        _showHint = false;
        _inputController.clear();
        _revealNext();
      });
    } else {
      setState(() {
        _wrongAttempts++;
        if (_wrongAttempts >= 2) _showHint = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum tepat, coba lagi.'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _listen() async {
    final status = await Permission.microphone.request();
    if (!mounted) return;
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Izin mikrofon dibutuhkan untuk menjawab dengan suara.'),
        ),
      );
      return;
    }
    setState(() => _listening = true);
    final started = await ref.read(speechToTextServiceProvider).listen(
      onResult: (text) {
        if (!mounted) return;
        setState(() => _inputController.text = text);
      },
      // Fires on a final result, a recognition error (no speech heard,
      // timeout, ...), or an explicit stop — resetting `_listening` here
      // rather than only inside `onResult` is the fix for the mic button
      // getting stuck disabled forever after a failed/silent attempt,
      // since recognition errors never reach `onResult` at all.
      onDone: () {
        if (!mounted) return;
        setState(() => _listening = false);
      },
    );
    if (!started && mounted) {
      setState(() => _listening = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech-to-text tidak tersedia di perangkat ini.'),
        ),
      );
    }
  }

  void _stopListening() {
    ref.read(speechToTextServiceProvider).stop();
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
    final lastIsUnansweredUserTurn = _revealedCount > 0 &&
        lines[_revealedCount - 1].isUserTurn &&
        !_answered.containsKey(_revealedCount - 1);
    final dialogueComplete = _revealedCount >= lines.length &&
        !lastIsUnansweredUserTurn;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(_entry.title)),
      body: Column(
        children: [
          Expanded(
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
                    _LineBubble(line: lines[i], matchedAnswer: _answered[i]),
                  if (lastIsUnansweredUserTurn && _showHint)
                    _HintCard(answer: lines[_revealedCount - 1].acceptedAnswers.first),
                ],
              ),
            ),
          ),
          if (lastIsUnansweredUserTurn)
            _AnswerInput(
              controller: _inputController,
              listening: _listening,
              onMic: _listen,
              onStopListening: _stopListening,
              onSubmit: _submit,
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

class _LineBubble extends StatelessWidget {
  final KaiwaLine line;
  final KaiwaAcceptedAnswer? matchedAnswer;

  const _LineBubble({required this.line, this.matchedAnswer});

  @override
  Widget build(BuildContext context) {
    if (!line.isUserTurn) return _npcBubble();
    if (matchedAnswer != null) return _answeredBubble(matchedAnswer!);
    return _promptBubble();
  }

  Widget _npcBubble() {
    final npc = line.npcLine;
    if (npc == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          npc.japanese,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textNavy,
                          ),
                        ),
                      ),
                      _SpeakButton(text: npc.japanese),
                    ],
                  ),
                  if (npc.romaji != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      npc.romaji!,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textNavy.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    npc.translation,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textNavy.withValues(alpha: 0.7),
                    ),
                  ),
                  if (line.note != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      line.note!,
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
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _answeredBubble(KaiwaAcceptedAnswer answer) {
    final emoji = kaiwaExpressionEmoji[answer.expressionTag];
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
                        answer.japanese,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textNavy,
                        ),
                      ),
                    ],
                  ),
                  if (answer.romaji != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      answer.romaji!,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textNavy.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    answer.translation,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textNavy.withValues(alpha: 0.7),
                    ),
                  ),
                  if (line.note != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      line.note!,
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
              line.promptHint ?? 'Giliranmu menjawab',
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

  const _SpeakButton({required this.text});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.volume_up, size: 18, color: AppColors.secondaryBlue),
      onPressed: () => ref.read(ttsServiceProvider).speak(text),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }
}

class _HintCard extends StatelessWidget {
  final KaiwaAcceptedAnswer answer;

  const _HintCard({required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.tertiaryAmberCardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, size: 16, color: AppColors.tertiaryAmber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Contoh jawaban: ${answer.japanese}'
              '${answer.romaji != null ? ' (${answer.romaji})' : ''} '
              '— ${answer.translation}',
              style: const TextStyle(fontSize: 12, color: AppColors.textNavy),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerInput extends StatelessWidget {
  final TextEditingController controller;
  final bool listening;
  final VoidCallback onMic;
  final VoidCallback onStopListening;
  final ValueChanged<String> onSubmit;

  const _AnswerInput({
    required this.controller,
    required this.listening,
    required this.onMic,
    required this.onStopListening,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
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
            tooltip: listening ? 'Berhenti mendengarkan' : 'Jawab dengan suara',
            icon: Icon(
              listening ? Icons.mic : Icons.mic_none,
              color: listening ? AppColors.primaryCoral : AppColors.secondaryBlue,
            ),
            // Tapping while listening stops the session instead of being
            // disabled — otherwise a stuck/slow recognizer left the
            // learner with no way to cancel and retry.
            onPressed: listening ? onStopListening : onMic,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Ketik jawabanmu di sini...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: onSubmit,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: AppColors.primaryCoral),
            onPressed: () => onSubmit(controller.text),
          ),
        ],
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
              icon: Icon(learned ? Icons.check_circle : Icons.check_circle_outline),
              label: Text(learned ? 'Sudah Dipelajari' : 'Tandai Sudah Dipelajari'),
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

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/battle_rules.dart';
import '../../core/localization/app_strings.dart';
import '../../core/providers.dart';
import '../../core/services/battle_deck_builder.dart';
import '../../core/services/rank_skip_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/kana_keyboard.dart';
import '../../data/models/card_game_rank.dart';
import 'widgets/battle_arena.dart';
import '../../core/widgets/romaji_keyboard.dart';

/// Skipping straight to a rank by proving you can already play it.
///
/// The mode deals cards by tier — hiragana at Bronze, katakana at
/// Silver, kanji from Gold up — so a learner who already reads kanji
/// had to grind through kana they knew before the mode had anything to
/// teach them. This is the way past that, and the request behind it was
/// exactly that: *"agar user tidak bosan di hiragana dan katakana"*.
///
/// **Nothing here decides anything.** The cards are drawn by the server
/// and the answers are marked there; this screen shows what it was sent
/// and posts back what was typed. See `RankSkipService` for why that
/// split is not optional.
class RankSkipScreen extends ConsumerStatefulWidget {
  const RankSkipScreen({super.key});

  @override
  ConsumerState<RankSkipScreen> createState() => _RankSkipScreenState();
}

enum _Phase { choosing, working, answering, done }

class _RankSkipScreenState extends ConsumerState<RankSkipScreen> {
  _Phase _phase = _Phase.choosing;
  RankSkipExam? _exam;
  RankSkipResult? _result;
  String? _error;
  DateTime? _cooldownUntil;

  /// One slot per drawn card, so an unanswered question keeps its place
  /// in the list — position is what pairs an answer with its card.
  late List<String> _answers;
  int _at = 0;

  /// The same thirty seconds a card gets in a real match
  /// (`kBattleMainPhaseSeconds`). An untimed exam is an easier test than
  /// the tier it admits you to: with no clock there is nothing stopping
  /// a player looking every reading up, and the rank it grants is worth
  /// roughly thirty won matches.
  ///
  /// Client-side, and honestly so — a modified app can ignore it, the
  /// same way it can already read its own bundled answers. The server's
  /// own limit is the whole exam's, in `rank_skip.js`, which is the part
  /// that cannot be edited away.
  Timer? _tick;
  DateTime? _cardDeadline;

  int get _secondsLeft {
    final deadline = _cardDeadline;
    if (deadline == null) return kBattleMainPhaseSeconds;
    final left = deadline.difference(DateTime.now());
    return left.isNegative ? 0 : (left.inMilliseconds / 1000).ceil();
  }

  void _startCardClock() {
    _cardDeadline = DateTime.now().add(
      const Duration(seconds: kBattleMainPhaseSeconds),
    );
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _phase != _Phase.answering) return;
      if (_secondsLeft > 0) {
        setState(() {});
        return;
      }
      // Out of time on this card. Whatever was typed stands and the exam
      // moves on, rather than stopping — a card nobody could read is a
      // card to lose, not a wall.
      _advance();
    });
  }

  void _advance() {
    final exam = _exam;
    if (exam == null) return;
    if (_at >= exam.questions - 1) {
      _tick?.cancel();
      _submit();
      return;
    }
    setState(() => _at++);
    _startCardClock();
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _start(CardGameTier tier) async {
    setState(() {
      _phase = _Phase.working;
      _error = null;
      _cooldownUntil = null;
    });
    try {
      final exam = await ref.read(rankSkipServiceProvider).start(tier);
      if (!mounted) return;
      setState(() {
        _exam = exam;
        _answers = List.filled(exam.questions, '');
        _at = 0;
        _phase = _Phase.answering;
      });
      _startCardClock();
    } on RankSkipCooldown catch (e) {
      if (!mounted) return;
      setState(() {
        _cooldownUntil = e.lockedUntil;
        _phase = _Phase.choosing;
      });
    } on RankSkipUnavailable catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _explain(e);
        _phase = _Phase.choosing;
      });
    }
  }

  Future<void> _submit() async {
    final exam = _exam;
    if (exam == null) return;
    _tick?.cancel();
    setState(() => _phase = _Phase.working);
    try {
      final result = await ref
          .read(rankSkipServiceProvider)
          .submit(sessionId: exam.sessionId, answers: _answers);
      if (!mounted) return;
      // The rank the rest of the app shows comes from Firestore, and the
      // server has just written it. Nothing here writes a rank, so the
      // only thing to do is ask again.
      ref.invalidate(cardGameRankProvider);
      setState(() {
        _result = result;
        _phase = _Phase.done;
      });
    } on RankSkipUnavailable catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _explain(e);
        _phase = _Phase.answering;
      });
    }
  }

  /// The line a learner reads, with the cause appended in debug builds.
  ///
  /// Not in release: a child does not need `not-found`, and it would be
  /// the only untranslated text in the app. In debug it is the
  /// difference between diagnosing this in a minute and rebuilding twice
  /// to find out.
  String _explain(RankSkipUnavailable e) {
    final friendly = ref.read(appStringsProvider).rankSkipUnavailable;
    if (!kDebugMode) return friendly;
    return '$friendly\n\n[${e.code}] ${e.message ?? ""}';
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.rankSkipEntry)),
      body: BattleBackdrop(
        child: SafeArea(
          child: switch (_phase) {
            _Phase.working => const Center(child: CircularProgressIndicator()),
            _Phase.choosing => _TierChoice(
              error: _error,
              cooldownUntil: _cooldownUntil,
              onPick: _start,
            ),
            _Phase.answering => _Answering(
              exam: _exam!,
              at: _at,
              answer: _answers[_at],
              secondsLeft: _secondsLeft,
              error: _error,
              onChanged: (v) => setState(() => _answers[_at] = v),
              onNext: _advance,
              onSubmit: _submit,
            ),
            _Phase.done => _Done(result: _result!),
          },
        ),
      ),
    );
  }
}

/// Which rank to aim at — only the ones actually above the player's own.
class _TierChoice extends ConsumerWidget {
  const _TierChoice({
    required this.error,
    required this.cooldownUntil,
    required this.onPick,
  });

  final String? error;
  final DateTime? cooldownUntil;
  final void Function(CardGameTier) onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final palette = context.palette;
    final rank = ref.watch(cardGameRankProvider).valueOrNull;
    if (rank == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final above = _tiersAbove(rank.tier);
    if (above.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            s.rankSkipAtTop,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: palette.textNavy),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          s.rankSkipPickTier,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: palette.textNavy,
          ),
        ),
        const SizedBox(height: 6),
        if (cooldownUntil != null || error != null)
          _Notice(
            palette: palette,
            text:
                error ??
                (cooldownUntil == null
                    ? s.rankSkipRetryTomorrow
                    : s.rankSkipRetryAfter(_when(s, cooldownUntil!))),
          ),
        const SizedBox(height: 10),
        for (final tier in above)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _TierCard(
              tier: tier,
              // The counts come back from the server with the exam, so
              // before one is drawn this states the rule rather than
              // this particular exam's numbers.
              subtitle: s.rankSkipRules(tier.displayName, 20, 18),
              onTap: cooldownUntil == null ? () => onPick(tier) : null,
            ),
          ),
      ],
    );
  }

  static List<CardGameTier> _tiersAbove(CardGameTier current) {
    final all = CardGameTier.values;
    return all.sublist(all.indexOf(current) + 1);
  }

  /// The wait is a whole day, so the day has to be said.
  ///
  /// This showed a bare "01:48" first, and on a device that reads as a
  /// few minutes away rather than as tomorrow — the one number a player
  /// needs from this screen, saying the opposite of what it means.
  static String _when(AppStrings s, DateTime at) {
    final t = at.toLocal();
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    final now = DateTime.now();
    final sameDay =
        t.year == now.year && t.month == now.month && t.day == now.day;
    return sameDay
        ? s.rankSkipTodayAt('$hh.$mm')
        : s.rankSkipTomorrowAt('$hh.$mm');
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.tier,
    required this.subtitle,
    required this.onTap,
  });

  final CardGameTier tier;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: Material(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tier.displayName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: palette.textNavy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: palette.textNavy.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One card at a time, answered the way that tier's battles are.
class _Answering extends ConsumerWidget {
  const _Answering({
    required this.exam,
    required this.at,
    required this.answer,
    required this.secondsLeft,
    required this.error,
    required this.onChanged,
    required this.onNext,
    required this.onSubmit,
  });

  final RankSkipExam exam;
  final int at;
  final String answer;
  final int secondsLeft;
  final String? error;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final palette = context.palette;
    final data = ref.watch(battleCardDataProvider).valueOrNull;
    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final card = resolveCard(exam.cardIds[at], data.$1, data.$2);
    final last = at == exam.questions - 1;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.rankSkipProgress(at + 1, exam.questions),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: palette.textNavy,
                ),
              ),
              _ExamClock(secondsLeft: secondsLeft, palette: palette),
              Text(
                exam.targetTier.displayName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: palette.primaryCoral,
                ),
              ),
            ],
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: _Notice(palette: palette, text: error!),
          ),
        Expanded(
          child: Center(
            child: card == null
                ? const SizedBox.shrink()
                : SizedBox(
                    width: 200,
                    height: 260,
                    child: BattleCardFace(
                      prompt: card.prompt,
                      caption: '',
                      flashColor: null,
                    ),
                  ),
          ),
        ),
        if (card != null) ...[
          // What has been typed, which neither keyboard shows anywhere
          // itself. Without it a learner is typing blind: no way to see a
          // wrong character, and no way to know a tap registered at all.
          _TypedAnswer(
            palette: palette,
            label: s.rankSkipYourAnswer,
            text: answer,
            empty: s.rankSkipAnswerEmpty,
          ),
          // Both answer types are typed on a keyboard this app draws.
          // The romaji half used to open the phone's own, which brought
          // a prediction bar onto a timed question and covered a
          // different amount of the card on every phone.
          SizedBox(
            height: card.answerInHiragana ? 240 : 190,
            child: card.answerInHiragana
                ? KanaKeyboard(value: answer, onChanged: onChanged)
                : RomajiKeyboard(value: answer, onChanged: onChanged),
          ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: palette.primaryCoral,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              // Never disabled on an empty answer. A card nobody can read
              // is a card to move past, and a button that refuses to
              // advance would strand the exam on it.
              onPressed: last ? onSubmit : onNext,
              child: Text(
                last ? s.rankSkipSubmit : s.rankSkipNext,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The seconds left on this card.
class _ExamClock extends StatelessWidget {
  const _ExamClock({required this.secondsLeft, required this.palette});

  final int secondsLeft;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final urgent = secondsLeft <= 5;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: urgent ? palette.errorRed : Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
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
          const Icon(Icons.timer_outlined, size: 18, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            '${secondsLeft}s',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// What the kana keyboard has produced so far.
class _TypedAnswer extends StatelessWidget {
  const _TypedAnswer({
    required this.palette,
    required this.label,
    required this.text,
    required this.empty,
  });

  final AppPalette palette;
  final String label;
  final String text;
  final String empty;

  @override
  Widget build(BuildContext context) {
    final blank = text.isEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: palette.primaryCoral.withValues(alpha: blank ? 0.3 : 0.8),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              blank ? empty : text,
              style: TextStyle(
                fontSize: blank ? 16 : 26,
                fontWeight: blank ? FontWeight.normal : FontWeight.bold,
                color: Colors.white.withValues(alpha: blank ? 0.45 : 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Done extends ConsumerWidget {
  const _Done({required this.result});

  final RankSkipResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final palette = context.palette;
    final lines = <String>[
      s.rankSkipScore(result.correct, result.total),
      if (result.passed && result.promoted)
        s.rankSkipPromoted(result.targetTier.displayName)
      else if (result.passed)
        s.rankSkipAlreadyThere
      else
        s.rankSkipRetryTomorrow,
    ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              result.passed ? s.rankSkipPassed : s.rankSkipFailed,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: result.passed ? palette.successGreen : palette.textNavy,
              ),
            ),
            const SizedBox(height: 14),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  line,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: palette.textNavy),
                ),
              ),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: palette.primaryCoral,
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.palette, required this.text});

  final AppPalette palette;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.errorRed.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.errorRed.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, color: palette.textNavy),
      ),
    );
  }
}

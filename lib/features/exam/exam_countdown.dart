import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';

/// The clock on one question of a timed exam.
///
/// **Owns its own ticker rather than taking a stream of seconds.** Every
/// exam screen would otherwise need the same timer, the same dispose and
/// the same "did it already fire" guard, and one of them would get it
/// wrong. Here [onExpired] fires exactly once per question, however many
/// rebuilds happen around it.
///
/// **Reset by key, not by argument.** The caller gives this widget a key
/// carrying the question index, so moving to the next question builds a
/// fresh state with a fresh budget. Trying to notice "the question
/// changed" from inside would mean comparing something this widget has no
/// business knowing about.
class ExamCountdown extends ConsumerStatefulWidget {
  const ExamCountdown({
    super.key,
    required this.limit,
    required this.onExpired,
    this.paused = false,
  });

  /// How long this one question gets.
  final Duration limit;

  /// Called once, when this question's time runs out.
  final VoidCallback onExpired;

  /// Stops the clock without ending the question.
  ///
  /// Set once the answer has been graded: the learner is then reading why
  /// they were right or wrong, and a clock still draining during an
  /// explanation would rush the one part of an exam that teaches
  /// anything.
  final bool paused;

  @override
  ConsumerState<ExamCountdown> createState() => _ExamCountdownState();
}

class _ExamCountdownState extends ConsumerState<ExamCountdown> {
  Timer? _ticker;
  late Duration _left;

  /// Guards [ExamCountdown.onExpired] against a second call. The tick that
  /// hits zero and a rebuild racing it would otherwise both fire it.
  bool _fired = false;

  /// Below this the clock turns red, so the last stretch is visibly the
  /// last stretch.
  static const _urgentFraction = 0.25;

  @override
  void initState() {
    super.initState();
    _left = widget.limit;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _tick() {
    if (!mounted || widget.paused) return;
    final next = _left - const Duration(seconds: 1);
    setState(() => _left = next.isNegative ? Duration.zero : next);
    if (_left > Duration.zero || _fired) return;
    _fired = true;
    _ticker?.cancel();
    widget.onExpired();
  }

  String get _clock {
    final minutes = _left.inMinutes;
    final seconds = _left.inSeconds % 60;
    if (minutes == 0) return '${seconds}s';
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final s = ref.watch(appStringsProvider);
    final fraction = widget.limit.inMilliseconds == 0
        ? 0.0
        : _left.inMilliseconds / widget.limit.inMilliseconds;
    final urgent = fraction <= _urgentFraction && !widget.paused;
    final colour = widget.paused
        ? palette.textNavy.withValues(alpha: 0.35)
        : (urgent ? palette.errorRed : palette.primaryCoral);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Row(
        children: [
          Icon(
            widget.paused ? Icons.pause_circle_outline : Icons.timer_outlined,
            size: 18,
            color: colour,
          ),
          const SizedBox(width: 6),
          Text(
            s.examTimeLeft,
            style: TextStyle(
              fontSize: 12,
              color: palette.textNavy.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: fraction.clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: colour.withValues(alpha: 0.15),
                color: colour,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _clock,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: colour,
              // Fixed-width digits: without this the row jiggles every
              // time a 1 replaces a 0.
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';

/// The clock on a timed exam: one budget for the whole paper, shown as a
/// bar that drains.
///
/// **Owns its own ticker rather than taking a stream of seconds.** Every
/// exam screen would otherwise need the same timer, the same dispose, and
/// the same "did it already fire" guard, and one of them would get it
/// wrong. Here [onExpired] is called exactly once, no matter how many
/// rebuilds happen or how the parent moves between questions.
///
/// Deliberately not persisted across a screen leaving: an exam abandoned
/// halfway is over, and resuming a clock that has been running while the
/// app was closed would hand the learner a paper with no time left on it.
class ExamCountdown extends ConsumerStatefulWidget {
  const ExamCountdown({
    super.key,
    required this.limit,
    required this.onExpired,
  });

  final Duration limit;

  /// Called once, when the budget runs out. The exam is expected to end
  /// and score whatever has been answered so far.
  final VoidCallback onExpired;

  @override
  ConsumerState<ExamCountdown> createState() => _ExamCountdownState();
}

class _ExamCountdownState extends ConsumerState<ExamCountdown> {
  Timer? _ticker;
  late Duration _left;

  /// Guards [ExamCountdown.onExpired] against a second call. The tick that
  /// hits zero and a rebuild racing it would otherwise both fire it, and
  /// the exam would try to finish twice.
  bool _fired = false;

  /// Below this the clock turns red and starts counting in whole seconds
  /// out loud, so the last stretch is visibly the last stretch.
  static const _urgent = Duration(seconds: 30);

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
    if (!mounted) return;
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
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final s = ref.watch(appStringsProvider);
    final urgent = _left <= _urgent;
    final colour = urgent ? palette.errorRed : palette.primaryCoral;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, size: 18, color: colour),
          const SizedBox(width: 6),
          Text(
            s.examTimeLeft,
            style: TextStyle(
              fontSize: 12,
              color: palette.textNavy.withValues(alpha: 0.6),
            ),
          ),
          const Spacer(),
          Text(
            _clock,
            style: TextStyle(
              fontSize: 16,
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

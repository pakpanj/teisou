import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// C1 (LAPORAN_FIX_FEEDBACKHOLDTIMER_DAN_AUDIT_FORENSIK_RIVERPOD.md) —
/// stress-test proof that the manual-subscription pattern
/// `_BattleScreenState` now uses for its match state (see `_matchSub`'s own
/// doc comment in `battle_screen.dart`) does not accumulate listeners
/// across repeated "masuk -> keluar -> masuk lagi -> keluar" cycles on the
/// same live entity, which is exactly the scenario that was proven to leak
/// when this screen still used `ref.watch(battleMatchProvider(...))`
/// directly in `build()`.
///
/// **Why this drives a mirror widget, not `BattleScreen` itself**:
/// `BattleScreen` needs a live Firestore/Riverpod match to pump as a
/// widget, and no such harness exists anywhere in this project's test
/// suite (see `battle_answer_feedback_c4_test.dart`'s own doc comment for
/// the same limitation on the same file) — building one would mean either
/// a live Firebase project or a new mocking dependency this codebase does
/// not currently pull in. `battle_reliability_wiring_test.dart`'s own new
/// "C1 Riverpod listener leak fix" group proves the *real* `battle_screen.dart`
/// is actually shaped this way (subscribes in `initState`, cancels in
/// `dispose`, guards every callback with `_isClosing || !mounted`, never
/// calls `ref.watch`/`ref.read` on `battleMatchProvider` any more) — this
/// file proves that *shape*, exercised through genuine Flutter `Navigator`
/// push/pop and real `Timer`/`Stream` timing (not a hand-rolled logic
/// mirror), actually holds up under repeated resume cycles.
///
/// **The stream never stops emitting, including across every pop/push
/// transition** — this is deliberate and is the whole point: the original
/// bug only ever manifested because the underlying `battleMatches/{id}`
/// document keeps changing after a player leaves (a bot playing on, the
/// opponent still answering, the server's own abandonment sweep) — a
/// screen that stopped watching a truly-frozen document would never have
/// surfaced this at all. A `Timer.periodic` firing throughout the whole
/// test, uncorrelated with the push/pop cycle, reproduces that "the entity
/// keeps moving whether or not anyone is watching" condition faithfully.
///
/// **The subscription count is tracked at the stream level, not by
/// trusting the widget's own dispose bookkeeping** — [_countedSubscribe]
/// wraps every `.listen()` call in a delegate whose [StreamSubscription]
/// only decrements [_StressTracker.activeSubscriptions] when `.cancel()`
/// is genuinely invoked on it. A widget that "disposes" without actually
/// calling `.cancel()` (exactly the shape of a leaked listener) would
/// still update its own `alive`/`totalDisposed` counters correctly — that
/// symmetry is precisely why counting *those* alone would prove nothing.
void main() {
  testWidgets(
    'repeated resume cycles on the same live stream never leave more than '
    'one subscriber alive at once, and no post-teardown callback ever '
    'fires',
    (tester) async {
      final tracker = _StressTracker();
      final controller = StreamController<int>.broadcast();
      var value = 0;

      final ticker = Timer.periodic(const Duration(milliseconds: 5), (_) {
        if (!controller.isClosed) controller.add(value++);
      });

      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: SizedBox()),
        ),
      );

      const cycles = 10;
      for (var i = 0; i < cycles; i++) {
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (_) => _MatchWatcherHarness(
              subscribe: (onData) =>
                  _countedSubscribe(controller.stream, onData, tracker),
              tracker: tracker,
            ),
          ),
        );
        await tester.pumpAndSettle();
        // Let several stream events land while genuinely mounted — the
        // ordinary "watching an active match" case.
        await tester.pump(const Duration(milliseconds: 17));
        expect(
          tracker.alive,
          1,
          reason: 'cycle $i: exactly one instance should be alive while its '
              'screen is on top',
        );
        expect(
          tracker.activeSubscriptions,
          1,
          reason: 'cycle $i: exactly one real stream subscription should be '
              'attached while mounted',
        );

        navigatorKey.currentState!.pop();
        await tester.pumpAndSettle();
        // Keep the stream running well past the pop — this is the exact
        // window the original bug needed: the underlying entity (there,
        // battleMatches/{id}; here, this stream) keeps emitting long after
        // the screen that opened it is gone.
        await tester.pump(const Duration(milliseconds: 17));

        expect(
          tracker.alive,
          0,
          reason: 'cycle $i: must be fully torn down after the pop, before '
              'the next resume',
        );
        expect(
          tracker.activeSubscriptions,
          0,
          reason: 'cycle $i: the real stream subscription must be cancelled '
              'too, not just the widget-level bookkeeping — a leaked '
              'listener here is exactly what battleMatchProvider did, and '
              'a widget that "disposes" without actually calling cancel() '
              'would still pass a check against `alive` alone',
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'cycle $i: a stale listener firing after teardown would '
              'throw here (setState on a disposed widget) — this is the '
              'exact failure mode `_isClosing` and the manual unsubscribe '
              'close',
        );
      }

      expect(tracker.totalMounted, cycles);
      expect(tracker.totalDisposed, cycles);
      expect(
        tracker.peakAlive,
        1,
        reason: 'no two instances watching the same entity should ever be '
            'alive at once across repeated resume cycles',
      );
      expect(
        tracker.peakActiveSubscriptions,
        1,
        reason: 'no two real stream subscriptions should ever be attached '
            'at once across repeated resume cycles — this is the '
            'stress-test proof that the manual-subscription pattern '
            'battle_screen.dart now uses cannot pile up listeners the way '
            'ref.watch(battleMatchProvider(...)) was proven to on-device',
      );

      // Cancelled explicitly at the end of the test body, not via
      // addTearDown — a Timer.periodic still pending when the test's own
      // pending-timer invariant check runs (which happens before
      // addTearDown callbacks fire) trips "A Timer is still pending even
      // after the widget tree was disposed" regardless of whether it was
      // ever going to matter to the assertions above.
      ticker.cancel();
      await controller.close();
    },
  );

  testWidgets(
    'leaving mid-transition (pop fired before the widget has even settled '
    'once) still tears down cleanly',
    (tester) async {
      // The original bug's worst instances came from exactly this kind of
      // rapid resume/leave — see LAPORAN_PERBAIKAN_BATTLESCREEN_LIFECYCLE_GATE.md's
      // stress-test section ("5 siklus resume->keluar berturut-turut dalam
      // ~14 detik"). This test compresses that into back-to-back cycles
      // with no settling time at all between push and pop.
      final tracker = _StressTracker();
      final controller = StreamController<int>.broadcast();
      var value = 0;
      final ticker = Timer.periodic(const Duration(milliseconds: 3), (_) {
        if (!controller.isClosed) controller.add(value++);
      });

      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: SizedBox()),
        ),
      );

      const cycles = 15;
      for (var i = 0; i < cycles; i++) {
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (_) => _MatchWatcherHarness(
              subscribe: (onData) =>
                  _countedSubscribe(controller.stream, onData, tracker),
              tracker: tracker,
            ),
          ),
        );
        // Deliberately no settle time here — pop lands mid-transition.
        await tester.pump();
        navigatorKey.currentState!.pop();
        await tester.pumpAndSettle();
      }
      // Let the stream keep firing well after the last pop.
      await tester.pump(const Duration(milliseconds: 30));

      expect(tester.takeException(), isNull);
      expect(tracker.alive, 0);
      expect(tracker.activeSubscriptions, 0);
      expect(tracker.peakAlive, 1);
      expect(tracker.peakActiveSubscriptions, 1);

      ticker.cancel();
      await controller.close();
    },
  );
}

/// Counts how many [_MatchWatcherHarnessState]s are currently mounted and
/// how many real stream subscriptions are currently attached — kept as two
/// separate counters on purpose (see this file's own top-of-file doc
/// comment for why `alive` alone would prove nothing).
class _StressTracker {
  int alive = 0;
  int peakAlive = 0;
  int totalMounted = 0;
  int totalDisposed = 0;
  int activeSubscriptions = 0;
  int peakActiveSubscriptions = 0;
}

/// Wraps `stream.listen(onData)` so [tracker.activeSubscriptions] only ever
/// reflects real, still-attached subscriptions — incremented here, and
/// decremented only when [_CountedSubscription.cancel] is actually called,
/// never just because a widget's own `dispose()` ran.
StreamSubscription<int> _countedSubscribe(
  Stream<int> stream,
  void Function(int) onData,
  _StressTracker tracker,
) {
  tracker.activeSubscriptions++;
  if (tracker.activeSubscriptions > tracker.peakActiveSubscriptions) {
    tracker.peakActiveSubscriptions = tracker.activeSubscriptions;
  }
  final inner = stream.listen(onData);
  return _CountedSubscription(inner, tracker);
}

/// Delegates everything to [_inner] — the only thing this adds is
/// decrementing [_StressTracker.activeSubscriptions] exactly once, the
/// first time [cancel] is actually called.
class _CountedSubscription implements StreamSubscription<int> {
  _CountedSubscription(this._inner, this._tracker);

  final StreamSubscription<int> _inner;
  final _StressTracker _tracker;
  bool _cancelledOnce = false;

  @override
  Future<void> cancel() {
    if (!_cancelledOnce) {
      _cancelledOnce = true;
      _tracker.activeSubscriptions--;
    }
    return _inner.cancel();
  }

  @override
  void onData(void Function(int data)? handleData) => _inner.onData(handleData);

  @override
  void onError(Function? handleError) => _inner.onError(handleError);

  @override
  void onDone(void Function()? handleDone) => _inner.onDone(handleDone);

  @override
  void pause([Future<void>? resumeSignal]) => _inner.pause(resumeSignal);

  @override
  void resume() => _inner.resume();

  @override
  bool get isPaused => _inner.isPaused;

  @override
  Future<E> asFuture<E>([E? futureValue]) => _inner.asFuture(futureValue);
}

/// A minimal, faithful mirror of `_BattleScreenState`'s manual-subscription
/// lifecycle: subscribe in [initState], flip a plain bool in [deactivate]
/// (which the Flutter SDK runs before the element is marked defunct —
/// see `_isClosing`'s own doc comment in `battle_screen.dart`), guard every
/// callback with that bool plus `mounted`, and cancel the subscription in
/// [dispose]. Not `BattleScreen` itself — see this file's own top-of-file
/// doc comment for why a mirror is what this project's test suite can
/// actually drive here.
class _MatchWatcherHarness extends StatefulWidget {
  const _MatchWatcherHarness({required this.subscribe, required this.tracker});

  /// Provided by the test rather than a bare `Stream<int>` field, so the
  /// test can wrap the real `.listen()` call and count actual
  /// subscriptions — see [_countedSubscribe].
  final StreamSubscription<int> Function(void Function(int) onData) subscribe;
  final _StressTracker tracker;

  @override
  State<_MatchWatcherHarness> createState() => _MatchWatcherHarnessState();
}

class _MatchWatcherHarnessState extends State<_MatchWatcherHarness> {
  bool _isClosing = false;
  StreamSubscription<int>? _sub;
  int? _value;

  @override
  void initState() {
    super.initState();
    widget.tracker.alive++;
    widget.tracker.totalMounted++;
    if (widget.tracker.alive > widget.tracker.peakAlive) {
      widget.tracker.peakAlive = widget.tracker.alive;
    }
    _sub = widget.subscribe(_onData);
  }

  void _onData(int value) {
    if (_isClosing || !mounted) return;
    setState(() => _value = value);
  }

  @override
  void deactivate() {
    _isClosing = true;
    super.deactivate();
  }

  @override
  void dispose() {
    _isClosing = true;
    _sub?.cancel();
    widget.tracker.alive--;
    widget.tracker.totalDisposed++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('value=$_value')));
  }
}

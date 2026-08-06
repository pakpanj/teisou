import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/theme/app_theme.dart';
import 'package:kana_master/core/widgets/app_loading.dart';
import 'package:kana_master/core/widgets/app_startup_splash.dart';
import 'package:kana_master/core/widgets/mascot_widget.dart';

/// The loading state that replaced 26 identical spinners.
///
/// The drawing is the easy half and a screenshot would settle it. The
/// timing is the half that decides whether the app feels calm or twitchy,
/// and it is invisible in any screenshot: nearly everything here loads
/// from the asset bundle in a few tens of milliseconds, so a loader that
/// appeared instantly would mostly appear *and vanish* inside one blink.
void main() {
  Widget wrap(Widget child) => ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: child),
        ),
      );

  /// How visible the skeleton is *right now*.
  ///
  /// Read off the FadeTransition that AnimatedOpacity builds, not off
  /// AnimatedOpacity itself — its `opacity` field is the target it is
  /// heading for, so it reads 1 the instant the fade begins and would
  /// have made the mid-fade check below pass on a widget that snapped.
  double opacity(WidgetTester tester) => tester
      .widget<FadeTransition>(
        find
            .descendant(
              of: find.byType(AppLoading),
              matching: find.byType(FadeTransition),
            )
            .first,
      )
      .opacity
      .value;

  group('the skeleton', () {
    testWidgets('shows nothing at all for a fast load', (tester) async {
      // The case this exists for. A spinner here flickers; this must not.
      //
      // Two pumps, and the second one is the whole test. A single pump
      // advances the clock and then builds one frame, so a fade that has
      // only just been triggered has not ticked yet and still reads 0 —
      // which made the first version of this pass even with the delay
      // removed entirely. It took injecting that defect to notice. The
      // second pump gives a wrongly-triggered fade somewhere to go.
      await tester.pumpWidget(wrap(const AppLoading()));
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump(const Duration(milliseconds: 60));

      expect(opacity(tester), 0);
    });

    testWidgets('appears once the wait is long enough to notice',
        (tester) async {
      await tester.pumpWidget(wrap(const AppLoading()));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 300));

      expect(opacity(tester), 1);
    });

    testWidgets('eases in rather than snapping', (tester) async {
      // A skeleton that appears instantly is its own small jolt.
      await tester.pumpWidget(wrap(const AppLoading()));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 60));

      final mid = opacity(tester);
      expect(mid, greaterThan(0));
      expect(mid, lessThan(1));
    });

    testWidgets('draws rows shaped like the real list', (tester) async {
      // The point of a skeleton over a spinner: it says what is coming.
      //
      // Counts the badge and the two text bars, not the sheen. The first
      // version counted the shimmer widget, which stayed happily at four
      // while the badge and bars were being painted over into a plain
      // grey slab — the one thing a skeleton must not do. Only looking
      // at a device caught it.
      await tester.pumpWidget(wrap(const AppLoading(rows: 4)));
      await tester.pump(const Duration(milliseconds: 250));

      // Three blocks per row: one round badge, two lines of "text".
      expect(
        find.descendant(
          of: find.byType(AppLoading),
          matching: find.byType(FractionallySizedBox),
        ),
        findsNWidgets(8),
      );
    });

    testWidgets('does not let the learner scroll a list of nothing',
        (tester) async {
      await tester.pumpWidget(wrap(const AppLoading()));
      await tester.pump(const Duration(milliseconds: 250));

      final list = tester.widget<ListView>(
        find.descendant(
          of: find.byType(AppLoading),
          matching: find.byType(ListView),
        ),
      );
      expect(list.physics, isA<NeverScrollableScrollPhysics>());
    });

    testWidgets('a load that finishes early disposes cleanly', (tester) async {
      // The delay is a pending timer. Tearing the widget down before it
      // fires must not call setState on a dead State.
      await tester.pumpWidget(wrap(const AppLoading()));
      await tester.pump(const Duration(milliseconds: 40));
      await tester.pumpWidget(wrap(const SizedBox()));
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
    });
  });

  group('the startup splash', () {
    testWidgets('shows the mascot rather than a blank screen', (tester) async {
      // It used to be a bare white rectangle — which, right after the
      // system splash, reads as the app having failed to start.
      await tester.pumpWidget(wrap(const AppStartupSplash()));
      await tester.pump();

      expect(find.byType(MascotWidget), findsOneWidget);
    });

    testWidgets('the dots keep moving', (tester) async {
      // A still row of dots is indistinguishable from a frozen app, which
      // is the exact impression this screen exists to avoid.
      await tester.pumpWidget(wrap(const AppStartupSplash()));
      await tester.pump();

      Offset dotOffset() => tester
          .widgetList<Transform>(find.byType(Transform))
          .map((t) => Offset(t.transform.storage[12], t.transform.storage[13]))
          .reduce((a, b) => a + b);

      final seen = <Offset>{};
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 40));
        seen.add(dotOffset());
      }
      expect(seen.length, greaterThan(3));
    });
  });
}

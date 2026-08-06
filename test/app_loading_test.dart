import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/theme/app_theme.dart';
import 'package:kana_master/core/widgets/app_loading.dart';
import 'package:kana_master/core/widgets/mascot_loading_screen.dart';
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

  group('the full-screen loading page', () {
    testWidgets('brings its own Material, so text is not debug-styled',
        (tester) async {
      // It is returned straight into `home:` with nothing above it. A Text
      // with no Material ancestor gets Flutter's debug fallback — yellow
      // underlines under every word — and that is exactly how it looked on
      // a device before anyone checked.
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: const MascotLoadingScreen(label: 'x'),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the mascot, a bar and a percentage', (tester) async {
      await tester.pumpWidget(wrap(const MascotLoadingScreen()));
      await tester.pump();

      expect(find.byType(MascotWidget), findsOneWidget);
      expect(find.textContaining('%'), findsOneWidget);
      expect(find.byType(FractionallySizedBox), findsOneWidget);
    });

    testWidgets('never climbs past its cap, however long the wait',
        (tester) async {
      // The one thing this must not do. There is no way to measure a
      // `rootBundle.loadString`, so the number is an estimate of elapsed
      // time — and a bar sitting at 100% while the app is still working is
      // the most annoying thing a progress bar does.
      //
      // Checks the cap, not just the literal "100%". An earlier version
      // only looked for that string, which meant the guard passed with the
      // supposed ceiling raised all the way to 1.0 — the curve happened to
      // stop at 93% anyway and nothing noticed. A bound catches a rate
      // that has been turned up until the cap rounds to 100.
      await tester.pumpWidget(wrap(const MascotLoadingScreen()));

      double percent() => double.parse(
            tester
                .widgetList<Text>(find.textContaining('%'))
                .first
                .data!
                .replaceAll('%', ''),
          );

      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        expect(percent(), lessThanOrEqualTo(95));
      }
    });

    testWidgets('climbs fast at first and then slows', (tester) async {
      // The shape of a wait whose end nobody can see. A linear bar
      // promises an arrival time it cannot know.
      await tester.pumpWidget(wrap(const MascotLoadingScreen()));

      double percent() {
        final text = tester
            .widgetList<Text>(find.textContaining('%'))
            .first
            .data!;
        return double.parse(text.replaceAll('%', ''));
      }

      await tester.pump(const Duration(seconds: 1));
      final early = percent();
      await tester.pump(const Duration(seconds: 1));
      final middle = percent();
      await tester.pump(const Duration(seconds: 1));
      final late = percent();

      expect(early, greaterThan(0));
      expect(middle - early, greaterThan(late - middle),
          reason: 'the second second should add more than the third');
    });

    testWidgets('the mascot changes pose as it works', (tester) async {
      // A single frozen pose is indistinguishable from a hung app, which
      // is the impression this screen exists to prevent.
      await tester.pumpWidget(wrap(const MascotLoadingScreen()));

      final poses = <MascotMood>{};
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        poses.add(
          tester.widget<MascotWidget>(find.byType(MascotWidget)).mood,
        );
      }
      expect(poses.length, greaterThan(2));
    });

    testWidgets('the poses are ones that look like work', (tester) async {
      // Never a celebration. A mascot cheering while you wait is
      // celebrating nothing.
      await tester.pumpWidget(wrap(const MascotLoadingScreen()));

      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        final mood = tester.widget<MascotWidget>(find.byType(MascotWidget)).mood;
        expect(
          mood,
          isNot(anyOf(
            MascotMood.cheering,
            MascotMood.proud,
            MascotMood.surprised,
            MascotMood.sad,
          )),
        );
      }
    });

    testWidgets('the bar keeps its full width whatever the fill', (tester) async {
      // The track must stay visible and the layout must not move. Without
      // an explicit width the Stack collapsed onto the filled portion, so
      // the bar had no track and the whole column drifted off-centre —
      // which looked plainly wrong on a device and perfectly fine in the
      // code.
      await tester.pumpWidget(wrap(const MascotLoadingScreen()));

      await tester.pump(const Duration(milliseconds: 300));
      final early = tester.getSize(find.byType(FractionallySizedBox)).width;
      await tester.pump(const Duration(seconds: 4));
      final later = tester.getSize(find.byType(FractionallySizedBox)).width;

      // The filled part grows...
      expect(later, greaterThan(early));

      // ...but the mascot stays put, which it cannot do if the column is
      // being resized by the bar underneath it.
      final mascot = tester.getCenter(find.byType(MascotWidget));
      final screen = tester.getSize(find.byType(MascotLoadingScreen));
      expect(mascot.dx, closeTo(screen.width / 2, 1));
    });

    testWidgets('shows a label when given one', (tester) async {
      await tester.pumpWidget(
        wrap(const MascotLoadingScreen(label: 'Menyiapkan pelajaranmu...')),
      );
      await tester.pump();

      expect(find.text('Menyiapkan pelajaranmu...'), findsOneWidget);
    });
  });
}

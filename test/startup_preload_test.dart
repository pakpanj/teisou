import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/providers.dart';
import 'package:kana_master/core/services/startup_preloader.dart';
import 'package:kana_master/core/theme/app_theme.dart';
import 'package:kana_master/core/widgets/mascot_loading_screen.dart';
import 'package:kana_master/core/widgets/mascot_widget.dart';

/// Reading the app's datasets before the home screen appears.
///
/// The reason this exists is not decoration. Every repository parses its
/// JSON on first use and caches it, so the cost was always being paid —
/// silently, on whichever frame a learner tapped into a module. Kaiwa
/// alone is 10MB across 1,700 dialogues. Moving it here turns an
/// unexplained mid-session stall into an explained wait, and turns the
/// loading screen's percentage from an estimate of elapsed time into a
/// count of something real.
void main() {
  group('progress', () {
    test('is zero, not NaN, before the step list is known', () {
      // The screen divides by `total`. A fresh app has no steps yet.
      expect(const StartupProgress().value, 0);
    });

    test('reads as the fraction of steps finished', () {
      expect(const StartupProgress(done: 3, total: 9).value, closeTo(1 / 3, 0.001));
      expect(const StartupProgress(done: 9, total: 9).value, 1);
    });
  });

  group('running it for real', () {
    // Plain `test`, not `testWidgets`. testWidgets runs inside a fake
    // clock, and the preloader yields once with `Future.delayed` before
    // it touches another provider — under a fake clock that timer never
    // fires and the test hangs rather than failing, which cost a
    // seven-minute run to work out.
    setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

    test('completes without throwing, and reports every step', () async {
      // The test that would have caught the bug this feature shipped
      // with. Riverpod forbids a provider from modifying another during
      // its own initialisation, and this one wrote its first progress
      // value before its first await — so it threw on every launch, the
      // preload never ran, and the app fell through the error branch to
      // the home screen. Nothing looked broken; the loading screen just
      // never appeared. Only reading logcat found it.
      //
      // Checking the arithmetic of StartupProgress was never going to
      // catch that. This actually runs the provider.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(appPreloadProvider.future);

      final progress = container.read(startupProgressProvider);
      expect(progress.total, greaterThan(0), reason: 'no steps ran');
      expect(progress.done, progress.total);
      expect(progress.value, 1);
    });

    test('warms the mascot art before the heavy reads', () async {
      // The bug the first device run showed: the loading screen drew its
      // ground shadow and no cat. Image.asset decodes on the main
      // isolate, and the dataset steps hold that isolate solidly — Kaiwa
      // alone is 10MB — so the PNG never got a slice to decode in. The
      // art has to be warmed before the reads, not after.
      final container = ProviderContainer();
      addTearDown(container.dispose);
      imageCache.clear();

      await container.read(appPreloadProvider.future);

      // Each pose the loading screen cycles through must already be
      // decoded, or it will not be there when it is needed.
      //
      // Keyed by what the cache actually stores, twice over.
      //
      // First: `obtainKey`'s key, not the ImageProvider — asserting on
      // the provider looks right and always fails.
      //
      // Second, and the one that mattered: the provider must be the one
      // the widget really asks for. MascotWidget passes `cacheWidth`,
      // which puts a ResizeImage in the cache — so warming a plain
      // AssetImage warms a key nothing ever requests. That version
      // passed its test and changed nothing on the device; the loading
      // screen still drew a ground shadow and no cat.
      for (final mood in [
        MascotMood.reading,
        MascotMood.thinking,
        MascotMood.writing,
        MascotMood.curious,
      ]) {
        final provider = MascotWidget.imageProviderFor(
          mood,
          size: MascotLoadingScreen.defaultMascotSize,
          showBackdrop: false,
        );
        final key = await provider.obtainKey(ImageConfiguration.empty);
        expect(imageCache.containsKey(key), isTrue,
            reason: '${mood.name} was never decoded at the size shown');
      }
    });

    test('leaves every dataset parsed and cached', () async {
      // The point of preloading: the module screens must find their data
      // already in memory rather than parsing it on the tap that opens
      // them. If a step silently failed, this is where it shows.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(appPreloadProvider.future);

      expect(await container.read(kanjiRepositoryProvider).getAll(),
          isNotEmpty);
      expect(await container.read(kaiwaRepositoryProvider).getAll(),
          isNotEmpty);
      expect(await container.read(bunpouRepositoryProvider).getAll(),
          isNotEmpty);
    });
  });

  group('the loading screen', () {
    Widget wrap(Widget child) => ProviderScope(
          child: MaterialApp(theme: AppTheme.light, home: child),
        );

    testWidgets('shows measured progress when it is given some',
        (tester) async {
      // Given real numbers it must use them, not the fallback curve — the
      // fallback deliberately caps below 100 because it cannot know.
      await tester.pumpWidget(
        wrap(const MascotLoadingScreen(progress: 0.5)),
      );
      await tester.pump();

      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('can honestly reach 100% when the work is really done',
        (tester) async {
      // The estimate never can, and should never claim to. A counted
      // preload finishes, and saying so is the whole point of counting.
      await tester.pumpWidget(
        wrap(const MascotLoadingScreen(progress: 1)),
      );
      await tester.pump();

      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('falls back to the estimate when nothing can be counted',
        (tester) async {
      // Waits with no step list — the age-question read, say — still get
      // a moving bar rather than a frozen zero.
      await tester.pumpWidget(wrap(const MascotLoadingScreen()));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('0%'), findsNothing);
    });

    testWidgets('names what it is reading', (tester) async {
      // A bare percentage says how long; the label says what for.
      await tester.pumpWidget(
        wrap(const MascotLoadingScreen(progress: 0.2, label: 'Memuat kanji...')),
      );
      await tester.pump();

      expect(find.text('Memuat kanji...'), findsOneWidget);
    });
  });
}

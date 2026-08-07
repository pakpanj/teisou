import 'dart:async';

import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../widgets/mascot_loading_screen.dart';
import '../widgets/mascot_widget.dart';

/// How far the startup preload has got.
class StartupProgress {
  const StartupProgress({this.done = 0, this.total = 0, this.label});

  final int done;
  final int total;

  /// What is being read right now, already localised.
  final String? label;

  /// 0 to 1. Zero rather than NaN before the step list is known.
  double get value => total == 0 ? 0 : done / total;
}

final startupProgressProvider =
    StateProvider<StartupProgress>((ref) => const StartupProgress());

/// Reads the app's bundled datasets before the home screen appears.
///
/// **This is real work moved, not work invented.** Every repository here
/// parses its JSON on first use and caches it, so the cost was always
/// being paid — just silently, in the middle of a session, on the frame
/// where a learner tapped into a module. Kaiwa alone is 10MB and 1,700
/// dialogues; on a mid-range phone that is a visible stall on the tap
/// that opens it. Doing it up front trades an unexplained freeze for an
/// explained wait, and every module screen then opens instantly.
///
/// It also makes the loading screen's percentage **a measurement rather
/// than an estimate**: these are discrete steps that finish one at a
/// time, so the number counts something real.
///
/// **Kaiwa is deliberately last.** If the ordering ever needs to change,
/// keep the largest read at the end: the bar should spend its time where
/// the work is, and a learner who backgrounds the app during startup has
/// already got the small datasets.
/// Decodes the mascot poses the loading screen is about to show.
///
/// **This has to happen before the datasets, not after.** `Image.asset`
/// decodes asynchronously on the main isolate, and the dataset steps below
/// occupy that isolate solidly — Kaiwa alone is 10MB of JSON. So the very
/// first run of this screen drew the ground shadow and no cat: the widget
/// was there, the PNG simply never got a slice of the isolate to decode
/// in. Warming the four poses first costs a few milliseconds and is the
/// difference between a loading screen with a character on it and one
/// with a grey ellipse floating in space.
///
/// Errors are swallowed per image: a mood whose art is missing already
/// falls back to an emoji, and must not stop the app from starting.
Future<void> _warmMascotArt(List<MascotMood> moods) async {
  for (final mood in moods) {
    final completer = Completer<void>();
    // The exact provider the screen will ask for, `cacheWidth` and all.
    // Warming a plain AssetImage warms a different key, which is a fix
    // that looks right, tests green, and changes nothing on the device —
    // the first attempt at this did precisely that.
    final stream = MascotWidget.imageProviderFor(
      mood,
      size: MascotLoadingScreen.defaultMascotSize,
      showBackdrop: false,
    ).resolve(ImageConfiguration.empty);

    late final ImageStreamListener listener;
    void finish() {
      stream.removeListener(listener);
      if (!completer.isCompleted) completer.complete();
    }

    listener = ImageStreamListener(
      (_, _) => finish(),
      onError: (_, _) => finish(),
    );
    stream.addListener(listener);
    await completer.future;
  }
}

final appPreloadProvider = FutureProvider<void>((ref) async {
  final strings = ref.read(appStringsProvider);

  // Ordered smallest to largest, so the bar moves immediately rather than
  // sitting at zero through the heaviest read.
  final steps = <(String, Future<void> Function())>[
    // First, and quick: without it the screen showing all of this has no
    // character on it. See [_warmMascotArt].
    (
      strings.preloadKana,
      () => _warmMascotArt(const [
            MascotMood.reading,
            MascotMood.thinking,
            MascotMood.writing,
            MascotMood.curious,
          ]),
    ),
    (strings.preloadKana, () => ref.read(kanaRepositoryProvider).getAll()),
    (
      strings.preloadCurriculum,
      () => ref.read(babRepositoryProvider).getAll(),
    ),
    (
      strings.preloadParticles,
      () => ref.read(particleRepositoryProvider).getAll(),
    ),
    (
      strings.preloadDictionary,
      () => ref.read(dictionaryRepositoryProvider).getAll(),
    ),
    (
      strings.preloadListening,
      () => ref.read(choukaiRepositoryProvider).getAll(),
    ),
    (strings.preloadReading, () => ref.read(dokkaiRepositoryProvider).getAll()),
    (strings.preloadGrammar, () => ref.read(bunpouRepositoryProvider).getAll()),
    (strings.preloadKanji, () => ref.read(kanjiRepositoryProvider).getAll()),
    (
      strings.preloadConversation,
      () => ref.read(kaiwaRepositoryProvider).getAll(),
    ),
  ];

  // Yield before touching another provider.
  //
  // Riverpod asserts that a provider may not modify another *during its
  // own initialisation*, and a FutureProvider's body runs synchronously
  // up to its first await — so writing progress straight away threw
  // "Providers are not allowed to modify other providers during their
  // initialization" on every launch. The preload never ran at all; the
  // app fell through this provider's error branch to the home screen, so
  // nothing looked broken and the loading screen simply never appeared.
  // One await is enough: after it, the build phase is over.
  await Future<void>.delayed(Duration.zero);

  final notifier = ref.read(startupProgressProvider.notifier);
  notifier.state = StartupProgress(
    total: steps.length,
    label: steps.first.$1,
  );

  for (var i = 0; i < steps.length; i++) {
    notifier.state = StartupProgress(
      done: i,
      total: steps.length,
      label: steps[i].$1,
    );
    try {
      await steps[i].$2();
    } catch (_) {
      // A dataset that fails to parse must not hold the whole app at a
      // loading screen forever. The screen that needs it will surface its
      // own error; every other module still works.
    }
  }

  notifier.state = StartupProgress(done: steps.length, total: steps.length);
});

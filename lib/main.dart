import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'core/navigation/root_navigator_key.dart';
import 'core/navigation/tts_stop_observer.dart';
import 'core/providers.dart';
import 'core/theme/app_theme.dart';
import 'data/models/app_theme_mode.dart';
import 'data/repositories/language_repository.dart';
import 'data/repositories/theme_repository.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/age_question_screen.dart';
import 'firebase_options.dart';
import 'core/services/fcm_service.dart';
import 'core/services/startup_preloader.dart';
import 'core/widgets/mascot_loading_screen.dart';
import 'features/onboarding/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Also locked via `android:screenOrientation="portrait"` in
  // AndroidManifest.xml (enforced before the Flutter engine even starts,
  // so there's no landscape flash on launch) — this call covers platforms
  // where the manifest lock doesn't apply.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Must be registered before runApp, and only makes sense once Firebase
    // itself is up — a message arriving while the app is fully
    // backgrounded/terminated runs this on a separate isolate with none of
    // this function's own state, which is exactly why it's a top-level
    // function in fcm_service.dart rather than something defined here.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase.initializeApp failed: $e');
  }
  // Deliberately not awaited: this hits the network (ad config, consent),
  // which can stall for seconds on a flaky connection. Nothing at startup
  // depends on it — ads are loaded lazily wherever they're shown — so it
  // must not block the first frame.
  unawaited(_initializeMobileAds());
  final initialLanguage = await LanguageRepository().getLanguage();
  final initialThemeMode = await ThemeRepository().getThemeMode();
  runApp(
    ProviderScope(
      overrides: [
        languageProvider.overrideWith((ref) => initialLanguage),
        themeModeProvider.overrideWith((ref) => initialThemeMode),
      ],
      child: const KanaMasterApp(),
    ),
  );
}

Future<void> _initializeMobileAds() async {
  try {
    await MobileAds.instance.initialize();
  } catch (e) {
    debugPrint('MobileAds.initialize failed: $e');
  }
}

class KanaMasterApp extends ConsumerStatefulWidget {
  const KanaMasterApp({super.key});

  @override
  ConsumerState<KanaMasterApp> createState() => _KanaMasterAppState();
}

/// Stateful only to own the two things that have to outlive a rebuild and
/// stop Japanese speech the app would otherwise keep reading aloud after
/// the learner has moved on: the navigator observer, and the app
/// lifecycle hook. See [TtsStopObserver] for why this is handled here
/// rather than in each of the eleven speaking screens.
class _KanaMasterAppState extends ConsumerState<KanaMasterApp>
    with WidgetsBindingObserver {
  // Built once and kept: a fresh list on every theme rebuild would make
  // Navigator detach and re-attach its observers for no reason.
  late final List<NavigatorObserver> _navigatorObservers = [
    TtsStopObserver(_stopSpeech),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _stopSpeech() {
    // Navigation and lifecycle transitions must not be able to fail
    // because a TTS engine misbehaved, and there is nothing useful to do
    // about it here anyway.
    ref.read(ttsServiceProvider).stop().catchError((_) {});
  }

  /// Pressing home mid-sentence used to leave the phone reading Japanese
  /// out loud with the app off screen.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _stopSpeech();
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    // Watched, not read: switching the mode in ThemeScreen has to repaint
    // the whole app immediately, the same way languageProvider does.
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'Teisou: Kana Master',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode.material,
      navigatorKey: rootNavigatorKey,
      navigatorObservers: _navigatorObservers,
      home: const _AudienceGate(),
    );
  }
}

/// Holds the app at the age question until it has an answer, then pushes
/// that answer to AdMob before the rest of the app — and its first ad
/// request — appears.
///
/// Ads are configured here rather than at each ad site so there is exactly
/// one place that can get it wrong. While the answer is still loading the
/// app shows nothing rather than the home screen: a banner rendering during
/// that gap would be an unconfigured request, which is the single case this
/// whole mechanism exists to prevent.
class _AudienceGate extends ConsumerWidget {
  const _AudienceGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audience = ref.watch(adAudienceProvider);

    return audience.when(
      data: (value) {
        if (!value.isKnown) return const AgeQuestionScreen();
        // Fire-and-forget: the configuration applies to requests made after
        // it lands, and every ad site is behind at least one more tap.
        unawaited(ref.read(adServiceProvider).applyAudience(value));
        return const _PreloadGate();
      },
      loading: () => const _StartupLoading(),
      // A failed read leaves the audience unknown, which AdAudience already
      // treats as a child — so ask rather than assume an adult.
      error: (_, _) => const AgeQuestionScreen(),
    );
  }
}

/// Shows the tutorial once per device, then the app.
///
/// Sits *after* the age question rather than before it: the age answer
/// configures ads and has to be settled before anything renders, and a
/// tutorial in front of it would delay that for no reason.
///
/// A failed read of the flag shows the home screen, not the tutorial. If
/// SharedPreferences is unreadable the flag can never be written either,
/// so erring the other way would trap the learner in a tutorial that
/// replays on every launch.
class _TutorialGate extends ConsumerWidget {
  const _TutorialGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seen = ref.watch(hasSeenTutorialProvider);

    return seen.when(
      data: (value) {
        if (value) return const HomeScreen();
        return OnboardingScreen(
          onFinished: () async {
            await ref.read(onboardingRepositoryProvider).markTutorialSeen();
            ref.invalidate(hasSeenTutorialProvider);
          },
        );
      },
      loading: () => const _StartupLoading(),
      error: (_, _) => const HomeScreen(),
    );
  }
}

/// Reads the app's datasets before the home screen appears.
///
/// **The work is not invented for the sake of a loading screen.** Every
/// repository parses its JSON on first use and caches it, so this cost was
/// always paid — silently, on whichever frame a learner tapped into a
/// module. Kaiwa alone is 10MB across 1,700 dialogues. Doing it here
/// trades an unexplained stall mid-session for an explained wait at the
/// start, and every module screen then opens instantly.
///
/// A failed preload still lets the app in: the steps swallow their own
/// errors, and a screen whose dataset is broken surfaces that itself
/// rather than holding everything else hostage.
class _PreloadGate extends ConsumerWidget {
  const _PreloadGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preload = ref.watch(appPreloadProvider);
    return preload.when(
      data: (_) => const _TutorialGate(),
      loading: () => const _StartupLoading(),
      error: (_, _) => const _TutorialGate(),
    );
  }
}

/// The loading screen, fed by whatever the preloader has counted so far.
///
/// Split out so the percentage comes from real steps rather than the
/// elapsed-time estimate. Before the preloader has started there is
/// nothing to count, and [MascotLoadingScreen] falls back to the estimate
/// on its own.
class _StartupLoading extends ConsumerWidget {
  const _StartupLoading();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(startupProgressProvider);
    final strings = ref.watch(appStringsProvider);
    return MascotLoadingScreen(
      progress: progress.total == 0 ? null : progress.value,
      label: progress.label ?? strings.loadingPreparing,
    );
  }
}

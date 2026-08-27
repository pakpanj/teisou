import 'dart:async';
import 'dart:ui';

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
import 'data/repositories/stroke_speed_repository.dart';
import 'data/repositories/theme_repository.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/age_question_screen.dart';
import 'firebase_options.dart';
import 'core/services/fcm_service.dart';
import 'core/services/startup_preloader.dart';
import 'core/widgets/mascot_loading_screen.dart';
import 'features/onboarding/first_visit_tutorial.dart';
import 'features/onboarding/home_tour.dart';
import 'features/onboarding/identity_gate_screen.dart';
import 'features/onboarding/min_version_gate.dart';
import 'features/onboarding/plan_intro_screen.dart';
import 'data/repositories/onboarding_repository.dart';

/// Installs the app's one global error boundary — RISK-7
/// (AUDIT_PHASE_C_BATTLE_RELIABILITY.md's C1, the half that was left
/// open). `FlutterError.onError` covers framework (build/layout/paint)
/// errors; `PlatformDispatcher.instance.onError` is Flutter's current
/// official mechanism for everything else an uncaught async error can
/// come from — an unguarded stream listener, an unawaited `Future` that
/// throws — anywhere in the app, not just where someone remembered to
/// add a local `onError`.
///
/// **Why this exists despite a prior, deliberate decision not to add
/// one.** `test/battle_reliability_wiring_test.dart` used to pin the
/// opposite — "harden per-listener, don't add a global zone... each
/// stream now handles its own errors" — correct for the two Battle
/// listeners that prompted it, but this session's broader audit found
/// the premise doesn't hold app-wide: `fcm_service.dart`'s three
/// `FirebaseMessaging` listeners (`onTokenRefresh`/`onMessage`/
/// `onMessageOpenedApp`) have neither an `onError` nor any internal
/// try/catch. Rather than add a fourth (and, inevitably later, fifth)
/// per-listener patch, this closes the gap at the root — new call sites
/// get the safety net automatically instead of needing to remember it.
///
/// Uses this project's existing `debugPrint`-based logging convention
/// (see e.g. `ad_service.dart`'s `catch (error) { debugPrint('... failed:
/// $error'); }` sites) rather than adding a new error-reporting service.
///
/// **Cannot be proven to intercept a genuinely uncaught error via
/// `flutter_test`** — confirmed empirically while building this:
/// `TestWidgetsFlutterBinding` installs its own zone that claims
/// uncaught errors before they ever reach `PlatformDispatcher.instance
/// .onError`, the same mechanism that powers `tester.takeException()`.
/// `test/global_error_handling_test.dart` verifies the wiring exists and
/// that both handlers behave correctly when invoked directly; it cannot
/// simulate a live interception the way a real device run could.
void installGlobalErrorHandlers() {
  FlutterError.onError = (FlutterErrorDetails details) {
    // Keeps Flutter's own default behavior (console dump, and the
    // debug-mode red error screen) — this is additive logging, not a
    // replacement, so a build/layout/paint error is exactly as visible
    // as it always was.
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('Uncaught error: $error\n$stack');
    // Handled: without this, an app running with no other zone in place
    // (this app's own case — see the doc comment above) can otherwise
    // still surface as an unhandled platform-level error.
    return true;
  };
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installGlobalErrorHandlers();
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
  final initialStrokeSpeed = await StrokeSpeedRepository().getSpeed();
  runApp(
    ProviderScope(
      overrides: [
        languageProvider.overrideWith((ref) => initialLanguage),
        themeModeProvider.overrideWith((ref) => initialThemeMode),
        strokeSpeedProvider.overrideWith((ref) => initialStrokeSpeed),
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
      // The very first gate, ahead of everything else — see
      // `MinVersionGate`'s own doc comment for why an old build has to
      // be stopped here, before the age question, before sign-in, before
      // anything a future Firestore Rules cutover could otherwise break
      // it against.
      home: const MinVersionGate(child: _AudienceGate()),
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
        return const _IdentityGate();
      },
      loading: () => const _StartupLoading(),
      // A failed read leaves the audience unknown, which AdAudience already
      // treats as a child — so ask rather than assume an adult.
      error: (_, _) => const AgeQuestionScreen(),
    );
  }
}

/// Google-or-Guest, shown once per device before the Plan Intro paywall —
/// see `identityChoiceMadeProvider` for exactly what "once" means and how
/// an existing install is migrated past this without ever seeing it.
///
/// **Sits here, not inside `_PlanIntroGate`**, for the same reason
/// `_PlanIntroGate` itself sits after `_AudienceGate` rather than before
/// it: each gate answers one question and hands off, and conflating "who
/// is this" with "do they want Premium" would make either one harder to
/// reason about alone. `appStartupProvider` (anonymous sign-in) has
/// already resolved by the time this can render — same guarantee
/// `_PlanIntroGate` already relied on before this gate existed — so
/// `IdentityGateScreen` never creates a UID, only optionally upgrades the
/// one that already exists.
class _IdentityGate extends ConsumerWidget {
  const _IdentityGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final made = ref.watch(identityChoiceMadeProvider);
    return made.when(
      data: (value) =>
          value ? const _PlanIntroGate() : const IdentityGateScreen(),
      loading: () => const _StartupLoading(),
      // A failed read must not trap every launch behind a screen that can
      // never resolve — same fail-open reasoning `_PlanIntroGate`'s own
      // error branch already documents, just for this gate instead. Not
      // showing the gate is the side that can never strand an existing
      // user; showing it again to someone who already chose is a minor
      // annoyance, not a lost account.
      error: (_, _) => const _PlanIntroGate(),
    );
  }
}

/// Shows the Free-vs-Premium plan intro right after the age question and
/// before the dataset preload / home tutorial — for every **account**
/// that hasn't seen it yet, and again for one whose premium subscription
/// has since lapsed. See [planIntroShouldShowProvider] for the actual
/// account/subscription logic.
///
/// **Here specifically, not merged into the home tutorial and not
/// before the age question** — an explicit product decision, not a
/// default: the age answer configures ads and has to be settled first
/// (same reasoning [_AudienceGate] already gives for sitting where it
/// does), and this is a one-time-per-account monetisation choice rather
/// than a coach-mark walkthrough of the home screen's own cards, so it
/// does not belong inside [FirstVisitTutorial]'s tour either.
///
/// **Sitting this early means [appStartupProvider] (sign-in) now
/// resolves before the home screen's own first frame, not lazily on it**
/// — [planIntroShouldShowProvider] depends on knowing which account this
/// is. Anonymous sign-in and the one Firestore read it needs are both
/// fast, and every screen past this gate already depended on sign-in
/// having happened anyway.
class _PlanIntroGate extends ConsumerWidget {
  const _PlanIntroGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shouldShow = ref.watch(planIntroShouldShowProvider);
    return shouldShow.when(
      data: (value) => value ? const PlanIntroFlow() : const _PreloadGate(),
      loading: () => const _StartupLoading(),
      // A failed read must not trap every launch behind a screen that
      // can never resolve — same asymmetry `_AudienceGate` accepts for
      // its own failed read, just the other way round: an unknown age is
      // treated as a child (the safer wrong answer), while a failure
      // here is treated as "don't show" (the one that never blocks the
      // app from opening).
      error: (_, _) => const _PreloadGate(),
    );
  }
}

/// Shows the tutorial once per device, then the app.
///
/// Sits *after* the age question rather than before it: the age answer
/// configures ads and has to be settled before anything renders, and a
/// tutorial in front of it would delay that for no reason.
///
/// The home screen, with the first-run walkthrough playing over it.
///
/// The tutorial used to stand in front of this, chosen instead of the
/// home screen rather than on top of it — see [FirstVisitTutorial] for
/// why that was the wrong way round.
class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) => FirstVisitTutorial(
    id: TutorialId.home,
    // Coach marks, not a slideshow: the mascot points at the real
    // cards on the real screen.
    tour: homeTourSteps,
    child: const HomeScreen(),
  );
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
      data: (_) => const _Home(),
      loading: () => const _StartupLoading(),
      error: (_, _) => const _Home(),
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

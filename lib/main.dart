import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'core/providers.dart';
import 'core/theme/app_theme.dart';
import 'data/models/app_theme_mode.dart';
import 'data/repositories/language_repository.dart';
import 'data/repositories/theme_repository.dart';
import 'features/home/home_screen.dart';
import 'firebase_options.dart';

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

class KanaMasterApp extends ConsumerWidget {
  const KanaMasterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watched, not read: switching the mode in ThemeScreen has to repaint
    // the whole app immediately, the same way languageProvider does.
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'Teisou: Kana Master',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode.material,
      home: const HomeScreen(),
    );
  }
}

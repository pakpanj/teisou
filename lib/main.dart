import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  runApp(const ProviderScope(child: KanaMasterApp()));
}

Future<void> _initializeMobileAds() async {
  try {
    await MobileAds.instance.initialize();
  } catch (e) {
    debugPrint('MobileAds.initialize failed: $e');
  }
}

class KanaMasterApp extends StatelessWidget {
  const KanaMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teisou: Kana Master',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}

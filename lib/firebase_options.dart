// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Generated from `android/app/google-services.json` (project
/// teisou-kana-master). Regenerate via `flutterfire configure` if the
/// Firebase project changes.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'run flutterfire configure to add web support.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform. '
          'Run flutterfire configure to add support for it.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB_oIrI5pP0_0ik2bDAwONqr2g1QhMsGH4',
    appId: '1:329692614759:android:cbca9fc670f162d60e44c2',
    messagingSenderId: '329692614759',
    projectId: 'teisou-kana-master',
    storageBucket: 'teisou-kana-master.firebasestorage.app',
  );
}

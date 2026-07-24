import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_language.dart';

/// Persists the user's chosen app-interface language. Pure device-local
/// setting (no Firestore mirror, unlike the progress repositories) —
/// there's nothing meaningful to sync across devices here, and a fresh
/// device should just fall back to the default (Indonesian) rather than
/// wait on a network round-trip to know which language to boot into.
class LanguageRepository {
  static const _prefsKey = 'app_language';

  Future<AppLanguage> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return AppLanguageX.fromCode(prefs.getString(_prefsKey));
  }

  Future<void> setLanguage(AppLanguage language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, language.code);
  }
}

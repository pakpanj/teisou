import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_theme_mode.dart';

/// Persists the user's chosen colour mode. Device-local only, exactly like
/// [LanguageRepository] — which theme a phone is in isn't something worth
/// syncing across devices, and a fresh device should boot straight into the
/// default rather than wait on a network round-trip to find out.
class ThemeRepository {
  static const _prefsKey = 'app_theme_mode';

  Future<AppThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return AppThemeModeX.fromKey(prefs.getString(_prefsKey));
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.key);
  }
}

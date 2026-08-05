import 'package:shared_preferences/shared_preferences.dart';

import '../models/ad_audience.dart';

/// Stores the learner's answer to the age question that decides how AdMob
/// may serve to them.
///
/// Device-local only, like [LanguageRepository] and unlike the progress
/// repositories: there is no Firestore mirror on purpose. The answer has to
/// be available before the first ad request, which happens well before any
/// network round-trip could finish, and a fresh device must fall back to
/// the restrictive default rather than serve unrestricted ads while it
/// waits to hear otherwise.
class AdAudienceRepository {
  static const _prefsKey = 'ad_audience_birth_year';

  Future<AdAudience> getAudience({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_prefsKey);
    if (stored == null) return const AdAudience();

    // A year from the future, or one implying a 150-year-old, means the
    // stored value is corrupt. Discarding it returns the unknown — and
    // therefore restricted — state instead of trusting a nonsense age to
    // unlock personalised ads.
    if (!AdAudience.isPlausibleBirthYear(stored, now ?? DateTime.now())) {
      return const AdAudience();
    }
    return AdAudience(birthYear: stored);
  }

  Future<void> setBirthYear(int year) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, year);
  }
}

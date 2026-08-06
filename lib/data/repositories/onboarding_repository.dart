import 'package:shared_preferences/shared_preferences.dart';

/// Whether this device has seen the first-run tutorial.
///
/// **Deliberately local only, with no Firestore mirror** — unlike every
/// other progress repository in the app. Learning progress belongs to the
/// person and should follow them to a new phone; "has been shown how this
/// app works" belongs to the *device*. Mirroring it would mean a learner
/// installing on a second phone gets dropped straight onto the home screen
/// with no explanation, which is exactly the case the tutorial exists for.
///
/// The key carries a version. Rewriting the tutorial for a redesigned app
/// and leaving the old key in place would show the new tutorial to nobody
/// who already had the app — bump the suffix and everyone sees it once
/// more.
class OnboardingRepository {
  static const _prefsKey = 'onboarding_seen_v1';

  Future<bool> hasSeenTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? false;
  }

  Future<void> markTutorialSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
  }

  /// Lets the learner watch it again from Profile. Also what a tester
  /// needs, since otherwise checking the tutorial means reinstalling.
  Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}

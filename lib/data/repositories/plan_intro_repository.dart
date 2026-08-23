import 'package:shared_preferences/shared_preferences.dart';

/// Whether this device has already seen the Free-vs-Premium plan intro
/// shown right after the age question, before the home-screen tutorial.
///
/// **Local only, same reasoning as [OnboardingRepository]**: "has been
/// shown the plan choice" belongs to the device, not the person — a
/// learner installing on a second phone should see it there too, not
/// be silently skipped because their account already saw it once
/// somewhere else.
///
/// Kept as its own tiny repository rather than folded into
/// [OnboardingRepository]'s `TutorialId` enum: that enum is explicitly
/// "one per module" coach-mark walkthroughs pointing at real on-screen
/// elements (see its own doc comment) — this is a different kind of
/// thing, a one-time full-screen choice shown before any module even
/// exists to point at.
class PlanIntroRepository {
  static const _prefsKey = 'plan_intro_seen_v1';

  Future<bool> hasSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? false;
  }

  Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
  }
}

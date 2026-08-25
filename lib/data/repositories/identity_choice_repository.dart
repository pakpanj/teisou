import 'package:shared_preferences/shared_preferences.dart';

/// Whether this **device** has been shown the Identity Gate (Google vs
/// Guest) — `main.dart`'s `_IdentityGate`, sat between the age question
/// and the Plan Intro paywall.
///
/// **Deliberately local only, no Firestore mirror** — the exact same
/// reasoning `OnboardingRepository` already documents for its own flag:
/// "has been asked to choose" belongs to the device, not the person, so a
/// learner installing on a second phone is asked again rather than
/// silently inheriting a choice made somewhere else.
///
/// A separate class from `OnboardingRepository` rather than a new
/// `TutorialId` value: this isn't a tutorial being replayed from Profile,
/// it's a one-time first-run gate with its own migration rule (see
/// `main.dart`'s `_IdentityGate` for exactly how an existing install is
/// treated as already having chosen, without ever showing it the gate).
class IdentityChoiceRepository {
  /// Public so a test can pin it — the same "renaming this makes every
  /// existing install look like it never chose" risk `TutorialId.prefsKey`
  /// already documents for itself.
  static const prefsKey = 'identity_choice_made_v1';

  Future<bool> hasChosen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefsKey) ?? false;
  }

  Future<void> markChosen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, true);
  }
}

/// Whether this **account** has already seen the Free-vs-Premium plan
/// intro, and whether it was premium the last time that state was
/// recorded — the second field is what lets the intro come back once a
/// subscription lapses, instead of being a true one-time screen.
///
/// Lives on `users/{uid}` (a plain, client-writable field — not
/// `subscription`/`entitlements`, which `firestore.rules` locks to
/// server-only writes, so this needed no rules change) rather than in
/// SharedPreferences: the whole point of this redesign is that "has seen
/// the plan choice" follows the *account*, not the device — log into the
/// same account on a second phone and it should already be marked seen
/// there too, and a different account signing in on the same phone
/// should see it fresh.
class PlanIntroState {
  final bool seen;

  /// Whether the account was premium the last time [seen] was recorded
  /// true, or the last time a startup check refreshed this field without
  /// showing the intro. Comparing this against the account's *current*
  /// premium status is how a lapse is detected: `true` stored alongside
  /// `false` now means "was premium, isn't anymore" — show the intro
  /// again. Anything else (never premium, or already re-shown for this
  /// particular lapse) stays quiet.
  final bool lastKnownPremium;

  const PlanIntroState({required this.seen, required this.lastKnownPremium});

  factory PlanIntroState.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const PlanIntroState(seen: false, lastKnownPremium: false);
    }
    return PlanIntroState(
      seen: map['seen'] as bool? ?? false,
      lastKnownPremium: map['lastKnownPremium'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'seen': seen,
    'lastKnownPremium': lastKnownPremium,
  };

  /// Whether `PlanIntroFlow` should be shown right now, given the
  /// account's current premium status.
  bool shouldShow({required bool isPremiumNow}) {
    if (!seen) return true;
    return lastKnownPremium && !isPremiumNow;
  }
}

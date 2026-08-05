/// Who is looking at the ads, which decides how AdMob is allowed to serve
/// them.
///
/// This app is mixed-audience: children and adults use the same build. AdMob
/// requires each request to say whether it is child-directed, and getting
/// that wrong is not a revenue question but a policy one — serving
/// personalised ads to a child breaches COPPA and Google Play's Families
/// policy, which costs the AdMob account, not just the impression.
///
/// **An unknown age is treated as a child.** Ads can load before anyone has
/// answered the age question, and the cost of the two mistakes is not
/// symmetric: over-restricting an adult loses a little revenue, while
/// under-restricting a child is a policy breach. So every getter below
/// returns the restrictive answer when [birthYear] is null.
class AdAudience {
  const AdAudience({this.birthYear});

  /// Null until the learner has answered the age question.
  final int? birthYear;

  /// COPPA's threshold: under 13 is child-directed.
  static const childUnderAge = 13;

  /// GDPR's default digital age of consent. Member states may set theirs
  /// anywhere from 13 to 16; 16 is used here because it is the strictest,
  /// and this flag only ever restricts what is served.
  static const digitalConsentAge = 16;

  /// The youngest this person could currently be.
  ///
  /// A birth *year* alone cannot say whether the birthday has passed, so
  /// someone born in 2013 is either 12 or 13 during 2026. Subtracting the
  /// extra year takes the lower of the two on purpose: an age used to
  /// decide how carefully to treat someone should err young.
  int? minimumAgeAt(DateTime now) {
    final year = birthYear;
    if (year == null) return null;
    return now.year - year - 1;
  }

  bool get isKnown => birthYear != null;

  bool isChildDirectedAt(DateTime now) {
    final age = minimumAgeAt(now);
    return age == null || age < childUnderAge;
  }

  bool isUnderAgeOfConsentAt(DateTime now) {
    final age = minimumAgeAt(now);
    return age == null || age < digitalConsentAge;
  }

  /// The oldest birth year the picker should offer, and the boundary a
  /// stored value is validated against — a year in the future, or one
  /// implying an implausible age, means corrupted storage rather than a
  /// real answer.
  static bool isPlausibleBirthYear(int year, DateTime now) {
    return year > now.year - 120 && year <= now.year;
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kana_master/data/models/ad_audience.dart';
import 'package:kana_master/data/repositories/ad_audience_repository.dart';

/// How AdMob is allowed to serve each learner.
///
/// The asymmetry is the whole point: over-restricting an adult costs a
/// little revenue, while under-restricting a child breaches COPPA and
/// Google Play's Families policy — which costs the AdMob account. So every
/// uncertain case here must resolve to the restrictive answer, and these
/// tests exist to catch the day someone "simplifies" that away.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 8, 5);

  group('an unanswered age is treated as a child', () {
    const unknown = AdAudience();

    test('child-directed', () {
      expect(unknown.isChildDirectedAt(now), isTrue);
    });

    test('under the age of consent', () {
      expect(unknown.isUnderAgeOfConsentAt(now), isTrue);
    });

    test('and is reported as not yet known', () {
      expect(unknown.isKnown, isFalse);
      expect(unknown.minimumAgeAt(now), isNull);
    });
  });

  test('a birth year resolves to the youngest that person could be', () {
    // Born 2013, in August 2026: 12 if the birthday has not passed, 13 if
    // it has. A birth year cannot tell us which, so the younger of the two
    // is used — the side that restricts.
    const born2013 = AdAudience(birthYear: 2013);
    expect(born2013.minimumAgeAt(now), 12);
    expect(born2013.isChildDirectedAt(now), isTrue,
        reason: 'might still be 12, so must not be treated as 13');
  });

  test('the COPPA boundary falls where it should', () {
    // Someone born in 2012 is at least 13 all through 2026.
    expect(const AdAudience(birthYear: 2012).isChildDirectedAt(now), isFalse);
    expect(const AdAudience(birthYear: 2013).isChildDirectedAt(now), isTrue);
  });

  test('the age-of-consent boundary is separate and higher', () {
    // A 14-year-old is not child-directed but is under the age of consent:
    // two different flags, and collapsing them into one would be wrong in
    // both directions.
    const fourteen = AdAudience(birthYear: 2011);
    expect(fourteen.minimumAgeAt(now), 14);
    expect(fourteen.isChildDirectedAt(now), isFalse);
    expect(fourteen.isUnderAgeOfConsentAt(now), isTrue);

    expect(const AdAudience(birthYear: 2009).isUnderAgeOfConsentAt(now), isFalse,
        reason: 'at least 16');
  });

  group('stored answers', () {
    test('a plausible year is read back', () async {
      SharedPreferences.setMockInitialValues({});
      final repository = AdAudienceRepository();
      await repository.setBirthYear(2000);

      final audience = await repository.getAudience(now: now);
      expect(audience.birthYear, 2000);
      expect(audience.isChildDirectedAt(now), isFalse);
    });

    test('nothing stored yields the restricted unknown', () async {
      SharedPreferences.setMockInitialValues({});
      final audience = await AdAudienceRepository().getAudience(now: now);
      expect(audience.isKnown, isFalse);
      expect(audience.isChildDirectedAt(now), isTrue);
    });

    test('a corrupt year is discarded rather than trusted', () async {
      // A future year, or an implausible one, must not be allowed to
      // unlock unrestricted ads by looking like an adult.
      for (final bad in [2099, 1700, 0, -5]) {
        SharedPreferences.setMockInitialValues({
          'ad_audience_birth_year': bad,
        });
        final audience = await AdAudienceRepository().getAudience(now: now);
        expect(audience.isKnown, isFalse, reason: 'stored year $bad');
        expect(audience.isChildDirectedAt(now), isTrue, reason: 'year $bad');
      }
    });

    test('the current year is accepted, next year is not', () async {
      expect(AdAudience.isPlausibleBirthYear(now.year, now), isTrue);
      expect(AdAudience.isPlausibleBirthYear(now.year + 1, now), isFalse);
    });
  });
}

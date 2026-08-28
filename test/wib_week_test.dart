import 'package:flutter_test/flutter_test.dart';
import 'package:kana_master/core/utils/wib_week.dart';

/// Mirrors `functions/wib_week.test.js`'s own boundary cases line for
/// line — see `wib_week.dart`'s own doc comment for why this client-side
/// copy must stay in exact lock-step with the server implementation even
/// though it has no security consequence on its own (a drift here is a
/// display bug, not a forgeable ranking input).
void main() {
  test('wibOffset is exactly +7 hours', () {
    expect(wibOffset, const Duration(hours: 7));
  });

  test(
    'Sunday 23:59:59.999 WIB is still the CLOSING week, not the new one',
    () {
      final justBeforeMidnightWib = DateTime.utc(
        2026,
        8,
        30,
        16,
        59,
        59,
        999,
      );
      final earlierSameSundayWib = DateTime.utc(2026, 8, 30, 5, 0);
      final idOfExactMonday = wibWeekId(DateTime.utc(2026, 8, 30, 17, 0));

      expect(
        wibWeekId(justBeforeMidnightWib),
        wibWeekId(earlierSameSundayWib),
        reason:
            'one millisecond before WIB midnight must still belong to '
            'the same week as earlier that same Sunday',
      );
      expect(
        wibWeekId(justBeforeMidnightWib),
        isNot(idOfExactMonday),
        reason:
            'one millisecond before WIB midnight must NOT belong to '
            'the week that is about to start at midnight',
      );
    },
  );

  test(
    'Monday 00:00:00.000 WIB starts a NEW week id, distinct from the '
    'previous week',
    () {
      final sundayNight = DateTime.utc(2026, 8, 30, 16, 59, 59, 999);
      final mondayMidnight = DateTime.utc(2026, 8, 30, 17, 0);
      expect(wibWeekId(sundayNight), isNot(wibWeekId(mondayMidnight)));
    },
  );

  test(
    'a UTC instant that is still Sunday in UTC but already Monday in '
    'WIB resolves to the NEW week',
    () {
      final stillSundayUtcButMondayWib = DateTime.utc(2026, 8, 30, 23, 0);
      final deepIntoMondayWib = DateTime.utc(2026, 8, 31, 10, 0);
      expect(
        wibWeekId(stillSundayUtcButMondayWib),
        wibWeekId(deepIntoMondayWib),
      );
    },
  );

  test('wibWeekId format matches the server convention (YYYY-Www)', () {
    final id = wibWeekId(DateTime.utc(2026, 8, 31, 0, 0));
    expect(RegExp(r'^\d{4}-W\d{2}$').hasMatch(id), isTrue);
  });

  test(
    'a year boundary correctly rolls the WIB week ISO year forward',
    () {
      final dec31Wib = DateTime.utc(2026, 12, 31, 10, 0);
      expect(wibWeekId(dec31Wib), '2026-W53');

      final jan5_2027Wib = DateTime.utc(2027, 1, 5, 10, 0);
      expect(wibWeekId(jan5_2027Wib), '2027-W01');
    },
  );

  test(
    'wibWeekStart returns the real UTC instant of Monday 00:00:00.000 '
    'WIB for the week containing the given date',
    () {
      final midWeek = DateTime.utc(2026, 9, 2, 5, 0);
      final start = wibWeekStart(midWeek);
      expect(start, DateTime.utc(2026, 8, 30, 17, 0));
    },
  );

  test(
    'wibWeekStart(x) and x itself always share the same wibWeekId',
    () {
      final samples = [
        DateTime.utc(2026, 8, 30, 16, 59, 59, 999),
        DateTime.utc(2026, 8, 30, 17, 0),
        DateTime.utc(2026, 9, 5, 23, 59, 59, 999),
        DateTime.utc(2027, 1, 1),
      ];
      for (final sample in samples) {
        final start = wibWeekStart(sample);
        expect(
          wibWeekId(start),
          wibWeekId(sample),
          reason: 'wibWeekStart($sample) must resolve to the same period '
              'id as the sample itself',
        );
      }
    },
  );

  test(
    'wibWeekStart is idempotent: calling it again on its own result '
    'returns the same instant',
    () {
      final midWeek = DateTime.utc(2026, 9, 2, 5, 0);
      final start = wibWeekStart(midWeek);
      final startOfStart = wibWeekStart(start);
      expect(start, startOfStart);
    },
  );

  test(
    'currentWibPeriodId agrees with wibWeekId(DateTime.now().toUtc())',
    () {
      // Not a boundary test — just proves the convenience wrapper
      // actually delegates rather than diverging (e.g. using local time
      // instead of UTC, which would silently shift by the device's own
      // timezone on top of the explicit WIB offset).
      final before = DateTime.now().toUtc();
      final id = currentWibPeriodId();
      final after = DateTime.now().toUtc();
      // The real "now" must resolve to the same id computed directly —
      // check against both bounds in case the wall clock ticked across
      // the two reads (extremely unlikely to cross a WEEK boundary
      // mid-test, but this avoids ever being flaky).
      expect(id, anyOf(wibWeekId(before), wibWeekId(after)));
    },
  );
}

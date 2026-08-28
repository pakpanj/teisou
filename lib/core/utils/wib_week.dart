/// WIB (Asia/Jakarta, UTC+7, no daylight saving) — anchored ISO-8601-
/// style week id, for the Weekly Global Ranking competition period.
///
/// **This is a client-side MIRROR of `functions/wib_week.js`'s
/// `wibWeekId`, used ONLY to know which already-written, read-only
/// `globalScorePeriods/{periodId}/users` document to fetch — it never
/// influences scoring or ranking itself.** The server (Cloud Functions,
/// via the CloudEvent's own `event.time`) is the sole authority on which
/// period an attempt's points actually land in; this function exists
/// purely so the app can compute "what period should I be reading right
/// now" without an extra round-trip. If this function's date math ever
/// drifted from the server's own `wibWeekId`, the practical effect would
/// be the client reading the WRONG (empty or stale) period document —
/// a display bug, not a security issue, since the client has no write
/// path to any of this data at all (`firestore.rules` denies every
/// client write to `globalScorePeriods`/`globalScorePeriodAwards`
/// unconditionally). Kept in exact lock-step with the server
/// implementation regardless — see `wib_week_test.dart`, which mirrors
/// `functions/wib_week.test.js`'s own boundary cases line for line.
///
/// The fixed `+7h` shift is exact and permanent specifically *because*
/// WIB has no DST (Indonesia does not observe daylight saving) — unsafe
/// to copy for a DST-observing zone without re-checking that assumption.
library;

/// WIB is a fixed UTC+7 offset, year-round — no DST to account for.
const wibOffset = Duration(hours: 7);

/// ISO-week-numbered id (`YYYY-Www`) for the WIB week containing [utc] —
/// the exact same string format the server's own `award_top_coins.js`
/// (`isoWeekId`, historical) and `wib_week.js` (`wibWeekId`, current)
/// use.
///
/// The period boundary is a half-open interval: `[Monday 00:00:00.000
/// WIB, next Monday 00:00:00.000 WIB)` — the boundary instant itself
/// belongs to the period that is *starting*, not the one ending. This
/// falls out of the date-math itself (at exactly midnight WIB, the
/// shifted calendar date has already rolled to Monday) — no special-
/// casing needed, mirroring `functions/wib_week.js`'s own `wibWeekId`.
///
/// @param utc must be a UTC [DateTime] (`DateTime.now().toUtc()`, or any
///   already-UTC instant) — passing a local-time [DateTime] would shift
///   by the device's own timezone on top of the explicit WIB shift below,
///   silently double-applying an offset.
String wibWeekId(DateTime utc) {
  assert(utc.isUtc, 'wibWeekId requires a UTC DateTime — call .toUtc() first');
  final shifted = utc.add(wibOffset);
  var d = DateTime.utc(shifted.year, shifted.month, shifted.day);
  final dayNum = d.weekday; // Dart's DateTime.weekday is already 1=Mon..7=Sun
  d = d.add(Duration(days: 4 - dayNum));
  final yearStart = DateTime.utc(d.year, 1, 1);
  final weekNum = (((d.difference(yearStart).inDays) + 1) / 7).ceil();
  return '${d.year}-W${weekNum.toString().padLeft(2, '0')}';
}

/// The start instant (Monday 00:00:00.000 WIB, expressed as its real UTC
/// instant) of the WIB week containing [utc] — mirrors
/// `functions/wib_week.js`'s own `wibWeekStart`.
DateTime wibWeekStart(DateTime utc) {
  assert(
    utc.isUtc,
    'wibWeekStart requires a UTC DateTime — call .toUtc() first',
  );
  final shifted = utc.add(wibOffset);
  final dayNum = shifted.weekday;
  final mondayShifted = DateTime.utc(
    shifted.year,
    shifted.month,
    shifted.day - (dayNum - 1),
  );
  return mondayShifted.subtract(wibOffset);
}

/// The current active WIB week's period id, for "what period should the
/// app be reading right now" — a thin, obviously-named wrapper around
/// [wibWeekId] so call sites read intent-first rather than repeating
/// `wibWeekId(DateTime.now().toUtc())` at every call site.
String currentWibPeriodId() => wibWeekId(DateTime.now().toUtc());

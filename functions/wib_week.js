/**
 * WIB (Asia/Jakarta, UTC+7, no daylight saving) — anchored ISO-8601-
 * style week id, for the weekly Top Global competition period.
 *
 * **Deliberately a new, separate module — `award_top_coins.js`'s own
 * `isoWeekId` is NOT modified or reused for this.** `isoWeekId`
 * computes week boundaries from raw UTC calendar dates; "Monday 00:00
 * WIB" is "Sunday 17:00 UTC the day before" — a 7-hour shift from
 * where `isoWeekId`'s own Monday-anchored math would place a UTC week
 * boundary. Reusing it unmodified would silently produce WIB-week
 * boundaries wrong by up to 7 hours. Confirmed via `grep -rln
 * "isoWeekId" functions/*.js` (excluding tests) that only
 * `award_top_coins.js` itself uses it — RISK-3's subscription backstop
 * uses no week-id concept at all (plain daily/weekly cron schedules) —
 * so `isoWeekId` is kept completely unmodified; nothing depends on
 * `wibWeekId` existing alongside it.
 *
 * The fixed `+7h` shift is exact and permanent here specifically
 * *because* WIB has no DST (Indonesia does not observe daylight
 * saving) — this trick is unsafe for a DST-observing zone and should
 * not be copied elsewhere without re-checking that assumption.
 */

/** WIB is a fixed UTC+7 offset, year-round — no DST to account for. */
const WIB_OFFSET_MS = 7 * 60 * 60 * 1000;

/**
 * ISO-week-numbered id (`YYYY-Www`) for the WIB week containing [date]
 * — the exact same string format `award_top_coins.js`'s `isoWeekId`
 * already uses, for consistency with the existing `weeklyCoinAwards/
 * {id}` convention, computed via the identical, already-proven
 * Monday-Thursday ISO-8601 anchor algorithm, just applied to the
 * WIB-shifted calendar date rather than the raw UTC one.
 *
 * The period boundary is a half-open interval: `[Monday 00:00:00.000
 * WIB, next Monday 00:00:00.000 WIB)` — the boundary instant itself
 * belongs to the period that is *starting*, not the one ending. This
 * falls out of the date-math itself (at exactly midnight WIB, the
 * shifted calendar date has already rolled to Monday) — no
 * special-casing needed.
 *
 * @param {Date} date the authoritative instant to resolve — callers
 *   must pass a server-derived timestamp (a Cloud Function trigger's
 *   own `event.time`, or an equivalent server clock read), never a
 *   client-supplied one. This function itself has no way to enforce
 *   that — it is a pure date-math utility — the caller's own choice of
 *   what `date` to pass is what makes the period identity
 *   server-authoritative or not.
 * @return {string} e.g. `"2026-W35"`
 */
function wibWeekId(date) {
  const shifted = new Date(date.getTime() + WIB_OFFSET_MS);
  const d = new Date(Date.UTC(
      shifted.getUTCFullYear(), shifted.getUTCMonth(), shifted.getUTCDate(),
  ));
  const dayNum = d.getUTCDay() || 7;
  d.setUTCDate(d.getUTCDate() + 4 - dayNum);
  const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
  const weekNum = Math.ceil((((d - yearStart) / 86400000) + 1) / 7);
  return `${d.getUTCFullYear()}-W${String(weekNum).padStart(2, "0")}`;
}

/**
 * The start instant (Monday 00:00:00.000 WIB, expressed as its real
 * UTC instant) of the WIB week containing [date] — used by the payout
 * job to derive period boundaries without re-deriving them from a
 * periodId string.
 *
 * @param {Date} date
 * @return {Date}
 */
function wibWeekStart(date) {
  const shifted = new Date(date.getTime() + WIB_OFFSET_MS);
  const dayNum = shifted.getUTCDay() || 7;
  const mondayShifted = new Date(Date.UTC(
      shifted.getUTCFullYear(), shifted.getUTCMonth(),
      shifted.getUTCDate() - (dayNum - 1),
  ));
  return new Date(mondayShifted.getTime() - WIB_OFFSET_MS);
}

module.exports = {WIB_OFFSET_MS, wibWeekId, wibWeekStart};

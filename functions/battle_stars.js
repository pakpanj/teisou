/**
 * Card Game Mode's star ladder — the promotion/demotion/streak/season
 * rules locked in `NOTES_CARD_GAME_MODE.md`'s "Tangga bintang" and
 * "Musim" sections, and the trigger that actually applies them when a
 * ranked match concludes.
 *
 * **This is server-only on purpose, and there is deliberately no Dart
 * copy of the ladder.** `battle_scoring.js` had to port RomajiConverter
 * because both sides genuinely need to convert kana; nothing on the
 * client needs to *decide* a star movement — it only needs to display
 * the rank the server wrote. A second implementation here would buy
 * nothing and could drift, which is exactly the cost that port already
 * pays once in this codebase.
 *
 * The client cannot write `cardGameRank` at all: `firestore.rules`
 * rejects any client write that changes it, so this function (running
 * with Admin SDK privileges, which bypass rules) is its only writer.
 * Without that lock the whole ladder would be decoration — a player
 * could set themselves to Emerald straight from the app.
 */

const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const {getFirestore} = require("firebase-admin/firestore");

const {BOT_UID} = require("./battle_bot");

function db() {
  return getFirestore();
}

// --- The ladder, as pure data ---

/** Climb order — also the promotion order. */
const TIERS = ["bronze", "silver", "gold", "diamond", "emerald"];

/** Stars that fill one division at each tier. Emerald has no divisions
 * (see [DIVISIONS_PER_TIER]) so it carries no entry here. */
const STARS_PER_DIVISION = {bronze: 3, silver: 4, gold: 5, diamond: 6};

/** Divisions V, IV, III, II, I — stored as 5 down to 1, so a *smaller*
 * number is a *higher* division, the same way the mockup draws them. */
const DIVISIONS_PER_TIER = 5;

/** Bronze and Silver never lose a star on a loss — "Bronze dan Silver
 * diberi perlindungan". Without this the ladder is a wall: at a 55% win
 * rate a flat +1/-1 needs roughly 360 matches to climb 36 stars. */
const LOSS_PROTECTED = new Set(["bronze", "silver"]);

/** How many times a single match may try to award its stars before it
 * is left alone — see the claim in `onBattleMatchConcluded`. */
const MAX_STAR_ATTEMPTS = 3;

/** Consecutive wins from which a win is worth +2 instead of +1. */
const STREAK_BONUS_AT = 3;

/** Seasons run two calendar months, counted from season 1 = Jan-Feb
 * 2026. Deriving the season from the date rather than storing a
 * "current season" document is what lets the rollover be lazy (see
 * [rollOverIfNewSeason]) instead of needing a scheduled function — this
 * project has no Cloud Scheduler set up, and a season boundary that
 * only takes effect when a player next plays is indistinguishable, from
 * that player's point of view, from one that fired at midnight. */
const SEASON_EPOCH_YEAR = 2026;
const SEASON_LENGTH_MONTHS = 2;

/** Fraction of a player's climbed stars carried into the next season —
 * "pemain memulai musim baru dengan 70% bintang terakhirnya". */
const SEASON_CARRY = 0.7;

/** Total stars standing at the very bottom of each tier, i.e. how far
 * up the whole 0-90 ladder that tier begins. */
function tierBase(tier) {
  let total = 0;
  for (const t of TIERS) {
    if (t === tier) return total;
    total += STARS_PER_DIVISION[t] * DIVISIONS_PER_TIER;
  }
  return total;
}

/** A rank collapsed to one number: how many stars have been climbed in
 * total, from Bronze V = 0 up. Everything below works on this number
 * rather than on (tier, division, stars) directly, because promotion,
 * demotion and the season's 70% carry are all just arithmetic on it —
 * expressed as three separate fields they need three special cases
 * each, and that is where an off-by-one hides. */
function totalStars(rank) {
  const base = tierBase(rank.tier);
  if (rank.tier === "emerald") return base + rank.stars;
  const perDivision = STARS_PER_DIVISION[rank.tier];
  const divisionsCleared = DIVISIONS_PER_TIER - rank.division;
  return base + divisionsCleared * perDivision + rank.stars;
}

/** The inverse of [totalStars]. Emerald has no ceiling — its stars just
 * accumulate ("bintang terus terkumpul"), so anything at or above its
 * base lands there. */
function rankFromTotal(total) {
  const clamped = Math.max(0, total);
  const emeraldBase = tierBase("emerald");
  if (clamped >= emeraldBase) {
    return {tier: "emerald", division: 1, stars: clamped - emeraldBase};
  }
  for (const tier of TIERS) {
    if (tier === "emerald") break;
    const perDivision = STARS_PER_DIVISION[tier];
    const span = perDivision * DIVISIONS_PER_TIER;
    const base = tierBase(tier);
    if (clamped < base + span) {
      const within = clamped - base;
      return {
        tier,
        division: DIVISIONS_PER_TIER - Math.floor(within / perDivision),
        stars: within % perDivision,
      };
    }
  }
  return {tier: "bronze", division: DIVISIONS_PER_TIER, stars: 0};
}

/** Which season [date] falls in. Dates before the epoch clamp to
 * season 1 rather than going negative — a device with a badly wrong
 * clock must not be able to invent season -4. */
function seasonForDate(date) {
  const months = (date.getUTCFullYear() - SEASON_EPOCH_YEAR) * 12 +
    date.getUTCMonth();
  if (months < 0) return 1;
  return Math.floor(months / SEASON_LENGTH_MONTHS) + 1;
}

/**
 * Carries a rank into [season] if it belongs to an older one, keeping
 * 70% of the stars climbed so far. Returns the rank unchanged when it
 * is already current, so this is safe to call on every match.
 *
 * The win streak is reset by a new season. The notes do not say either
 * way; a streak is momentum inside a season's own run of matches, and
 * carrying one across a two-month boundary would hand a returning
 * player a +2 win for something they did in a season that no longer
 * exists.
 */
function rollOverIfNewSeason(rank, season) {
  if (rank.season >= season) return rank;
  const carried = Math.round(totalStars(rank) * SEASON_CARRY);
  return Object.assign(rankFromTotal(carried), {season, winStreak: 0});
}

/**
 * The whole movement rule for one concluded ranked match.
 * [outcome] is `"win"`, `"loss"`, or `"draw"`.
 *
 * Returns the new rank plus the star delta actually applied, which is
 * not always the nominal delta: a loss at the very bottom of a tier is
 * absorbed by that tier's floor, and the result screen should say
 * "0" there rather than claim a star was lost that wasn't.
 *
 * **A win's bonus applies from the third consecutive win onward, not
 * only on exactly the third.** The notes say "beruntun 3 kemenangan
 * memberi +2 bintang" without settling what the fourth win is worth;
 * this reads it the way Mobile Legends does — which is the comparison
 * the notes themselves reach for — because the alternative (every third
 * win only) makes the bonus almost invisible at the top of the ladder,
 * which is the exact place it exists to unblock.
 *
 * **A draw leaves the streak alone** rather than breaking it: a draw is
 * not a defeat, and this mode's draws are common by design (a 10-card
 * match with a shared timer ends level often), so treating one as a
 * loss of momentum would punish the format rather than the player.
 */
function applyOutcome(rank, outcome) {
  const streak = outcome === "win" ? rank.winStreak + 1 :
    outcome === "loss" ? 0 : rank.winStreak;

  let delta = 0;
  if (outcome === "win") {
    delta = streak >= STREAK_BONUS_AT ? 2 : 1;
  } else if (outcome === "loss" && !LOSS_PROTECTED.has(rank.tier)) {
    delta = -1;
  }

  // "Tidak pernah keluar dari tingkat yang sudah dicapai" — a loss can
  // cost a division, but never the tier itself. The floor is this
  // tier's own bottom, so demotion stops at (for example) Gold V rather
  // than dropping into Silver I.
  const floor = tierBase(rank.tier);
  const before = totalStars(rank);
  const after = Math.max(floor, before + delta);

  return {
    rank: Object.assign(rankFromTotal(after), {
      season: rank.season,
      winStreak: streak,
    }),
    delta: after - before,
  };
}

// --- Firestore shape ---

function readRank(data) {
  const map = (data && data.cardGameRank) || {};
  return {
    tier: TIERS.includes(map.tier) ? map.tier : "bronze",
    division: typeof map.division === "number" ? map.division :
      DIVISIONS_PER_TIER,
    stars: typeof map.stars === "number" ? map.stars : 0,
    season: typeof map.season === "number" ? map.season : 1,
    winStreak: typeof map.winStreak === "number" ? map.winStreak : 0,
  };
}

function outcomeFor(uid, result) {
  if (result === "draw") return "draw";
  return result === uid ? "win" : "loss";
}

/**
 * Applies one concluded match to one player. Runs as its own
 * transaction per player rather than one transaction covering both,
 * because the two touch entirely separate documents and a retry caused
 * by one player's contention should not re-run the other's already
 * committed update.
 */
async function applyToPlayer(uid, result, season) {
  const userRef = db().collection("users").doc(uid);

  return db().runTransaction(async (transaction) => {
    const snap = await transaction.get(userRef);
    const current = rollOverIfNewSeason(readRank(snap.data()), season);
    const outcome = outcomeFor(uid, result);
    const applied = applyOutcome(current, outcome);

    transaction.set(userRef, {cardGameRank: applied.rank}, {merge: true});
    return Object.assign({before: current, outcome}, applied);
  });
}

/**
 * What the result screen needs to say what just happened, computed here
 * because only this function knows the standing *before* the match.
 *
 * The client could not work the delta out for itself without a second
 * copy of the ladder's arithmetic — the very duplication this file
 * exists to avoid — so it is handed the answer instead. Written onto the
 * match rather than the player: it describes one match, and a player who
 * finishes a second match before opening the first one's result would
 * otherwise see the wrong number.
 */
function summarize(applied) {
  const before = applied.before;
  const after = applied.rank;
  return {
    delta: applied.delta,
    tier: after.tier,
    division: after.division,
    stars: after.stars,
    winStreak: after.winStreak,
    // Distinguishes "promoted" from "moved within a division", so the
    // screen can celebrate the first and merely report the second.
    tierChanged: after.tier !== before.tier,
    divisionChanged: after.division !== before.division ||
      after.tier !== before.tier,
    // A loss that cost nothing, either because the tier is protected or
    // because the tier floor absorbed it — worth saying out loud, or a
    // player who lost and sees no change assumes it is broken.
    lossAbsorbed: applied.outcome === "loss" && applied.delta === 0,
  };
}

/**
 * Mirrors a player's standing onto their public `leaderboard/{uid}`
 * row — the "papan peringkat bintang berdiri sendiri" the notes
 * describe, which is deliberately extra fields on the existing document
 * rather than a new collection, so the name and avatar already kept in
 * step by `LeaderboardRepository.syncProfileInfo` come along for free.
 *
 * Best effort, and outside the transaction above on purpose: the
 * player's own rank is the source of truth, and a leaderboard row that
 * failed to update must never roll back a star the player really
 * earned. `starTotal` is stored flat because Firestore cannot `orderBy`
 * a value computed from three other fields — the same reason
 * `globalScore` is denormalized next to it.
 */
async function mirrorToLeaderboard(uid, rank) {
  try {
    await db().collection("leaderboard").doc(uid).set({
      cardGameTier: rank.tier,
      cardGameDivision: rank.division,
      cardGameStars: rank.stars,
      cardGameSeason: rank.season,
      cardGameStarTotal: totalStars(rank),
    }, {merge: true});
  } catch (_) {
    // Ignored deliberately — see the doc comment.
  }
}

/**
 * Fires on every write to a match and does nothing unless that write is
 * the one that concluded it. Deliberately watches `result` appearing
 * rather than hooking into `battle_scoring.js` where it is written:
 * that keeps scoring and ranking independent, and it means any future
 * path that concludes a match (a forfeit handled server-side, an
 * abandoned-match sweeper) moves stars without needing to remember to
 * call this.
 *
 * `starsApplied` is the idempotency guard. Cloud Functions v2 delivers
 * at least once, and this trigger also re-fires on its *own* write to
 * the match document, so without the flag a single concluded match
 * could hand out stars repeatedly.
 */
exports.onBattleMatchConcluded = onDocumentWritten(
    "battleMatches/{matchId}",
    async (event) => {
      const after = event.data.after;
      if (!after || !after.exists) return; // deleted
      const match = after.data();

      if (!match.result) return; // still running
      if (match.starsApplied) return; // already handled

      const before = event.data.before;
      const wasConcluded = before && before.exists && before.data().result;
      if (wasConcluded) return; // concluded by an earlier write

      const matchRef = db().collection("battleMatches")
          .doc(event.params.matchId);

      // Claim the match before touching any rank, so a duplicate
      // delivery that overlaps this one loses the race instead of
      // paying out twice.
      //
      // `starsAttempts` is what makes the claim recoverable. Claiming
      // first is necessary (two overlapping deliveries must not both pay
      // out) but it means a failure *after* the claim would otherwise
      // strand the match forever: every retry sees `starsApplied` and
      // returns, so the stars are never awarded and `starResult` never
      // appears — the result screen waits and then gives up. Observed
      // exactly once during testing before this guard existed. So a
      // failure clears the flag to let the next delivery try again,
      // bounded by the attempt count because clearing it is itself a
      // write to this document, which re-triggers this function: without
      // a bound, a persistently failing match would retry forever.
      const claimed = await db().runTransaction(async (transaction) => {
        const snap = await transaction.get(matchRef);
        const data = snap.data();
        if (!data || !data.result || data.starsApplied) return false;
        const attempts = data.starsAttempts || 0;
        if (attempts >= MAX_STAR_ATTEMPTS) return false;
        transaction.update(matchRef, {
          starsApplied: true,
          starsAttempts: attempts + 1,
        });
        return true;
      });
      if (!claimed) return;

      // Friend and clan matches never move stars: their card content is
      // chosen freely by the challenger, so ranking them would let a
      // player pick hiragana and climb to Emerald without ever meeting
      // a kanji. They are claimed above anyway, so the flag records
      // that this match was considered and settled.
      if (match.rankedMatch === false) return;

      const season = seasonForDate(new Date());
      const players = (match.players || []).filter((uid) => uid !== BOT_UID);

      try {
        const starResult = {};
        for (const uid of players) {
          const applied = await applyToPlayer(uid, match.result, season);
          starResult[uid] = summarize(applied);
          await mirrorToLeaderboard(uid, applied.rank);
        }

        // Written last, after every rank is safely committed, so a
        // screen that sees this field can trust the standing behind it.
        // Its absence is what the result screen shows "counting..." for.
        await matchRef.set({starResult}, {merge: true});
      } catch (error) {
        console.error("stars: failed, releasing claim", error);
        await matchRef.set({starsApplied: false}, {merge: true});
        throw error;
      }
    },
);

// Exported for tests only.
exports._internal = {
  TIERS,
  STARS_PER_DIVISION,
  DIVISIONS_PER_TIER,
  tierBase,
  totalStars,
  rankFromTotal,
  seasonForDate,
  rollOverIfNewSeason,
  applyOutcome,
  readRank,
  outcomeFor,
  summarize,
};

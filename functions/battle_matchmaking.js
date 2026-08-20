/**
 * Card Game Mode's public matchmaking queue — Tahap 3 butir 10 in
 * NOTES_CARD_GAME_MODE.md, "Pemasangan lawan publik". Reuses Realtime
 * Database (not a new Firestore collection) for the same reason
 * presence does: pairing two waiting players needs an **atomic claim**
 * ("take the two who've been waiting longest, remove both from the
 * queue at once"), which is exactly the operation RTDB transactions are
 * built for and Firestore has no equivalent primitive for without real
 * risk of two concurrent Cloud Function invocations both claiming the
 * same waiting player.
 *
 * Schema (see database.rules.json for the matching validation):
 *   matchmakingQueue/{tier}/{uid}: { joinedAt: <server time> }
 *   matchmakingResults/{uid}: { matchId: <string> }
 *
 * A client joins its own tier's queue by writing itself under
 * `matchmakingQueue/{tier}/{uid}` (see `MatchmakingRepository.joinQueue`
 * in the Flutter app). This trigger fires on `onValueCreated` — only a
 * brand-new child, never on the deletion this function's own claim
 * performs, so it cannot retrigger itself. It looks for another waiting
 * player in the same tier; if found, claims both atomically (removing
 * them from the queue), builds a fresh `battleMatches` doc exactly the
 * way the Flutter app's own `BattleRepository.createMatch` +
 * `buildTurnOrder` would (see the two ports below — kept in careful
 * lockstep with `battle_deck_builder.dart`/`battle_turn_order_builder.dart`,
 * the same "two copies, keep them in step by hand" situation this
 * project already accepted for `RomajiConverter` in battle_scoring.js),
 * and writes the resulting matchId to `matchmakingResults/{uid}` for
 * both players — the signal each waiting client's own listener is
 * watching for.
 *
 * If nobody else is waiting yet, this trigger simply does nothing —
 * the player who just joined waits, and it's whichever player joins
 * **next** into the same tier whose own trigger performs the actual
 * pairing. A client that gives up after its own 20-second timeout
 * (`NOTES_CARD_GAME_MODE.md`'s "usulan: 20 detik") removes itself from
 * the queue and falls back to a bot match through the exact same
 * `createMatch`-equivalent path `functions/battle_bot.js` already
 * handles — no code here needs to know about that fallback at all.
 */

const {onValueCreated} = require("firebase-functions/v2/database");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {getDatabase} = require("firebase-admin/database");

const kanaData = require("./data/kana_data.json");
const kanjiIdsByLevel = require("./data/kanji_ids_by_level.json");

function db() {
  return getFirestore();
}

function rtdb() {
  return getDatabase();
}

// --- Tier -> card content, mirroring card_game_rank.dart's CardGameTierX ---

const TIER_CONTENT = {
  bronze: "hiragana",
  silver: "katakanaAndKanaCombo",
  gold: "kanjiN5",
  diamond: "kanjiN4N3",
  emerald: "kanjiN2N1",
};

// --- Deck building — mirrors battle_deck_builder.dart's buildDeckIds ---

function poolFor(cardTierContent) {
  switch (cardTierContent) {
    case "hiragana":
      return kanaData
          .filter((k) => k.type === "hiragana" && k.row <= 10)
          .map((k) => k.id);
    case "katakanaAndKanaCombo":
      return kanaData
          .filter((k) =>
            k.type === "katakana" || (k.type === "hiragana" && k.row > 10))
          .map((k) => k.id);
    case "kanjiN5":
      return kanjiIdsByLevel.n5;
    case "kanjiN4N3":
      return [...kanjiIdsByLevel.n4, ...kanjiIdsByLevel.n3];
    case "kanjiN2N1":
      return [...kanjiIdsByLevel.n2, ...kanjiIdsByLevel.n1];
    default:
      return kanaData
          .filter((k) => k.type === "hiragana" && k.row <= 10)
          .map((k) => k.id);
  }
}

function shuffle(array, random) {
  const copy = [...array];
  for (let i = copy.length - 1; i > 0; i--) {
    const j = Math.floor(random() * (i + 1));
    [copy[i], copy[j]] = [copy[j], copy[i]];
  }
  return copy;
}

/** Throws if the matching pool has fewer than 20 entries — mirrors
 * buildDeckIds's own ArgumentError; should never happen against the
 * real bundled datasets (see that function's doc comment for why). */
function buildDeckIds(cardTierContent, random = Math.random) {
  const pool = poolFor(cardTierContent);
  if (pool.length < 20) {
    throw new Error(
        `card pool for ${cardTierContent} has only ${pool.length} entries, need at least 20`,
    );
  }
  return shuffle(pool, random).slice(0, 20);
}

// --- Turn order — mirrors battle_turn_order_builder.dart's buildTurnOrder ---

function buildTurnOrder(firstUid, firstDeck, secondUid, secondDeck, random = Math.random) {
  const firstPool = shuffle(firstDeck, random).slice(0, 10);
  const secondPool = shuffle(secondDeck, random).slice(0, 10);

  const entries = new Array(20);
  for (let i = 0; i < 10; i++) {
    entries[i * 2] = {round: i * 2, deckOwnerUid: firstUid, cardId: firstPool[i]};
    entries[i * 2 + 1] =
      {round: i * 2 + 1, deckOwnerUid: secondUid, cardId: secondPool[i]};
  }
  return entries;
}

// --- Pairing ---

/** Atomically claims another waiting uid (earliest joinedAt, not the
 * one who just triggered this) from `matchmakingQueue/{tier}`, removing
 * both from the queue in the same transaction. Returns the claimed uid,
 * or `null` if nobody else was waiting (or a concurrent claim already
 * took the only other candidate — the transaction's own retry-on-
 * conflict handles that race, per RTDB's normal guarantees). */
async function claimWaitingOpponent(tier, myUid) {
  const ref = rtdb().ref(`matchmakingQueue/${tier}`);
  let claimedUid = null;

  const result = await ref.transaction((current) => {
    claimedUid = null;
    if (!current) return current;

    let earliestUid = null;
    let earliestAt = null;
    for (const [uid, value] of Object.entries(current)) {
      if (uid === myUid) continue;
      if (!value || typeof value.joinedAt !== "number") continue;
      if (earliestAt === null || value.joinedAt < earliestAt) {
        earliestUid = uid;
        earliestAt = value.joinedAt;
      }
    }
    if (earliestUid === null) return current;

    claimedUid = earliestUid;
    const next = {...current};
    delete next[myUid];
    delete next[earliestUid];
    return next;
  });

  if (!result.committed) return null;
  return claimedUid;
}

async function createRankedMatch(firstUid, secondUid, cardTierContent) {
  const firstGoesFirst = Math.random() < 0.5;
  const firstDeck = buildDeckIds(cardTierContent);
  const secondDeck = buildDeckIds(cardTierContent);
  const turnOrder = firstGoesFirst ?
    buildTurnOrder(firstUid, firstDeck, secondUid, secondDeck) :
    buildTurnOrder(secondUid, secondDeck, firstUid, firstDeck);

  const matchRef = await db().collection("battleMatches").add({
    players: [firstUid, secondUid],
    status: "active",
    currentRound: 0,
    turnOrder,
    turnStartedAt: FieldValue.serverTimestamp(),
    // Written here as well as on the client path, because Firestore's
    // orderBy silently drops documents missing the field it sorts on:
    // without this, every publicly matched game is invisible to the
    // lobby's recent-matches list, and its result screen can compute no
    // duration either. Only bot and challenge matches, which the client
    // creates, had it.
    createdAt: FieldValue.serverTimestamp(),
    clientResult: null,
    officialScore: {[firstUid]: 0, [secondUid]: 0},
    result: null,
    scoredRounds: {},
    cardTierContent,
    rankedMatch: true,
  });
  return matchRef.id;
}

// A plain string ref (as every other trigger in this file's siblings
// uses for its own path) defaults an RTDB trigger's region to
// us-central1, which fails outright — confirmed by deploy error
// "pattern cannot match any databases in region us-central1" — since
// this project's Realtime Database instance lives in asia-southeast1
// (see PresenceService's own doc comment / firebase_options.dart's
// databaseURL), the same region every other Cloud Function here
// already deploys to. Unlike Firestore triggers, which infer their
// region from where the Firestore database itself lives, an RTDB
// trigger needs both the region and the instance name spelled out
// explicitly.
exports.onMatchmakingQueueJoined = onValueCreated(
    {
      ref: "matchmakingQueue/{tier}/{uid}",
      region: "asia-southeast1",
      instance: "teisou-kana-master-default-rtdb",
    },
    async (event) => {
      const tier = event.params.tier;
      const myUid = event.params.uid;
      const cardTierContent = TIER_CONTENT[tier];
      if (!cardTierContent) return;

      const opponentUid = await claimWaitingOpponent(tier, myUid);
      if (!opponentUid) return;

      const matchId = await createRankedMatch(myUid, opponentUid, cardTierContent);

      await rtdb().ref(`matchmakingResults/${myUid}`).set({matchId});
      await rtdb().ref(`matchmakingResults/${opponentUid}`).set({matchId});
    },
);

exports._internal = {
  poolFor,
  shuffle,
  buildDeckIds,
  buildTurnOrder,
  claimWaitingOpponent,
  createRankedMatch,
  TIER_CONTENT,
};

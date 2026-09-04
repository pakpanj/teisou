import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../../core/firebase/firestore_paths.dart';
import '../../core/services/battle_turn_order_builder.dart';
import '../models/battle_answer.dart';
import '../models/battle_match.dart';
import '../models/card_game_rank.dart';

/// The sentinel opponent uid for a bot match — never a real Firebase Auth
/// uid (those are always 28-character random strings), so this can never
/// collide. See `functions/battle_bot.js` for the server-side half.
const battleBotUid = 'BOT';

/// Reads and writes `battleMatches/{matchId}` and its `answers`
/// subcollection — see `NOTES_CARD_GAME_MODE.md`'s "Bentuk data" /
/// "Detail penilaian Cloud Function" for the schema this implements.
///
/// **What this repository deliberately does not do**: it never writes
/// `officialScore` or `result` — those are Cloud-Function-only fields
/// (see `BattleMatch`'s own doc comment), and the scoring Cloud Function
/// itself hasn't been built yet (Tahap 2 butir 7 in the notes). It also
/// doesn't decide *which* cards go into a deck — [createMatch] takes
/// already-chosen card ids, leaving "which 20 cards for this player's
/// current tier" to whoever builds the match-start flow (Tahap 2 butir
/// 5), since that's a genuinely separate, not-yet-designed concern (see
/// the notes: `cardId` is referenced throughout only as an opaque
/// string, never pinned to a concrete source). And it doesn't yet handle
/// the timeout/forfeit-on-disconnect path ("kalau lawan menutup aplikasi
/// di tengah pertandingan") — that's tightly coupled to the match
/// screen's own timer UI and is deferred to when that screen is built.
class BattleRepository {
  final FirebaseFirestore _firestore;
  final Random _random;
  // Lazily resolved, same reasoning as `IapService._fx`: constructing a
  // `BattleRepository` (done eagerly, at provider-creation time) must
  // never require `Firebase.initializeApp()` to already have run — only
  // actually resolving/clearing an abandonment does.
  final FirebaseFunctions? _functionsOverride;
  FirebaseFunctions? _functions;
  FirebaseFunctions get _fx =>
      _functions ??= _functionsOverride ?? FirebaseFunctions.instance;

  BattleRepository({
    FirebaseFirestore? firestore,
    Random? random,
    FirebaseFunctions? functions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _random = random ?? Random(),
       _functionsOverride = functions;

  CollectionReference<Map<String, dynamic>> get _matches =>
      _firestore.collection(FirestorePaths.battleMatches);

  DocumentReference<Map<String, dynamic>> _matchDoc(String matchId) =>
      _matches.doc(matchId);

  CollectionReference<Map<String, dynamic>> _answers(String matchId) =>
      _matchDoc(matchId).collection(FirestorePaths.battleAnswers);

  /// Creates a fresh match: flips a coin for who plays round 0, builds
  /// the 20-round `turnOrder` via [buildTurnOrder], and writes the
  /// document. Returns the new match's id. Pass [battleBotUid] as
  /// [secondCandidateUid] (with any deck built from the same tier the
  /// human is at) for a bot match — the trigger in
  /// `functions/battle_bot.js` recognizes that sentinel and plays every
  /// turn it owns automatically; nothing else about match creation
  /// changes for a bot opponent.
  ///
  /// [rankedMatch] defaults to `true` (public/bot matches) — pass
  /// `false` for a friend/clan challenge started via `BattleInvite`,
  /// per `NOTES_CARD_GAME_MODE.md`'s "Kecuali lawan teman dan clan" —
  /// see `BattleMatch.rankedMatch`'s own doc comment for why.
  ///
  /// [awaitingAccept] marks the match as still waiting on an invited
  /// player — pass `true` for a friend/clan challenge, so neither side
  /// plays and the round clock stays parked until
  /// [respondToMatchInvite] starts it. Public and bot matches leave it
  /// `false`: there is nobody left to ask by the time they exist.
  Future<String> createMatch({
    required String firstCandidateUid,
    required List<String> firstCandidateDeck,
    required String secondCandidateUid,
    required List<String> secondCandidateDeck,
    required CardTierContent cardTierContent,
    bool rankedMatch = true,
    bool awaitingAccept = false,
  }) async {
    final firstGoesFirst = _random.nextBool();
    final firstUid = firstGoesFirst ? firstCandidateUid : secondCandidateUid;
    final firstDeck = firstGoesFirst
        ? firstCandidateDeck
        : secondCandidateDeck;
    final secondUid = firstGoesFirst ? secondCandidateUid : firstCandidateUid;
    final secondDeck = firstGoesFirst
        ? secondCandidateDeck
        : firstCandidateDeck;

    final turnOrder = buildTurnOrder(
      firstUid: firstUid,
      firstDeck: firstDeck,
      secondUid: secondUid,
      secondDeck: secondDeck,
      random: _random,
    );

    final match = BattleMatch(
      id: '',
      players: [firstCandidateUid, secondCandidateUid],
      status: BattleMatchStatus.active,
      currentRound: 0,
      turnOrder: turnOrder,
      officialScore: {firstCandidateUid: 0, secondCandidateUid: 0},
      cardTierContent: cardTierContent,
      rankedMatch: rankedMatch,
      // Both full hands travel with the match so each device can show
      // its own player what they still hold to choose from.
      decks: {
        firstCandidateUid: firstCandidateDeck,
        secondCandidateUid: secondCandidateDeck,
      },
      inviteState: awaitingAccept
          ? BattleInviteState.pending
          : BattleInviteState.none,
    );

    final docRef = await _matches.add(match.toCreateMap());
    return docRef.id;
  }

  /// Answers a friend/clan challenge on the match itself, and — on an
  /// accept — starts the round clock.
  ///
  /// Returns `false` when the match was no longer waiting on an answer,
  /// which is the whole reason this is a transaction rather than a plain
  /// `update`. Two people can act on the same challenge at the same
  /// moment: the invited player taps Terima while the challenger, tired
  /// of waiting, taps Batal. Whoever's write lands second would
  /// otherwise overwrite the first, and the two devices would disagree
  /// about whether a match is happening — one sitting in an arena, the
  /// other back on the friend list. First write wins; the loser is told
  /// so and can say something useful instead of opening a match nobody
  /// else is in.
  ///
  /// The clock is (re)started here rather than at creation because a
  /// challenge can sit unanswered for up to two minutes. Left running
  /// from creation, a slow "yes" would drop both players straight into a
  /// round that had already timed out — which is exactly what the old
  /// straight-into-the-match flow did.
  Future<bool> respondToMatchInvite({
    required String matchId,
    required bool accept,
  }) {
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(_matchDoc(matchId));
      final data = snapshot.data();
      if (data == null) return false;
      final state = BattleInviteStateX.fromKey(data['inviteState'] as String?);
      if (state != BattleInviteState.pending) return false;

      transaction.update(_matchDoc(matchId), {
        'inviteState': (accept
                ? BattleInviteState.accepted
                : BattleInviteState.declined)
            .key,
        if (accept) 'turnStartedAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
  }

  Stream<BattleMatch> watchMatch(String matchId) {
    return _matchDoc(
      matchId,
    ).snapshots().map((snapshot) => BattleMatch.fromMap(matchId, snapshot.data()!));
  }

  /// The most recent matches [uid] played, newest first.
  ///
  /// `players` is a list, so `array-contains` finds them without any extra
  /// field — and `firestore.rules` already restricts reads on this
  /// collection to `request.auth.uid in resource.data.players`, so the
  /// query can only ever return this player's own matches. Nothing deletes
  /// finished matches, so this reaches all the way back.
  ///
  /// **Needs a composite index** (`players` array-contains + `createdAt`
  /// descending). Firestore refuses the query until it exists and puts a
  /// link to create it in the error, so a missing index shows up as an
  /// empty list here rather than a broken screen.
  ///
  /// One-shot rather than a live listener: a finished match never changes
  /// again, so there is nothing to listen for — the same reasoning the
  /// clan ranking already uses.
  Future<List<BattleMatch>> recentMatches(String uid, {int limit = 5}) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.battleMatches)
        .where('players', arrayContains: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return [
      for (final doc in snapshot.docs) BattleMatch.fromMap(doc.id, doc.data()),
    ];
  }

  Future<BattleMatch?> getMatch(String matchId) async {
    final snapshot = await _matchDoc(matchId).get();
    final data = snapshot.data();
    if (data == null) return null;
    return BattleMatch.fromMap(matchId, data);
  }

  /// Records the card its owner chose to play for [round].
  ///
  /// Only ever *adds* to `playedCards`; the round's dealt card stays in
  /// `turnOrder` untouched as the fallback for an owner who runs out of
  /// choosing time. Guarded by the same "has the turn already moved on"
  /// transaction check every other write here uses, so a choice that
  /// arrives a moment too late is dropped rather than landing on the
  /// wrong round.
  Future<void> playCard({
    required String matchId,
    required int round,
    required String cardId,
  }) async {
    final matchRef = _matchDoc(matchId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(matchRef);
      final data = snapshot.data();
      if (data == null) return;
      if ((data['currentRound'] as int? ?? 0) != round) return;
      final played = Map<String, dynamic>.from(
        data['playedCards'] as Map? ?? const {},
      );
      // First choice wins: without this a second write could swap the
      // card after the opponent has already seen it.
      if (played.containsKey('$round')) return;
      transaction.update(matchRef, {'playedCards.$round': cardId});
    });
  }

  /// Submits [byUid]'s answer for [round] and advances the turn in one
  /// transaction. Guards against a race where the turn has *already*
  /// moved past [round] by the time this runs (e.g. a timeout-forced
  /// advance beat this answer to the write) — in that case the answer
  /// is silently dropped rather than double-advancing the turn, since
  /// whichever write landed first is the one that counts.
  Future<void> submitAnswer({
    required String matchId,
    required int round,
    required String byUid,
    required String text,
  }) async {
    final matchRef = _matchDoc(matchId);
    final answerRef = _answers(matchId).doc('$round');

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(matchRef);
      final data = snapshot.data();
      if (data == null) return;
      final currentRound = data['currentRound'] as int? ?? 0;
      if (currentRound != round) return;

      transaction.set(
        answerRef,
        BattleAnswer(byUid: byUid, text: text).toMap(),
      );
      transaction.update(matchRef, {
        'currentRound': round + 1,
        'turnStartedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Called by the **waiting** player (never the one who was actually
  /// supposed to answer) once a round's timer runs out with nothing
  /// submitted — see `NOTES_CARD_GAME_MODE.md`'s "Kalau lawan menutup
  /// aplikasi di tengah pertandingan". Writes an empty answer (counted
  /// as a loss for [answererUid]) and advances the turn — same
  /// transaction and race-guard as [submitAnswer], since this is really
  /// just that method called on someone else's behalf.
  Future<void> forfeitRoundOnTimeout({
    required String matchId,
    required int round,
    required String answererUid,
  }) {
    return submitAnswer(
      matchId: matchId,
      round: round,
      byUid: answererUid,
      text: '',
    );
  }

  /// Computed locally the moment a client notices the match conclude
  /// (see `BattleMatch.clientResult`'s own doc comment) — purely for an
  /// instant "match over" screen, never read for anything that moves
  /// stars.
  Future<void> setClientResult(String matchId, String result) {
    return _matchDoc(matchId).update({'clientResult': result});
  }

  Future<BattleAnswer?> getAnswer(String matchId, int round) async {
    final snapshot = await _answers(matchId).doc('$round').get();
    final data = snapshot.data();
    if (data == null) return null;
    return BattleAnswer.fromMap(data);
  }

  /// Every answer submitted so far, keyed by round — used to build a
  /// running local score tally (see `battle_score_tally.dart`) as the
  /// match progresses, without watching each round's doc one at a time.
  Stream<Map<int, BattleAnswer>> watchAllAnswers(String matchId) {
    return _answers(matchId).snapshots().map((snapshot) {
      final map = <int, BattleAnswer>{};
      for (final doc in snapshot.docs) {
        final round = int.tryParse(doc.id);
        if (round == null) continue;
        map[round] = BattleAnswer.fromMap(doc.data());
      }
      return map;
    });
  }

  Stream<BattleAnswer?> watchAnswer(String matchId, int round) {
    return _answers(matchId).doc('$round').snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return null;
      return BattleAnswer.fromMap(data);
    });
  }

  // -------------------------------------------------------------------
  // Two-sided absence / pause system (2026-08-30, generalized 2026-09) —
  // see `BattleMatch.absence`'s own doc comment for the full mechanism.
  // -------------------------------------------------------------------

  /// Marks [uid] as having just left [matchId] — the server timestamp
  /// this writes is what their own 30-second grace period counts down
  /// from. A transaction, not a plain merge write: it has to read the
  /// current `absence` map first, both to avoid clobbering the
  /// *opponent's* own entry if they happen to already be marked away
  /// too, and to refuse to act at all once the match is no longer
  /// `active` (a `finished`/`abandoned` match must never be reopened
  /// into a paused one by a straggling leave-write landing late).
  ///
  /// **Best-effort by design, never allowed to throw into a caller.**
  /// This is fired from places that cannot usefully await a failure —
  /// `dispose()`, an app-lifecycle callback — and `firestore.rules`
  /// itself will legitimately reject this write in cases that are not
  /// bugs (the match already concluded, or this exact uid already has an
  /// entry from an earlier, still-pending leave). A rejected write here
  /// simply means the older mechanism (`functions/battle_abandonment_sweep.js`'s
  /// pre-existing per-round staleness sweep) is still watching, same as
  /// it always has been.
  Future<void> markAbsent(String matchId, String uid) async {
    try {
      final matchRef = _matchDoc(matchId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(matchRef);
        final data = snapshot.data();
        if (data == null) return;
        if ((data['status'] as String? ?? 'active') != 'active') return;
        final absence = Map<String, dynamic>.from(
          data['absence'] as Map? ?? const {},
        );
        if (absence.containsKey(uid)) return; // already marked, don't refresh
        absence[uid] = {'since': FieldValue.serverTimestamp()};
        transaction.update(matchRef, {'absence': absence});
      });
    } catch (e) {
      // See doc comment — a failed mark is not a crash, just a missed
      // fast path. Logged (not surfaced) so a real regression here is
      // at least visible in a debug session instead of indistinguishable
      // from "nobody left" — this call has no other observable effect
      // when it fails.
      debugPrint('markAbsent($matchId, $uid) failed: $e');
    }
  }

  /// Clears [uid]'s own absence mark on return — "I'm back". A
  /// transaction for the same reason [markAbsent] is one, plus one more:
  /// when clearing this uid's key empties the `absence` map entirely
  /// (the *other* player, if they were ever away at all, is already
  /// back too), this also refreshes `turnStartedAt` in the same write —
  /// see [BattleMatch.isPaused]'s own doc comment for why resuming must
  /// give the round a fresh full budget rather than picking up wherever
  /// the clock happened to be when the pause began.
  ///
  /// Best-effort for the same reason [markAbsent] is: called from a
  /// screen's own `initState`/app-resume path, where nothing useful can
  /// be done with a thrown error, and `firestore.rules` already refuses
  /// this exact write once the match has actually concluded (every
  /// grace period involved ran out before this call landed) — that is
  /// the correct outcome, not a bug to surface.
  Future<void> clearAbsence(String matchId, String uid) async {
    try {
      final matchRef = _matchDoc(matchId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(matchRef);
        final data = snapshot.data();
        if (data == null) return;
        final absence = Map<String, dynamic>.from(
          data['absence'] as Map? ?? const {},
        );
        if (!absence.containsKey(uid)) return; // nothing to clear
        absence.remove(uid);
        final updates = <String, dynamic>{'absence': absence};
        if (absence.isEmpty) {
          // Everyone is present again — the round that was frozen mid-
          // pause gets a fresh full budget rather than resuming a clock
          // that may have already run out while nobody could act on it.
          updates['turnStartedAt'] = FieldValue.serverTimestamp();
        }
        transaction.update(matchRef, updates);
      });
    } catch (e) {
      // See doc comment.
      debugPrint('clearAbsence($matchId, $uid) failed: $e');
    }
  }

  /// Asks the server whether [matchId]'s grace period is actually up
  /// yet, and finalizes it (the abandoning player loses) if so — see
  /// `functions/battle_abandonment_sweep.js`'s `resolveBattleAbandonment`
  /// for the authoritative check this performs; nothing about *when*
  /// the match actually ends is decided here on the client, only when to
  /// ask. Safe to call early, call twice, or call for a match with no
  /// abandon marker at all — every one of those is a defined, harmless
  /// no-op server-side (see that function's own doc comment).
  ///
  /// Returns `true` once the server confirms it actually finalized the
  /// match this call, `false` for every other outcome (not due yet, the
  /// player already reconnected, the match already concluded some other
  /// way).
  Future<bool> resolveAbandonmentIfDue(String matchId) async {
    try {
      final result = await _fx
          .httpsCallable('resolveBattleAbandonment')
          .call({'matchId': matchId});
      final data = result.data;
      return data is Map && data['finalized'] == true;
    } catch (_) {
      // A network hiccup here just means the opponent's next countdown
      // tick (or the server-side sweep backstop) tries again.
      return false;
    }
  }

  /// The match [uid] can still resume — the one behind the Card Game
  /// lobby's "Kembali ke Pertandingan" card.
  ///
  /// **Deliberately its own query, not a slice of [recentMatches].**
  /// An earlier version reused [recentMatches]' last-5-overall list and
  /// filtered it client-side — which meant a match that was still
  /// genuinely open became permanently invisible to this card the
  /// moment 5 *newer* matches existed of any kind (finished, declined,
  /// bot games), since it had already fallen out of that window.
  /// Confirmed to reproduce in real testing, not just in theory — see
  /// the audit this fixed.
  ///
  /// Filters server-side on `status` (an equality clause Firestore can
  /// combine with `players`/`createdAt`), then narrows to
  /// [BattleMatch.isResumable] client-side for `result`/`inviteState`/age
  /// — Firestore can't express those as further clauses on the same
  /// query without another composite index each, and the number of
  /// simultaneously `active` matches for one player is expected to
  /// stay small regardless. The age check
  /// (`kBattleResumableMaxAge`, AUDIT_ARSITEKTUR_PRESENCE_LIFECYCLE_MODE_KARTU.md's
  /// M3) does not reopen the "no limit()" reasoning below — it is a
  /// per-document semantic check ("is this one still plausibly live"),
  /// not a count-based window a genuinely fresh match could ever fall
  /// out of.
  ///
  /// **Needs a new composite index**: `players` (array-contains) +
  /// `status` (==) + `createdAt` (desc) — see `firestore.indexes.json`.
  /// Not yet deployed; this file being correct is not the same as the
  /// index being live (same standing caveat every entry in that file
  /// already carries).
  ///
  /// [createMatch] has no guard against a player already holding
  /// another active match, so more than one truly resumable match can
  /// exist for the same uid at once — this is not assumed away.
  /// `orderBy('createdAt', descending: true)` makes the pick
  /// deterministic rather than arbitrary in that case: the newest one
  /// wins, i.e. whichever match this player left most recently.
  ///
  /// Deliberately no `limit()` here. A cap — any cap, 5 or 50 — reopens
  /// the exact bug this query replaced: a genuinely resumable match
  /// aging out of an arbitrary "N most recent active" window once
  /// enough other active matches exist. `status == active` already
  /// bounds the result to matches that are actually still open, which
  /// is the only bound this query should have.
  Future<BattleMatch?> findResumableMatch(String uid) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.battleMatches)
        .where('players', arrayContains: uid)
        .where('status', isEqualTo: BattleMatchStatus.active.key)
        .orderBy('createdAt', descending: true)
        .get();
    for (final doc in snapshot.docs) {
      final match = BattleMatch.fromMap(doc.id, doc.data());
      if (match.isResumable(uid: uid)) return match;
    }
    return null;
  }
}

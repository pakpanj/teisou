import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

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

  BattleRepository({FirebaseFirestore? firestore, Random? random})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _random = random ?? Random();

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
  Future<String> createMatch({
    required String firstCandidateUid,
    required List<String> firstCandidateDeck,
    required String secondCandidateUid,
    required List<String> secondCandidateDeck,
    required CardTierContent cardTierContent,
    bool rankedMatch = true,
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
    );

    final docRef = await _matches.add(match.toCreateMap());
    return docRef.id;
  }

  Stream<BattleMatch> watchMatch(String matchId) {
    return _matchDoc(
      matchId,
    ).snapshots().map((snapshot) => BattleMatch.fromMap(matchId, snapshot.data()!));
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
}

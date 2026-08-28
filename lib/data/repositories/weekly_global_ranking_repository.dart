import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase/firestore_paths.dart';
import '../../core/utils/wib_week.dart';
import '../models/weekly_period_standing.dart';

/// Read-only access to the Weekly Global Ranking's period-scoped
/// standings and historical payout records — see
/// `functions/award_top_coins.js`'s own top-of-file doc comment for the
/// full design (this is the P0-fix payout ranking source, distinct from
/// both [FirestorePaths.leaderboard]'s `globalScore` and `globalPoints`
/// fields, which remain unchanged and untouched by this repository).
///
/// **Genuinely a separate repository from `LeaderboardRepository`, not a
/// method bolted onto it** — matching this codebase's own established
/// convention of a dedicated model/repository per genuinely distinct
/// concern (see `CLAUDE.md`'s own "own model/repository/screens trio"
/// note, applied here to a data source rather than a full module). The
/// weekly period documents have an entirely different shape from
/// [LeaderboardEntry] (no display fields, no avatar, no historical
/// `globalScore`/`globalPoints`) and a different write authority
/// (`global_points.js`'s live trigger, not the leaderboard-sync call
/// sites `LeaderboardRepository` already owns).
///
/// **Every method here is read-only by construction** — there is no
/// `set`/`update`/`create` method anywhere in this class, because there
/// is no legitimate client write path to either collection at all
/// (`firestore.rules` denies every client write unconditionally). This
/// isn't an oversight to fill in later.
class WeeklyGlobalRankingRepository {
  final FirebaseFirestore _firestore;

  WeeklyGlobalRankingRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _periodUsersCollection(
    String periodId,
  ) => _firestore.collection(
    FirestorePaths.globalScorePeriodUsersCollection(periodId),
  );

  /// The top [limit] standings for [periodId], in the exact deterministic
  /// order `functions/award_top_coins.js`'s `awardTopGlobalCoinsOnce`
  /// pays out by: points DESC, then attempts DESC, then uid (document id)
  /// ASC. Matching this ordering exactly means "who the app shows in
  /// 1st/2nd/3rd this week" and "who the payout actually pays" can never
  /// quietly disagree — the same guarantee this app's `globalPoints`
  /// Top Global ranking already established for its own metric.
  Future<List<WeeklyPeriodStanding>> getTopForPeriod(
    String periodId, {
    int limit = 20,
  }) async {
    final snapshot = await _periodUsersCollection(periodId)
        .orderBy('points', descending: true)
        .orderBy('attempts', descending: true)
        .orderBy(FieldPath.documentId)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => WeeklyPeriodStanding.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// The top standings for the CURRENT active WIB week — see
  /// `wib_week.dart`'s own doc comment on why the client-computed period
  /// id is safe to use for a read (it only decides which already-written
  /// document to fetch; it never influences scoring or ranking, both of
  /// which are entirely server-side).
  Future<List<WeeklyPeriodStanding>> getCurrentPeriodTop({
    int limit = 20,
  }) => getTopForPeriod(currentWibPeriodId(), limit: limit);

  /// A live view of [getTopForPeriod] — mirrors
  /// `LeaderboardRepository.watchTop`'s own `.snapshots()` pattern.
  Stream<List<WeeklyPeriodStanding>> watchTopForPeriod(
    String periodId, {
    int limit = 20,
  }) {
    return _periodUsersCollection(periodId)
        .orderBy('points', descending: true)
        .orderBy('attempts', descending: true)
        .orderBy(FieldPath.documentId)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => WeeklyPeriodStanding.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// [uid]'s own standing within [periodId], or `null` if they have not
  /// yet earned any points this period (the document simply doesn't
  /// exist until their first attempt in that period is processed —
  /// matching every other progress/standing lookup in this app's own
  /// "absence, not a gap to repair" convention, e.g.
  /// `LeaderboardRepository.watchTopByCardGameStars`'s own doc comment).
  Future<WeeklyPeriodStanding?> getSelfStanding(
    String uid, {
    String? periodId,
  }) async {
    final resolvedPeriodId = periodId ?? currentWibPeriodId();
    final doc = await _periodUsersCollection(resolvedPeriodId).doc(uid).get();
    final data = doc.data();
    if (data == null) return null;
    return WeeklyPeriodStanding.fromMap(doc.id, data);
  }

  /// This [uid]'s 1-based rank within [periodId] (or the current period,
  /// if omitted) — `null` if they have no standing to rank at all this
  /// period. Mirrors `LeaderboardRepository.rankOf`'s own
  /// count-strictly-greater-then-add-one approach, extended with the
  /// same three-level tie-break the payout itself uses so a displayed
  /// rank never disagrees with the deterministic payout order.
  Future<int?> rankOf(String uid, {String? periodId}) async {
    final resolvedPeriodId = periodId ?? currentWibPeriodId();
    final self = await getSelfStanding(uid, periodId: resolvedPeriodId);
    if (self == null) return null;

    final strictlyHigherPoints = await _periodUsersCollection(
      resolvedPeriodId,
    ).where('points', isGreaterThan: self.points).count().get();

    final tiedPointsHigherAttempts = await _periodUsersCollection(
          resolvedPeriodId,
        )
        .where('points', isEqualTo: self.points)
        .where('attempts', isGreaterThan: self.attempts)
        .count()
        .get();

    final tiedPointsAndAttemptsLowerUid = await _periodUsersCollection(
          resolvedPeriodId,
        )
        .where('points', isEqualTo: self.points)
        .where('attempts', isEqualTo: self.attempts)
        .where(FieldPath.documentId, isLessThan: uid)
        .count()
        .get();

    final higher =
        (strictlyHigherPoints.count ?? 0) +
        (tiedPointsHigherAttempts.count ?? 0) +
        (tiedPointsAndAttemptsLowerUid.count ?? 0);
    return higher + 1;
  }

  /// The historical payout record for a closed period, or `null` if that
  /// period has not been paid out yet (still open, or the payout job
  /// hasn't run for it) — `globalScorePeriodAwards/{periodId}`, written
  /// only by `functions/award_top_coins.js`'s `awardTopGlobalCoinsOnce`.
  Future<Map<String, dynamic>?> getPayoutRecord(String periodId) async {
    final doc = await _firestore
        .doc(FirestorePaths.globalScorePeriodAwardDoc(periodId))
        .get();
    return doc.data();
  }
}

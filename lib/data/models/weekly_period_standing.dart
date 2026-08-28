/// One user's standing within a single Weekly Global Ranking period —
/// `globalScorePeriods/{periodId}/users/{uid}`, written **only** by
/// `functions/global_points.js`'s `awardPointsForHistoryDoc` transaction
/// (`firestore.rules` denies every client write to this collection
/// unconditionally — see that file's own doc comment). Deliberately a
/// separate, minimal model from [LeaderboardEntry]: this document carries
/// none of [LeaderboardEntry]'s display fields (name, avatar, ...) by
/// design — see `functions/global_points.js`'s own comment on why no
/// client-controlled value is stored here, only server-computed deltas
/// and server-derived identifiers.
class WeeklyPeriodStanding {
  final String uid;
  final String periodId;
  final double points;
  final int attempts;

  const WeeklyPeriodStanding({
    required this.uid,
    required this.periodId,
    required this.points,
    required this.attempts,
  });

  /// [docId] is the Firestore document's own id (always equal to [uid],
  /// since the server writes this doc at `.../users/{uid}`) — passed
  /// separately from [data] rather than read out of it, so a standing can
  /// still be constructed correctly even if a future write ever omitted
  /// the redundant `uid` field from the document body.
  factory WeeklyPeriodStanding.fromMap(
    String docId,
    Map<String, dynamic> data,
  ) {
    final rawPoints = data['points'];
    final rawAttempts = data['attempts'];
    return WeeklyPeriodStanding(
      uid: docId,
      periodId: data['periodId'] as String? ?? '',
      points: rawPoints is num ? rawPoints.toDouble() : 0,
      attempts: rawAttempts is num ? rawAttempts.toInt() : 0,
    );
  }
}

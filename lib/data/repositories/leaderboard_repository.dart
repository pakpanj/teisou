import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase/firestore_paths.dart';
import '../models/leaderboard_entry.dart';

enum LeaderboardMetric { totalMastered, examHighScore }

extension LeaderboardMetricX on LeaderboardMetric {
  String get field =>
      this == LeaderboardMetric.totalMastered ? 'totalMastered' : 'examHighScore';
}

/// Reads/writes the top-level `leaderboard` collection (one doc per user,
/// keyed by uid — separate from the private `users/{uid}` document).
class LeaderboardRepository {
  final FirebaseFirestore _firestore;

  LeaderboardRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.leaderboard);

  Stream<List<LeaderboardEntry>> watchTop(
    LeaderboardMetric metric, {
    int limit = 20,
  }) {
    return _collection
        .orderBy(metric.field, descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LeaderboardEntry.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<LeaderboardEntry?> getSelf(String uid) async {
    final doc = await _collection.doc(uid).get();
    if (!doc.exists) return null;
    return LeaderboardEntry.fromMap(doc.id, doc.data()!);
  }

  /// Ranks [uid] within [metric]'s ordering (1-based). Returns null if the
  /// user has no leaderboard entry yet.
  Future<int?> getRank(String uid, LeaderboardMetric metric) async {
    final self = await getSelf(uid);
    if (self == null) return null;
    final value = metric == LeaderboardMetric.totalMastered
        ? self.totalMastered
        : self.examHighScore;
    final higher = await _collection.where(metric.field, isGreaterThan: value).count().get();
    return (higher.count ?? 0) + 1;
  }

  /// Updates `totalMastered` for [uid] if [totalMastered] is higher than
  /// what's currently stored (never regresses the leaderboard on a
  /// mastery -> learning demotion elsewhere).
  Future<void> updateTotalMastered({
    required String uid,
    required String displayName,
    String? photoUrl,
    required int totalMastered,
  }) async {
    final existing = await getSelf(uid);
    if (existing != null && existing.totalMastered >= totalMastered) {
      return;
    }
    await _collection.doc(uid).set({
      'displayName': displayName,
      'photoUrl': photoUrl,
      'totalMastered': totalMastered,
      'examHighScore': existing?.examHighScore ?? 0,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Updates `examHighScore` for [uid] only if [score] beats the existing
  /// high score.
  Future<void> updateExamHighScoreIfHigher({
    required String uid,
    required String displayName,
    String? photoUrl,
    required int score,
  }) async {
    final existing = await getSelf(uid);
    if (existing != null && existing.examHighScore >= score) {
      return;
    }
    await _collection.doc(uid).set({
      'displayName': displayName,
      'photoUrl': photoUrl,
      'totalMastered': existing?.totalMastered ?? 0,
      'examHighScore': score,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

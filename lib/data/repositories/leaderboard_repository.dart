import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase/firestore_paths.dart';
import '../models/leaderboard_entry.dart';
import '../models/user_profile.dart' show AvatarType, AvatarTypeX;

enum LeaderboardMetric {
  totalMastered,
  examHighScore,
  kanaRecord,
  dokkaiRecord,
  choukaiRecord,
  kanjiComboRecord,
}

extension LeaderboardMetricX on LeaderboardMetric {
  String get field {
    switch (this) {
      case LeaderboardMetric.totalMastered:
        return 'totalMastered';
      case LeaderboardMetric.examHighScore:
        return 'examHighScore';
      case LeaderboardMetric.kanaRecord:
        return 'kanaRecordAvg';
      case LeaderboardMetric.dokkaiRecord:
        return 'dokkaiRecordAvg';
      case LeaderboardMetric.choukaiRecord:
        return 'choukaiRecordAvg';
      case LeaderboardMetric.kanjiComboRecord:
        return 'kanjiComboRecordAvg';
    }
  }
}

/// The four exam categories that each earn their own "Rekor" (average
/// score-percentage across every attempt) — see [LeaderboardRepository.
/// updateCategoryRecord]. Kept separate from [LeaderboardMetric] since a
/// metric is a *leaderboard tab selector* (includes non-exam metrics like
/// `totalMastered`) while a category is specifically "which exam type is
/// this attempt for".
enum LeaderboardCategory { kana, dokkai, choukai, kanjiCombo }

extension LeaderboardCategoryX on LeaderboardCategory {
  String get key {
    switch (this) {
      case LeaderboardCategory.kana:
        return 'kana';
      case LeaderboardCategory.dokkai:
        return 'dokkai';
      case LeaderboardCategory.choukai:
        return 'choukai';
      case LeaderboardCategory.kanjiCombo:
        return 'kanjiCombo';
    }
  }
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

  num _valueFor(LeaderboardEntry entry, LeaderboardMetric metric) {
    switch (metric) {
      case LeaderboardMetric.totalMastered:
        return entry.totalMastered;
      case LeaderboardMetric.examHighScore:
        return entry.examHighScore;
      case LeaderboardMetric.kanaRecord:
        return entry.kanaRecordAvg;
      case LeaderboardMetric.dokkaiRecord:
        return entry.dokkaiRecordAvg;
      case LeaderboardMetric.choukaiRecord:
        return entry.choukaiRecordAvg;
      case LeaderboardMetric.kanjiComboRecord:
        return entry.kanjiComboRecordAvg;
    }
  }

  /// Ranks [uid] within [metric]'s ordering (1-based). Returns null if the
  /// user has no leaderboard entry yet.
  Future<int?> getRank(String uid, LeaderboardMetric metric) async {
    final self = await getSelf(uid);
    if (self == null) return null;
    final value = _valueFor(self, metric);
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
    AvatarType avatarType = AvatarType.google,
    String? avatarValue,
    required int totalMastered,
  }) async {
    final existing = await getSelf(uid);
    if (existing != null && existing.totalMastered >= totalMastered) {
      return;
    }
    await _collection.doc(uid).set({
      'displayName': displayName,
      'photoUrl': photoUrl,
      'avatarType': avatarType.key,
      'avatarValue': avatarValue,
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
    AvatarType avatarType = AvatarType.google,
    String? avatarValue,
    required int score,
  }) async {
    final existing = await getSelf(uid);
    if (existing != null && existing.examHighScore >= score) {
      return;
    }
    await _collection.doc(uid).set({
      'displayName': displayName,
      'photoUrl': photoUrl,
      'avatarType': avatarType.key,
      'avatarValue': avatarValue,
      'totalMastered': existing?.totalMastered ?? 0,
      'examHighScore': score,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Folds one exam attempt's score-percentage into [category]'s running
  /// "Rekor" average for [uid] — `sum`/`count` are kept alongside the
  /// derived `avg` (the only field actually queried/sorted by, since
  /// Firestore can't `orderBy` a computed ratio of two fields) so the
  /// average can be recomputed here without re-reading the full attempt
  /// history. Read-then-write like [updateTotalMastered]/
  /// [updateExamHighScoreIfHigher] above — not transactional, same accepted
  /// trade-off already made for those two.
  Future<void> updateCategoryRecord({
    required String uid,
    required String displayName,
    String? photoUrl,
    AvatarType avatarType = AvatarType.google,
    String? avatarValue,
    required LeaderboardCategory category,
    required double percentage,
  }) async {
    final existing = await getSelf(uid);
    final newSum = (existing?.recordSumFor(category) ?? 0.0) + percentage;
    final newCount = (existing?.recordCountFor(category) ?? 0) + 1;
    await _collection.doc(uid).set({
      'displayName': displayName,
      'photoUrl': photoUrl,
      'avatarType': avatarType.key,
      'avatarValue': avatarValue,
      '${category.key}RecordSum': newSum,
      '${category.key}RecordCount': newCount,
      '${category.key}RecordAvg': newSum / newCount,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Refreshes just the display metadata (name + avatar) for [uid] without
  /// touching `totalMastered`/`examHighScore` — used when the user changes
  /// their name or avatar in ProfileScreen, independent of exam/mastery
  /// events.
  Future<void> syncProfileInfo({
    required String uid,
    required String displayName,
    String? photoUrl,
    required AvatarType avatarType,
    String? avatarValue,
  }) {
    return _collection.doc(uid).set({
      'displayName': displayName,
      'photoUrl': photoUrl,
      'avatarType': avatarType.key,
      'avatarValue': avatarValue,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

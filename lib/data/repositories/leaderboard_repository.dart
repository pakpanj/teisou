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

  /// Human-readable label — used by the Clan tab's metric picker dropdown
  /// (`LeaderboardScreen`'s own tabs still spell these out directly as
  /// `Tab(text: ...)`, so this getter isn't a duplicate of those, just a
  /// reusable source for anywhere else a metric needs a display name).
  String get label {
    switch (this) {
      case LeaderboardMetric.totalMastered:
        return 'Kana Dikuasai';
      case LeaderboardMetric.examHighScore:
        return 'Skor Ujian';
      case LeaderboardMetric.kanaRecord:
        return 'Rekor Kana';
      case LeaderboardMetric.dokkaiRecord:
        return 'Rekor Dokkai';
      case LeaderboardMetric.choukaiRecord:
        return 'Rekor Choukai';
      case LeaderboardMetric.kanjiComboRecord:
        return 'Rekor Kanji-Kombinasi';
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

  static const _whereInBatchSize = 10;

  /// Fetches whichever of [uids] actually have a `leaderboard/{uid}` doc —
  /// a uid with no exam/mastery activity yet simply won't appear in the
  /// result, callers that need every uid represented (e.g. a clan's
  /// ranking, where a student with zero attempts should still show up at
  /// 0) must fill in the gaps themselves. Chunked since `whereIn` caps the
  /// number of values per query — this is the first `whereIn` query in
  /// this codebase, so there's no existing chunk-size precedent to match;
  /// 10 is a conservative choice safely under every Firestore SDK version's
  /// limit.
  Future<List<LeaderboardEntry>> getMany(List<String> uids) async {
    if (uids.isEmpty) return [];
    final results = <LeaderboardEntry>[];
    for (var i = 0; i < uids.length; i += _whereInBatchSize) {
      final chunk = uids.sublist(
        i,
        i + _whereInBatchSize > uids.length ? uids.length : i + _whereInBatchSize,
      );
      final snapshot =
          await _collection.where(FieldPath.documentId, whereIn: chunk).get();
      results.addAll(
        snapshot.docs.map((doc) => LeaderboardEntry.fromMap(doc.id, doc.data())),
      );
    }
    return results;
  }

  /// Sorts a pre-fetched list of entries by [metric], descending — reuses
  /// [_valueFor] so the metric-to-field mapping stays one source of truth
  /// whether the ranking comes from a live Firestore `orderBy` (`watchTop`)
  /// or a locally-assembled list (e.g. a clan's combined roster).
  List<LeaderboardEntry> sortByMetric(
    List<LeaderboardEntry> entries,
    LeaderboardMetric metric,
  ) {
    final sorted = List<LeaderboardEntry>.from(entries);
    sorted.sort(
      (a, b) => _valueFor(b, metric).compareTo(_valueFor(a, metric)),
    );
    return sorted;
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

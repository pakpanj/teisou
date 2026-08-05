import 'package:cloud_firestore/cloud_firestore.dart';

import '../repositories/leaderboard_repository.dart' show LeaderboardCategory;
import 'user_profile.dart' show AvatarType, AvatarTypeX;

class LeaderboardEntry {
  final String uid;
  final String displayName;
  final String? photoUrl;
  final AvatarType avatarType;
  final String? avatarValue;
  final int totalMastered;
  final int examHighScore;
  final double kanaRecordSum;
  final int kanaRecordCount;
  final double kanaRecordAvg;
  final double dokkaiRecordSum;
  final int dokkaiRecordCount;
  final double dokkaiRecordAvg;
  final double choukaiRecordSum;
  final int choukaiRecordCount;
  final double choukaiRecordAvg;
  final double kanjiComboRecordSum;
  final int kanjiComboRecordCount;
  final double kanjiComboRecordAvg;

  /// Denormalized copy of [computedGlobalScore], stored purely so Firestore
  /// can `orderBy` it — the same reason `{category}RecordAvg` is stored
  /// alongside its own sum/count. Never read for *display*: use
  /// [computedGlobalScore] there, since a doc written before this field
  /// existed (or by an older client) carries a stale value while its four
  /// per-category averages are always current.
  ///
  /// Null specifically means *absent from the document*, which is not the
  /// same as a stored 0: Firestore's `orderBy` omits docs missing the field
  /// entirely, so "absent" is the state [LeaderboardRepository.
  /// backfillGlobalScore] has to repair. Collapsing it to 0 would leave a
  /// genuinely-zero-scoring user permanently invisible in the ranking,
  /// since their stored-vs-computed comparison would look already in sync.
  final double? globalScore;

  final DateTime updatedAt;

  LeaderboardEntry({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    this.avatarType = AvatarType.google,
    this.avatarValue,
    required this.totalMastered,
    required this.examHighScore,
    this.kanaRecordSum = 0,
    this.kanaRecordCount = 0,
    this.kanaRecordAvg = 0,
    this.dokkaiRecordSum = 0,
    this.dokkaiRecordCount = 0,
    this.dokkaiRecordAvg = 0,
    this.choukaiRecordSum = 0,
    this.choukaiRecordCount = 0,
    this.choukaiRecordAvg = 0,
    this.kanjiComboRecordSum = 0,
    this.kanjiComboRecordCount = 0,
    this.kanjiComboRecordAvg = 0,
    this.globalScore,
    required this.updatedAt,
  });

  factory LeaderboardEntry.fromMap(String uid, Map<String, dynamic> map) {
    return LeaderboardEntry(
      uid: uid,
      displayName: map['displayName'] as String? ?? 'Pelajar Kana',
      photoUrl: map['photoUrl'] as String?,
      avatarType: AvatarTypeX.fromKey(map['avatarType'] as String?),
      avatarValue: map['avatarValue'] as String?,
      totalMastered: (map['totalMastered'] as num?)?.toInt() ?? 0,
      examHighScore: (map['examHighScore'] as num?)?.toInt() ?? 0,
      kanaRecordSum: (map['kanaRecordSum'] as num?)?.toDouble() ?? 0,
      kanaRecordCount: (map['kanaRecordCount'] as num?)?.toInt() ?? 0,
      kanaRecordAvg: (map['kanaRecordAvg'] as num?)?.toDouble() ?? 0,
      dokkaiRecordSum: (map['dokkaiRecordSum'] as num?)?.toDouble() ?? 0,
      dokkaiRecordCount: (map['dokkaiRecordCount'] as num?)?.toInt() ?? 0,
      dokkaiRecordAvg: (map['dokkaiRecordAvg'] as num?)?.toDouble() ?? 0,
      choukaiRecordSum: (map['choukaiRecordSum'] as num?)?.toDouble() ?? 0,
      choukaiRecordCount: (map['choukaiRecordCount'] as num?)?.toInt() ?? 0,
      choukaiRecordAvg: (map['choukaiRecordAvg'] as num?)?.toDouble() ?? 0,
      kanjiComboRecordSum: (map['kanjiComboRecordSum'] as num?)?.toDouble() ?? 0,
      kanjiComboRecordCount: (map['kanjiComboRecordCount'] as num?)?.toInt() ?? 0,
      kanjiComboRecordAvg: (map['kanjiComboRecordAvg'] as num?)?.toDouble() ?? 0,
      globalScore: (map['globalScore'] as num?)?.toDouble(),
      updatedAt: _toDateTime(map['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'photoUrl': photoUrl,
        'avatarType': avatarType.key,
        'avatarValue': avatarValue,
        'totalMastered': totalMastered,
        'examHighScore': examHighScore,
        'kanaRecordSum': kanaRecordSum,
        'kanaRecordCount': kanaRecordCount,
        'kanaRecordAvg': kanaRecordAvg,
        'dokkaiRecordSum': dokkaiRecordSum,
        'dokkaiRecordCount': dokkaiRecordCount,
        'dokkaiRecordAvg': dokkaiRecordAvg,
        'choukaiRecordSum': choukaiRecordSum,
        'choukaiRecordCount': choukaiRecordCount,
        'choukaiRecordAvg': choukaiRecordAvg,
        'kanjiComboRecordSum': kanjiComboRecordSum,
        'kanjiComboRecordCount': kanjiComboRecordCount,
        'kanjiComboRecordAvg': kanjiComboRecordAvg,
        'globalScore': globalScore ?? computedGlobalScore,
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  /// The single number the leaderboard ranks by: every exam category's
  /// "Rekor" average added together, so 0-400 rather than 0-100. Summing
  /// (instead of averaging) is deliberate — it rewards breadth, since a
  /// learner who scores decently across all four categories outranks one
  /// who only ever attempts a single category perfectly. A never-attempted
  /// category contributes 0, which is also why this isn't averaged over
  /// four: Choukai currently ships with no content at all, so dividing by
  /// four would penalize every user for a category they can't even take.
  double get computedGlobalScore =>
      kanaRecordAvg + dokkaiRecordAvg + choukaiRecordAvg + kanjiComboRecordAvg;

  /// True once at least one exam category has been attempted — lets the UI
  /// distinguish "genuinely scored 0" from "hasn't started", which a bare
  /// 0.0 [computedGlobalScore] can't.
  bool get hasAnyRecord =>
      kanaRecordCount > 0 ||
      dokkaiRecordCount > 0 ||
      choukaiRecordCount > 0 ||
      kanjiComboRecordCount > 0;

  /// Sum/count/avg accessors keyed by [LeaderboardCategory] — used by
  /// [LeaderboardRepository.updateCategoryRecord] (read the previous
  /// sum/count before writing the new running average) and by the
  /// Leaderboard UI (render whichever category's tab is active) without
  /// each caller needing its own switch statement.
  double recordSumFor(LeaderboardCategory category) {
    switch (category) {
      case LeaderboardCategory.kana:
        return kanaRecordSum;
      case LeaderboardCategory.dokkai:
        return dokkaiRecordSum;
      case LeaderboardCategory.choukai:
        return choukaiRecordSum;
      case LeaderboardCategory.kanjiCombo:
        return kanjiComboRecordSum;
    }
  }

  int recordCountFor(LeaderboardCategory category) {
    switch (category) {
      case LeaderboardCategory.kana:
        return kanaRecordCount;
      case LeaderboardCategory.dokkai:
        return dokkaiRecordCount;
      case LeaderboardCategory.choukai:
        return choukaiRecordCount;
      case LeaderboardCategory.kanjiCombo:
        return kanjiComboRecordCount;
    }
  }

  double recordAvgFor(LeaderboardCategory category) {
    switch (category) {
      case LeaderboardCategory.kana:
        return kanaRecordAvg;
      case LeaderboardCategory.dokkai:
        return dokkaiRecordAvg;
      case LeaderboardCategory.choukai:
        return choukaiRecordAvg;
      case LeaderboardCategory.kanjiCombo:
        return kanjiComboRecordAvg;
    }
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

import 'card_game_rank.dart';
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

  /// Denormalized lowercase copy of [displayName], stored purely so
  /// `LeaderboardRepository.searchPublicUsers` can `orderBy` + prefix-range
  /// it (Firestore has no case-insensitive query). Same absent-vs-stale
  /// distinction as [globalScore], and the same fix: a doc written before
  /// this field existed is invisible to that query entirely (Firestore's
  /// `orderBy` omits docs missing the sorted field) until
  /// `LeaderboardRepository.backfillDisplayNameLower` repairs it — found by
  /// an actual on-device search for a real pre-existing account turning up
  /// nothing, not caught by any automated check.
  final String? displayNameLower;

  /// Mirror of `UserProfile.userId` — the private `users/{uid}` document's
  /// short shareable id copied here so it's visible without needing read
  /// access to that private doc (the same reasoning `babCompletedCount`
  /// below documents for Bab progress). Backfilled the same way as
  /// [displayNameLower]/[globalScore], via `LeaderboardRepository
  /// .backfillUserId` inside `selfLeaderboardEntryProvider` — deliberately
  /// *not* threaded as a parameter through every leaderboard write method,
  /// since the id itself never changes once assigned and the self-heal
  /// pattern already exists for exactly this shape of gap.
  final String? userId;

  /// Mirror of `UserProfile.coverId`/`frameId` — the profile header cover
  /// and avatar frame the learner picked in `CoverPickerSheet`/
  /// `AvatarPickerSheet`. Published here (via
  /// `LeaderboardRepository.updateCoverId`/`updateFrameId`, called
  /// best-effort right after each picker saves) so `PublicProfileScreen`
  /// and `LeaderboardAvatar` can show them without needing read access to
  /// the private `users/{uid}` document — same reasoning as [userId] and
  /// [babCompletedCount] below. Unlike those, both can change repeatedly
  /// over an account's lifetime (a picked cover/frame isn't permanent the
  /// way an id is), so they're written directly rather than through a
  /// once-only backfill.
  final String? coverId;
  final String? frameId;

  /// Public summary of the learner's Bab curriculum progress: how many
  /// chapters they've completed, and the `order` of the furthest one.
  ///
  /// Denormalized here rather than read from `users/{uid}/babProgress`
  /// because that subcollection is strictly private per `firestore.rules`
  /// (only its owner can read it), and a teacher checking a student's
  /// progress from the clan ranking has to be able to see this. Publishing
  /// two aggregate integers is a much smaller disclosure than loosening
  /// read access to the whole private user document — and it costs no
  /// extra read either, since the profile view already fetches this row.
  ///
  /// Only the counts live here; the chapter's *title* is resolved locally
  /// from the bundled `bab_data.json` by `order`, so renaming a chapter
  /// never leaves stale copies scattered across user documents.
  final int babCompletedCount;
  final int babHighestOrder;

  /// Card Game Mode's own standing, mirrored here by
  /// `functions/battle_stars.js` — see "Papan peringkat bintang berdiri
  /// sendiri" in `NOTES_CARD_GAME_MODE.md`: deliberately extra fields on
  /// this already-existing document rather than a new collection, so
  /// name/avatar sync comes along for free. **Written only by that
  /// Cloud Function** — nothing in this Dart model's [toMap] includes
  /// these fields, so no client-side write path can ever clobber them
  /// (mirrors `CardGameRank`'s own "read-only from this app's point of
  /// view" doc comment, which describes the same standing before it's
  /// mirrored here).
  ///
  /// [cardGameStarTotal] doubles as the "has this player ever finished a
  /// ranked match" flag: `null` means the field has genuinely never been
  /// written (Firestore's `orderBy` already excludes such docs from the
  /// star ranking on its own, which is the correct behavior — unlike
  /// [globalScore], 0 total stars from a real match is a valid ranked
  /// standing, not indistinguishable from never having played).
  final CardGameTier cardGameTier;
  final int cardGameDivision;
  final int cardGameStars;
  final int cardGameSeason;
  final int? cardGameStarTotal;

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
    this.displayNameLower,
    this.userId,
    this.coverId,
    this.frameId,
    this.babCompletedCount = 0,
    this.babHighestOrder = 0,
    this.cardGameTier = CardGameTier.bronze,
    this.cardGameDivision = 5,
    this.cardGameStars = 0,
    this.cardGameSeason = 1,
    this.cardGameStarTotal,
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
      displayNameLower: map['displayNameLower'] as String?,
      userId: map['userId'] as String?,
      coverId: map['coverId'] as String?,
      frameId: map['frameId'] as String?,
      babCompletedCount: (map['babCompletedCount'] as num?)?.toInt() ?? 0,
      babHighestOrder: (map['babHighestOrder'] as num?)?.toInt() ?? 0,
      cardGameTier: CardGameTierX.fromKey(map['cardGameTier'] as String?),
      cardGameDivision: (map['cardGameDivision'] as num?)?.toInt() ?? 5,
      cardGameStars: (map['cardGameStars'] as num?)?.toInt() ?? 0,
      cardGameSeason: (map['cardGameSeason'] as num?)?.toInt() ?? 1,
      cardGameStarTotal: (map['cardGameStarTotal'] as num?)?.toInt(),
      updatedAt: _toDateTime(map['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'displayNameLower': displayNameLower ?? displayName.toLowerCase(),
        'userId': userId,
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
        'coverId': coverId,
        'frameId': frameId,
        'babCompletedCount': babCompletedCount,
        'babHighestOrder': babHighestOrder,
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

  /// Whether this player has ever finished a ranked Card Game Mode match
  /// — see [cardGameStarTotal]'s own doc comment for why `null` (not `0`)
  /// is what distinguishes "never played" from "played and stands at 0".
  bool get hasPlayedCardGame => cardGameStarTotal != null;

  /// The same [CardGameRank] shape `Profile`/the Home card already
  /// render via [CardGameRank.displayName] — reconstructed from this
  /// entry's own mirrored fields rather than adding a second "Bronze
  /// IV"-style formatter here, so a division-label change only ever
  /// needs to happen in one place.
  CardGameRank get cardGameRankStanding => CardGameRank(
        tier: cardGameTier,
        division: cardGameDivision,
        stars: cardGameStars,
        season: cardGameSeason,
      );

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

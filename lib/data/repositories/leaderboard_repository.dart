import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase/firestore_paths.dart';
import '../models/leaderboard_entry.dart';
import '../models/user_profile.dart' show AvatarType, AvatarTypeX;

/// The four exam categories that each earn their own "Rekor" (average
/// score-percentage across every attempt) — see [LeaderboardRepository.
/// updateCategoryRecord]. Their four averages are what
/// [LeaderboardEntry.computedGlobalScore] sums into the single ranking
/// number the leaderboard shows.
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

  /// Field name of the denormalized sort key. Only the *ordering* comes from
  /// this stored copy; every displayed number is recomputed client-side via
  /// [LeaderboardEntry.computedGlobalScore] — see [backfillGlobalScore] for
  /// how docs predating the field get pulled back into the ranking.
  static const globalScoreField = 'globalScore';

  Stream<List<LeaderboardEntry>> watchTop({int limit = 20}) {
    return _collection
        .orderBy(globalScoreField, descending: true)
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

  /// Sorts a pre-fetched list by global score, descending — for rankings
  /// assembled locally rather than by Firestore's own `orderBy` (a clan's
  /// combined roster). Sorts on [LeaderboardEntry.computedGlobalScore], not
  /// the stored copy, so a member whose doc predates the field still ranks
  /// correctly here even before [backfillGlobalScore] has run for them.
  List<LeaderboardEntry> sortByGlobalScore(List<LeaderboardEntry> entries) {
    final sorted = List<LeaderboardEntry>.from(entries);
    sorted.sort(
      (a, b) => b.computedGlobalScore.compareTo(a.computedGlobalScore),
    );
    return sorted;
  }

  /// Ranks an already-fetched [entry] (1-based). Takes the entry rather than
  /// a uid so the caller can reuse the single [getSelf] read the screen's
  /// header already does, leaving only the count query below.
  Future<int> rankOf(LeaderboardEntry entry) async {
    final higher = await _collection
        .where(globalScoreField, isGreaterThan: entry.computedGlobalScore)
        .count()
        .get();
    return (higher.count ?? 0) + 1;
  }

  /// Writes [globalScoreField] for [entry] when the stored copy is absent or
  /// has drifted from the entry's real
  /// [LeaderboardEntry.computedGlobalScore].
  ///
  /// Exists because Firestore's `orderBy` silently *omits* documents missing
  /// the sorted field: every leaderboard doc written before this field
  /// existed would vanish from the ranking entirely until its owner happened
  /// to submit another exam. Rather than a one-off migration script (which
  /// this project has no mechanism to run against live data), each user
  /// self-heals the moment they open the leaderboard.
  ///
  /// The absent-vs-zero distinction matters: a user whose only activity is
  /// kana mastery has a real score of 0 and a doc with no `globalScore` at
  /// all, so a plain `stored != computed` test would call them in sync and
  /// leave them permanently unrankable. Hence the explicit null check
  /// rather than defaulting the stored value to 0.
  ///
  /// No-ops once in sync, so it costs one write per user, once — and nothing
  /// at all for docs written by this version or later.
  Future<void> backfillGlobalScore(LeaderboardEntry entry) async {
    final stored = entry.globalScore;
    if (stored != null &&
        (stored - entry.computedGlobalScore).abs() < 0.001) {
      return;
    }
    await _collection.doc(entry.uid).set({
      globalScoreField: entry.computedGlobalScore,
    }, SetOptions(merge: true));
  }

  /// Writes `displayNameLower` for [entry] when absent or stale — the exact
  /// same shape as [backfillGlobalScore] immediately above, for the exact
  /// same reason: a doc written before this field existed is invisible to
  /// [searchPublicUsers]' `orderBy('displayNameLower')` query, since
  /// Firestore's `orderBy` omits documents missing the sorted field
  /// entirely rather than sorting them last. Found by an actual on-device
  /// search for a real pre-existing account turning up nothing — the same
  /// failure mode [backfillGlobalScore]'s own doc comment already
  /// documents, recurring for a different field added later.
  Future<void> backfillDisplayNameLower(LeaderboardEntry entry) async {
    final expected = entry.displayName.toLowerCase();
    if (entry.displayNameLower == expected) return;
    await _collection.doc(entry.uid).set({
      'displayNameLower': expected,
    }, SetOptions(merge: true));
  }

  /// Mirrors `UserProfile.userId` onto `entry`'s leaderboard doc when
  /// missing or stale — unlike [backfillGlobalScore]/
  /// [backfillDisplayNameLower], which recompute their field from data the
  /// leaderboard doc already has, this one copies in a value from a
  /// *different* document (the private `users/{uid}` profile), which is
  /// why it takes [userId] as a parameter rather than deriving it from
  /// [entry] alone. A no-op once `userId` never changes after first
  /// assignment, so this costs one write per user, once.
  Future<void> backfillUserId(LeaderboardEntry entry, String? userId) async {
    if (userId == null || entry.userId == userId) return;
    await _collection.doc(entry.uid).set({
      'userId': userId,
    }, SetOptions(merge: true));
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
      'displayNameLower': displayName.toLowerCase(),
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
      'displayNameLower': displayName.toLowerCase(),
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
  /// history.
  ///
  /// Transactional, unlike [updateTotalMastered]/
  /// [updateExamHighScoreIfHigher] above, because the failure mode is
  /// genuinely worse here. Those two write a *maximum* — a lost update just
  /// misses a record, and `totalMastered` self-heals anyway since the next
  /// exam recomputes it from the authoritative progress map. This one
  /// accumulates: a lost update permanently drops one attempt out of both
  /// the sum and the count, so the average stays wrong forever with no
  /// later write to correct it.
  ///
  /// The trade-off is that transactions need connectivity, so this now
  /// fails offline where the old read-then-write would have queued. That's
  /// the better failure: offline, the old path read a stale cached
  /// sum/count and queued a write computed from it, silently corrupting the
  /// average on sync. Failing outright loses the same single attempt
  /// without poisoning the aggregate — and every caller already treats this
  /// as a best-effort mirror wrapped in try/catch, with exam history (the
  /// real source of truth) written separately beforehand.
  Future<void> updateCategoryRecord({
    required String uid,
    required String displayName,
    String? photoUrl,
    AvatarType avatarType = AvatarType.google,
    String? avatarValue,
    required LeaderboardCategory category,
    required double percentage,
  }) async {
    final docRef = _collection.doc(uid);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final data = snapshot.data();
      final existing = data == null
          ? null
          : LeaderboardEntry.fromMap(snapshot.id, data);
      final newSum = (existing?.recordSumFor(category) ?? 0.0) + percentage;
      final newCount = (existing?.recordCountFor(category) ?? 0) + 1;
      final newAvg = newSum / newCount;

      // The global score is this category's fresh average plus the other
      // three's existing ones — recomputed here (inside the same
      // transaction that produced newAvg) rather than derived later, so the
      // stored sort key can never lag the averages it's built from.
      final newGlobalScore = LeaderboardCategory.values.fold<double>(
        0,
        (total, c) =>
            total + (c == category ? newAvg : (existing?.recordAvgFor(c) ?? 0)),
      );

      transaction.set(docRef, {
        'displayName': displayName,
        'displayNameLower': displayName.toLowerCase(),
        'photoUrl': photoUrl,
        'avatarType': avatarType.key,
        'avatarValue': avatarValue,
        '${category.key}RecordSum': newSum,
        '${category.key}RecordCount': newCount,
        '${category.key}RecordAvg': newAvg,
        globalScoreField: newGlobalScore,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  /// Publishes [uid]'s Bab curriculum progress so other learners (and a
  /// teacher watching a clan) can see it — the private
  /// `users/{uid}/babProgress` subcollection that actually drives the
  /// in-app lock stays the source of truth and stays unreadable to anyone
  /// else. See [LeaderboardEntry.babCompletedCount] for why this is
  /// denormalized instead of read directly.
  ///
  /// Best-effort like every other leaderboard write: callers wrap it in
  /// try/catch, because a chapter is already marked complete locally by the
  /// time this runs and a failed publish must never undo that.
  Future<void> updateBabProgress({
    required String uid,
    required String displayName,
    String? photoUrl,
    AvatarType avatarType = AvatarType.google,
    String? avatarValue,
    required int completedCount,
    required int highestOrder,
  }) {
    return _collection.doc(uid).set({
      'displayName': displayName,
      'displayNameLower': displayName.toLowerCase(),
      'photoUrl': photoUrl,
      'avatarType': avatarType.key,
      'avatarValue': avatarValue,
      'babCompletedCount': completedCount,
      'babHighestOrder': highestOrder,
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
      'displayNameLower': displayName.toLowerCase(),
      'photoUrl': photoUrl,
      'avatarType': avatarType.key,
      'avatarValue': avatarValue,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Case-insensitive prefix search over every public `leaderboard/{uid}`
  /// row's name, for a clan leader/co-leader inviting a specific learner
  /// (see `ClanRepository.sendInvite`). Firestore has no substring search,
  /// so this is a prefix match on [displayNameLower] — good enough to find
  /// someone by typing the start of their name, the same limitation any
  /// simple "search a name field" feature has without a dedicated search
  /// index. U+F8FF is a high Unicode sentinel that sorts after any
  /// realistic input, the standard Firestore idiom for a prefix range.
  ///
  /// Also tries an exact match on [LeaderboardEntry.userId] and merges it
  /// in — many accounts share the exact same name (every learner who never
  /// set a custom one defaults to the identical "Pelajar Kana"), which
  /// otherwise makes the name search alone unable to tell them apart; the
  /// id exists specifically so a precise, unambiguous invite is possible.
  /// The id query is exact rather than a prefix range since ids are meant
  /// to be typed or pasted in full, not partially guessed.
  Future<List<LeaderboardEntry>> searchPublicUsers(
    String query, {
    int limit = 20,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];
    final lower = trimmed.toLowerCase();

    final byName = await _collection
        .orderBy('displayNameLower')
        .startAt([lower])
        .endAt(['$lower${String.fromCharCode(0xf8ff)}'])
        .limit(limit)
        .get();
    final byId = await _collection
        .where('userId', isEqualTo: trimmed.toUpperCase())
        .limit(1)
        .get();

    final seen = <String>{};
    final results = <LeaderboardEntry>[];
    for (final doc in [...byId.docs, ...byName.docs]) {
      if (!seen.add(doc.id)) continue;
      results.add(LeaderboardEntry.fromMap(doc.id, doc.data()));
    }
    return results;
  }
}

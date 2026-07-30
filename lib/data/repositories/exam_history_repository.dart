import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase/firestore_paths.dart';
import '../models/simple_exam_result.dart';
import '../models/user_profile.dart' show AvatarType;
import 'leaderboard_repository.dart';

/// Shared "submit + read recent history" repository for Dokkai/Choukai/
/// Kanji-Kombinasi. Unlike Kanji/Kotoba/Bunpou/Partikel/Kaiwa's "learned"
/// toggle (which needs a local-first SharedPreferences source of truth, see
/// `KanjiProgressRepository` and friends), an exam attempt is a one-shot
/// append-only event with an identical shape across all three new exam
/// types (itemId/level/score/total/completedAt) — same as how the existing
/// kana `ExamRepository.submitExam` writes straight to Firestore with no
/// local cache. Parametrized by collection name so one class replaces what
/// would otherwise be three copy-pasted repositories.
class ExamHistoryRepository {
  final String collectionName;
  final LeaderboardCategory category;
  final LeaderboardRepository leaderboardRepository;
  final FirebaseFirestore _firestore;

  ExamHistoryRepository(
    this.collectionName, {
    required this.category,
    required this.leaderboardRepository,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Writes the attempt (source of truth, not wrapped in try/catch here —
  /// a failure should propagate to the caller's own best-effort handling),
  /// then folds its score-percentage into [category]'s "Rekor" running
  /// average on the leaderboard — best-effort, wrapped so a leaderboard
  /// hiccup never undoes the history write that already succeeded.
  Future<void> submit({
    required String uid,
    required SimpleExamResult result,
    required String displayName,
    String? photoUrl,
    AvatarType avatarType = AvatarType.google,
    String? avatarValue,
  }) async {
    await _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .collection(collectionName)
        .add(result.toMap());
    try {
      await leaderboardRepository.updateCategoryRecord(
        uid: uid,
        displayName: displayName,
        photoUrl: photoUrl,
        avatarType: avatarType,
        avatarValue: avatarValue,
        category: category,
        percentage: result.percentage,
      );
    } catch (_) {
      // Best-effort mirror only — the history write above already
      // succeeded and is the source of truth.
    }
  }

  Stream<List<SimpleExamResult>> watchRecent(String uid, {int limit = 10}) {
    return _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .collection(collectionName)
        .orderBy('completedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SimpleExamResult.fromMap(doc.data()))
              .toList(),
        );
  }

  /// One-shot equivalent of [watchRecent] — used by the full "Riwayat
  /// Ujian" screen, which fetches-and-merges across all four exam
  /// categories on open/pull-to-refresh rather than holding four live
  /// listeners open at once.
  Future<List<SimpleExamResult>> getRecent(String uid, {int limit = 30}) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .collection(collectionName)
        .orderBy('completedAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => SimpleExamResult.fromMap(doc.data()))
        .toList();
  }
}

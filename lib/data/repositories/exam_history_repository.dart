import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase/firestore_paths.dart';
import '../models/simple_exam_result.dart';

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
  final FirebaseFirestore _firestore;

  ExamHistoryRepository(this.collectionName, {FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> submit(String uid, SimpleExamResult result) {
    return _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .collection(collectionName)
        .add(result.toMap());
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
}

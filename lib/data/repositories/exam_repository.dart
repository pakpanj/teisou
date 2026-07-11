import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase/firestore_paths.dart';
import '../models/exam_mode.dart';
import '../models/exam_question.dart';
import '../models/exam_result.dart';
import '../models/kana_character.dart';
import '../models/kana_progress.dart';
import '../models/kana_status.dart';
import '../models/kana_type.dart';
import 'kana_repository.dart';
import 'leaderboard_repository.dart';
import 'progress_repository.dart';

/// Generates weighted exam sessions and persists results atomically.
class ExamRepository {
  static const questionsPerExam = 10;
  static const _newOrLearningWeight = 0.7;

  final KanaRepository kanaRepository;
  final ProgressRepository progressRepository;
  final LeaderboardRepository leaderboardRepository;
  final FirebaseFirestore _firestore;
  final Random _random;

  ExamRepository({
    required this.kanaRepository,
    required this.progressRepository,
    required this.leaderboardRepository,
    FirebaseFirestore? firestore,
    Random? random,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _random = random ?? Random();

  /// Most recent exam attempts, newest first — used for the "3 terakhir"
  /// preview on ProfileScreen.
  Stream<List<ExamResult>> watchRecentHistory(String uid, {int limit = 3}) {
    return _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .collection(FirestorePaths.examHistory)
        .orderBy('completedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => ExamResult.fromMap(doc.data())).toList(),
        );
  }

  /// Builds a 10-question session for [mode], weighting kana that are
  /// `new`/`learning` (~70% chance) over `mastered` (~30%) so exams
  /// reinforce weak spots rather than testing purely at random.
  Future<List<ExamQuestion>> generateExam(ExamMode mode, String uid) async {
    final pools = await _resolvePools(mode);
    final allKana = pools.values.expand((list) => list).toList();

    final progressByType = <KanaType, Map<String, KanaProgress>>{};
    for (final type in pools.keys) {
      final typeProgress = await progressRepository.getTypeProgress(
        uid,
        type,
      );
      progressByType[type] = typeProgress.items;
    }

    final newOrLearning = <KanaCharacter>[];
    final mastered = <KanaCharacter>[];
    for (final kana in allKana) {
      final status =
          progressByType[kana.type]?[kana.id]?.status ?? KanaStatus.newKana;
      (status == KanaStatus.mastered ? mastered : newOrLearning).add(kana);
    }

    final count = min(questionsPerExam, allKana.length);
    final selected = _pickWeighted(newOrLearning, mastered, count);
    selected.shuffle(_random);

    return selected
        .map((kana) => _buildQuestion(kana, pools[kana.type]!))
        .toList();
  }

  List<KanaCharacter> _pickWeighted(
    List<KanaCharacter> groupA,
    List<KanaCharacter> groupB,
    int count,
  ) {
    final remainingA = List<KanaCharacter>.from(groupA)..shuffle(_random);
    final remainingB = List<KanaCharacter>.from(groupB)..shuffle(_random);
    final selected = <KanaCharacter>[];

    while (selected.length < count &&
        (remainingA.isNotEmpty || remainingB.isNotEmpty)) {
      final preferA = _random.nextDouble() < _newOrLearningWeight;
      if (preferA && remainingA.isNotEmpty) {
        selected.add(remainingA.removeLast());
      } else if (!preferA && remainingB.isNotEmpty) {
        selected.add(remainingB.removeLast());
      } else if (remainingA.isNotEmpty) {
        selected.add(remainingA.removeLast());
      } else {
        selected.add(remainingB.removeLast());
      }
    }
    return selected;
  }

  ExamQuestion _buildQuestion(
    KanaCharacter kana,
    List<KanaCharacter> sameTypePool,
  ) {
    final candidates = sameTypePool
        .where((k) => k.romaji != kana.romaji)
        .toList()
      ..shuffle(_random);

    final distractors = <String>{};
    for (final candidate in candidates) {
      if (distractors.length >= 3) break;
      distractors.add(candidate.romaji);
    }

    final options = [kana.romaji, ...distractors]..shuffle(_random);
    return ExamQuestion(kana: kana, options: options);
  }

  Future<Map<KanaType, List<KanaCharacter>>> _resolvePools(
    ExamMode mode,
  ) async {
    switch (mode) {
      case ExamMode.hiragana:
        return {
          KanaType.hiragana: await kanaRepository.getByType(
            KanaType.hiragana,
          ),
        };
      case ExamMode.katakana:
        return {
          KanaType.katakana: await kanaRepository.getByType(
            KanaType.katakana,
          ),
        };
      case ExamMode.mixed:
        return {
          KanaType.hiragana: await kanaRepository.getByType(
            KanaType.hiragana,
          ),
          KanaType.katakana: await kanaRepository.getByType(
            KanaType.katakana,
          ),
        };
    }
  }

  /// Persists the exam attempt and every touched kana's progress update in
  /// a single atomic batch: either both writes land, or neither does. Also
  /// refreshes the user's `leaderboard` entry (total mastered + exam high
  /// score) afterwards — best-effort, not part of the atomic write.
  Future<ExamResult> submitExam({
    required String uid,
    required ExamMode mode,
    required List<AnsweredQuestion> answers,
    required String displayName,
    String? photoUrl,
  }) async {
    // Load progress for both kana types (not just the ones covered by this
    // exam) so the post-submit total-mastered count is accurate even for a
    // hiragana-only or katakana-only session.
    final progressCache = <KanaType, Map<String, KanaProgress>>{};
    for (final type in KanaType.values) {
      final typeProgress = await progressRepository.getTypeProgress(
        uid,
        type,
      );
      progressCache[type] = typeProgress.items;
    }

    final now = DateTime.now();
    final wrongAnswers = <WrongAnswerEntry>[];
    final progressUpdates = <String, dynamic>{};
    var score = 0;

    for (final answered in answers) {
      final kana = answered.question.kana;
      final current =
          progressCache[kana.type]?[kana.id] ?? KanaProgress.initial(kana.id);

      final KanaProgress updated;
      if (answered.isCorrect) {
        score++;
        final newStreak = current.correctStreak + 1;
        final newStatus = newStreak >= 3
            ? KanaStatus.mastered
            : (current.status == KanaStatus.newKana
                ? KanaStatus.learning
                : current.status);
        updated = current.copyWith(
          correctStreak: newStreak,
          status: newStatus,
          lastReviewedAt: now,
        );
      } else {
        wrongAnswers.add(
          WrongAnswerEntry(
            kanaId: kana.id,
            userAnswer: answered.selectedAnswer,
            correctAnswer: answered.question.correctAnswer,
          ),
        );
        final regressedStatus = current.status == KanaStatus.mastered
            ? KanaStatus.learning
            : current.status;
        updated = current.copyWith(
          correctStreak: 0,
          status: regressedStatus,
          lastReviewedAt: now,
        );
      }

      progressUpdates['progress.${kana.type.key}.items.${kana.id}'] =
          updated.toMap();
      progressCache[kana.type]![kana.id] = updated;
    }

    final result = ExamResult(
      mode: mode,
      score: score,
      total: answers.length,
      wrongAnswers: wrongAnswers,
      completedAt: now,
    );

    final userDoc = _firestore.collection(FirestorePaths.users).doc(uid);
    final historyDoc = userDoc
        .collection(FirestorePaths.examHistory)
        .doc();

    final batch = _firestore.batch();
    batch.set(historyDoc, result.toMap());
    batch.set(
      userDoc,
      _expandDotPaths(progressUpdates),
      SetOptions(merge: true),
    );
    await batch.commit();

    final totalMastered = progressCache.values
        .expand((items) => items.values)
        .where((p) => p.status == KanaStatus.mastered)
        .length;

    await leaderboardRepository.updateTotalMastered(
      uid: uid,
      displayName: displayName,
      photoUrl: photoUrl,
      totalMastered: totalMastered,
    );
    await leaderboardRepository.updateExamHighScoreIfHigher(
      uid: uid,
      displayName: displayName,
      photoUrl: photoUrl,
      score: score,
    );

    return result;
  }

  /// Turns `{'progress.hiragana.items.hiragana_a': {...}}` into nested maps
  /// so a merge-`set()` writes the right sub-fields (dotted string keys are
  /// only auto-nested by `update()`, not by `set(merge: true)`).
  Map<String, dynamic> _expandDotPaths(Map<String, dynamic> flat) {
    final result = <String, dynamic>{};
    for (final entry in flat.entries) {
      final parts = entry.key.split('.');
      var node = result;
      for (var i = 0; i < parts.length - 1; i++) {
        node = node.putIfAbsent(parts[i], () => <String, dynamic>{})
            as Map<String, dynamic>;
      }
      node[parts.last] = entry.value;
    }
    return result;
  }
}

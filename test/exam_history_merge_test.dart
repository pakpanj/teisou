import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/localization/app_strings.dart';
import 'package:kana_master/data/models/app_language.dart';
import 'package:kana_master/data/models/exam_mode.dart';
import 'package:kana_master/data/models/exam_result.dart';
import 'package:kana_master/data/models/simple_exam_result.dart';
import 'package:kana_master/features/profile/exam_history_providers.dart';

/// Covers [mergeExamHistory], the pure merge/sort/label function backing
/// the "riwayat ujian tidak menampilkan apa apa" fix — it takes plain
/// constructed lists rather than a live Firestore connection, so this
/// exercises the actual bug (Dokkai/Choukai/Kanji-Kombinasi attempts never
/// showing up anywhere, since the old provider only ever read kana's
/// collection) without needing to mock four Firestore collections.
void main() {
  const id = AppStrings(AppLanguage.indonesian);
  const en = AppStrings(AppLanguage.english);

  ExamResult kanaResult({
    ExamMode mode = ExamMode.hiragana,
    int score = 8,
    int total = 10,
    required DateTime completedAt,
  }) =>
      ExamResult(
        mode: mode,
        score: score,
        total: total,
        wrongAnswers: const [],
        completedAt: completedAt,
      );

  SimpleExamResult simpleResult({
    required String itemId,
    String jlptLevel = 'N4',
    int score = 7,
    int total = 10,
    required DateTime completedAt,
  }) =>
      SimpleExamResult(
        itemId: itemId,
        jlptLevel: jlptLevel,
        score: score,
        total: total,
        completedAt: completedAt,
      );

  test('a Dokkai-only history (no kana attempts) still produces entries', () {
    // This is the exact bug report: a user who only ever took Dokkai/
    // Choukai/Kanji-Kombinasi exams saw an empty history, because the old
    // provider queried kana's `examHistory` collection exclusively.
    final entries = mergeExamHistory(
      kana: const [],
      dokkai: [simpleResult(itemId: 'dokkai_session_1', jlptLevel: 'N3', completedAt: DateTime(2026, 7, 30))],
      choukai: const [],
      kanjiCombo: const [],
      s: id,
    );

    expect(entries, hasLength(1));
    expect(entries.single.label, 'Dokkai N3');
    expect(entries.single.score, 7);
    expect(entries.single.total, 10);
  });

  test('merges and sorts all four categories newest-first', () {
    final entries = mergeExamHistory(
      kana: [
        kanaResult(mode: ExamMode.hiragana, completedAt: DateTime(2026, 7, 28)),
      ],
      dokkai: [
        simpleResult(itemId: 'dokkai_session_1', jlptLevel: 'N3', completedAt: DateTime(2026, 7, 30)),
      ],
      choukai: [
        simpleResult(itemId: 'clip_1', jlptLevel: 'N2', completedAt: DateTime(2026, 7, 29)),
      ],
      kanjiCombo: [
        simpleResult(itemId: 'combo_n5', jlptLevel: 'N5', completedAt: DateTime(2026, 7, 27)),
        simpleResult(itemId: 'single_n5', jlptLevel: 'N5', completedAt: DateTime(2026, 7, 26)),
      ],
      s: id,
    );

    expect(entries, hasLength(5));
    // Newest first: Dokkai (7/30) > Choukai (7/29) > Kana (7/28) >
    // combo (7/27) > single (7/26).
    expect(entries.map((e) => e.label), [
      'Dokkai N3',
      'Choukai N2',
      'Ujian Hiragana',
      'Kombinasi Kanji N5',
      'Kanji Tunggal N5',
    ]);
  });

  test('kana mode label follows the language toggle', () {
    final now = DateTime(2026, 7, 30);
    final indonesianEntries = mergeExamHistory(
      kana: [kanaResult(mode: ExamMode.mixed, completedAt: now)],
      dokkai: const [],
      choukai: const [],
      kanjiCombo: const [],
      s: id,
    );
    final englishEntries = mergeExamHistory(
      kana: [kanaResult(mode: ExamMode.mixed, completedAt: now)],
      dokkai: const [],
      choukai: const [],
      kanjiCombo: const [],
      s: en,
    );

    expect(indonesianEntries.single.label, 'Ujian Campuran');
    expect(englishEntries.single.label, 'Mixed Exam');
  });

  test('kanji-combo label distinguishes combination vs single from itemId', () {
    final now = DateTime(2026, 7, 30);
    final entries = mergeExamHistory(
      kana: const [],
      dokkai: const [],
      choukai: const [],
      kanjiCombo: [
        simpleResult(itemId: 'combo_n2', jlptLevel: 'N2', completedAt: now),
        simpleResult(
          itemId: 'single_n2',
          jlptLevel: 'N2',
          completedAt: now.subtract(const Duration(minutes: 1)),
        ),
      ],
      s: en,
    );

    expect(entries[0].label, 'Kanji Combination N2');
    expect(entries[1].label, 'Single Kanji N2');
  });

  test('truncates to at most [limit] entries after sorting', () {
    final many = List.generate(
      5,
      (i) => simpleResult(
        itemId: 'dokkai_session_$i',
        completedAt: DateTime(2026, 7, 30).subtract(Duration(days: i)),
      ),
    );
    final entries = mergeExamHistory(
      kana: const [],
      dokkai: many,
      choukai: const [],
      kanjiCombo: const [],
      s: id,
      limit: 3,
    );

    expect(entries, hasLength(3));
    // Still newest-first after truncation.
    expect(entries.first.completedAt, DateTime(2026, 7, 30));
  });

  test('empty everywhere produces an empty list, not an error', () {
    final entries = mergeExamHistory(
      kana: const [],
      dokkai: const [],
      choukai: const [],
      kanjiCombo: const [],
      s: id,
    );
    expect(entries, isEmpty);
  });
}

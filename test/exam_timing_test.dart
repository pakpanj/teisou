import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/constants/exam_timing.dart';
import 'package:kana_master/core/theme/app_theme.dart';
import 'package:kana_master/data/models/quiz_review_entry.dart';
import 'package:kana_master/features/exam/exam_countdown.dart';
import 'package:kana_master/features/exam/mc_quiz_flow.dart';

/// Timed and untimed exams.
///
/// The part worth covering is what happens when the clock runs out, and
/// it is worth covering because the tempting shortcut — end the exam,
/// score what was answered — makes running out of time *raise* the
/// learner's percentage, which would make the timed mode the easy one.
void main() {
  const questions = 4;

  Widget host({
    Duration? limit,
    required void Function(int score, int total, List<QuizReviewEntry> wrong)
        onComplete,
  }) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: McQuizFlow(
            totalQuestions: questions,
            timeLimit: limit,
            headerBuilder: (_, index) => Text('soal $index'),
            optionsOf: (index) => ['benar $index', 'salah $index'],
            correctIndexOf: (_) => 0,
            questionLabelOf: (index) => 'soal $index',
            onComplete: onComplete,
          ),
        ),
      ),
    );
  }

  group('aturan waktu', () {
    test('setiap jenis ujian punya jatah per soalnya sendiri', () {
      // Satu angka untuk semuanya akan kejam buat Dokkai (harus baca
      // bacaan dulu) atau tak berarti buat Kana.
      expect(examSecondsPerQuestion(ExamKind.dokkai),
          greaterThan(examSecondsPerQuestion(ExamKind.kana)));
      expect(examSecondsPerQuestion(ExamKind.choukai),
          greaterThan(examSecondsPerQuestion(ExamKind.kanji)));
      for (final kind in ExamKind.values) {
        expect(examSecondsPerQuestion(kind), greaterThan(0));
      }
    });

    test('jatah ujian adalah satu anggaran untuk seluruh soal', () {
      final ten = examTimeLimit(ExamKind.kana, 10);
      final twenty = examTimeLimit(ExamKind.kana, 20);
      expect(twenty, ten * 2);
    });
  });

  testWidgets('tanpa timer, tidak ada jam yang berjalan', (tester) async {
    await tester.pumpWidget(host(onComplete: (_, _, _) {}));
    await tester.pump();

    expect(find.byType(ExamCountdown), findsNothing);
  });

  testWidgets('dengan timer, jam tampil dan berkurang', (tester) async {
    await tester.pumpWidget(
      host(limit: const Duration(minutes: 1), onComplete: (_, _, _) {}),
    );
    await tester.pump();

    expect(find.text('1:00'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('0:59'), findsOneWidget);
  });

  testWidgets('waktu habis mengakhiri ujian', (tester) async {
    int? score;
    int? total;
    await tester.pumpWidget(
      host(
        limit: const Duration(seconds: 2),
        onComplete: (s, t, _) {
          score = s;
          total = t;
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(score, isNull, reason: 'masih ada waktu');

    await tester.pump(const Duration(seconds: 1));
    expect(score, 0);
    expect(total, questions);
  });

  testWidgets('soal yang belum dijawab dihitung salah, bukan diabaikan', (
    tester,
  ) async {
    // Kalau yang belum dikerjakan tidak dihitung, kehabisan waktu di soal
    // pertama justru memberi nilai 1/1 = 100%.
    int? score;
    int? total;
    List<QuizReviewEntry>? wrong;
    await tester.pumpWidget(
      host(
        limit: const Duration(seconds: 2),
        onComplete: (s, t, w) {
          score = s;
          total = t;
          wrong = w;
        },
      ),
    );
    await tester.pump();

    // Jawab satu soal dengan benar, lalu biarkan waktunya habis.
    await tester.tap(find.text('benar 0'));
    await tester.pump();
    await tester.tap(find.text('Periksa Jawaban'));
    await tester.pump();

    await tester.pump(const Duration(seconds: 2));

    expect(score, 1);
    expect(total, questions, reason: 'seluruh paper, bukan yang dikerjakan');
    expect(wrong, hasLength(questions - 1),
        reason: 'tiga soal sisanya masuk daftar salah');
    expect(wrong!.every((w) => w.userAnswer.isEmpty), isTrue);
  });

  testWidgets('ujian tidak diselesaikan dua kali', (tester) async {
    // Jam yang habis tepat saat soal terakhir dikirim akan memanggil
    // penyelesaian untuk kedua kalinya.
    var completions = 0;
    await tester.pumpWidget(
      host(
        limit: const Duration(seconds: 3),
        onComplete: (_, _, _) => completions++,
      ),
    );
    await tester.pump();

    for (var i = 0; i < questions; i++) {
      await tester.tap(find.text('benar $i'));
      await tester.pump();
      await tester.tap(find.text('Periksa Jawaban'));
      await tester.pump();
      // "Soal Berikutnya" pada soal biasa, "Selesai" pada yang terakhir.
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
    }
    expect(completions, 1);

    await tester.pump(const Duration(seconds: 5));
    expect(completions, 1, reason: 'jam yang habis setelahnya tidak menambah');
  });
}

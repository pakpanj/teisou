import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/constants/exam_timing.dart';
import 'package:kana_master/core/theme/app_theme.dart';
import 'package:kana_master/data/models/quiz_review_entry.dart';
import 'package:kana_master/features/exam/exam_countdown.dart';
import 'package:kana_master/features/exam/mc_quiz_flow.dart';

/// Timed and untimed exams, with the clock running per question.
///
/// The parts worth covering are what running out costs and what it does
/// *not* cost: a timed-out question must be marked wrong (skipping it
/// would let a learner who stalls on everything they cannot answer finish
/// with a perfect score out of the few they can), and the clock must stop
/// once an answer is graded, or reading the explanation is rushed.
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

  group('pilihan waktu', () {
    test('waktu yang bisa dipilih mencakup drill sampai baca santai', () {
      expect(kExamPerQuestionChoices, isNotEmpty);
      expect(kExamPerQuestionChoices.first, lessThanOrEqualTo(10));
      expect(kExamPerQuestionChoices.last, greaterThanOrEqualTo(60));
      // Menaik, supaya deretan pilihannya terbaca wajar.
      final sorted = [...kExamPerQuestionChoices]..sort();
      expect(kExamPerQuestionChoices, sorted);
    });

    test('saran awal tiap ujian ada di daftar pilihan', () {
      // Kalau tidak, picker terbuka tanpa satu pun pilihan tersorot.
      for (final kind in ExamKind.values) {
        expect(
          kExamPerQuestionChoices,
          contains(examDefaultSecondsPerQuestion(kind)),
          reason: '$kind',
        );
      }
    });

    test('saran awalnya berbeda sesuai berat soalnya', () {
      expect(
        examDefaultSecondsPerQuestion(ExamKind.dokkai),
        greaterThan(examDefaultSecondsPerQuestion(ExamKind.kana)),
      );
      expect(
        examDefaultSecondsPerQuestion(ExamKind.choukai),
        greaterThan(examDefaultSecondsPerQuestion(ExamKind.kanji)),
      );
    });
  });

  testWidgets('tanpa timer, tidak ada jam yang berjalan', (tester) async {
    await tester.pumpWidget(host(onComplete: (_, _, _) {}));
    await tester.pump();

    expect(find.byType(ExamCountdown), findsNothing);
  });

  testWidgets('jam berjalan mundur pada soal berjalan', (tester) async {
    await tester.pumpWidget(
      host(limit: const Duration(seconds: 20), onComplete: (_, _, _) {}),
    );
    await tester.pump();

    expect(find.text('20s'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('19s'), findsOneWidget);
  });

  testWidgets('waktu soal habis: ditandai salah lalu lanjut', (tester) async {
    await tester.pumpWidget(
      host(limit: const Duration(seconds: 3), onComplete: (_, _, _) {}),
    );
    await tester.pump();
    expect(find.text('soal 0'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(find.text('soal 1'), findsOneWidget, reason: 'pindah sendiri');
    expect(find.text('soal 0'), findsNothing);
  });

  testWidgets('tiap soal dapat jatah baru, bukan sisa soal sebelumnya', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(limit: const Duration(seconds: 3), onComplete: (_, _, _) {}),
    );
    await tester.pump();

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(find.text('3s'), findsOneWidget, reason: 'jam disetel ulang');
  });

  testWidgets('soal yang kehabisan waktu dihitung salah', (tester) async {
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

    // Jawab soal pertama dengan benar, lalu biarkan tiga sisanya habis.
    await tester.tap(find.text('benar 0'));
    await tester.pump();
    await tester.tap(find.text('Periksa Jawaban'));
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
    }

    expect(score, 1);
    expect(total, questions, reason: 'dibagi seluruh soal, bukan yang dijawab');
    expect(wrong, hasLength(3));
    expect(wrong!.every((w) => w.userAnswer.isEmpty), isTrue);
  });

  testWidgets('jam berhenti begitu jawaban diperiksa', (tester) async {
    // Kalau tidak, penjelasan jawaban ikut dikejar waktu. Yang diperiksa
    // angkanya, bukan sekadar "soalnya tidak berpindah": perpindahan
    // sudah dijaga terpisah oleh pemeriksaan _committed, jadi tes yang
    // hanya melihat itu tetap lulus walau jamnya terus jalan.
    await tester.pumpWidget(
      host(limit: const Duration(seconds: 30), onComplete: (_, _, _) {}),
    );
    await tester.pump();

    await tester.pump(const Duration(seconds: 5));
    expect(find.text('25s'), findsOneWidget);

    await tester.tap(find.text('benar 0'));
    await tester.pump();
    await tester.tap(find.text('Periksa Jawaban'));
    await tester.pump();

    await tester.pump(const Duration(seconds: 5));
    expect(
      find.text('25s'),
      findsOneWidget,
      reason: 'jamnya tetap jalan saat jawaban sedang dibaca',
    );
  });

  testWidgets('waktu habis di soal terakhir menyelesaikan ujian', (
    tester,
  ) async {
    var completions = 0;
    await tester.pumpWidget(
      host(
        limit: const Duration(seconds: 2),
        onComplete: (_, _, _) => completions++,
      ),
    );
    await tester.pump();

    for (var i = 0; i < questions; i++) {
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
    }
    expect(completions, 1);

    await tester.pump(const Duration(seconds: 10));
    expect(completions, 1, reason: 'tidak diselesaikan dua kali');
  });
}

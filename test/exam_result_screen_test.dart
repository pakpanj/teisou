import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/data/models/exam_mode.dart';
import 'package:kana_master/data/models/exam_result.dart';
import 'package:kana_master/features/exam_result/exam_result_screen.dart';

void main() {
  testWidgets('ExamResultScreen shows score, percentage and stat cards', (
    WidgetTester tester,
  ) async {
    final result = ExamResult(
      mode: ExamMode.hiragana,
      score: 8,
      total: 10,
      wrongAnswers: const [],
      completedAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(MaterialApp(home: ExamResultScreen(result: result)));

    expect(find.text('8 / 10'), findsOneWidget);
    expect(find.text('80%'), findsOneWidget);
    expect(find.text('Benar'), findsOneWidget);
    expect(find.text('Salah'), findsOneWidget);
    expect(find.text('Ulangi Ujian'), findsOneWidget);
    expect(find.text('Kembali ke Menu'), findsOneWidget);
  });
}

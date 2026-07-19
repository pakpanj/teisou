import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/features/exam/exam_mode_picker_screen.dart';

void main() {
  testWidgets('ExamModePickerScreen lists all four exam categories', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ExamModePickerScreen()),
      ),
    );

    expect(find.text('Kana'), findsOneWidget);
    expect(find.text('Dokkai'), findsOneWidget);
    expect(find.text('Choukai'), findsOneWidget);
    expect(find.text('Kanji'), findsOneWidget);
  });
}

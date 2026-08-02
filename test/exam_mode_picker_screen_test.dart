import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/features/exam/exam_mode_picker_screen.dart';

void main() {
  testWidgets(
      'ExamModePickerScreen lists the two real exam categories '
      '(Dokkai moved to Home\'s Latihan section, Choukai hidden until it '
      'has content)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ExamModePickerScreen()),
      ),
    );

    expect(find.text('Kana'), findsOneWidget);
    expect(find.text('Kanji'), findsOneWidget);
    expect(find.text('Dokkai'), findsNothing);
    expect(find.text('Choukai'), findsNothing);
  });
}

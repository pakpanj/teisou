import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/services/kanjivg_parser.dart';

void main() {
  testWidgets('parses a single-stroke kanji (一)', (tester) async {
    final data = await KanjiVgParser.parse('assets/kanjivg/04e00.svg');

    expect(data, isNotNull);
    expect(data!.strokes.length, 1);
    expect(data.viewBox.width, 109);
  });

  testWidgets('parses a complex multi-group kanji (漢, 13 strokes)', (tester) async {
    final data = await KanjiVgParser.parse('assets/kanjivg/06f22.svg');

    expect(data, isNotNull);
    final strokes = data!.strokes;
    expect(strokes.length, 13);
    // Stroke numbers must come out sorted 1..13 even though nested <g>
    // groups interleave the underlying XML order.
    expect(strokes.map((s) => s.number).toList(), List.generate(13, (i) => i + 1));
    for (final stroke in strokes) {
      expect(stroke.path.computeMetrics().isNotEmpty, isTrue);
    }
  });

  testWidgets('returns null for a missing asset', (tester) async {
    final data = await KanjiVgParser.parse('assets/kanjivg/00000.svg');
    expect(data, isNull);
  });
}

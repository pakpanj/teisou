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

  testWidgets('correctly parses smooth-cubic s/S commands (近, N4)', (tester) async {
    final data = await KanjiVgParser.parse('assets/kanjivg/08fd1.svg');
    expect(data, isNotNull);
    final strokes = data!.strokes;
    expect(strokes.length, 7);

    // Stroke 1 (kvg:08fd1-s1) ends with an absolute "C"; endpoint
    // hand-computed by walking the raw SVG's `d` attribute. The old
    // M/c-only parser (case-sensitive: "C" != "c") dropped or misgrouped
    // these numbers instead, same failure mode as s/S below.
    final stroke1 = strokes[0].path.computeMetrics().first;
    final stroke1End = stroke1.getTangentForOffset(stroke1.length)!.position;
    expect(stroke1End.dx, closeTo(51.81, 0.5));
    expect(stroke1End.dy, closeTo(26.72, 0.5));

    // Stroke 6 (kvg:08fd1-s6) has a mid-path absolute "S"; endpoint
    // hand-computed the same way.
    final stroke6 = strokes[5].path.computeMetrics().first;
    final stroke6End = stroke6.getTangentForOffset(stroke6.length)!.position;
    expect(stroke6End.dx, closeTo(19.36, 0.5));
    expect(stroke6End.dy, closeTo(81.5, 0.5));

    // Stroke 7 (kvg:08fd1-s7) has a relative "s"; endpoint hand-computed
    // the same way.
    final stroke7 = strokes[6].path.computeMetrics().first;
    final stroke7End = stroke7.getTangentForOffset(stroke7.length)!.position;
    expect(stroke7End.dx, closeTo(93.5, 0.5));
    expect(stroke7End.dy, closeTo(94, 0.5));
  });

  testWidgets('correctly parses a lowercase opening "m" (N3 addition)', (tester) async {
    // kvg:06163-s4 opens with lowercase "m" instead of "M" — the only two
    // strokes (out of 5003 across all 555 bundled kanji) that do. Endpoint
    // hand-computed by walking the raw `d` attribute; the pre-fix parser
    // dropped this stroke's numbers entirely (its regex only recognized
    // uppercase M as a moveto).
    final data = await KanjiVgParser.parse('assets/kanjivg/06163.svg');
    expect(data, isNotNull);
    final strokes = data!.strokes;
    expect(strokes.length, 14);

    final stroke4 = strokes[3].path.computeMetrics().first;
    final stroke4End = stroke4.getTangentForOffset(stroke4.length)!.position;
    expect(stroke4End.dx, closeTo(82.19, 0.5));
    expect(stroke4End.dy, closeTo(36.22, 0.5));
  });
}

import 'dart:ui' show Rect;

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/services/kanjivg_parser.dart';

void main() {
  // rootBundle caches one Future per asset, globally. These tests load
  // the same file more than once, and the second read would otherwise
  // await a Future created inside an earlier test's fake-async zone --
  // already complete, but unable to deliver that completion here, so the
  // test hangs rather than fails. Same trap as kana_table_screen_test.
  setUp(rootBundle.clear);

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

    final stroke4b = strokes[3].path.computeMetrics().first;
    final stroke4End = stroke4b.getTangentForOffset(stroke4b.length)!.position;
    expect(stroke4End.dx, closeTo(82.19, 0.5));
    expect(stroke4End.dy, closeTo(36.22, 0.5));
  });

  /// Youon are two codepoints with no combined KanjiVG file, so the halves
  /// are merged here into one sequence. きょ is the worked example: き is 3
  /// strokes, ょ is 3, and a learner writes all six in that order.
  group('combining two glyphs into one sequence (youon)', () {
    const ki = 'assets/svg/hiragana/ki.svg';
    const smallYo = 'assets/svg/hiragana/small_yo.svg';

    testWidgets('strokes of both glyphs, numbered straight through',
        (tester) async {
      final data = await KanjiVgParser.parseAll([ki, smallYo]);
      expect(data, isNotNull);

      final single = await KanjiVgParser.parse(ki);
      final smaller = await KanjiVgParser.parse(smallYo);
      final expected = single!.strokes.length + smaller!.strokes.length;

      expect(data!.strokes.length, expected);
      // Restarting at 1 for the second glyph would tell a learner to write
      // the small kana first, which is the thing this exists to get right.
      expect(
        data.strokes.map((s) => s.number).toList(),
        List.generate(expected, (i) => i + 1),
      );
    });

    testWidgets('the second glyph is moved clear of the first',
        (tester) async {
      final single = await KanjiVgParser.parse(ki);
      final data = await KanjiVgParser.parseAll([ki, smallYo]);
      final width = single!.viewBox.width;

      // Without the shift both glyphs would be drawn on top of each other
      // inside the same 109-unit box, which reads as one scribble.
      for (final stroke in data!.strokes.skip(single.strokes.length)) {
        expect(stroke.path.getBounds().left, greaterThanOrEqualTo(width));
      }
      for (final stroke in data.strokes.take(single.strokes.length)) {
        expect(stroke.path.getBounds().left, lessThan(width));
      }
      expect(
        data.viewBox.width,
        closeTo(width * (1 + KanjiVgParser.secondaryGlyphScale), 0.01),
      );
      expect(data.viewBox.height, single.viewBox.height);
    });

    testWidgets('the small half is drawn smaller, and sits lower',
        (tester) async {
      final smaller = await KanjiVgParser.parse(smallYo);
      final single = await KanjiVgParser.parse(ki);
      final data = await KanjiVgParser.parseAll([ki, smallYo]);

      Rect boundsOf(Iterable<KanjiStroke> strokes) => strokes
          .map((s) => s.path.getBounds())
          .reduce((a, b) => a.expandToInclude(b));

      final alone = boundsOf(smaller!.strokes);
      final combined = boundsOf(data!.strokes.skip(single!.strokes.length));

      // KanjiVG draws a small kana at very nearly the size of a full one,
      // so without this the pair reads as two full-size characters.
      expect(
        combined.height,
        closeTo(alone.height * KanjiVgParser.secondaryGlyphScale, 0.5),
      );
      // Anchored at the bottom, so shrinking drops it onto the line instead
      // of leaving it hanging where a full-size kana's top would be.
      expect(combined.top, greaterThan(alone.top));
    });

    testWidgets('one asset is left exactly as parse() returns it',
        (tester) async {
      final viaParse = await KanjiVgParser.parse(ki);
      final viaParseAll = await KanjiVgParser.parseAll([ki]);
      expect(viaParseAll!.strokes.length, viaParse!.strokes.length);
      expect(viaParseAll.viewBox, viaParse.viewBox);
    });

    testWidgets('a broken half still yields the readable one', (tester) async {
      // Better a half-drawn character than a blank card.
      final data = await KanjiVgParser.parseAll([ki, 'assets/svg/nope.svg']);
      final single = await KanjiVgParser.parse(ki);
      expect(data, isNotNull);
      expect(data!.strokes.length, single!.strokes.length);
    });
  });
}

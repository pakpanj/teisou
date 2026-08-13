import 'dart:typed_data' show Float64List;
import 'dart:ui';

import 'package:flutter/services.dart' show rootBundle;
import 'package:xml/xml.dart';

/// One numbered stroke: the drawable [path] plus where KanjiVG itself
/// placed the stroke-order number label (`kvg:StrokeNumbers_*`'s `<text>`
/// position) — reused rather than recomputed.
class KanjiStroke {
  final Path path;
  final Offset numberPosition;
  final int number;

  KanjiStroke({required this.path, required this.numberPosition, required this.number});
}

class KanjiStrokeData {
  final List<KanjiStroke> strokes;
  final Size viewBox;

  KanjiStrokeData({required this.strokes, required this.viewBox});
}

/// Parses a KanjiVG SVG asset into drawable strokes for
/// `StrokeOrderAnimator`.
///
/// KanjiVG's own SVG generator opens each stroke with a moveto — usually
/// absolute `M`, occasionally lowercase `m` (only ever as the very first
/// command, where the SVG spec says relative-vs-absolute is moot: a
/// path's opening moveto has no preceding current point, so `m` there
/// means the same thing `M` would) — followed by cubic-Bezier commands:
/// relative `c` most often, but also absolute `C` and smooth continuations
/// `s`/`S` (reflecting the previous curve's second control point instead
/// of specifying its own first control point) — confirmed by scanning
/// every bundled file's stroke paths rather than assuming general SVG
/// path-data support (M/m/c/C/s/S is the complete command vocabulary
/// actually used; nothing else appears, and every stroke is a single
/// continuous subpath — `m`/`M` never recurs mid-stroke). That constrained
/// vocabulary is what makes a small hand-written parser safe here; this
/// is not a general SVG path parser and will silently produce an empty
/// path for any command outside M/m/c/C/s/S.
class KanjiVgParser {
  static final _strokeNumberPattern = RegExp(r'-s(\d+)$');
  static final _matrixPattern = RegExp(r'matrix\(([^)]+)\)');
  static final _commandPattern = RegExp(r'([McsSCm])([^McsSCm]*)');
  static final _numberPattern = RegExp(r'-?\d+\.?\d*');

  /// Parses several glyphs and lays them out left to right as one sequence.
  ///
  /// This exists for youon: きょ is two codepoints, KanjiVG has no combined
  /// file for the pair, and drawing them as two independent animations
  /// would play both at once — the wrong order for something written き
  /// first, ょ second. Merging into a single [KanjiStrokeData] instead means
  /// the animator needs no notion of "several glyphs" at all: it sees one
  /// six-stroke character in a wider view box.
  ///
  /// Stroke numbers are reassigned across the whole run, so the second
  /// glyph continues 4, 5, 6 rather than restarting at 1.
  ///
  /// Returns null only if every path failed; one unreadable glyph out of
  /// two still yields the other, which is better than a blank card.
  static Future<KanjiStrokeData?> parseAll(List<String> assetPaths) async {
    if (assetPaths.length == 1) return parse(assetPaths.first);

    final parsed = <KanjiStrokeData>[];
    for (final path in assetPaths) {
      final data = await parse(path);
      if (data != null) parsed.add(data);
    }
    if (parsed.isEmpty) return null;
    if (parsed.length == 1) return parsed.first;

    final height = parsed
        .map((d) => d.viewBox.height)
        .reduce((a, b) => a > b ? a : b);

    final strokes = <KanjiStroke>[];
    var offsetX = 0.0;
    for (var i = 0; i < parsed.length; i++) {
      final data = parsed[i];
      final scale = i == 0 ? 1.0 : secondaryGlyphScale;
      // Anchored at the bottom, so shrinking moves the glyph down onto the
      // line rather than leaving it floating at the height a full-size kana
      // would occupy — which is where a small kana actually sits.
      final dy = height * (1 - scale);
      for (final stroke in data.strokes) {
        strokes.add(KanjiStroke(
          path: stroke.path.transform(_scaleThenShift(scale, offsetX, dy)),
          numberPosition: Offset(
            stroke.numberPosition.dx * scale + offsetX,
            stroke.numberPosition.dy * scale + dy,
          ),
          number: strokes.length + 1,
        ));
      }
      offsetX += data.viewBox.width * scale;
    }
    return KanjiStrokeData(
      strokes: strokes,
      viewBox: Size(offsetX, height),
    );
  }

  /// How much smaller every glyph after the first is drawn.
  ///
  /// KanjiVG draws each codepoint to fill its own box, so a small ゃ/ゅ/ょ
  /// arrives very nearly the size of a full kana — measured against the
  /// bundled files, identical in width (59.9 vs chi's 59.8) and 0.77 of the
  /// height. Rendered as-is the pair reads as two full-size characters
  /// rather than a kana and its small partner, so the second is taken down
  /// a step here.
  static const double secondaryGlyphScale = 0.8;

  /// Column-major 4x4 for `x' = scale*x + dx`, `y' = scale*y + dy`.
  ///
  /// Written out rather than built with Matrix4: that lives in
  /// `vector_math`, which this package does not depend on directly, and
  /// pulling in a transitive dependency for one translation-and-scale is a
  /// worse trade than sixteen explicit numbers.
  static Float64List _scaleThenShift(double scale, double dx, double dy) {
    return Float64List.fromList([
      scale, 0, 0, 0, //
      0, scale, 0, 0, //
      0, 0, 1, 0, //
      dx, dy, 0, 1, //
    ]);
  }

  static Future<KanjiStrokeData?> parse(String assetPath) async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final document = XmlDocument.parse(raw);
      final svg = document.rootElement;

      final viewBox = _parseViewBox(svg.getAttribute('viewBox'));

      final pathElements = document
          .findAllElements('path')
          .where((e) => (e.getAttribute('id') ?? '').contains('-s'))
          .toList()
        ..sort((a, b) => _strokeNumber(a).compareTo(_strokeNumber(b)));

      final numberPositions = document
          .findAllElements('text')
          .map(_parseTextPosition)
          .toList();

      final strokes = <KanjiStroke>[
        for (var i = 0; i < pathElements.length; i++)
          KanjiStroke(
            path: _parsePathData(pathElements[i].getAttribute('d') ?? ''),
            numberPosition: i < numberPositions.length ? numberPositions[i] : Offset.zero,
            number: i + 1,
          ),
      ];

      if (strokes.isEmpty) return null;
      return KanjiStrokeData(strokes: strokes, viewBox: viewBox);
    } catch (_) {
      // Missing asset, malformed SVG, whatever — callers fall back to a
      // plain character display, same spirit as KanjiGlyph.
      return null;
    }
  }

  static int _strokeNumber(XmlElement path) {
    final id = path.getAttribute('id') ?? '';
    final match = _strokeNumberPattern.firstMatch(id);
    return match != null ? int.parse(match.group(1)!) : 0;
  }

  static Size _parseViewBox(String? raw) {
    if (raw == null) return const Size(109, 109);
    final parts = raw.trim().split(RegExp(r'\s+')).map(double.tryParse).toList();
    if (parts.length < 4 || parts[2] == null || parts[3] == null) {
      return const Size(109, 109);
    }
    return Size(parts[2]!, parts[3]!);
  }

  static Offset _parseTextPosition(XmlElement text) {
    final transform = text.getAttribute('transform') ?? '';
    final match = _matrixPattern.firstMatch(transform);
    if (match == null) return Offset.zero;
    final numbers = match
        .group(1)!
        .trim()
        .split(RegExp(r'[\s,]+'))
        .map(double.tryParse)
        .toList();
    if (numbers.length < 6 || numbers[4] == null || numbers[5] == null) return Offset.zero;
    return Offset(numbers[4]!, numbers[5]!);
  }

  /// Converts one stroke's `d` attribute into a [Path]. Handles "M x,y",
  /// relative "c" and absolute "C" cubics, and smooth-continuation "s"/"S"
  /// cubics — the latter omit their own first control point, instead
  /// implying it as the reflection of the previous cubic's second control
  /// point through the current point (or the current point itself if the
  /// previous command wasn't a cubic). Tracking `currentX/Y` and the last
  /// cubic's second control point (updated after c *and* C, since either
  /// can precede a smooth continuation) is what makes that reflection
  /// possible; without it, C/s/S's argument numbers would have to be
  /// either dropped or (as the original M/c-only parser did) misread as
  /// more args of the preceding c command, corrupting the curve from that
  /// point on.
  static Path _parsePathData(String d) {
    final path = Path();
    var currentX = 0.0, currentY = 0.0;
    var lastControl2X = 0.0, lastControl2Y = 0.0;
    var lastWasCubic = false;

    for (final match in _commandPattern.allMatches(d)) {
      final command = match.group(1)!;
      final numbers = _numberPattern
          .allMatches(match.group(2) ?? '')
          .map((m) => double.parse(m.group(0)!))
          .toList();

      if ((command == 'M' || command == 'm') && numbers.length >= 2) {
        // A path's opening moveto is absolute regardless of case (there's
        // no current point yet to be relative to) — see class doc.
        currentX = numbers[0];
        currentY = numbers[1];
        path.moveTo(currentX, currentY);
        lastWasCubic = false;
      } else if (command == 'c') {
        for (var i = 0; i + 5 < numbers.length; i += 6) {
          final x2 = numbers[i + 2], y2 = numbers[i + 3];
          final x = numbers[i + 4], y = numbers[i + 5];
          path.relativeCubicTo(numbers[i], numbers[i + 1], x2, y2, x, y);
          lastControl2X = currentX + x2;
          lastControl2Y = currentY + y2;
          currentX += x;
          currentY += y;
          lastWasCubic = true;
        }
      } else if (command == 's') {
        for (var i = 0; i + 3 < numbers.length; i += 4) {
          final x2 = numbers[i], y2 = numbers[i + 1];
          final x = numbers[i + 2], y = numbers[i + 3];
          final cp1X = lastWasCubic ? currentX - lastControl2X : 0.0;
          final cp1Y = lastWasCubic ? currentY - lastControl2Y : 0.0;
          path.relativeCubicTo(cp1X, cp1Y, x2, y2, x, y);
          lastControl2X = currentX + x2;
          lastControl2Y = currentY + y2;
          currentX += x;
          currentY += y;
          lastWasCubic = true;
        }
      } else if (command == 'C') {
        for (var i = 0; i + 5 < numbers.length; i += 6) {
          final x2 = numbers[i + 2], y2 = numbers[i + 3];
          final x = numbers[i + 4], y = numbers[i + 5];
          path.cubicTo(numbers[i], numbers[i + 1], x2, y2, x, y);
          lastControl2X = x2;
          lastControl2Y = y2;
          currentX = x;
          currentY = y;
          lastWasCubic = true;
        }
      } else if (command == 'S') {
        for (var i = 0; i + 3 < numbers.length; i += 4) {
          final x2 = numbers[i], y2 = numbers[i + 1];
          final x = numbers[i + 2], y = numbers[i + 3];
          final cp1X = lastWasCubic ? 2 * currentX - lastControl2X : currentX;
          final cp1Y = lastWasCubic ? 2 * currentY - lastControl2Y : currentY;
          path.cubicTo(cp1X, cp1Y, x2, y2, x, y);
          lastControl2X = x2;
          lastControl2Y = y2;
          currentX = x;
          currentY = y;
          lastWasCubic = true;
        }
      }
    }
    return path;
  }
}

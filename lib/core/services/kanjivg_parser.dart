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
/// KanjiVG's own SVG generator only ever emits two path commands per
/// stroke — one absolute `M` (moveto) followed by one or more relative `c`
/// (cubic Bezier) — confirmed by inspecting the fetched files directly
/// rather than assuming general SVG path-data support. That constrained
/// vocabulary is what makes a small hand-written parser safe here; this is
/// not a general SVG path parser and will silently produce an empty path
/// for any command outside M/c.
class KanjiVgParser {
  static final _strokeNumberPattern = RegExp(r'-s(\d+)$');
  static final _matrixPattern = RegExp(r'matrix\(([^)]+)\)');
  static final _commandPattern = RegExp(r'([Mc])([^Mc]*)');
  static final _numberPattern = RegExp(r'-?\d+\.?\d*');

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

  /// Converts one stroke's `d` attribute (always "M x,y" followed by one or
  /// more "c x1,y1 x2,y2 x,y" relative-cubic groups) into a [Path].
  static Path _parsePathData(String d) {
    final path = Path();
    for (final match in _commandPattern.allMatches(d)) {
      final command = match.group(1)!;
      final numbers = _numberPattern
          .allMatches(match.group(2) ?? '')
          .map((m) => double.parse(m.group(0)!))
          .toList();

      if (command == 'M' && numbers.length >= 2) {
        path.moveTo(numbers[0], numbers[1]);
      } else if (command == 'c') {
        for (var i = 0; i + 5 < numbers.length; i += 6) {
          path.relativeCubicTo(
            numbers[i],
            numbers[i + 1],
            numbers[i + 2],
            numbers[i + 3],
            numbers[i + 4],
            numbers[i + 5],
          );
        }
      }
    }
    return path;
  }
}

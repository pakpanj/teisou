import 'package:flutter/material.dart';

import '../services/kanjivg_parser.dart';
import '../theme/app_colors.dart';

/// Renders a kanji as a static, fully-drawn glyph from its KanjiVG stroke
/// data, otherwise falls back to a plain [Text] with the character.
///
/// Deliberately parses strokes via [KanjiVgParser] rather than handing the
/// raw SVG straight to `SvgPicture.asset` — the KanjiVG file also bundles a
/// `StrokeNumbers` text layer for the animated `StrokeOrderAnimator`'s
/// "show all numbered" mode, and a naive `SvgPicture.asset` render draws
/// those number labels directly on top of the glyph here too, which looks
/// like a rendering bug in a context that isn't teaching stroke order.
class KanjiGlyph extends StatelessWidget {
  final String character;
  final String? svgAsset;
  final double size;
  final Color fallbackColor;

  const KanjiGlyph({
    super.key,
    required this.character,
    this.svgAsset,
    this.size = 120,
    this.fallbackColor = AppColors.textNavy,
  });

  static final Map<String, Future<KanjiStrokeData?>> _cache = {};

  static Future<KanjiStrokeData?> _parse(String path) {
    return _cache.putIfAbsent(path, () => KanjiVgParser.parse(path));
  }

  @override
  Widget build(BuildContext context) {
    final asset = svgAsset;
    if (asset == null) return _fallback();
    return FutureBuilder<KanjiStrokeData?>(
      future: _parse(asset),
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null) return _fallback();
        return CustomPaint(
          size: Size(size, size),
          painter: _GlyphPainter(data: data, color: fallbackColor),
        );
      },
    );
  }

  Widget _fallback() => Text(
        character,
        style: TextStyle(
          fontSize: size * 0.6,
          fontWeight: FontWeight.bold,
          color: fallbackColor,
        ),
      );
}

class _GlyphPainter extends CustomPainter {
  final KanjiStrokeData data;
  final Color color;

  _GlyphPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / data.viewBox.width;
    canvas.save();
    canvas.scale(scale, scale);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final stroke in data.strokes) {
      canvas.drawPath(stroke.path, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter oldDelegate) => oldDelegate.data != data;
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

/// Renders a kanji's SVG stroke-order glyph if the asset has been
/// bundled, otherwise falls back to a plain [Text] with the character —
/// same pattern as [KanaGlyph], since `assets/svg/kanji/` art doesn't
/// exist yet.
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

  static final Map<String, bool> _existsCache = {};

  static Future<bool> _assetExists(String path) async {
    final cached = _existsCache[path];
    if (cached != null) return cached;
    try {
      await rootBundle.load(path);
      _existsCache[path] = true;
      return true;
    } catch (_) {
      _existsCache[path] = false;
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final asset = svgAsset;
    if (asset == null) return _fallback();
    return FutureBuilder<bool>(
      future: _assetExists(asset),
      builder: (context, snapshot) {
        if (snapshot.data == true) {
          return SvgPicture.asset(asset, width: size, height: size);
        }
        return _fallback();
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

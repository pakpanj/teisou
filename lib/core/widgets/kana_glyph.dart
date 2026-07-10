import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/models/kana_character.dart';
import '../theme/app_colors.dart';

/// Renders a kana's SVG glyph if the asset has been bundled, otherwise
/// falls back to a plain [Text] with the character so missing art never
/// crashes the app during development.
class KanaGlyph extends StatelessWidget {
  final KanaCharacter kana;
  final double size;
  final Color fallbackColor;

  const KanaGlyph({
    super.key,
    required this.kana,
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
    return FutureBuilder<bool>(
      future: _assetExists(kana.svgAsset),
      builder: (context, snapshot) {
        if (snapshot.data == true) {
          return SvgPicture.asset(kana.svgAsset, width: size, height: size);
        }
        return Text(
          kana.character,
          style: TextStyle(
            fontSize: size * 0.6,
            fontWeight: FontWeight.bold,
            color: fallbackColor,
          ),
        );
      },
    );
  }
}

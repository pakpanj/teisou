import 'package:shared_preferences/shared_preferences.dart';

import '../models/stroke_speed.dart';

/// Persists how fast the kana flashcard draws its strokes.
///
/// Device-local with no Firestore mirror, exactly like [LanguageRepository]
/// and the theme setting: this is a comfort preference tied to how well a
/// particular child reads a moving line, not progress worth carrying to
/// another phone. It is persisted rather than held in screen state because
/// a speed that resets every time the deck is reopened is not a setting,
/// it is a knob you have to keep re-finding.
class StrokeSpeedRepository {
  static const _prefsKey = 'stroke_speed';

  Future<StrokeSpeed> getSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    return StrokeSpeedX.fromCode(prefs.getString(_prefsKey));
  }

  Future<void> setSpeed(StrokeSpeed speed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, speed.code);
  }
}

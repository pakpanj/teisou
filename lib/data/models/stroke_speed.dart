/// How fast the kana flashcard draws each stroke.
///
/// Three named steps rather than a free slider, and that is a gesture
/// decision as much as a simplicity one: the card sits inside a
/// `SwipeNavigator`, and a slider would put a second horizontal-drag
/// recogniser in the same place as the one that changes cards. Taps cannot
/// collide with a swipe.
enum StrokeSpeed { slow, normal, fast }

extension StrokeSpeedX on StrokeSpeed {
  /// Stored in SharedPreferences, so these strings are a persisted format —
  /// renaming one silently resets every learner who had chosen it.
  String get code => switch (this) {
        StrokeSpeed.slow => 'slow',
        StrokeSpeed.normal => 'normal',
        StrokeSpeed.fast => 'fast',
      };

  /// Milliseconds per stroke handed to `StrokeOrderAnimator`.
  ///
  /// `normal` is 1000ms — a stroke you can follow with a pencil rather than
  /// one you can only watch. `fast` is the 500ms the kanji screen uses, so
  /// nothing here is quicker than the app already had, and `slow` is for a
  /// child still working out where the pen starts.
  int get msPerStroke => switch (this) {
        StrokeSpeed.slow => 1800,
        StrokeSpeed.normal => 1000,
        StrokeSpeed.fast => 500,
      };

  static StrokeSpeed fromCode(String? code) => switch (code) {
        'slow' => StrokeSpeed.slow,
        'fast' => StrokeSpeed.fast,
        _ => StrokeSpeed.normal,
      };
}

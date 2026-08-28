/// One Kanji-Kombinasi exam question, generated at runtime from the
/// existing Kanji/Kotoba datasets (no bundled JSON of its own — see
/// `KanjiComboRepository`). Either "single" mode (one kanji's
/// reading/meaning) or "combination" mode (a 2-3 kanji compound word's
/// reading, sourced from `KotobaEntry.kanji`).
class KanjiComboQuestion {
  final String id;
  final String prompt;
  final List<String> options;
  final int correctIndex;

  /// What this question is actually asking (e.g. "Apa artinya kanji ini?"
  /// vs "Bagaimana bacaan kanji ini?") — per-question rather than fixed
  /// for the whole exam, since single-kanji mode mixes meaning and reading
  /// questions in the same session to exercise both fields of the dataset.
  final String promptLabel;

  /// The REAL, stable content identity being tested — the bare kanji
  /// character (single mode) or the compound word's kanji string
  /// (combination mode) — distinct from [prompt], which for a reading
  /// question is a more elaborate display string
  /// (`_readingPrompt`'s output), not necessarily the bare character
  /// alone. This is what a server-side grader looks up in its own copy
  /// of `kanji_data.json`/`kotoba_data.json` to independently verify
  /// [correctIndex] — see `functions/exam_grading.js`.
  final String contentKey;

  /// Machine-readable prompt kind — `'reading'` or `'meaning'` — distinct
  /// from [promptLabel], which is localized display text unsuitable for a
  /// server-side grading switch.
  final String promptKind;

  KanjiComboQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.promptLabel,
    required this.contentKey,
    required this.promptKind,
  });
}

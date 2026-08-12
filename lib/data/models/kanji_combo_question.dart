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

  KanjiComboQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.promptLabel,
  });
}

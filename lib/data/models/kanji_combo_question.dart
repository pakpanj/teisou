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

  /// True for any question whose correct answer *is* a reading of
  /// [prompt] (single-kanji reading, or a compound word's reading) —
  /// used to withhold furigana from the prompt on these specifically,
  /// since a reading shown above the kanji would just be the answer.
  /// False for meaning questions, where furigana is safe and helpful.
  final bool isReadingQuestion;

  KanjiComboQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.promptLabel,
    required this.isReadingQuestion,
  });
}

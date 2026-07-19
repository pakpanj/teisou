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

  KanjiComboQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctIndex,
  });
}

/// The app's UI-chrome display language — Bahasa Indonesia (default) or
/// English. Deliberately separate from the learning content itself: kana/
/// kanji/kotoba/bunpou/particle/kaiwa datasets stay Indonesian-authored
/// either way (translating ~4000 pieces of educational content is a
/// separate, much larger effort than switching interface text). See
/// CLAUDE.md for exactly which screens read this so far.
enum AppLanguage { indonesian, english }

extension AppLanguageX on AppLanguage {
  String get code => this == AppLanguage.indonesian ? 'id' : 'en';

  String get label =>
      this == AppLanguage.indonesian ? 'Bahasa Indonesia' : 'English';

  String get flagEmoji => this == AppLanguage.indonesian ? '🇮🇩' : '🇬🇧';

  static AppLanguage fromCode(String? code) =>
      code == 'en' ? AppLanguage.english : AppLanguage.indonesian;
}

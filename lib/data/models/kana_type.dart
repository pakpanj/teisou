enum KanaType { hiragana, katakana }

extension KanaTypeX on KanaType {
  String get key => this == KanaType.hiragana ? 'hiragana' : 'katakana';

  static KanaType fromKey(String key) =>
      key == 'hiragana' ? KanaType.hiragana : KanaType.katakana;
}

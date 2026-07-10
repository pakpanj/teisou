enum ExamMode { hiragana, katakana, mixed }

extension ExamModeX on ExamMode {
  String get key {
    switch (this) {
      case ExamMode.hiragana:
        return 'hiragana';
      case ExamMode.katakana:
        return 'katakana';
      case ExamMode.mixed:
        return 'mixed';
    }
  }

  String get title {
    switch (this) {
      case ExamMode.hiragana:
        return 'Ujian Hiragana';
      case ExamMode.katakana:
        return 'Ujian Katakana';
      case ExamMode.mixed:
        return 'Ujian Campuran';
    }
  }
}

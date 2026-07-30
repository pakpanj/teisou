import 'app_language.dart';

enum SpeechRegister { casual, formal, keigo }

extension SpeechRegisterX on SpeechRegister {
  String get key {
    switch (this) {
      case SpeechRegister.casual:
        return 'casual';
      case SpeechRegister.formal:
        return 'formal';
      case SpeechRegister.keigo:
        return 'keigo';
    }
  }

  String get label {
    switch (this) {
      case SpeechRegister.casual:
        return 'Santai';
      case SpeechRegister.formal:
        return 'Formal';
      case SpeechRegister.keigo:
        return 'Keigo';
    }
  }

  String localizedLabel(AppLanguage language) {
    if (language != AppLanguage.english) return label;
    switch (this) {
      case SpeechRegister.casual:
        return 'Casual';
      case SpeechRegister.formal:
        return 'Formal';
      case SpeechRegister.keigo:
        return 'Keigo';
    }
  }

  String get emoji {
    switch (this) {
      case SpeechRegister.casual:
        return '😊';
      case SpeechRegister.formal:
        return '🤵';
      case SpeechRegister.keigo:
        return '🎌';
    }
  }
}

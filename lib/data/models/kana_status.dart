enum KanaStatus { newKana, learning, mastered }

extension KanaStatusX on KanaStatus {
  String get key {
    switch (this) {
      case KanaStatus.newKana:
        return 'new';
      case KanaStatus.learning:
        return 'learning';
      case KanaStatus.mastered:
        return 'mastered';
    }
  }

  static KanaStatus fromKey(String? key) {
    switch (key) {
      case 'learning':
        return KanaStatus.learning;
      case 'mastered':
        return KanaStatus.mastered;
      default:
        return KanaStatus.newKana;
    }
  }
}

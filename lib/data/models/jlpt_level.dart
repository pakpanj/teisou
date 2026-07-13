enum JlptLevel { n5, n4, n3, n2, n1 }

extension JlptLevelX on JlptLevel {
  String get key {
    switch (this) {
      case JlptLevel.n5:
        return 'N5';
      case JlptLevel.n4:
        return 'N4';
      case JlptLevel.n3:
        return 'N3';
      case JlptLevel.n2:
        return 'N2';
      case JlptLevel.n1:
        return 'N1';
    }
  }

  static JlptLevel fromKey(String? key) {
    switch (key) {
      case 'N4':
        return JlptLevel.n4;
      case 'N3':
        return JlptLevel.n3;
      case 'N2':
        return JlptLevel.n2;
      case 'N1':
        return JlptLevel.n1;
      case 'N5':
      default:
        return JlptLevel.n5;
    }
  }
}

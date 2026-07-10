/// Centralized Firestore collection/field names so paths stay consistent
/// across repositories.
class FirestorePaths {
  FirestorePaths._();

  static const users = 'users';
  static const examHistory = 'examHistory';

  static const fieldProfile = 'profile';
  static const fieldProgress = 'progress';

  static String userDoc(String uid) => '$users/$uid';
  static String examHistoryCollection(String uid) =>
      '$users/$uid/$examHistory';
}

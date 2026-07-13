/// Centralized Firestore collection/field names so paths stay consistent
/// across repositories.
class FirestorePaths {
  FirestorePaths._();

  static const users = 'users';
  static const examHistory = 'examHistory';
  static const moduleInterest = 'moduleInterest';
  static const leaderboard = 'leaderboard';
  static const savedItems = 'savedItems';

  static const fieldProfile = 'profile';
  static const fieldProgress = 'progress';
  static const fieldSubscription = 'subscription';
  static const fieldAdRewards = 'adRewards';

  static String userDoc(String uid) => '$users/$uid';
  static String examHistoryCollection(String uid) =>
      '$users/$uid/$examHistory';
  static String moduleInterestCollection(String uid) =>
      '$users/$uid/$moduleInterest';
  static String savedItemsCollection(String uid) => '$users/$uid/$savedItems';
}

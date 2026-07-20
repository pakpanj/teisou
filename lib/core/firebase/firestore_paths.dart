/// Centralized Firestore collection/field names so paths stay consistent
/// across repositories.
class FirestorePaths {
  FirestorePaths._();

  static const users = 'users';
  static const examHistory = 'examHistory';
  static const moduleInterest = 'moduleInterest';
  static const leaderboard = 'leaderboard';
  static const savedItems = 'savedItems';
  static const savedWords = 'savedWords';
  static const kotobaProgress = 'kotobaProgress';
  static const kanjiProgress = 'kanjiProgress';
  static const bunpouProgress = 'bunpouProgress';
  static const particleProgress = 'particleProgress';
  static const kaiwaProgress = 'kaiwaProgress';
  static const dokkaiExamHistory = 'dokkaiExamHistory';
  static const choukaiExamHistory = 'choukaiExamHistory';
  static const kanjiComboExamHistory = 'kanjiComboExamHistory';
  static const clans = 'clans';
  static const clanMembers = 'members';
  static const clanMemberships = 'clanMemberships';

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
  static String savedWordsCollection(String uid) => '$users/$uid/$savedWords';
  static String kotobaProgressCollection(String uid) =>
      '$users/$uid/$kotobaProgress';
  static String kanjiProgressCollection(String uid) =>
      '$users/$uid/$kanjiProgress';
  static String bunpouProgressCollection(String uid) =>
      '$users/$uid/$bunpouProgress';
  static String particleProgressCollection(String uid) =>
      '$users/$uid/$particleProgress';
  static String kaiwaProgressCollection(String uid) =>
      '$users/$uid/$kaiwaProgress';
  static String dokkaiExamHistoryCollection(String uid) =>
      '$users/$uid/$dokkaiExamHistory';
  static String choukaiExamHistoryCollection(String uid) =>
      '$users/$uid/$choukaiExamHistory';
  static String kanjiComboExamHistoryCollection(String uid) =>
      '$users/$uid/$kanjiComboExamHistory';
  static String clanDoc(String code) => '$clans/$code';
  static String clanMembersCollection(String code) =>
      '$clans/$code/$clanMembers';
  static String clanMembershipsCollection(String uid) =>
      '$users/$uid/$clanMemberships';
}

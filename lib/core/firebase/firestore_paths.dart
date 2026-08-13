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
  static const babProgress = 'babProgress';
  static const dokkaiExamHistory = 'dokkaiExamHistory';
  static const choukaiExamHistory = 'choukaiExamHistory';
  static const kanjiComboExamHistory = 'kanjiComboExamHistory';
  static const userIds = 'userIds';
  static const clans = 'clans';
  static const clanFreeSlotUsed = 'clanFreeSlotUsed';
  static const clanMembers = 'members';
  static const clanMemberships = 'clanMemberships';
  static const clanInvites = 'clanInvites';
  static const clanMessages = 'messages';
  static const clanAnnouncements = 'announcements';
  static const blockedClanUsers = 'blockedClanUsers';
  static const messageReports = 'messageReports';
  static const friends = 'friends';
  static const friendRequests = 'friendRequests';
  static const directMessages = 'directMessages';
  static const dmMessages = 'messages';
  static const fcmTokens = 'fcmTokens';
  static const notifications = 'notifications';
  static const battleMatches = 'battleMatches';
  static const battleAnswers = 'answers';
  static const battleInvites = 'battleInvites';

  static const fieldProfile = 'profile';
  static const fieldProgress = 'progress';
  static const fieldSubscription = 'subscription';
  static const fieldAdRewards = 'adRewards';
  static const fieldCardGameRank = 'cardGameRank';

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
  static String babProgressCollection(String uid) =>
      '$users/$uid/$babProgress';
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
  static String clanInvitesCollection(String uid) =>
      '$users/$uid/$clanInvites';
  static String clanMessagesCollection(String code) =>
      '$clans/$code/$clanMessages';
  static String clanAnnouncementsCollection(String code) =>
      '$clans/$code/$clanAnnouncements';
  static String blockedClanUsersCollection(String uid) =>
      '$users/$uid/$blockedClanUsers';
  static String friendsCollection(String uid) => '$users/$uid/$friends';
  static String friendRequestsCollection(String uid) =>
      '$users/$uid/$friendRequests';
  static String directMessagesDoc(String conversationId) =>
      '$directMessages/$conversationId';
  static String dmMessagesCollection(String conversationId) =>
      '$directMessages/$conversationId/$dmMessages';
  static String fcmTokensCollection(String uid) => '$users/$uid/$fcmTokens';
  static String notificationsCollection(String uid) =>
      '$users/$uid/$notifications';
  static String battleMatchDoc(String matchId) => '$battleMatches/$matchId';
  static String battleAnswersCollection(String matchId) =>
      '$battleMatches/$matchId/$battleAnswers';
}

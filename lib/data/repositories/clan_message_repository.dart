import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase/firestore_paths.dart';
import '../models/clan_message.dart';

/// Group chat scoped to one clan's own roster — every member the same
/// small circle a shared join code already vetted, not open messaging to
/// any public user.
///
/// **Why the scope stops here, deliberately, not as a placeholder for
/// "DM later".** This app has no moderation tooling anywhere — no admin
/// surface, no content review pipeline, nothing — and its audience
/// includes children (see `AdAudience`'s COPPA-driven defaults elsewhere
/// in this codebase, which already treat an unknown age as a child by
/// default). Free-text messaging between strangers, in that context, is a
/// real child-safety exposure this project has already declined once
/// before for a much smaller-risk feature: gallery avatar upload was
/// removed outright for exactly this reason ("no path to being reviewed
/// or taken down"). A clan's members already share a real join code —
/// usually a teacher/class or a group of friends who know each other —
/// which is a meaningfully different trust boundary than a public
/// leaderboard full of strangers. Open DM to any user is not built here on
/// purpose; doing that responsibly would need real moderation (human
/// review, or at minimum server-side filtering this project has no
/// Cloud Functions to run) that doesn't exist in this project yet.
///
/// **Safety rails that do exist, all client-and-rules-enforced together**:
/// a hard length cap (both here and in `firestore.rules`, so a raw write
/// can't bypass it), messages are immutable (no edit/delete, so a reported
/// message can't quietly change), per-user block (`blockUser`, hides a
/// sender's messages client-side — doesn't stop them posting, just stops
/// you from seeing it), and report-with-reason (`reportMessage`, write-only
/// — there's no admin UI to review these yet, but the record exists for
/// manual review via the Firebase console, which is the honest ceiling of
/// what this project can support right now).
class ClanMessageRepository {
  static const maxMessageLength = 300;

  final FirebaseFirestore _firestore;

  ClanMessageRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _messagesOf(String code) =>
      _firestore
          .collection(FirestorePaths.clans)
          .doc(code)
          .collection(FirestorePaths.clanMessages);

  CollectionReference<Map<String, dynamic>> _blockedBy(String uid) =>
      _firestore
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection(FirestorePaths.blockedClanUsers);

  /// Most recent [limit] messages, oldest first (ready to render straight
  /// into a chat list) — fetched newest-first from Firestore (the only
  /// direction a `limit()` can bound usefully) and reversed here.
  Stream<List<ClanMessage>> watchMessages(String code, {int limit = 100}) {
    return _messagesOf(code)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ClanMessage.fromMap(doc.id, doc.data()))
              .toList()
              .reversed
              .toList(),
        );
  }

  /// Trims and length-caps client-side as a fast, friendly rejection —
  /// `firestore.rules` enforces the same cap server-side, since a client
  /// check alone can always be bypassed by a raw write.
  Future<void> sendMessage({
    required String code,
    required String senderUid,
    required String senderName,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (trimmed.length > ClanMessageRepository.maxMessageLength) {
      throw ArgumentError('Pesan terlalu panjang.');
    }
    final message = ClanMessage(
      id: '',
      senderUid: senderUid,
      senderName: senderName,
      text: trimmed,
      createdAt: DateTime.now(),
    );
    await _messagesOf(code).add(message.toMap());
  }

  /// Live set of uids [uid] has blocked, across every clan — a block is a
  /// per-user decision, not scoped to one clan, so it applies uniformly
  /// anywhere the two might share a clan chat.
  Stream<Set<String>> watchBlockedUsers(String uid) {
    return _blockedBy(uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }

  Future<void> blockUser({required String uid, required String blockedUid}) {
    return _blockedBy(uid).doc(blockedUid).set({
      'blockedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unblockUser({
    required String uid,
    required String blockedUid,
  }) {
    return _blockedBy(uid).doc(blockedUid).delete();
  }

  /// Write-only from the app's side on purpose — there is no reader UI for
  /// this collection anywhere in the app, and `firestore.rules` only grants
  /// `create`. It exists so a report is at least on record for manual
  /// review, not because this project has a moderation workflow to route
  /// it into yet.
  Future<void> reportMessage({
    required String code,
    required String messageId,
    required String reporterUid,
    required String reason,
  }) {
    return _firestore.collection(FirestorePaths.messageReports).add({
      'code': code,
      'messageId': messageId,
      'reporterUid': reporterUid,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

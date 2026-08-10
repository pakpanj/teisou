import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase/firestore_paths.dart';
import '../models/direct_message.dart';

/// Private 1:1 chat between two friends — the "personal chat" counterpart
/// to `ClanMessageRepository`'s group chat, reachable only after both sides
/// have accepted a friend request (see `FriendRepository`).
///
/// **Why this is safer than the open DM originally asked for, and this
/// project declined once already** (see `ClanMessageRepository`'s doc
/// comment for that full child-safety reasoning): a conversation only
/// opens once the *other* person has actively accepted a request — found
/// by searching their exact short unique id or name, not by browsing a
/// public list — so a message can never reach someone who hasn't agreed to
/// hear from that specific person first. `firestore.rules` re-checks live
/// friendship on every single read and write of a conversation, not just
/// at creation time, so removing a friend immediately and permanently cuts
/// off the conversation on both sides — a stronger safety valve than clan
/// chat's client-side block, which only hides messages locally without
/// actually stopping the sender.
///
/// Same safety rails as clan chat otherwise: a hard length cap (enforced
/// here and in `firestore.rules`), immutable messages (no edit/delete),
/// and a write-only report path (`reportMessage`, into the same
/// `messageReports` collection clan chat uses) for manual review via the
/// Firebase console — there's still no admin UI in this project to route
/// reports into, same honest ceiling `ClanMessageRepository` already
/// documents.
class DirectMessageRepository {
  static const maxMessageLength = 300;

  final FirebaseFirestore _firestore;

  DirectMessageRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Deterministic conversation id for a pair of uids — sorted so both
  /// participants compute the exact same id regardless of who opens the
  /// chat first, mirroring how a clan's join code doubles as its own
  /// document id (no separate lookup index needed).
  static String conversationId(String uidA, String uidB) {
    final sorted = [uidA, uidB]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  DocumentReference<Map<String, dynamic>> _conversationDoc(
    String conversationId,
  ) =>
      _firestore.collection(FirestorePaths.directMessages).doc(conversationId);

  CollectionReference<Map<String, dynamic>> _messagesOf(
    String conversationId,
  ) =>
      _conversationDoc(conversationId).collection(FirestorePaths.dmMessages);

  /// Creates (or refreshes) the parent conversation doc with both
  /// participants — `firestore.rules` needs this doc to exist with a
  /// `participants` array before it can gate the messages subcollection on
  /// "is the caller one of the two people this conversation is between",
  /// since a security rule can't decode uids out of the id string itself.
  /// Safe to call every time a chat screen opens: writing the same two
  /// participants every time is a no-op after the first call.
  Future<void> ensureConversation({
    required String uidA,
    required String uidB,
  }) {
    final sorted = [uidA, uidB]..sort();
    return _conversationDoc(conversationId(uidA, uidB)).set({
      'participants': sorted,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Most recent [limit] messages, oldest first — same
  /// fetch-newest-then-reverse shape as `ClanMessageRepository.
  /// watchMessages`.
  Stream<List<DirectMessage>> watchMessages(
    String conversationId, {
    int limit = 100,
  }) {
    return _messagesOf(conversationId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DirectMessage.fromMap(doc.id, doc.data()))
              .toList()
              .reversed
              .toList(),
        );
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderUid,
    required String senderName,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (trimmed.length > DirectMessageRepository.maxMessageLength) {
      throw ArgumentError('Pesan terlalu panjang.');
    }
    final message = DirectMessage(
      id: '',
      senderUid: senderUid,
      senderName: senderName,
      text: trimmed,
      createdAt: DateTime.now(),
    );
    await _messagesOf(conversationId).add(message.toMap());
  }

  /// Write-only, same shape and same honest limitation as
  /// `ClanMessageRepository.reportMessage` — see that method's doc
  /// comment. `kind: 'dm'` lets a manual review in the Firebase console
  /// tell this apart from a clan-chat report sharing the same collection.
  Future<void> reportMessage({
    required String conversationId,
    required String messageId,
    required String reporterUid,
    required String reason,
  }) {
    return _firestore.collection(FirestorePaths.messageReports).add({
      'kind': 'dm',
      'conversationId': conversationId,
      'messageId': messageId,
      'reporterUid': reporterUid,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

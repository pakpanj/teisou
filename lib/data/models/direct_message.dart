import 'package:cloud_firestore/cloud_firestore.dart';

/// One message at `directMessages/{conversationId}/messages/{id}` — a
/// private 1:1 chat between two friends. See `DirectMessageRepository`'s
/// doc comment for why this only opens between users who are already
/// mutual friends (found by searching someone's exact unique id), not open
/// messaging to any public user.
///
/// Immutable once sent (no edit, no delete), same as `ClanMessage`.
class DirectMessage {
  final String id;
  final String senderUid;
  final String senderName;
  final String text;
  final DateTime createdAt;

  DirectMessage({
    required this.id,
    required this.senderUid,
    required this.senderName,
    required this.text,
    required this.createdAt,
  });

  factory DirectMessage.fromMap(String id, Map<String, dynamic> map) {
    return DirectMessage(
      id: id,
      senderUid: map['senderUid'] as String? ?? '',
      senderName: map['senderName'] as String? ?? 'Pelajar Kana',
      text: map['text'] as String? ?? '',
      createdAt: _toDateTime(map['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'senderUid': senderUid,
        'senderName': senderName,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      };

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

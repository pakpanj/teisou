import 'package:cloud_firestore/cloud_firestore.dart';

/// One message at `clans/{code}/messages/{id}` — a clan-scoped group chat,
/// deliberately **not** open direct messaging to any public user. See
/// `ClanMessageRepository`'s own doc comment for why that scope line was
/// drawn where it was.
///
/// Immutable once sent (no edit, no delete) — the simplest way to make sure
/// a reported message can't quietly change after the fact.
class ClanMessage {
  final String id;
  final String senderUid;
  final String senderName;
  final String text;
  final DateTime createdAt;

  ClanMessage({
    required this.id,
    required this.senderUid,
    required this.senderName,
    required this.text,
    required this.createdAt,
  });

  factory ClanMessage.fromMap(String id, Map<String, dynamic> map) {
    return ClanMessage(
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

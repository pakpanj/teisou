import 'package:cloud_firestore/cloud_firestore.dart';

/// One announcement at `clans/{code}/announcements/{id}` — a leader-only
/// broadcast to every clan member, distinct from `ClanMessage`'s peer chat:
/// only the leader can post one (enforced server-side by `firestore.rules`'
/// `actorRole(...) == 'leader'` check, mirroring `ClanMessage`'s own
/// `isClanMember` check one level up), and posting one fans out a real push
/// notification to every member via `functions/index.js`'s
/// `onClanAnnouncementCreated` — see that trigger's own doc comment for why
/// this is a separate collection from `messages` rather than a flag on a
/// chat message.
///
/// Immutable once posted (no edit/delete) — same reasoning as
/// `ClanMessage`: the simplest way to guarantee a member who already read
/// (and got pushed) an announcement never sees it silently change after.
class ClanAnnouncement {
  final String id;
  final String authorUid;
  final String authorName;
  final String text;
  final DateTime createdAt;

  ClanAnnouncement({
    required this.id,
    required this.authorUid,
    required this.authorName,
    required this.text,
    required this.createdAt,
  });

  factory ClanAnnouncement.fromMap(String id, Map<String, dynamic> map) {
    return ClanAnnouncement(
      id: id,
      authorUid: map['authorUid'] as String? ?? '',
      authorName: map['authorName'] as String? ?? 'Pelajar Kana',
      text: map['text'] as String? ?? '',
      createdAt: _toDateTime(map['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'authorUid': authorUid,
        'authorName': authorName,
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

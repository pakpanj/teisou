import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase/firestore_paths.dart';
import '../models/clan_announcement.dart';

/// Leader-only broadcasts at `clans/{code}/announcements` — see
/// [ClanAnnouncement]'s own doc comment for how this differs from
/// [ClanMessage]'s peer chat. Structurally mirrors `ClanMessageRepository`
/// (same watch/markRead/lastReadAt shape) rather than sharing a class with
/// it, since the two have genuinely different write permissions (leader-only
/// vs. any member) and this project's own convention is a dedicated
/// repository per collection rather than one repository branching on a
/// caller-supplied "kind".
class ClanAnnouncementRepository {
  static const maxAnnouncementLength = 500;

  final FirebaseFirestore _firestore;

  ClanAnnouncementRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _clanDoc(String code) =>
      _firestore.collection(FirestorePaths.clans).doc(code);

  CollectionReference<Map<String, dynamic>> _announcementsOf(String code) =>
      _clanDoc(code).collection(FirestorePaths.clanAnnouncements);

  /// Most recent [limit] announcements, newest first — unlike
  /// `ClanMessageRepository.watchMessages`, this stays newest-first rather
  /// than reversing to oldest-first, since an announcement list reads more
  /// like a feed (newest at top) than a chat transcript.
  Stream<List<ClanAnnouncement>> watchAnnouncements(
    String code, {
    int limit = 50,
  }) {
    return _announcementsOf(code)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ClanAnnouncement.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// The single most recent announcement, or `null` — powers the unread
  /// check in `clan_providers.dart`'s `clanAnnouncementUnreadProvider`.
  /// Defensively falls back to `null` on `permission-denied`, the same
  /// kicked-mid-refresh race `ClanMessageRepository.watchLastMessage`
  /// already guards against.
  Stream<ClanAnnouncement?> watchLastAnnouncement(String code) async* {
    try {
      await for (final snapshot in _announcementsOf(code)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots()) {
        yield snapshot.docs.isEmpty
            ? null
            : ClanAnnouncement.fromMap(
                snapshot.docs.first.id,
                snapshot.docs.first.data(),
              );
      }
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
      yield null;
    }
  }

  /// Records that [uid] has read [code]'s announcements up to now — a
  /// separate map field from `ClanMessageRepository.markRead`'s
  /// `lastReadAt`, so reading the chat and reading announcements track
  /// independently (a member who's caught up on chat but never opened
  /// announcements should still see an unread badge there, and vice versa).
  Future<void> markRead(String code, String uid) {
    return _clanDoc(code).set({
      'announcementLastReadAt': {uid: FieldValue.serverTimestamp()},
    }, SetOptions(merge: true));
  }

  Stream<Map<String, DateTime>> watchLastReadAt(String code) async* {
    try {
      await for (final doc in _clanDoc(code).snapshots()) {
        final raw = doc.data()?['announcementLastReadAt'] as Map<String, dynamic>?;
        if (raw == null) {
          yield <String, DateTime>{};
        } else {
          yield raw.map((uid, value) {
            final ts = value is Timestamp ? value.toDate() : DateTime.now();
            return MapEntry(uid, ts);
          });
        }
      }
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
      yield <String, DateTime>{};
    }
  }

  /// Posts a new announcement. Client-side trim/length-cap is a fast,
  /// friendly rejection only — `firestore.rules` enforces both the same cap
  /// and the leader-only check server-side, since a raw write could
  /// otherwise bypass either. Posting this document is what
  /// `onClanAnnouncementCreated` (Cloud Function) reacts to by fanning out a
  /// push to every member; nothing else in this method sends one directly.
  Future<void> postAnnouncement({
    required String code,
    required String authorUid,
    required String authorName,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (trimmed.length > maxAnnouncementLength) {
      throw ArgumentError('Pengumuman terlalu panjang.');
    }
    final announcement = ClanAnnouncement(
      id: '',
      authorUid: authorUid,
      authorName: authorName,
      text: trimmed,
      createdAt: DateTime.now(),
    );
    await _announcementsOf(code).add(announcement.toMap());
  }
}

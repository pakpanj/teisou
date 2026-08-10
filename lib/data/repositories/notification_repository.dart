import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase/firestore_paths.dart';
import '../models/app_notification.dart';

/// The generic, non-chat notification feed at
/// `users/{uid}/notifications` — see [AppNotification]'s own doc comment
/// for why this is separate from the chat/clan-message push path.
///
/// `functions/index.js`'s `onUserNotificationCreated` trigger fires a push
/// for every document created here, so [create] is the one call any future
/// feature (a streak reminder, an achievement unlock, ...) needs to make to
/// get both an in-app feed entry and a real push notification, with no
/// further Cloud Functions work required.
class NotificationRepository {
  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      FirebaseFirestore.instance
          .collection(FirestorePaths.notificationsCollection(uid))
          .withConverter<Map<String, dynamic>>(
            fromFirestore: (doc, _) => doc.data() ?? {},
            toFirestore: (data, _) => data,
          );

  /// Sorted client-side rather than via a server `.orderBy('createdAt')` —
  /// this repository has no `.where()` alongside it so no composite index
  /// is actually required here, but every other listener in this codebase
  /// that combines a filter with a sort has hit that requirement (see
  /// `FriendRepository.watchMyRequests`), so sorting client-side is kept
  /// as the default even where it isn't strictly needed, for consistency.
  Stream<List<AppNotification>> watch(String uid) {
    return _collection(uid).snapshots().map((snapshot) {
      final items = snapshot.docs.map(AppNotification.fromDoc).toList();
      items.sort((a, b) {
        final aTime = a.createdAt;
        final bTime = b.createdAt;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
      return items;
    });
  }

  /// Best-effort, matching every other progress-repository write in this
  /// app — a failed write here must never block whatever feature just
  /// tried to notify the learner about something that already happened.
  Future<void> create(
    String uid, {
    required String title,
    required String body,
    String category = 'system',
  }) async {
    try {
      await _collection(uid).add({
        'category': category,
        'title': title,
        'body': body,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> markRead(String uid, String id) async {
    try {
      await _collection(uid).doc(id).update({'read': true});
    } catch (_) {}
  }

  Future<void> markAllRead(String uid, List<String> ids) async {
    if (ids.isEmpty) return;
    try {
      final batch = FirebaseFirestore.instance.batch();
      final collection = _collection(uid);
      for (final id in ids) {
        batch.update(collection.doc(id), {'read': true});
      }
      await batch.commit();
    } catch (_) {}
  }
}

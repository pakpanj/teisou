import 'package:cloud_firestore/cloud_firestore.dart';

/// A single row in `users/{uid}/notifications` — the generic, non-chat
/// notification feed. Chat/clan messages have their own separate delivery
/// path (`functions/index.js`'s `onDirectMessageCreated`/
/// `onClanMessageCreated`, `lib/core/services/fcm_service.dart`) and are
/// deliberately not funneled through this collection — this one is for
/// everything else: system announcements, and whatever future feature
/// (streak reminders, achievements, ...) writes here next.
///
/// [category] is a plain validated `String`, not a Dart enum — same
/// reasoning already established for `ParticleEntry.category` elsewhere in
/// this codebase: an enum would be a second source of truth for a value
/// set that doesn't exist yet beyond `'system'`, and every consumer
/// ([NotificationRepository], the Cloud Function, [FcmService]) already
/// treats an unrecognized category as a safe default rather than crashing
/// on it.
class AppNotification {
  final String id;
  final String category;
  final String title;
  final String body;
  final DateTime? createdAt;
  final bool read;

  const AppNotification({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.read,
  });

  factory AppNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final timestamp = data['createdAt'];
    return AppNotification(
      id: doc.id,
      category: (data['category'] as String?) ?? 'system',
      title: (data['title'] as String?) ?? '',
      body: (data['body'] as String?) ?? '',
      createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
      read: data['read'] == true,
    );
  }
}

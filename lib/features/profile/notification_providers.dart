import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/app_notification.dart';

/// Live — one user's own notification feed (system announcements today,
/// whatever future feature writes to `users/{uid}/notifications` next),
/// small enough to keep streaming so the badge and the feed both update
/// the instant a push arrives while the app is open.
final myNotificationsProvider = StreamProvider<List<AppNotification>>((ref) async* {
  final user = await ref.watch(appStartupProvider.future);
  yield* ref.watch(notificationRepositoryProvider).watch(user.uid);
});

/// Just the unread count, derived from [myNotificationsProvider] — mirrors
/// `pendingFriendRequestCountProvider`'s own derived-count pattern so
/// `CountBadge` call sites stay consistent across the app.
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(myNotificationsProvider).valueOrNull ?? [];
  return notifications.where((n) => !n.read).length;
});

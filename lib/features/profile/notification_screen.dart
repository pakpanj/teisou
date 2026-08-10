import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_loading.dart';
import '../../data/models/app_notification.dart';
import 'notification_providers.dart';

/// The real notification feed — `users/{uid}/notifications`, delivered by
/// `functions/index.js`'s `onUserNotificationCreated` trigger and
/// `lib/core/services/fcm_service.dart` on the client. Used to be a static
/// "not built yet" placeholder (`SimplePlaceholderScreen`); this is the
/// generic pipeline described in CLAUDE.md's notification-infrastructure
/// note, so any future feature (streak reminder, achievement, ...) that
/// writes to that collection shows up here with no further screen work.
class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final uid = ref.watch(appStartupProvider).valueOrNull?.uid;
    final notificationsAsync = ref.watch(myNotificationsProvider);
    final unreadIds = notificationsAsync.valueOrNull
            ?.where((n) => !n.read)
            .map((n) => n.id)
            .toList() ??
        const <String>[];

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        title: Text(s.notifications),
        actions: [
          if (uid != null && unreadIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: s.markAllNotificationsRead,
              onPressed: () => ref
                  .read(notificationRepositoryProvider)
                  .markAllRead(uid, unreadIds),
            ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return _EmptyNotificationsState(
              title: s.notificationsEmptyTitle,
              body: s.notificationsEmptyBody,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            separatorBuilder: (_, _) => const SizedBox(height: 2),
            itemBuilder: (context, index) => _NotificationRow(
              notification: notifications[index],
              onTap: uid == null
                  ? null
                  : () => ref
                      .read(notificationRepositoryProvider)
                      .markRead(uid, notifications[index].id),
            ),
          );
        },
        loading: () => const AppLoading(),
        error: (e, _) => Center(child: Text(s.failedToLoadNotifications(e))),
      ),
    );
  }
}

IconData _iconForCategory(String category) {
  switch (category) {
    case 'achievement':
      return Icons.emoji_events_outlined;
    case 'streak':
      return Icons.local_fire_department_outlined;
    default:
      return Icons.notifications_outlined;
  }
}

class _NotificationRow extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;

  const _NotificationRow({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final unread = !notification.read;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: unread
            ? context.palette.primaryCoral.withValues(alpha: 0.06)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor:
                  context.palette.primaryCoral.withValues(alpha: 0.15),
              child: Icon(
                _iconForCategory(notification.category),
                color: context.palette.primaryCoral,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: unread ? FontWeight.bold : FontWeight.w600,
                      color: context.palette.textNavy,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.palette.textNavy.withValues(alpha: 0.7),
                    ),
                  ),
                  if (notification.createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatRelativeTime(notification.createdAt!),
                      style: TextStyle(
                        fontSize: 11,
                        color: context.palette.textNavy.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (unread)
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4, left: 8),
                decoration: BoxDecoration(
                  color: context.palette.primaryCoral,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays >= 1 || now.day != time.day) {
      return '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}';
    }
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour.$minute';
  }
}

class _EmptyNotificationsState extends StatelessWidget {
  final String title;
  final String body;

  const _EmptyNotificationsState({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔔', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: context.palette.textNavy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.palette.textNavy),
            ),
          ],
        ),
      ),
    );
  }
}

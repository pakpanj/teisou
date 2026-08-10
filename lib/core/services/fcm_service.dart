import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/leaderboard/widgets/clan_chat_screen.dart';
import '../../features/leaderboard/widgets/direct_message_screen.dart';
import '../firebase/firestore_paths.dart';
import '../navigation/root_navigator_key.dart';

/// One notification channel for every chat/clan-message push —
/// `functions/index.js` sends this exact id in its `android.notification.
/// channelId`, and `AndroidManifest.xml` declares it as the FCM default
/// too, so foreground display (Dart-shown), background display (Android-
/// shown, explicit id) and terminated display (Android-shown, manifest
/// default) all land on the same channel instead of Android silently
/// creating a second, unconfigured one for whichever path skips the id.
const _chatChannelId = 'chat_messages';
const _chatChannelName = 'Pesan Chat';
const _chatChannelDescription =
    'Notifikasi pesan baru dari chat clan atau chat pribadi.';

/// Matches `lib/core/theme/app_colors.dart`'s `primaryCoral` — no shared
/// source between Dart and the notification tray for a single color
/// value like this, so keep this, `android/app/src/main/res/values/
/// colors.xml`'s `notification_color`, and `app_colors.dart` in sync by
/// hand if the brand color ever changes.
const _notificationColor = Color(0xFFF4667A);

/// FNV-1a 32-bit — a plain, dependency-free stable hash, the same
/// approach this codebase already uses elsewhere for "derive a
/// consistent X from a string id" (e.g. picking a consistent TTS voice
/// per Kaiwa speaker). A notification id has to be the *same* value
/// every time for the *same* conversation, or Android stacks a brand new
/// tray entry per message instead of updating the existing one — Dart's
/// built-in `String.hashCode` happens to work for this in practice but
/// isn't a documented cross-version guarantee, and a proper hash costs
/// only a few lines.
int _stableNotificationId(String key) {
  var hash = 0x811c9dc5;
  for (final unit in key.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  // Android notification ids are a Java `int` (32-bit signed) — mask down
  // to a safe positive range.
  return hash & 0x7FFFFFFF;
}

/// Must be a **top-level** function annotated `@pragma('vm:entry-point')`
/// — `FirebaseMessaging.onBackgroundMessage` runs it on a separate
/// isolate with no access to anything `main()` built up, which is why
/// this can't be a method on [FcmService]. It deliberately does nothing:
/// with both a `notification` and a `data` payload attached (see
/// `functions/index.js`), Android already displays the system
/// notification on its own while the app is backgrounded or terminated —
/// this only exists because `firebase_messaging` expects *something*
/// registered, not to duplicate that display.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// Push notifications for chat/clan messages — the client half of
/// `functions/index.js`'s two Cloud Functions. Requests permission, keeps
/// this device's FCM token saved to `users/{uid}/fcmTokens/{token}` (the
/// Cloud Function's only way to find where to send), shows a local
/// notification while the app is foregrounded (Android only auto-displays
/// FCM notifications when it *isn't* foregrounded), and deep-links a
/// tapped notification to the right chat screen via [rootNavigatorKey] —
/// the one thing a notification tap can rely on existing, whether it's
/// tapped from the background or from a fully cold start with no widget
/// tree built yet.
class FcmService {
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// The chat currently on screen, if any — set/cleared by
  /// `DirectMessageScreen`/`ClanChatScreen` themselves in `initState`/
  /// `dispose`. A foreground push for the conversation the learner is
  /// already looking at would just be a redundant banner over a message
  /// they can already see arrive live in the message list, so it's
  /// suppressed instead of shown. Keyed `'dm:{conversationId}'` or
  /// `'clan:{code}'`, matching [_keyFor]'s own encoding of a push's data
  /// payload.
  static String? currentOpenChatKey;

  Future<void> init(String uid) async {
    if (_initialized) return;
    _initialized = true;

    await _localNotifications.initialize(
      const InitializationSettings(
        // A flat white silhouette (drawable-*dpi/ic_notification.png,
        // scripts/generate_notification_icon.py) — not the full-color
        // launcher icon this used to point at. Android force-flattens a
        // status-bar icon regardless of what's passed, and the launcher
        // icon has no transparency to flatten cleanly, so it rendered as
        // a plain solid square before this.
        android: AndroidInitializationSettings('@drawable/ic_notification'),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null) return;
        _handleData(Map<String, dynamic>.from(jsonDecode(payload) as Map));
      },
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _chatChannelId,
          _chatChannelName,
          description: _chatChannelDescription,
          importance: Importance.high,
        ));

    // Best-effort — a learner who denies this simply never sees a push,
    // the same as one on a device with no Google Play Services at all;
    // the in-app CountBadge system (see chat_providers.dart) still works
    // regardless, since it doesn't depend on FCM at all.
    try {
      await FirebaseMessaging.instance.requestPermission();
    } catch (_) {}

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _saveToken(uid, token);
    } catch (_) {}
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      _saveToken(uid, token).catchError((_) {});
    });

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleData(message.data);
    });

    // App launched fresh by tapping a notification — getInitialMessage
    // only ever returns a value once per cold start, so it's safe to
    // call unconditionally here without risking a duplicate navigation
    // on a later, unrelated rebuild.
    final initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) _handleData(initialMessage.data);
  }

  Future<void> _saveToken(String uid, String token) {
    return FirebaseFirestore.instance
        .collection(FirestorePaths.fcmTokensCollection(uid))
        .doc(token)
        .set({
      'platform': defaultTargetPlatform.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  String? _keyFor(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    if (type == 'dm') return 'dm:${data['conversationId']}';
    if (type == 'clan') return 'clan:${data['code']}';
    return null;
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    final key = _keyFor(message.data);
    if (key == currentOpenChatKey) return;

    // A stable id (derived from the conversation, not the current
    // timestamp) means a second message from the same chat *updates* the
    // existing tray entry instead of stacking a new one underneath it —
    // the previous version used a millisecond timestamp here, which made
    // every single message its own permanent notification and cluttered
    // the tray after just a few messages.
    final id = key != null
        ? _stableNotificationId(key)
        : DateTime.now().millisecondsSinceEpoch.remainder(100000);

    _localNotifications.show(
      id,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _chatChannelId,
          _chatChannelName,
          channelDescription: _chatChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
          color: _notificationColor,
          // Expandable (pull down to see the full message) instead of a
          // single truncated line — most useful for a longer clan
          // message, which the server already caps at ~80 characters but
          // still doesn't always fit the collapsed one-line view.
          styleInformation: BigTextStyleInformation(
            notification.body ?? '',
            contentTitle: notification.title,
          ),
          // Purely cosmetic clustering hint for Android's own grouping —
          // notifications from the same conversation are visually kept
          // together if the system chooses to group them; no summary
          // notification is posted, so this never creates an extra entry
          // on its own.
          groupKey: key,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _handleData(Map<String, dynamic> data) {
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) return;
    final type = data['type'] as String?;

    if (type == 'dm') {
      final friendUid = data['friendUid'] as String?;
      if (friendUid == null) return;
      navigator.push(MaterialPageRoute(
        builder: (_) => DirectMessageScreen(
          friendUid: friendUid,
          friendName: (data['friendName'] as String?) ?? '',
        ),
      ));
    } else if (type == 'clan') {
      final code = data['code'] as String?;
      if (code == null) return;
      navigator.push(MaterialPageRoute(
        builder: (_) => ClanChatScreen(
          code: code,
          clanName: (data['clanName'] as String?) ?? 'Clan',
        ),
      ));
    }
  }
}

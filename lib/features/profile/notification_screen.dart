import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/widgets/simple_placeholder_screen.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    return SimplePlaceholderScreen(
      title: s.notifications,
      icon: Icons.notifications_outlined,
      message: s.notificationsPlaceholderMessage,
    );
  }
}

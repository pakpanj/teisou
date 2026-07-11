import 'package:flutter/material.dart';

import '../../core/widgets/simple_placeholder_screen.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimplePlaceholderScreen(
      title: 'Notifikasi',
      icon: Icons.notifications_outlined,
      message: 'Pengaturan pengingat belajar harian akan tersedia di sini.',
    );
  }
}

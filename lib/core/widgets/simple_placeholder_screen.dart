import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// Generic "not built yet" screen shell — a proper container with a
/// consistent look, used for menu destinations that don't have real
/// content yet (language/notification settings, etc.).
class SimplePlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String message;

  const SimplePlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 64, color: context.palette.textNavy.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.palette.textNavy, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

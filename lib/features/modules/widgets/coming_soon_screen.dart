import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'coming_soon_content.dart';

/// Full-screen "coming soon" placeholder for a not-yet-built module,
/// reusing [ComingSoonContent] as the body (no "Tutup" button here — the
/// back arrow in the app bar covers that).
class ComingSoonScreen extends StatelessWidget {
  final String moduleId;
  final String title;

  const ComingSoonScreen({
    super.key,
    required this.moduleId,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: Center(child: ComingSoonContent(moduleId: moduleId)),
    );
  }
}

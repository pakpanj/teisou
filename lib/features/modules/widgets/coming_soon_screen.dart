import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/module_info.dart';
import 'coming_soon_content.dart';

/// Full-screen "coming soon" placeholder for a not-yet-built module,
/// reusing [ComingSoonContent] as the body (no "Tutup" button here — the
/// back arrow in the app bar covers that).
class ComingSoonScreen extends StatelessWidget {
  final String moduleId;

  const ComingSoonScreen({super.key, required this.moduleId});

  @override
  Widget build(BuildContext context) {
    final module = kComingSoonModules.firstWhere((m) => m.id == moduleId);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(module.title)),
      body: Center(child: ComingSoonContent(moduleId: moduleId)),
    );
  }
}

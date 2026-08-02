import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/module_info.dart';
import 'coming_soon_content.dart';

/// Full-screen "coming soon" placeholder for a not-yet-built module,
/// reusing [ComingSoonContent] as the body (no "Tutup" button here — the
/// back arrow in the app bar covers that).
class ComingSoonScreen extends ConsumerWidget {
  final String moduleId;

  const ComingSoonScreen({super.key, required this.moduleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final module = kComingSoonModules.firstWhere((m) => m.id == moduleId);
    final s = ref.watch(appStringsProvider);
    final title = switch (moduleId) {
      'picture_learning' => s.pictureLearningTitle,
      'video_learning' => s.videoLearningTitle,
      _ => module.title,
    };
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: Text(title)),
      body: Center(child: ComingSoonContent(moduleId: moduleId)),
    );
  }
}

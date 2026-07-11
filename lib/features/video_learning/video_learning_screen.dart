import 'package:flutter/material.dart';

import '../modules/widgets/coming_soon_screen.dart';

class VideoLearningScreen extends StatelessWidget {
  const VideoLearningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      moduleId: 'video_learning',
      title: 'Belajar dari Video',
    );
  }
}

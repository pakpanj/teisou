import 'package:flutter/material.dart';

import '../modules/widgets/coming_soon_screen.dart';

class KaiwaScreen extends StatelessWidget {
  const KaiwaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(moduleId: 'kaiwa');
  }
}

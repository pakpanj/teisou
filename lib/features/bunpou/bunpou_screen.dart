import 'package:flutter/material.dart';

import '../modules/widgets/coming_soon_screen.dart';

class BunpouScreen extends StatelessWidget {
  const BunpouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      moduleId: 'bunpou',
      title: 'Bunpou (Tata Bahasa)',
    );
  }
}

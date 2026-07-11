import 'package:flutter/material.dart';

import '../modules/widgets/coming_soon_screen.dart';

class ParticleScreen extends StatelessWidget {
  const ParticleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(moduleId: 'particle', title: 'Partikel');
  }
}

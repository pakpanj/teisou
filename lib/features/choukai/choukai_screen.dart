import 'package:flutter/material.dart';

import '../modules/widgets/coming_soon_screen.dart';

class ChoukaiScreen extends StatelessWidget {
  const ChoukaiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      moduleId: 'choukai',
      title: 'Choukai (Listening)',
    );
  }
}

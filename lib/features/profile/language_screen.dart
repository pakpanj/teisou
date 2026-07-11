import 'package:flutter/material.dart';

import '../../core/widgets/simple_placeholder_screen.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimplePlaceholderScreen(
      title: 'Bahasa App',
      icon: Icons.language,
      message: 'Pilihan bahasa aplikasi akan tersedia di sini.\n'
          'Untuk saat ini Teisou hanya berbahasa Indonesia.',
    );
  }
}

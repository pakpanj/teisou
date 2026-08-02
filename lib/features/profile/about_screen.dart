import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  static const _appVersion = '1.0.0';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: Text(s.aboutApp)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Center(
            child: Text('🐱', style: TextStyle(fontSize: 64)),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Teisou: Kana Master',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.palette.textNavy,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              s.appVersionLabel(_appVersion),
              style: TextStyle(color: context.palette.textNavy.withValues(alpha: 0.6)),
            ),
          ),
          const SizedBox(height: 32),
          _Section(title: s.aboutSectionTitle, body: s.aboutSectionBody),
          const SizedBox(height: 20),
          _Section(title: s.creditsSectionTitle, body: s.creditsSectionBody),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: context.palette.textNavy,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: TextStyle(color: context.palette.textNavy, height: 1.4),
        ),
      ],
    );
  }
}

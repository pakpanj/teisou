import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _appVersion = '1.0.0';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Tentang App')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Center(
            child: Text('🐱', style: TextStyle(fontSize: 64)),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Teisou: Kana Master',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textNavy,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Versi $_appVersion',
              style: TextStyle(color: AppColors.textNavy.withValues(alpha: 0.6)),
            ),
          ),
          const SizedBox(height: 32),
          const _Section(
            title: 'Tentang',
            body:
                'Teisou adalah teman belajar bahasa Jepang — dimulai dari '
                'Hiragana dan Katakana, menuju Kanji, Partikel, dan Tata '
                'Bahasa. Belajar Kana, langkah pertama menuju Jepang!',
          ),
          const SizedBox(height: 20),
          const _Section(
            title: 'Kredit',
            body:
                'Ilustrasi urutan goresan karakter menggunakan data dari '
                'proyek KanjiVG (© Ulrich Apel), dilisensikan di bawah '
                'Creative Commons Attribution-Share Alike 3.0.',
          ),
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
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textNavy,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: const TextStyle(color: AppColors.textNavy, height: 1.4),
        ),
      ],
    );
  }
}

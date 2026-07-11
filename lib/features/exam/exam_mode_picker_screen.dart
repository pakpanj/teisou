import 'package:flutter/material.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/exam_mode.dart';
import 'exam_screen.dart';

/// Lets the user choose which kana pool ("Hiragana", "Katakana", or
/// "Campuran") the upcoming 10-question exam should draw from.
class ExamModePickerScreen extends StatelessWidget {
  const ExamModePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Mode Ujian')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _ModeCard(
              color: AppColors.primaryCoral,
              icon: Icons.text_fields,
              title: 'Ujian Hiragana',
              subtitle: 'Soal dari 46 karakter hiragana',
              onTap: () => _startExam(context, ExamMode.hiragana),
            ),
            const SizedBox(height: 16),
            _ModeCard(
              color: AppColors.secondaryBlue,
              icon: Icons.text_fields,
              title: 'Ujian Katakana',
              subtitle: 'Soal dari 46 karakter katakana',
              onTap: () => _startExam(context, ExamMode.katakana),
            ),
            const SizedBox(height: 16),
            _ModeCard(
              color: AppColors.tertiaryAmber,
              icon: Icons.shuffle,
              title: 'Ujian Campuran',
              subtitle: 'Gabungan hiragana & katakana',
              onTap: () => _startExam(context, ExamMode.mixed),
            ),
          ],
        ),
      ),
    );
  }

  void _startExam(BuildContext context, ExamMode mode) {
    AppNavigator.slideFromBottom(context, ExamScreen(mode: mode));
  }
}

class _ModeCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModeCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textNavy.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

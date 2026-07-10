import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/sakura_decoration.dart';
import '../../data/models/exam_result.dart';
import '../exam/exam_screen.dart';
import '../home/home_screen.dart';
import 'widgets/maneki_neko_mascot.dart';

class ExamResultScreen extends StatelessWidget {
  final ExamResult result;

  const ExamResultScreen({super.key, required this.result});

  String get _title {
    if (result.percentage >= 80) return 'Hebat! Ujian Selesai 🎉';
    if (result.percentage >= 60) return 'Bagus! Terus Berlatih 👍';
    return 'Jangan Menyerah, Ayo Coba Lagi! 💪';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 0,
                    top: 8,
                    child: SakuraDecoration(size: 40),
                  ),
                  Positioned(
                    right: 0,
                    top: 8,
                    child: Transform.flip(
                      flipX: true,
                      child: const SakuraDecoration(size: 40),
                    ),
                  ),
                  const ManekiNekoMascot(size: 180),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                _title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textNavy,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '${result.score} / ${result.total}',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryCoral,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryAmberCardBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${result.percentage.round()}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textNavy,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Benar',
                      value: result.correctCount,
                      color: AppColors.successGreen,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      label: 'Salah',
                      value: result.wrongCount,
                      color: AppColors.errorRed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => ExamScreen(mode: result.mode),
                      ),
                    );
                  },
                  child: const Text('Ulangi Ujian'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text('Kembali ke Menu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.textNavy)),
        ],
      ),
    );
  }
}

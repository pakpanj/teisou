import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/mascot_widget.dart';
import '../../core/widgets/sakura_decoration.dart';
import '../../data/models/exam_result.dart';
import '../exam/exam_screen.dart';
import '../home/home_screen.dart';

class ExamResultScreen extends ConsumerStatefulWidget {
  final ExamResult result;

  const ExamResultScreen({super.key, required this.result});

  @override
  ConsumerState<ExamResultScreen> createState() => _ExamResultScreenState();
}

class _ExamResultScreenState extends ConsumerState<ExamResultScreen> {
  ExamResult get result => widget.result;

  String get _title {
    if (result.percentage >= 80) return 'Hebat! Ujian Selesai 🎉';
    if (result.percentage >= 60) return 'Bagus! Terus Berlatih 👍';
    return 'Jangan Menyerah, Ayo Coba Lagi! 💪';
  }

  MascotMood get _mood {
    if (result.percentage >= 80) return MascotMood.happy;
    if (result.percentage >= 60) return MascotMood.cheering;
    return MascotMood.sad;
  }

  late final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(seconds: 2),
  );

  @override
  void initState() {
    super.initState();
    if (result.newlyMasteredCount > 0) {
      _confettiController.play();
    }
    // Free users only — premium's whole pitch includes "Tanpa iklan".
    final isPremium = ref.read(subscriptionProvider).valueOrNull?.isPremium ?? false;
    if (!isPremium) {
      ref.read(adServiceProvider).maybeShowInterstitialAfterExam();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
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
                  MascotWidget(mood: _mood, size: 180),
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
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: math.pi / 2,
              maxBlastForce: 20,
              minBlastForce: 8,
              emissionFrequency: 0.05,
              numberOfParticles: 24,
              gravity: 0.3,
              colors: const [
                AppColors.primaryCoral,
                AppColors.secondaryBlue,
                AppColors.tertiaryAmber,
              ],
            ),
          ),
        ],
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

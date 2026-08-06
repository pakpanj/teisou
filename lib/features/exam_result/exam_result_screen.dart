import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
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

  String _title(AppStrings s) {
    if (result.percentage >= 80) return s.examResultTitleGreat;
    if (result.percentage >= 60) return s.examResultTitleGood;
    return s.examResultTitleTryAgain;
  }

  MascotMood get _mood {
    // A clean sweep is the rarest result in the app and used to look
    // exactly like an 80%.
    if (result.percentage >= 100) return MascotMood.surprised;
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
    final s = ref.watch(appStringsProvider);
    return Scaffold(
      backgroundColor: context.palette.background,
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
                _title(s),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.palette.textNavy,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '${result.score} / ${result.total}',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: context.palette.primaryCoral,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: context.palette.tertiaryAmberCardBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${result.percentage.round()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: context.palette.textNavy,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: s.correctLabel,
                      value: result.correctCount,
                      color: context.palette.successGreen,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      label: s.wrongLabel,
                      value: result.wrongCount,
                      color: context.palette.errorRed,
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
                  child: Text(s.retryExamButton),
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
                  child: Text(s.backToMenuButton),
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
              colors: [
                context.palette.primaryCoral,
                context.palette.secondaryBlue,
                context.palette.tertiaryAmber,
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
        color: context.palette.cardWhite,
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
          Text(label, style: TextStyle(color: context.palette.textNavy)),
        ],
      ),
    );
  }
}

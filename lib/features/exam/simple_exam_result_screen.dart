import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../data/models/simple_exam_result.dart';

/// Shared score-summary screen for Dokkai/Choukai/Kanji-Kombinasi/the Bab
/// gate quiz — unlike the kana `ExamResultScreen` (confetti, mastery
/// tracking), these share an identical simple "score/total + try again"
/// shape, so one screen replaces four near-duplicates. [reviewContent],
/// when given, is shown below the score (e.g. Choukai's audio script
/// reveal for post-listening review) — null for exam types with nothing
/// extra to show.
class SimpleExamResultScreen extends ConsumerStatefulWidget {
  final String title;
  final SimpleExamResult result;
  final Widget? reviewContent;

  const SimpleExamResultScreen({
    super.key,
    required this.title,
    required this.result,
    this.reviewContent,
  });

  @override
  ConsumerState<SimpleExamResultScreen> createState() =>
      _SimpleExamResultScreenState();
}

class _SimpleExamResultScreenState
    extends ConsumerState<SimpleExamResultScreen> {
  @override
  void initState() {
    super.initState();
    // Same gate and shared counter as the kana ExamResultScreen — see
    // AdService.maybeShowInterstitialAfterExam, which now fires from every
    // exam type that reaches a result screen, not just kana.
    final isPremium =
        ref.read(subscriptionProvider).valueOrNull?.isPremium ?? false;
    if (!isPremium) {
      ref.read(adServiceProvider).maybeShowInterstitialAfterExam();
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final reviewContent = widget.reviewContent;
    final s = ref.watch(appStringsProvider);
    final percentage = result.total == 0
        ? 0
        : ((result.score / result.total) * 100).round();
    final label = percentage >= 80
        ? s.simpleExamResultGreat
        : percentage >= 60
            ? s.simpleExamResultGood
            : s.simpleExamResultTryAgain;

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar:
          AppBar(title: Text(widget.title), automaticallyImplyLeading: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.palette.textNavy,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: context.palette.primaryCoral.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${result.score}/${result.total}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: context.palette.primaryCoral,
                      ),
                    ),
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.palette.textNavy.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (reviewContent != null) ...[
                const SizedBox(height: 24),
                reviewContent,
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(s.done),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

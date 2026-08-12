import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/providers.dart';
import '../../core/services/secure_screen_service.dart';
import '../../core/theme/app_palette.dart';
import '../../data/models/quiz_review_entry.dart';

/// Shows every question a learner got wrong in the quiz/exam session that
/// just ended — what was asked, what they picked, what was actually right.
/// One shared screen for every quiz/exam surface in the app (kana exam,
/// the four bespoke module quizzes, and everything routed through
/// `McQuizFlow`), reached via a "Lihat Kesalahan" button on whichever
/// result screen just showed the score.
class QuizReviewScreen extends ConsumerStatefulWidget {
  final List<QuizReviewEntry> entries;

  /// Blocks screenshots/recording for as long as this screen is open, the
  /// same protection `BabGateQuizScreen` gives itself — set by the one
  /// caller (the Bab gate quiz) whose questions come from a small, fixed,
  /// reused pool per chapter, where a captured wrong-answer review is just
  /// as reusable as a captured question sheet. Every other quiz's content
  /// is either large (Kaiwa/Dokkai/Choukai's pools) or has no lock riding
  /// on it, so this stays off by default.
  final bool secure;

  const QuizReviewScreen({
    super.key,
    required this.entries,
    this.secure = false,
  });

  @override
  ConsumerState<QuizReviewScreen> createState() => _QuizReviewScreenState();
}

class _QuizReviewScreenState extends ConsumerState<QuizReviewScreen> {
  // Deliberately not SecureScreenMixin: that mixin acquires unconditionally
  // in initState, which would mean every one of this screen's eight
  // non-secure call sites still made a real enable-then-disable round trip
  // through the platform channel for no reason. Acquiring only when
  // [widget.secure] is true keeps the (best-effort, reference-counted)
  // protection exactly where BabGateQuizScreen already asks for it, and
  // costs nothing everywhere else.
  SecureScreenService? _secureScreen;

  @override
  void initState() {
    super.initState();
    if (!widget.secure) return;
    final service = ref.read(secureScreenServiceProvider);
    _secureScreen = service;
    service.onScreenshotDetected = () {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(ref.read(appStringsProvider).screenshotDetectedNotice),
        ),
      );
    };
    service.acquire();
  }

  @override
  void dispose() {
    if (widget.secure) {
      _secureScreen?.onScreenshotDetected = null;
      _secureScreen?.release();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: Text(s.reviewMistakesTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  s.reviewMistakesCount(widget.entries.length),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.palette.textNavy.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: widget.entries.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) =>
                    _ReviewCard(entry: widget.entries[i], strings: s),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final QuizReviewEntry entry;
  final AppStrings strings;

  const _ReviewCard({required this.entry, required this.strings});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.question,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: context.palette.textNavy,
            ),
          ),
          const SizedBox(height: 12),
          _AnswerRow(
            label: strings.yourAnswerLabel,
            value: entry.userAnswer,
            color: context.palette.errorRed,
            icon: Icons.cancel,
          ),
          const SizedBox(height: 6),
          _AnswerRow(
            label: strings.correctAnswerLabel,
            value: entry.correctAnswer,
            color: context.palette.secondaryBlue,
            icon: Icons.check_circle,
          ),
        ],
      ),
    );
  }
}

class _AnswerRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _AnswerRow({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.palette.textNavy.withValues(alpha: 0.6),
                  ),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

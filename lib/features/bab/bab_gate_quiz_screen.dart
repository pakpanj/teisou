import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/providers.dart';
import '../../core/services/secure_screen_service.dart';
import '../../core/theme/app_palette.dart';
import '../../data/models/jlpt_level.dart';
import '../../data/models/leaderboard_entry.dart';
import '../../data/models/simple_exam_result.dart';
import '../../data/models/user_profile.dart' show AvatarType;
import '../exam/mc_quiz_flow.dart';
import '../exam/simple_exam_result_screen.dart';
import 'bab_gate_quiz_generator.dart';
import 'bab_providers.dart';
import '../../core/widgets/mascot_widget.dart';

/// The cumulative "gerbang" (gate) quiz standing between one Bab chapter
/// and the next. Passing it — with a perfect score, no partial credit —
/// marks [babId] complete and unlocks the chapter right after [upToOrder];
/// failing leaves the next chapter locked and this screen can simply be
/// re-entered for a freshly-shuffled attempt (see `buildGateQuestions`).
///
/// Every question is generated at runtime from real Kotoba/Bunpou/Partikel
/// content already authored for chapters 1 through [upToOrder] — there is
/// no separate gate-quiz dataset to keep in sync as the curriculum grows.
class BabGateQuizScreen extends ConsumerStatefulWidget {
  final JlptLevel level;
  final int upToOrder;
  final String babId;

  const BabGateQuizScreen({
    super.key,
    required this.level,
    required this.upToOrder,
    required this.babId,
  });

  @override
  ConsumerState<BabGateQuizScreen> createState() => _BabGateQuizScreenState();
}

/// Screenshots and screen recording are blocked for as long as this screen
/// is alive ([SecureScreenMixin]). This is the one quiz in the app whose
/// answers decide whether the next chapter opens, so a captured question
/// sheet is worth more than a captured practice screen — and the questions
/// are generated from a small, fixed pool per chapter, which makes a shared
/// screenshot genuinely reusable.
///
/// The mixin releases in `dispose`, and every exit from here goes through
/// it: `AppNavigator.replaceFadeScale` to the result screen tears this
/// route down, and so does backing out. Nothing needs to remember to
/// unlock.
class _BabGateQuizScreenState extends ConsumerState<BabGateQuizScreen>
    with SecureScreenMixin {
  List<GateQuestion>? _questions;

  /// Reached on iOS only, which cannot stop a screenshot and can merely
  /// report one afterwards. On Android this never fires, because the
  /// capture never happens — silence here is the protection working.
  @override
  void onScreenshotDetected() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ref.read(appStringsProvider).screenshotDetectedNotice)),
    );
  }

  /// Publishes the learner's curriculum progress to their public
  /// `leaderboard/{uid}` row so it shows on their profile — including when
  /// someone else opens it, which the private `users/{uid}/babProgress`
  /// subcollection driving the lock can never support (see
  /// [LeaderboardEntry.babCompletedCount]).
  ///
  /// Entirely best-effort: the chapter is already marked complete locally
  /// before this runs, so a network failure here must not surface as an
  /// error or block the result screen. The next completed chapter
  /// republishes the whole summary anyway, so a skipped publish
  /// self-corrects rather than compounding.
  Future<void> _publishBabProgress(String uid) async {
    try {
      final all = await ref.read(babAllProvider.future);
      final completed = await ref.read(babCompletedIdsProvider.future);
      final done = all.where((b) => completed.contains(b.id));
      final profile = ref.read(userProfileProvider).valueOrNull;
      final user = ref.read(appStartupProvider).valueOrNull;

      await ref.read(leaderboardRepositoryProvider).updateBabProgress(
            uid: uid,
            displayName: profile?.resolveDisplayName(user) ??
                (user?.displayName ?? 'Pelajar Kana'),
            photoUrl: user?.photoURL,
            avatarType: profile?.avatarType ?? AvatarType.google,
            avatarValue: profile?.avatarValue,
            completedCount: done.length,
            highestOrder: done.fold<int>(
              0,
              (highest, b) => b.order > highest ? b.order : highest,
            ),
          );
    } catch (_) {
      // See the doc comment: local progress already succeeded.
    }
  }

  Future<void> _onComplete(int score, int total) async {
    final passed = total > 0 && score == total;
    if (passed) {
      final uid = ref.read(appStartupProvider).valueOrNull?.uid;
      await ref.read(babProgressRepositoryProvider).markCompleted(
            widget.babId,
            widget.level.key,
            uid: uid,
          );
      ref.invalidate(babCompletedIdsProvider);
      ref.invalidate(babNextUpProvider);
      if (uid != null) await _publishBabProgress(uid);
    }
    if (!mounted) return;
    final s = ref.read(appStringsProvider);
    final result = SimpleExamResult(
      itemId: 'bab_gate_${widget.babId}_${DateTime.now().millisecondsSinceEpoch}',
      jlptLevel: widget.level.key,
      score: score,
      total: total,
      completedAt: DateTime.now(),
    );
    AppNavigator.replaceFadeScale(
      context,
      SimpleExamResultScreen(
        title: s.babGateQuizTitle,
        result: result,
        reviewContent: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Concerned, not disappointed: failing the gate leaves the
            // learner stuck on this chapter, and a mascot that looks let
            // down by them is the last thing that moment needs.
            MascotWidget(
              mood: passed ? MascotMood.cheering : MascotMood.worried,
              size: 110,
              showBackdrop: false,
            ),
            const SizedBox(height: 12),
            Text(
              passed ? s.babGatePassedMessage : s.babGateFailedMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: passed
                    ? context.palette.successGreen
                    : context.palette.errorRed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final resolvedAsync = ref.watch(babAllResolvedProvider(widget.level));

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: Text(s.babGateQuizTitle)),
      body: resolvedAsync.when(
        data: (allResolved) {
          final questions = _questions ??= buildGateQuestions(
            allResolved: allResolved,
            upToOrder: widget.upToOrder,
            language: s.language,
          );
          if (questions.isEmpty) {
            return Center(child: Text(s.babGateNoQuestions));
          }
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: McQuizFlow(
              totalQuestions: questions.length,
              headerBuilder: (context, index) => _QuestionCard(
                context: questions[index].context,
                prompt: questions[index].prompt,
              ),
              optionsOf: (index) => questions[index].options,
              correctIndexOf: (index) => questions[index].correctIndex,
              onComplete: _onComplete,
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(s.failedToLoadLevels(e))),
      ),
    );
  }
}

class _QuestionCard extends ConsumerWidget {
  final String? context;
  final String prompt;

  const _QuestionCard({required this.context, required this.prompt});

  @override
  Widget build(BuildContext buildContext, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: buildContext.palette.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (context != null) ...[
            Text(
              s.sentenceExamplesTitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: buildContext.palette.textNavy.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context!,
              style: TextStyle(
                fontSize: 18,
                color: buildContext.palette.textNavy,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            prompt,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: buildContext.palette.textNavy,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../data/models/choukai_clip.dart';
import '../../data/models/jlpt_level.dart';
import '../../data/models/simple_exam_result.dart';
import '../../data/models/user_profile.dart' show AvatarType;
import '../exam/mc_quiz_flow.dart';
import '../exam/simple_exam_result_screen.dart';
import '../profile/exam_history_providers.dart';
import '../../core/services/japanese_voices.dart';

/// Runs one Choukai clip: [clip.audioText] is only ever spoken via
/// [ttsServiceProvider], never shown on screen — that's the whole point of
/// a listening exercise, same "no visible text for audio-source content"
/// rule Kaiwa's NPC turns already follow. The script is revealed on the
/// result screen afterward, for review.
class ChoukaiExamScreen extends ConsumerWidget {
  final ChoukaiClip clip;

  const ChoukaiExamScreen({super.key, required this.clip});

  Future<void> _onComplete(
    BuildContext context,
    WidgetRef ref,
    int score,
    int total,
  ) async {
    final user = ref.read(appStartupProvider).valueOrNull;
    final result = SimpleExamResult(
      itemId: clip.id,
      jlptLevel: clip.jlptLevel.key,
      score: score,
      total: total,
      completedAt: DateTime.now(),
    );
    if (user != null) {
      try {
        final profile = ref.read(userProfileProvider).valueOrNull;
        await ref.read(choukaiExamHistoryRepositoryProvider).submit(
              uid: user.uid,
              result: result,
              displayName: profile?.resolveDisplayName(user) ??
                  (user.displayName ?? 'Pelajar Kana'),
              photoUrl: user.photoURL,
              avatarType: profile?.avatarType ?? AvatarType.google,
              avatarValue: profile?.avatarValue,
            );
        ref.invalidate(fullExamHistoryProvider);
      } catch (_) {
        // Best-effort mirror only — see DokkaiExamScreen for the same
        // reasoning.
      }
    }
    if (!context.mounted) return;
    final s = ref.read(appStringsProvider);
    AppNavigator.replaceFadeScale(
      context,
      SimpleExamResultScreen(
        title: s.examResultTitle(s.examCategoryChoukai),
        result: result,
        reviewContent: _ScriptReview(clip: clip, strings: s),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: Text(clip.localizedTitle(s.language))),
      body: McQuizFlow(
        totalQuestions: clip.questions.length,
        headerBuilder: (context, index) => _AudioHeader(
          clip: clip,
          prompt: clip.questions[index].prompt,
        ),
        optionsOf: (index) => clip.questions[index].options,
        correctIndexOf: (index) => clip.questions[index].correctIndex,
        onComplete: (score, total) => _onComplete(context, ref, score, total),
      ),
    );
  }
}

class _AudioHeader extends ConsumerWidget {
  final ChoukaiClip clip;
  final String prompt;

  const _AudioHeader({required this.clip, required this.prompt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    return Column(
      children: [
        Material(
          color: context.palette.primaryCoral,
          shape: const CircleBorder(),
          elevation: 3,
          child: InkWell(
            customBorder: const CircleBorder(),
            // Listening practice against one voice teaches that voice.
            // The clip's own id picks the speaker, so a given clip always
            // sounds the same while the set as a whole is mixed.
            onTap: () => ref.read(ttsServiceProvider).speak(
                  clip.audioText,
                  gender: voiceForSpeaker(
                    dialogueId: clip.id,
                    speaker: 'choukai',
                  ),
                ),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Icon(Icons.volume_up, color: Colors.white, size: 40),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          s.tapToPlayAudio,
          style: TextStyle(
            fontSize: 12,
            color: context.palette.textNavy.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          prompt,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.palette.textNavy,
          ),
        ),
      ],
    );
  }
}

class _ScriptReview extends StatelessWidget {
  final ChoukaiClip clip;
  final AppStrings strings;

  const _ScriptReview({required this.clip, required this.strings});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.cardWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.audioScriptTitle,
            style: TextStyle(fontWeight: FontWeight.bold, color: context.palette.textNavy),
          ),
          const SizedBox(height: 8),
          Text(clip.audioText, style: TextStyle(color: context.palette.textNavy)),
          const SizedBox(height: 8),
          Text(
            clip.localizedAudioTranslation(strings.language),
            style: TextStyle(color: context.palette.textNavy.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}

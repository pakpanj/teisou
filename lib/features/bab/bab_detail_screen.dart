import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/mascot_guide_bubble.dart';
import '../../core/widgets/mascot_widget.dart';
import '../bunpou/bunpou_detail_screen.dart';
import '../dokkai/dokkai_exam_screen.dart';
import '../kaiwa/kaiwa_dialogue_screen.dart';
import '../kanji/kanji_word_detail_screen.dart';
import '../kotoba/kotoba_word_detail_screen.dart';
import '../particle/particle_detail_screen.dart';
import 'bab_gate_quiz_screen.dart';
import 'bab_level_screen.dart' show kBabGateQuizRequired;
import 'bab_providers.dart';

/// One Bab chapter — a curated "playlist" over already-resolved items from
/// six other modules (see [ResolvedBab]/`babDetailProvider`). Renders only
/// section headers and compact rows; tapping a row opens that module's own
/// existing detail screen, so no content is ever re-rendered here.
class BabDetailScreen extends ConsumerWidget {
  final String babId;

  const BabDetailScreen({super.key, required this.babId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final resolvedAsync = ref.watch(babDetailProvider(babId));
    final completed = ref.watch(babCompletedIdsProvider).valueOrNull ?? {};
    final done = completed.contains(babId);

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: Text(s.babTitle)),
      body: resolvedAsync.when(
        data: (resolved) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              resolved.bab.localizedTitle(s.language),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: context.palette.textNavy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              resolved.bab.localizedDescription(s.language),
              style: TextStyle(fontSize: 14, color: context.palette.textNavy.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 20),
            if (resolved.kotoba.isNotEmpty)
              _Section(
                label: s.babSectionKotoba,
                children: [
                  for (var i = 0; i < resolved.kotoba.length; i++)
                    _Row(
                      text: resolved.kotoba[i].word,
                      subtitle: resolved.kotoba[i].localizedMeaning(s.language),
                      onTap: () => AppNavigator.slideFromRight(
                        context,
                        KotobaWordDetailScreen(entries: resolved.kotoba, initialIndex: i),
                      ),
                    ),
                ],
              ),
            if (resolved.kanji.isNotEmpty)
              _Section(
                label: s.babSectionKanji,
                children: [
                  for (var i = 0; i < resolved.kanji.length; i++)
                    _Row(
                      text: resolved.kanji[i].character,
                      subtitle: resolved.kanji[i].localizedMeanings(s.language).join(', '),
                      onTap: () => AppNavigator.slideFromRight(
                        context,
                        KanjiWordDetailScreen(
                          entries: resolved.kanji,
                          initialIndex: i,
                          levelName: resolved.bab.localizedTitle(s.language),
                        ),
                      ),
                    ),
                ],
              ),
            if (resolved.bunpou.isNotEmpty)
              _Section(
                label: s.babSectionBunpou,
                children: [
                  for (var i = 0; i < resolved.bunpou.length; i++)
                    _Row(
                      text: resolved.bunpou[i].pattern,
                      subtitle: resolved.bunpou[i].localizedMeaning(s.language),
                      onTap: () => AppNavigator.slideFromRight(
                        context,
                        BunpouDetailScreen(
                          entries: resolved.bunpou,
                          initialIndex: i,
                          levelName: resolved.bab.localizedTitle(s.language),
                        ),
                      ),
                    ),
                ],
              ),
            if (resolved.particles.isNotEmpty)
              _Section(
                label: s.babSectionParticle,
                children: [
                  for (var i = 0; i < resolved.particles.length; i++)
                    _Row(
                      text: resolved.particles[i].particle,
                      subtitle: resolved.particles[i].localizedOverview(s.language),
                      onTap: () => AppNavigator.slideFromRight(
                        context,
                        ParticleDetailScreen(
                          entries: resolved.particles,
                          initialIndex: i,
                          categoryName: resolved.bab.localizedTitle(s.language),
                        ),
                      ),
                    ),
                ],
              ),
            if (resolved.kaiwa.isNotEmpty)
              _Section(
                label: s.babSectionKaiwa,
                children: [
                  for (var i = 0; i < resolved.kaiwa.length; i++)
                    _Row(
                      text: resolved.kaiwa[i].localizedTitle(s.language),
                      subtitle: null,
                      onTap: () => AppNavigator.slideFromRight(
                        context,
                        KaiwaDialogueScreen(
                          entries: resolved.kaiwa,
                          initialIndex: i,
                          categoryName: resolved.bab.localizedTitle(s.language),
                        ),
                      ),
                    ),
                ],
              ),
            if (resolved.dokkai.isNotEmpty)
              _Section(
                label: s.babSectionDokkai,
                children: [
                  for (final passage in resolved.dokkai)
                    _Row(
                      text: passage.localizedTitle(s.language),
                      subtitle: null,
                      onTap: () => AppNavigator.slideFromRight(
                        context,
                        DokkaiExamScreen(passages: [passage]),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 24),
            MascotGuideBubble(
              mood: done ? MascotMood.cheering : MascotMood.happy,
              message: done
                  ? s.babGuideDoneMessage
                  : s.babGuideQuizMessage(resolved.bab.order,
                      gated: kBabGateQuizRequired),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: done
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: context.palette.successGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: context.palette.successGreen),
                          const SizedBox(width: 8),
                          Text(
                            s.babCompletedLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: context.palette.successGreen,
                            ),
                          ),
                        ],
                      ),
                    )
                  : FilledButton.icon(
                      onPressed: () => AppNavigator.slideFromRight(
                        context,
                        BabGateQuizScreen(
                          level: resolved.bab.level,
                          upToOrder: resolved.bab.order,
                          babId: babId,
                        ),
                      ),
                      icon: const Icon(Icons.quiz),
                      label: Text(s.babStartGateQuiz),
                    ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(s.failedToLoadLevels(e))),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const _Section({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: context.palette.textNavy,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String text;
  final String? subtitle;
  final VoidCallback onTap;

  const _Row({required this.text, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.cardWhite,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: context.palette.textNavy,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.palette.textNavy.withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.palette.primaryCoral, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

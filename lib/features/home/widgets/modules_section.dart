import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/mascot_guide_bubble.dart';
import '../../../core/widgets/mascot_widget.dart';
import '../../../data/models/module_info.dart';
import '../../../data/models/kana_type.dart';
import '../../bab/bab_home_screen.dart';
import '../../bab/bab_providers.dart';
import '../../bunpou/bunpou_home_screen.dart';
import '../../choukai/choukai_home_screen.dart';
import '../../dokkai/dokkai_home_screen.dart';
import '../../flashcard/flashcard_screen.dart';
import '../../kaiwa/kaiwa_home_screen.dart';
import '../../kanji/kanji_home_screen.dart';
import '../../kotoba/kotoba_home_screen.dart';
import '../../modules/widgets/coming_soon_content.dart';
import '../../particle/particle_home_screen.dart';

/// The whole Home learning menu, grouped by where each module falls in a
/// beginner's path: the two syllabaries, then the words and characters
/// built out of them, then the grammar that joins those, then putting it
/// to use. Tools and unbuilt modules come after that path rather than
/// sitting inside it.
///
/// This used to be only the modules *below* Home's Hiragana/Katakana/Ujian
/// shortcut cards, under one catch-all "Modul Lainnya" heading that mixed
/// vocabulary, grammar, conversation and a camera tool together. The kana
/// cards moved in here so the ordering lives in one place instead of being
/// split across two files, and the Ujian card was dropped entirely — it
/// duplicated the Ujian tab in the bottom nav.
///
/// Not a [Scaffold]/[AppBar] — this is embedded in Home's own scroll body.
class ModulesSection extends ConsumerWidget {
  const ModulesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(s.sectionBasics),
        const SizedBox(height: 12),
        _AvailableModuleCard(
          emoji: 'あ',
          backgroundColor: palette.hiraganaCardBg,
          iconColor: palette.primaryCoral,
          title: s.learnHiragana,
          subtitle: s.basicChars46,
          onTap: () => AppNavigator.slideFromRight(
            context,
            const FlashcardScreen(type: KanaType.hiragana),
          ),
        ),
        const SizedBox(height: 12),
        _AvailableModuleCard(
          emoji: 'ア',
          backgroundColor: palette.katakanaCardBg,
          iconColor: palette.secondaryBlue,
          title: s.learnKatakana,
          subtitle: s.basicChars46,
          onTap: () => AppNavigator.slideFromRight(
            context,
            const FlashcardScreen(type: KanaType.katakana),
          ),
        ),
        const SizedBox(height: 28),
        _SectionHeader(s.sectionKurikulum),
        const SizedBox(height: 12),
        const _BabCurriculumCard(),
        const SizedBox(height: 28),
        _SectionHeader(s.sectionVocabKanji),
        const SizedBox(height: 12),
        _AvailableModuleCard(
          emoji: '📚',
          backgroundColor: palette.katakanaCardBg,
          iconColor: palette.secondaryBlue,
          title: s.kotobaTitle,
          subtitle: s.kotobaSubtitle,
          onTap: () => AppNavigator.slideFromRight(
            context,
            const KotobaHomeScreen(),
          ),
        ),
        const SizedBox(height: 12),
        _AvailableModuleCard(
          emoji: '字',
          backgroundColor: palette.tertiaryAmberCardBg,
          iconColor: palette.tertiaryAmber,
          title: s.kanjiTitle,
          subtitle: s.kanjiSubtitle,
          onTap: () => AppNavigator.slideFromRight(
            context,
            const KanjiHomeScreen(),
          ),
        ),
        const SizedBox(height: 28),
        _SectionHeader(s.sectionGrammar),
        const SizedBox(height: 12),
        _AvailableModuleCard(
          emoji: '文',
          backgroundColor: palette.hiraganaCardBg,
          iconColor: palette.primaryCoral,
          title: s.bunpouTitle,
          subtitle: s.bunpouSubtitle,
          onTap: () => AppNavigator.slideFromRight(
            context,
            const BunpouHomeScreen(),
          ),
        ),
        const SizedBox(height: 12),
        // Premium gate temporarily removed for dev testing (2026-07-17) —
        // see memory/project_monetization_roadmap.md. Restore
        // _PremiumModuleCard + PaywallScreen branch before release.
        _AvailableModuleCard(
          emoji: 'を',
          backgroundColor: palette.tertiaryAmberCardBg,
          iconColor: palette.tertiaryAmber,
          title: s.particleTitle,
          subtitle: s.particleSubtitle,
          onTap: () =>
              AppNavigator.slideFromRight(context, const ParticleHomeScreen()),
        ),
        const SizedBox(height: 28),
        _SectionHeader(s.sectionPractice),
        const SizedBox(height: 12),
        _AvailableModuleCard(
          emoji: '💬',
          backgroundColor: palette.hiraganaCardBg,
          iconColor: palette.primaryCoral,
          title: s.kaiwaTitle,
          subtitle: s.kaiwaSubtitle,
          onTap: () =>
              AppNavigator.slideFromRight(context, const KaiwaHomeScreen()),
        ),
        const SizedBox(height: 12),
        // Moved here from the Ujian tab's category picker — Dokkai is
        // reading-practice material (500 real passages), not an exam; it
        // sat oddly next to Kana/Kanji-Kombinasi before.
        _AvailableModuleCard(
          emoji: '読',
          backgroundColor: palette.katakanaCardBg,
          iconColor: palette.secondaryBlue,
          title: 'Dokkai',
          subtitle: s.dokkaiCategorySubtitle,
          onTap: () =>
              AppNavigator.slideFromRight(context, const DokkaiHomeScreen()),
        ),
        const SizedBox(height: 12),
        // Choukai had full screens but no entry point anywhere in the app —
        // nothing navigated to ChoukaiHomeScreen, and it was in neither the
        // module list nor the coming-soon list, so the module was orphaned.
        // Listening is roughly a quarter of every JLPT paper, so it belongs
        // next to Dokkai as practice material rather than hidden.
        _AvailableModuleCard(
          emoji: '聴',
          backgroundColor: palette.hiraganaCardBg,
          iconColor: palette.primaryCoral,
          title: 'Choukai',
          subtitle: s.choukaiCategorySubtitle,
          onTap: () =>
              AppNavigator.slideFromRight(context, const ChoukaiHomeScreen()),
        ),
        const SizedBox(height: 28),
        _SectionHeader(s.sectionTools),
        const SizedBox(height: 12),
        _LockedModuleCard(
          emoji: '📷',
          title: s.camDetectorTitle,
          subtitle: s.camDetectorSubtitle,
          reason: s.camDetectorReason,
          fixingBadge: s.fixingBadge,
        ),
        const SizedBox(height: 28),
        _SectionHeader(s.comingSoonHeader),
        const SizedBox(height: 12),
        ...kComingSoonModules.map(
          (module) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ComingSoonCard(module: module, strings: s),
          ),
        ),
      ],
    );
  }
}

/// Entry point into the Bab curriculum — taller than [_AvailableModuleCard]
/// since it embeds a [MascotGuideBubble] instead of just an emoji+title,
/// making the mascot's first "active guide" appearance the very first
/// thing a learner sees about this section.
class _BabCurriculumCard extends ConsumerWidget {
  const _BabCurriculumCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final nextUp = ref.watch(babNextUpProvider).valueOrNull;

    return Material(
      color: context.palette.cardWhite,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => AppNavigator.slideFromRight(context, const BabHomeScreen()),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: MascotGuideBubble(
            mood: nextUp != null ? MascotMood.excited : MascotMood.happy,
            message: nextUp != null
                ? s.babGuideContinue(nextUp.localizedTitle(s.language))
                : s.babGuideIntro,
            mascotSize: 56,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: context.palette.textNavy,
      ),
    );
  }
}

class _AvailableModuleCard extends StatelessWidget {
  final String emoji;
  final Color backgroundColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AvailableModuleCard({
    required this.emoji,
    required this.backgroundColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
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
                decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  emoji,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.palette.textNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.palette.textNavy.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: iconColor),
            ],
          ),
        ),
      ),
    );
  }
}

/// A module that already has real code/screens behind it, but is
/// deliberately kept unreachable from navigation because of known bugs —
/// distinct from [_ComingSoonCard] (which is for modules that don't exist
/// yet). Tapping shows why, via a [SnackBar], instead of the "under
/// development / remind me / premium" [ComingSoonContent] sheet, since that
/// messaging would be misleading for a feature that already exists.
class _LockedModuleCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String reason;
  final String fixingBadge;

  const _LockedModuleCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.reason,
    required this.fixingBadge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.mutedSurface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(reason)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.palette.freeBadgeGrey.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: context.palette.textNavy,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: context.palette.freeBadgeGrey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            fixingBadge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: context.palette.freeBadgeGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.palette.textNavy.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.lock, color: context.palette.freeBadgeGrey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  final ModuleInfo module;
  final AppStrings strings;

  const _ComingSoonCard({required this.module, required this.strings});

  static const _icons = {
    'picture_learning': '🖼️',
    'video_learning': '🎬',
  };

  /// [ModuleInfo.title]/[description] are the dataset's Indonesian-authored
  /// identity strings (see `module_info.dart`) — resolve the localized
  /// display text by id instead of touching the model itself.
  (String, String) _displayText() {
    switch (module.id) {
      case 'picture_learning':
        return (strings.pictureLearningTitle, strings.pictureLearningSubtitle);
      case 'video_learning':
        return (strings.videoLearningTitle, strings.videoLearningSubtitle);
      default:
        return (module.title, module.description);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (title, description) = _displayText();
    return Material(
      color: context.palette.mutedSurface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => showComingSoonSheet(context, moduleId: module.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.palette.freeBadgeGrey.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _icons[module.id] ?? '❓',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: context.palette.textNavy,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: context.palette.freeBadgeGrey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            strings.comingSoonBadge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: context.palette.freeBadgeGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.palette.textNavy.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (module.requiresPremium) ...[
                const SizedBox(width: 8),
                Icon(Icons.lock, color: context.palette.freeBadgeGrey, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

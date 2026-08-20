import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../paywall/paywall_screen.dart';
import '../../paywall/module_access.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/mascot_guide_bubble.dart';
import '../../../core/widgets/mascot_widget.dart';
import '../../../data/models/module_info.dart';
import '../../../data/models/kana_type.dart';
import '../../../data/models/card_game_rank.dart';
import '../../bab/bab_home_screen.dart';
import '../../bab/bab_providers.dart';
import '../../bab/widgets/bab_ring_badge.dart';
import '../../battle/card_game_shell.dart';
import '../../bunpou/bunpou_home_screen.dart';
import '../../choukai/choukai_home_screen.dart';
import '../../dokkai/dokkai_home_screen.dart';
import '../../flashcard/kana_table_screen.dart';
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
        _SectionHeader(
          s.sectionBasics,
          emoji: '🌸',
          color: palette.primaryCoral,
          iconAsset: 'icon_dasar_kurikulum',
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _KanaHeroCard(
                emoji: 'あ',
                backgroundColor: palette.hiraganaCardBg,
                accent: palette.primaryCoral,
                title: s.learnHiragana,
                subtitle: s.basicChars46,
                torii: true,
                onTap: () => AppNavigator.slideFromRight(
                  context,
                  const KanaTableScreen(type: KanaType.hiragana),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KanaHeroCard(
                emoji: 'ア',
                backgroundColor: palette.katakanaCardBg,
                accent: palette.secondaryBlue,
                title: s.learnKatakana,
                subtitle: s.basicChars46,
                torii: false,
                onTap: () => AppNavigator.slideFromRight(
                  context,
                  const KanaTableScreen(type: KanaType.katakana),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        _SectionHeader(
          s.sectionKurikulum,
          emoji: '🌸',
          color: palette.primaryCoral,
          iconAsset: 'icon_dasar_kurikulum',
        ),
        const SizedBox(height: 12),
        const _BabCurriculumCard(),
        const SizedBox(height: 28),
        _SectionHeader(
          s.sectionBattle,
          emoji: '⚔',
          color: palette.secondaryBlue,
        ),
        const SizedBox(height: 12),
        const _CardGameCard(),
        const SizedBox(height: 28),
        // Vocabulary/kanji and practice modules side by side, matching how
        // often a learner reaches for one right after the other — not just
        // a cosmetic 2-column grid, the two columns group by the same
        // "build blocks, then use them" split the section headers name.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    s.sectionVocabKanji,
                    emoji: '📖',
                    color: palette.secondaryBlue,
                    iconAsset: 'icon_kosakata_kanji_header',
                  ),
                  const SizedBox(height: 12),
                  _AvailableModuleCard(
                    dense: true,
                    emoji: '📚',
                    iconAsset: 'icon_kosakata',
                    backgroundColor: palette.katakanaCardBg,
                    iconColor: palette.secondaryBlue,
                    title: s.kotobaTitle,
                    subtitle: s.kotobaSubtitle,
                    onTap: () => AppNavigator.slideFromRight(
                      context,
                      const KotobaHomeScreen(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _AvailableModuleCard(
                    dense: true,
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
                ],
              ),
            ),
            SizedBox(
              width: 25,
              child: Center(
                child: Container(
                  width: 1,
                  height: 170,
                  color: palette.textNavy.withValues(alpha: 0.08),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    s.sectionPractice,
                    emoji: '💬',
                    color: palette.primaryCoral,
                    iconAsset: 'icon_kaiwa_latihan',
                  ),
                  const SizedBox(height: 12),
                  _PremiumModuleCard(
                    moduleId: PremiumModules.kaiwa,
                    dense: true,
                    emoji: '💬',
                    iconAsset: 'icon_kaiwa_latihan',
                    backgroundColor: palette.hiraganaCardBg,
                    iconColor: palette.primaryCoral,
                    title: s.kaiwaTitle,
                    subtitle: s.kaiwaSubtitle,
                    onOpen: () => AppNavigator.slideFromRight(
                      context,
                      const KaiwaHomeScreen(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Moved here from the Ujian tab's category picker — Dokkai
                  // is reading-practice material (500 real passages), not
                  // an exam; it sat oddly next to Kana/Kanji-Kombinasi
                  // before.
                  _AvailableModuleCard(
                    dense: true,
                    emoji: '読',
                    backgroundColor: palette.katakanaCardBg,
                    iconColor: palette.secondaryBlue,
                    title: 'Dokkai',
                    subtitle: s.dokkaiCategorySubtitle,
                    onTap: () => AppNavigator.slideFromRight(
                      context,
                      const DokkaiHomeScreen(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Choukai had full screens but no entry point anywhere in
                  // the app — nothing navigated to ChoukaiHomeScreen, and it
                  // was in neither the module list nor the coming-soon
                  // list, so the module was orphaned. Listening is roughly
                  // a quarter of every JLPT paper, so it belongs next to
                  // Dokkai as practice material rather than hidden.
                  _PremiumModuleCard(
                    moduleId: PremiumModules.choukai,
                    dense: true,
                    emoji: '聴',
                    backgroundColor: palette.hiraganaCardBg,
                    iconColor: palette.primaryCoral,
                    title: 'Choukai',
                    subtitle: s.choukaiCategorySubtitle,
                    onOpen: () => AppNavigator.slideFromRight(
                      context,
                      const ChoukaiHomeScreen(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        _SectionHeader(s.sectionGrammar, emoji: '文', color: palette.primaryCoral),
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
        _PremiumModuleCard(
          moduleId: PremiumModules.particle,
          emoji: 'を',
          backgroundColor: palette.tertiaryAmberCardBg,
          iconColor: palette.tertiaryAmber,
          title: s.particleTitle,
          subtitle: s.particleSubtitle,
          onOpen: () =>
              AppNavigator.slideFromRight(context, const ParticleHomeScreen()),
        ),
        const SizedBox(height: 28),
        _SectionHeader(
          s.sectionTools,
          emoji: '🔧',
          color: palette.freeBadgeGrey,
          iconAsset: 'icon_alat',
        ),
        const SizedBox(height: 12),
        _LockedModuleCard(
          emoji: '📷',
          title: s.camDetectorTitle,
          subtitle: s.camDetectorSubtitle,
          reason: s.camDetectorReason,
          fixingBadge: s.fixingBadge,
        ),
        const SizedBox(height: 28),
        _SectionHeader(
          s.comingSoonHeader,
          emoji: '⏳',
          color: palette.freeBadgeGrey,
          iconAsset: 'icon_segera_hadir',
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < kComingSoonModules.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(
                child: _ComingSoonCard(
                  dense: true,
                  module: kComingSoonModules[i],
                  strings: s,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Entry point into Card Game Mode, and — until a dedicated screen for it
/// exists — the only place in the app that shows a player their standing
/// without starting anything.
///
/// The mode's whole engine (matchmaking, bot, server-side scoring, the
/// star ladder) was finished and deployed while remaining unreachable
/// from Home: the only way in was a friend challenge from `ChatHubScreen`,
/// so public play existed on the server and nowhere in the app. This card
/// is that missing door.
///
/// A [ConsumerWidget] rather than a plain card because the subtitle names
/// the current tier — a card that reads "Bronze V · 1/3 bintang" is an
/// invitation to climb, where a fixed description is just another module.
/// The standing is allowed to be absent (still loading, or a failed read):
/// it falls back to the generic subtitle rather than blocking the door,
/// since nothing about *entering* a match depends on knowing the rank
/// first — the matchmaking screen re-reads it anyway.
class _CardGameCard extends ConsumerWidget {
  const _CardGameCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final palette = context.palette;
    final rank = ref.watch(cardGameRankProvider).valueOrNull;

    final subtitle = rank == null
        ? s.cardGameSubtitle
        : s.cardGameSubtitleWithRank(
            rank.displayName,
            rank.tier.hasDivisions
                ? s.battleRankStars(rank.stars, rank.tier.starsPerDivision)
                : s.battleRankStarsUncapped(rank.stars),
          );

    return _AvailableModuleCard(
      emoji: '⚔',
      backgroundColor: palette.katakanaCardBg,
      iconColor: palette.secondaryBlue,
      title: s.cardGameTitle,
      subtitle: subtitle,
      onTap: () => AppNavigator.slideFromRight(
        context,
        const CardGameShell(),
      ),
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
            // A greeting when nothing is in progress, rather than a
            // grin about nothing in particular.
            mood: nextUp != null ? MascotMood.excited : MascotMood.waving,
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
  final String emoji;
  final Color color;

  /// A real illustrated glyph (`assets/icons/{name}.png`) in place of the
  /// plain-emoji [emoji] fallback — every section header uses one of
  /// these now except "Tata Bahasa", which keeps 文 as real Japanese
  /// script (see `icon_asset_prompts.md`'s own note that meaningful
  /// characters like あ/字/文 were deliberately left out of that prompt
  /// set, only decorative emoji were replaced).
  final String? iconAsset;

  const _SectionHeader(
    this.title, {
    required this.emoji,
    required this.color,
    this.iconAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (iconAsset != null)
          Image.asset(
            'assets/icons/$iconAsset.png',
            width: 18,
            height: 18,
            errorBuilder: (context, error, stackTrace) =>
                Text(emoji, style: TextStyle(fontSize: 14, color: color)),
          )
        else
          Text(emoji, style: TextStyle(fontSize: 14, color: color)),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.palette.textNavy,
          ),
        ),
      ],
    );
  }
}

/// The Hiragana/Katakana entry point — taller than a plain
/// [_AvailableModuleCard] and carrying its own scene behind the text, so
/// the two syllabaries read as the app's front door rather than just the
/// first two rows of a list. [torii] picks which real illustration sits
/// behind the card in light mode (`assets/banners/hiragana_card.png`'s
/// sakura branch + torii, or `katakana_card.png`'s pagoda) — both cropped
/// from the reference mockup with its icon/title/chevron chrome removed
/// via inpainting, the same real-asset treatment [HomeHeroScene] and
/// [ModuleSkylineBanner] use. Dark mode falls back to
/// [_KanaSceneryPainter]'s code-drawn silhouette for the same reason those
/// two fall back to a painter — a flat illustration can't be relit by a
/// runtime filter.
class _KanaHeroCard extends StatelessWidget {
  final String emoji;
  final Color backgroundColor;
  final Color accent;
  final String title;
  final String subtitle;
  final bool torii;
  final VoidCallback onTap;

  const _KanaHeroCard({
    required this.emoji,
    required this.backgroundColor,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.torii,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Material(
        color: backgroundColor,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 210,
            child: Stack(
              children: [
                // One path for both themes, with the painter kept only as
                // the safety net it was always meant to be. Dark used to
                // skip the asset entirely; now it asks for the night
                // twin and falls through to the painter while that file
                // does not exist, so this costs nothing until the art
                // lands and needs no code change when it does.
                Positioned.fill(
                  child: IgnorePointer(
                    child: Image.asset(
                      switch ((torii, isDark)) {
                        (true, false) => 'assets/banners/hiragana_card.png',
                        (true, true) => 'assets/banners/hiragana_card_dark.png',
                        (false, false) => 'assets/banners/katakana_card.png',
                        (false, true) => 'assets/banners/katakana_card_dark.png',
                      },
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => CustomPaint(
                        painter: _KanaSceneryPainter(
                          color: accent.withValues(alpha: 0.22),
                          torii: torii,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration:
                            BoxDecoration(color: accent, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: Text(
                          emoji,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: context.palette.textNavy,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.palette.textNavy.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 14,
                  bottom: 14,
                  child: BabChevronButton(color: accent, size: 34),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A single mountain hump plus one landmark, sitting low in the card so the
/// icon/title/subtitle above always stay legible — the low-alpha,
/// flat-shape restraint this app's decorative painters share (see
/// [BabDecorativeBackground]'s skyline, [SakuraDecoration]'s petals).
class _KanaSceneryPainter extends CustomPainter {
  final Color color;
  final bool torii;

  const _KanaSceneryPainter({required this.color, required this.torii});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fill = Paint()..color = color;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final mountain = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.82)
      ..quadraticBezierTo(w * 0.3, h * 0.55, w * 0.55, h * 0.78)
      ..quadraticBezierTo(w * 0.78, h * 0.95, w, h * 0.7)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(mountain, fill);

    if (torii) {
      final x = w * 0.28;
      final baseY = h * 0.94;
      final topY = h * 0.72;
      canvas.drawLine(Offset(x - 12, baseY), Offset(x - 12, topY), stroke);
      canvas.drawLine(Offset(x + 12, baseY), Offset(x + 12, topY), stroke);
      canvas.drawLine(Offset(x - 18, topY), Offset(x + 18, topY), stroke);
      canvas.drawLine(
        Offset(x - 22, topY - 7),
        Offset(x + 22, topY - 7),
        stroke,
      );
    } else {
      final x = w * 0.68;
      final baseY = h * 0.94;
      for (var tier = 0; tier < 3; tier++) {
        final tierWidth = 26.0 - tier * 6;
        final tierY = baseY - tier * 15;
        canvas.drawRect(
          Rect.fromCenter(center: Offset(x, tierY), width: tierWidth, height: 4),
          fill,
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(x, tierY - 7),
            width: tierWidth * 0.45,
            height: 10,
          ),
          fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _KanaSceneryPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.torii != torii;
}

class _AvailableModuleCard extends StatelessWidget {
  final String emoji;
  final Color backgroundColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// A real illustrated icon (`assets/icons/{name}.png`) shown in place of
  /// [emoji] inside the coloured circle — only set for the modules covered
  /// by `icon_asset_prompts.md`'s Set A. Modules that show a real Japanese
  /// character (字/文/を/読/聴) keep [emoji] as plain text; those are
  /// meaningful script, not decorative emoji, and were deliberately left
  /// out of that prompt set.
  final String? iconAsset;

  /// Tighter padding/icon/type for the two-column "Kosakata & Kanji" /
  /// "Latihan" grid, where each card only owns half the row's width.
  final bool dense;

  const _AvailableModuleCard({
    required this.emoji,
    required this.backgroundColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconAsset,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = dense ? 38.0 : 48.0;
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(dense ? 12 : 16),
          child: Row(
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: iconAsset != null
                    ? Padding(
                        padding: EdgeInsets.all(iconSize * 0.14),
                        child: Image.asset(
                          'assets/icons/$iconAsset.png',
                          errorBuilder: (context, error, stackTrace) => Text(
                            emoji,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: dense ? 15 : 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        emoji,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: dense ? 15 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              SizedBox(width: dense ? 10 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: dense ? 13 : 16,
                        fontWeight: FontWeight.bold,
                        color: context.palette.textNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: dense ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: dense ? 11 : 13,
                        color: context.palette.textNavy.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: iconColor, size: dense ? 18 : 24),
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
  final bool dense;

  const _ComingSoonCard({
    required this.module,
    required this.strings,
    this.dense = false,
  });

  static const _icons = {
    'picture_learning': '🖼️',
    'video_learning': '🎬',
  };

  static const _iconAssets = {
    'picture_learning': 'icon_belajar_gambar',
    'video_learning': 'icon_belajar_video',
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
    final iconSize = dense ? 38.0 : 48.0;
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: context.palette.freeBadgeGrey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        strings.comingSoonBadge,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: context.palette.freeBadgeGrey,
        ),
      ),
    );
    final titleText = Text(
      title,
      maxLines: dense ? 2 : 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: dense ? 13 : 15,
        fontWeight: FontWeight.bold,
        color: context.palette.textNavy,
      ),
    );

    return Material(
      color: context.palette.mutedSurface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => showComingSoonSheet(context, moduleId: module.id),
        child: Padding(
          padding: EdgeInsets.all(dense ? 12 : 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: context.palette.freeBadgeGrey.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: _iconAssets[module.id] != null
                    ? Padding(
                        padding: EdgeInsets.all(iconSize * 0.14),
                        child: Image.asset(
                          'assets/icons/${_iconAssets[module.id]}.png',
                          errorBuilder: (context, error, stackTrace) => Text(
                            _icons[module.id] ?? '❓',
                            style: TextStyle(fontSize: dense ? 15 : 20),
                          ),
                        ),
                      )
                    : Text(
                        _icons[module.id] ?? '❓',
                        style: TextStyle(fontSize: dense ? 15 : 20),
                      ),
              ),
              SizedBox(width: dense ? 10 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A dense (two-column) card stacks the badge under the
                    // title instead of squeezing both onto one line — at
                    // half the row's width an inline badge either clips
                    // the title or overflows the card.
                    if (dense) ...[
                      titleText,
                      const SizedBox(height: 4),
                      badge,
                    ] else
                      Row(
                        children: [
                          Flexible(child: titleText),
                          const SizedBox(width: 8),
                          badge,
                        ],
                      ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      maxLines: dense ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: dense ? 11 : 13,
                        color: context.palette.textNavy.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (module.requiresPremium) ...[
                SizedBox(width: dense ? 4 : 8),
                Icon(
                  Icons.lock,
                  color: context.palette.freeBadgeGrey,
                  size: dense ? 16 : 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


/// A module that costs money, on the list beside the ones that do not.
///
/// **Shown rather than hidden, and tappable rather than inert.** A
/// learner who cannot see what they are missing has no reason to buy it,
/// and a card that refuses to respond reads as broken. Tapping opens the
/// paywall, which is also where a rewarded ad can open the module for a
/// day — so this is a door, not a wall.
///
/// It becomes an ordinary [_AvailableModuleCard] the moment access is
/// granted, rather than staying a premium-styled card with the lock
/// taken off: once you own it, it is simply one of your modules.
class _PremiumModuleCard extends ConsumerWidget {
  const _PremiumModuleCard({
    required this.moduleId,
    required this.emoji,
    required this.backgroundColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onOpen,
    this.dense = false,
    this.iconAsset,
  });

  final String moduleId;
  final String emoji;
  final Color backgroundColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onOpen;
  final bool dense;
  final String? iconAsset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final palette = context.palette;
    // `false` while the answer is still loading. The alternative is a
    // card that is briefly open on every cold start, which is the one
    // moment a gate must not be.
    final unlocked =
        ref.watch(moduleAccessProvider(moduleId)).valueOrNull ?? false;

    if (unlocked) {
      return _AvailableModuleCard(
        dense: dense,
        emoji: emoji,
        iconAsset: iconAsset,
        backgroundColor: backgroundColor,
        iconColor: iconColor,
        title: title,
        subtitle: subtitle,
        onTap: onOpen,
      );
    }

    return Stack(
      children: [
        _AvailableModuleCard(
          dense: dense,
          emoji: emoji,
          iconAsset: iconAsset,
          backgroundColor: palette.mutedSurface,
          iconColor: palette.freeBadgeGrey,
          title: title,
          subtitle: subtitle,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PaywallScreen(
                moduleId: moduleId,
                moduleTitle: title,
              ),
            ),
          ),
        ),
        Positioned(
          top: 10,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [palette.premiumGoldStart, palette.premiumGoldEnd],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock, size: 10, color: Colors.white),
                const SizedBox(width: 3),
                Text(
                  s.premiumBadge,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    color: Colors.white,
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

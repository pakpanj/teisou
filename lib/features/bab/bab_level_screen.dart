import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_refresh_indicator.dart';
import '../../core/widgets/mascot_advisor.dart';
import '../../core/widgets/mascot_widget.dart';
import '../../core/widgets/module_card_frame.dart';
import '../../core/widgets/module_skyline_banner.dart';
import '../../core/widgets/module_title_plaque.dart';
import '../../data/models/bab_entry.dart';
import '../../data/models/jlpt_level.dart';
import 'bab_detail_screen.dart';
import 'bab_providers.dart';
import 'widgets/bab_decorative_background.dart';
import 'widgets/bab_ring_badge.dart';
import '../../core/widgets/app_loading.dart';

/// Whether a chapter stays locked until its immediate predecessor's gate
/// quiz has been passed — the intended product behaviour.
///
/// Was temporarily `false` during the 358-chapter content rollout so the
/// whole curriculum could be tapped through freely for testing (with 250+
/// chapters never yet opened on a device, a quiz per chapter would have
/// made that impossible). **Switched back on 2026-08-04 for the release
/// build**, which is what this flag was always meant to be reset to.
///
/// Kept as a named constant rather than inlined so the same
/// dev-vs-release trade-off stays a one-line toggle if a future content
/// rollout needs the same freedom again. Flipping it only removes the
/// *requirement*: the gate quiz itself, the completed checkmarks, and the
/// mascot's "what's next" all behave identically either way.
const bool kBabGateQuizRequired = true;

/// Ordered chapter list for one JLPT level.
class BabLevelScreen extends ConsumerWidget {
  final JlptLevel level;

  const BabLevelScreen({super.key, required this.level});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final chaptersAsync = ref.watch(babByLevelProvider(level));
    final completed = ref.watch(babCompletedIdsProvider).valueOrNull ?? {};

    return Scaffold(
      backgroundColor: context.palette.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: context.palette.textNavy,
        title: ModuleTitlePlaque(title: s.babLevelAppBarTitle(level.key)),
      ),
      body: chaptersAsync.when(
        data: (chapters) => BabDecorativeBackground(
          child: MascotAdvisor(
            // Explaining, not just cheerful: this message tells the
            // learner how the screen works rather than reacting to them.
            mood: MascotMood.explaining,
            message: s.babLevelGuideMessage,
            child: AppRefreshIndicator(
              onRefresh: () => ref.refresh(babByLevelProvider(level).future),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  const ModuleSkylineBanner(),
                  Padding(
                    // Bottom padding, not a gap widget: the advisor is
                    // anchored to the screen rather than to the list, so
                    // the list has to leave room under itself or the last
                    // chapter scrolls to a stop underneath the character.
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      20,
                      20,
                      MascotAdvisor.reservedBottomSpace,
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < chapters.length; i++) ...[
                          if (i > 0)
                            Padding(
                              padding: const EdgeInsets.only(left: 42),
                              child: BabPathConnector(
                                color: context.palette.freeBadgeGrey
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          _ChapterCard(
                            bab: chapters[i],
                            done: completed.contains(chapters[i].id),
                            // Chapter 1 never needs a gate quiz behind it
                            // (nothing came before it); every other chapter
                            // stays locked until its immediate
                            // predecessor's gate quiz has been passed.
                            // `chapters` is already sorted by `order`
                            // (BabRepository.getByLevel), so the
                            // predecessor is always the previous list item,
                            // not a lookup by id. Gated on
                            // kBabGateQuizRequired, see that constant's doc
                            // comment above.
                            locked:
                                kBabGateQuizRequired &&
                                i > 0 &&
                                !completed.contains(chapters[i - 1].id),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        loading: () => const AppLoading(),
        error: (e, _) => Center(child: Text(s.failedToLoadLevels(e))),
      ),
    );
  }
}

class _ChapterCard extends ConsumerWidget {
  final BabEntry bab;
  final bool done;
  final bool locked;

  const _ChapterCard({
    required this.bab,
    required this.done,
    required this.locked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final palette = context.palette;
    final greyed = palette.freeBadgeGrey;
    final active = !locked;
    // The framed card is a pale sakura picture, not a surface the theme
    // repaints, so everything drawn on it takes the light palette however
    // the app is themed — see [framePaletteOf(context)]. Without this the open
    // level rendered its own title and progress in near-white on pink.
    final surface = active ? framePaletteOf(context) : palette;

    final accent = done
        ? palette.successGreen
        : locked
        ? greyed
        : surface.primaryCoral;

    final card = Material(
      // Active cards get the sakura nine-patch frame's own flat pink fill
      // behind them instead of a flat colour — same convention as
      // ModuleLevelCard's own available/locked split.
      color: active ? Colors.transparent : palette.cardWhite,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => locked
            ? ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(s.babLockedReason(bab.order - 1))),
              )
            : AppNavigator.slideFromRight(
                context,
                BabDetailScreen(babId: bab.id),
              ),
        child: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                BabRingBadge(
                  size: 60,
                  color: accent,
                  showPetals: active,
                  child: done
                      ? Icon(Icons.check, color: accent)
                      : locked
                      ? Icon(Icons.lock, color: accent, size: 20)
                      : Text(
                          '${bab.order}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: accent,
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bab.localizedTitle(s.language),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: locked ? greyed : surface.textNavy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        locked
                            ? s.babLockedReason(bab.order - 1)
                            : bab.localizedDescription(s.language),
                        style: TextStyle(
                          fontSize: 12,
                          color: locked
                              ? greyed
                              : surface.textNavy.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                locked
                    ? Icon(Icons.lock, color: greyed, size: 20)
                    : BabChevronButton(color: surface.primaryCoral),
              ],
            ),
          ),
        ),
      ),
    );

    return active ? ModuleCardFrame(child: card) : card;
  }
}

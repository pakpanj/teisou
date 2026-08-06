import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_refresh_indicator.dart';
import '../../core/widgets/mascot_advisor.dart';
import '../../core/widgets/mascot_widget.dart';
import '../../data/models/jlpt_level.dart';
import 'bab_level_screen.dart';
import 'bab_providers.dart';

/// Entry point for the Bab curriculum: a JLPT level picker, mirroring
/// [KanjiHomeScreen]'s shape. Unlike Kanji/Kotoba/Bunpou/Kaiwa, Bab has no
/// separate `_levels.json` metadata file — the dataset is small enough
/// that level availability/counts are derived straight from
/// [babByLevelProvider] instead.
class BabHomeScreen extends ConsumerWidget {
  const BabHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final nextUp = ref.watch(babNextUpProvider).valueOrNull;

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: Text(s.babTitle)),
      body: MascotAdvisor(
        // Waving when there is nothing in progress — it is a greeting,
        // not a reaction. Excited once there is somewhere to carry on to.
        mood: nextUp != null ? MascotMood.excited : MascotMood.waving,
        message: nextUp != null
            ? s.babGuideContinue(nextUp.localizedTitle(s.language))
            : s.babGuideIntro,
        child: AppRefreshIndicator(
          onRefresh: () async {
            ref.invalidate(babAllProvider);
            ref.invalidate(babNextUpProvider);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            // Bottom padding clears the advisor standing over this list,
            // so the last level card can always be scrolled out from
            // under it.
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MascotAdvisor.reservedBottomSpace,
            ),
            children: [
              for (final level in JlptLevel.values) ...[
                _LevelCard(level: level),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelCard extends ConsumerWidget {
  final JlptLevel level;

  const _LevelCard({required this.level});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapters = ref.watch(babByLevelProvider(level)).valueOrNull;
    final levels = ref.watch(babLevelProgressProvider).valueOrNull;
    final s = ref.watch(appStringsProvider);

    final authored = (chapters?.isNotEmpty ?? false);
    final standing = levels?.firstWhere((l) => l.level == level);

    // A level opens only once every earlier level is finished end to end —
    // the same rule chapters already follow one step down, applied one
    // step up. Gated on the same kBabGateQuizRequired toggle so flipping
    // that for a content rollout opens chapters *and* levels together
    // rather than leaving half the gating on.
    //
    // While the standing is still loading, treat the level as locked
    // rather than open: a card that is briefly tappable and then locks
    // under the learner's finger is worse than one that resolves from
    // locked to open.
    final reached = standing?.reachedByProgress ?? (level == JlptLevel.n5);
    final locked = kBabGateQuizRequired && !reached;
    final available = authored && !locked;

    final previousLevel = level == JlptLevel.n5
        ? null
        : JlptLevel.values[JlptLevel.values.indexOf(level) - 1];

    void open() {
      if (locked) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.babLevelLockedReason(previousLevel!.key))),
        );
        return;
      }
      if (!authored) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.babLevelComingSoon(level.key))),
        );
        return;
      }
      AppNavigator.slideFromRight(context, BabLevelScreen(level: level));
    }

    return Material(
      color: available
          ? context.palette.cardWhite
          : context.palette.mutedSurface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: open,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color:
                      (available
                              ? context.palette.primaryCoral
                              : context.palette.freeBadgeGrey)
                          .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: locked
                    ? Icon(
                        Icons.lock,
                        size: 22,
                        color: context.palette.freeBadgeGrey,
                      )
                    : Text(
                        level.key,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: available
                              ? context.palette.primaryCoral
                              : context.palette.freeBadgeGrey,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.babLevelCardTitle(level.key),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: available
                            ? context.palette.textNavy
                            : context.palette.freeBadgeGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (locked)
                      _Badge(
                        label: s.babLevelLockedBadge,
                        color: context.palette.freeBadgeGrey,
                      )
                    else if (!authored)
                      _Badge(
                        label: s.soonBadge,
                        color: context.palette.freeBadgeGrey,
                      )
                    else
                      // Once a level is open, showing progress inside it
                      // is more useful than its raw chapter count — the
                      // learner already knows how long it is.
                      Text(
                        standing == null
                            ? s.babChapterCount(chapters!.length)
                            : s.babLevelChapterProgress(
                                standing.completed,
                                standing.total,
                              ),
                        style: TextStyle(
                          fontSize: 12,
                          color: context.palette.textNavy.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: available
                    ? context.palette.primaryCoral
                    : context.palette.freeBadgeGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

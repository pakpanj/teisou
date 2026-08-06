import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_refresh_indicator.dart';
import '../../core/widgets/mascot_advisor.dart';
import '../../core/widgets/mascot_widget.dart';
import '../../data/models/bab_entry.dart';
import '../../data/models/jlpt_level.dart';
import 'bab_detail_screen.dart';
import 'bab_providers.dart';

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
      appBar: AppBar(title: Text(s.babLevelAppBarTitle(level.key))),
      body: chaptersAsync.when(
        data: (chapters) => MascotAdvisor(
          mood: MascotMood.happy,
          message: s.babLevelGuideMessage,
          child: AppRefreshIndicator(
            onRefresh: () => ref.refresh(babByLevelProvider(level).future),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              // Bottom padding, not a gap widget: the advisor is anchored
              // to the screen rather than to the list, so the list has to
              // leave room under itself or the last chapter scrolls to a
              // stop underneath the character.
              padding: const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MascotAdvisor.reservedBottomSpace,
              ),
              children: [
                for (var i = 0; i < chapters.length; i++) ...[
                  _ChapterCard(
                    bab: chapters[i],
                    done: completed.contains(chapters[i].id),
                    // Chapter 1 never needs a gate quiz behind it (nothing
                    // came before it); every other chapter stays locked
                    // until its immediate predecessor's gate quiz has been
                    // passed. `chapters` is already sorted by `order`
                    // (BabRepository.getByLevel), so the predecessor is
                    // always the previous list item, not a lookup by id.
                    // Gated on kBabGateQuizRequired, currently off for
                    // testing — see that constant's doc comment above.
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
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
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
    final greyed = context.palette.freeBadgeGrey;

    return Material(
      color: locked ? context.palette.mutedSurface : context.palette.cardWhite,
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color:
                      (done
                              ? context.palette.successGreen
                              : locked
                              ? greyed
                              : context.palette.primaryCoral)
                          .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: done
                    ? Icon(Icons.check, color: context.palette.successGreen)
                    : locked
                    ? Icon(Icons.lock, color: greyed, size: 20)
                    : Text(
                        '${bab.order}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: context.palette.primaryCoral,
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
                        color: locked ? greyed : context.palette.textNavy,
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
                            : context.palette.textNavy.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                locked ? Icons.lock : Icons.chevron_right,
                color: locked ? greyed : context.palette.primaryCoral,
                size: locked ? 20 : 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

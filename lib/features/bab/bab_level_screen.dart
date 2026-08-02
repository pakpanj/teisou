import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_refresh_indicator.dart';
import '../../core/widgets/mascot_guide_bubble.dart';
import '../../core/widgets/mascot_widget.dart';
import '../../data/models/bab_entry.dart';
import '../../data/models/jlpt_level.dart';
import 'bab_detail_screen.dart';
import 'bab_providers.dart';

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
        data: (chapters) => AppRefreshIndicator(
          onRefresh: () => ref.refresh(babByLevelProvider(level).future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              MascotGuideBubble(
                mood: MascotMood.happy,
                message: s.babLevelGuideMessage,
              ),
              const SizedBox(height: 20),
              for (final bab in chapters) ...[
                _ChapterCard(bab: bab, done: completed.contains(bab.id)),
                const SizedBox(height: 12),
              ],
            ],
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

  const _ChapterCard({required this.bab, required this.done});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);

    return Material(
      color: context.palette.cardWhite,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => AppNavigator.slideFromRight(context, BabDetailScreen(babId: bab.id)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: (done ? context.palette.successGreen : context.palette.primaryCoral)
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: done
                    ? Icon(Icons.check, color: context.palette.successGreen)
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
                        color: context.palette.textNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bab.localizedDescription(s.language),
                      style: TextStyle(
                        fontSize: 12,
                        color: context.palette.textNavy.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.palette.primaryCoral),
            ],
          ),
        ),
      ),
    );
  }
}

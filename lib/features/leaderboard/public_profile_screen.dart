import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../data/models/bab_entry.dart';
import '../../data/models/jlpt_level.dart';
import '../../data/models/leaderboard_entry.dart';
import '../bab/bab_providers.dart';
import 'leaderboard_screen.dart' show LeaderboardAvatar, globalScoreLabel;

/// One learner's public profile, opened by tapping their row in the global
/// leaderboard or a clan ranking — built for the teacher/clan use case the
/// Clan feature exists for: see a student's score *and* how far through the
/// curriculum they've actually got, without needing their device.
///
/// Renders entirely from the already-fetched [LeaderboardEntry], so opening
/// it costs no extra Firestore read. That's also why it can only show what
/// `leaderboard/{uid}` publishes: the per-chapter progress list itself
/// lives in `users/{uid}/babProgress`, which `firestore.rules` keeps
/// readable only by its owner — hence the two denormalized counters (see
/// [LeaderboardEntry.babCompletedCount]).
class PublicProfileScreen extends ConsumerWidget {
  final LeaderboardEntry entry;

  const PublicProfileScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final allBabAsync = ref.watch(babAllProvider);

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: Text(s.publicProfileTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _IdentityCard(entry: entry),
          const SizedBox(height: 20),
          _SectionCard(
            title: s.scoreBreakdownTitle,
            child: Column(
              children: [
                _ScoreRow(
                  label: s.scorePartKana,
                  avg: entry.kanaRecordAvg,
                  attempts: entry.kanaRecordCount,
                ),
                _ScoreRow(
                  label: s.scorePartDokkai,
                  avg: entry.dokkaiRecordAvg,
                  attempts: entry.dokkaiRecordCount,
                ),
                _ScoreRow(
                  label: s.scorePartChoukai,
                  avg: entry.choukaiRecordAvg,
                  attempts: entry.choukaiRecordCount,
                ),
                _ScoreRow(
                  label: s.scorePartKanjiCombo,
                  avg: entry.kanjiComboRecordAvg,
                  attempts: entry.kanjiComboRecordCount,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: s.curriculumProgressTitle,
            // The total comes from the bundled dataset rather than
            // Firestore, so it always reflects the curriculum this build
            // actually ships — a published count can't go stale against it.
            child: allBabAsync.when(
              data: (all) => BabProgressBody(
                completedCount: entry.babCompletedCount,
                highestOrder: entry.babHighestOrder,
                totalChapters: all.length,
                furthestTitle: _titleForOrder(ref, all, entry.babHighestOrder),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text(s.failedToLoadLevels(e)),
            ),
          ),
        ],
      ),
    );
  }

  String? _titleForOrder(WidgetRef ref, List<BabEntry> all, int order) {
    if (order <= 0) return null;
    final s = ref.read(appStringsProvider);
    for (final bab in all) {
      if (bab.order == order) return bab.localizedTitle(s.language);
    }
    return null;
  }
}

/// Curriculum-progress body: count, progress bar, and the furthest chapter
/// reached. Shared by [PublicProfileScreen] and the learner's own
/// `ProfileScreen` so both render progress identically.
class BabProgressBody extends ConsumerWidget {
  final int completedCount;
  final int highestOrder;
  final int totalChapters;
  final String? furthestTitle;

  /// Per-level breakdown, shown only on the learner's own profile.
  ///
  /// A public profile deliberately cannot supply this: `leaderboard/{uid}`
  /// publishes two aggregate counters and nothing else, because the
  /// per-chapter list lives in `users/{uid}/babProgress`, which
  /// `firestore.rules` keeps readable only by its owner (see this file's
  /// header). So this stays null there rather than being faked from the
  /// aggregate — a level breakdown guessed from a total would be wrong the
  /// moment a learner skipped nothing but sat mid-level.
  final List<BabLevelProgress>? levels;

  const BabProgressBody({
    super.key,
    required this.completedCount,
    required this.highestOrder,
    required this.totalChapters,
    required this.furthestTitle,
    this.levels,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);

    if (completedCount == 0) {
      return Text(
        s.babNotStartedYet,
        style: TextStyle(color: context.palette.textNavy.withValues(alpha: 0.7)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.babProgressOf(completedCount, totalChapters),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: context.palette.textNavy,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: totalChapters == 0 ? 0 : completedCount / totalChapters,
            minHeight: 8,
            backgroundColor: context.palette.primaryCoral.withValues(alpha: 0.15),
            color: context.palette.primaryCoral,
          ),
        ),
        if (furthestTitle != null) ...[
          const SizedBox(height: 8),
          Text(
            s.babFurthestChapter('$highestOrder. $furthestTitle'),
            style: TextStyle(
              fontSize: 12,
              color: context.palette.textNavy.withValues(alpha: 0.7),
            ),
          ),
        ],
        if (levels != null) ...[
          const SizedBox(height: 16),
          for (final level in levels!) ...[
            _LevelProgressRow(standing: level),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

/// One JLPT level's line in the profile breakdown: its key, how far
/// through it the learner is, and whether they have reached it at all.
class _LevelProgressRow extends ConsumerWidget {
  final BabLevelProgress standing;

  const _LevelProgressRow({required this.standing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reached = standing.reachedByProgress;
    final complete = standing.isComplete;

    final accent = complete
        ? context.palette.successGreen
        : reached
            ? context.palette.primaryCoral
            : context.palette.freeBadgeGrey;

    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            standing.level.key,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              // A locked level reads as an empty bar, not as its real
              // (always zero) progress dressed up in the active colour.
              value: reached ? standing.fraction : 0,
              minHeight: 6,
              backgroundColor: accent.withValues(alpha: 0.15),
              color: accent,
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (!reached)
          Icon(Icons.lock, size: 13, color: context.palette.freeBadgeGrey)
        else
          Text(
            '${standing.completed}/${standing.total}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: complete ? FontWeight.bold : FontWeight.normal,
              color: complete
                  ? context.palette.successGreen
                  : context.palette.textNavy.withValues(alpha: 0.7),
            ),
          ),
        if (complete) ...[
          const SizedBox(width: 4),
          Icon(Icons.check_circle,
              size: 13, color: context.palette.successGreen),
        ],
      ],
    );
  }

}

class _IdentityCard extends ConsumerWidget {
  final LeaderboardEntry entry;

  const _IdentityCard({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.palette.primaryCoral.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.palette.primaryCoral.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          LeaderboardAvatar(entry: entry, size: 72),
          const SizedBox(height: 12),
          Text(
            entry.displayName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.palette.textNavy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            globalScoreLabel(entry, s),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: context.palette.primaryCoral,
            ),
          ),
          Text(
            s.tabGlobalScore,
            style: TextStyle(
              fontSize: 12,
              color: context.palette.textNavy.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

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
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: context.palette.textNavy,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ScoreRow extends ConsumerWidget {
  final String label;
  final double avg;
  final int attempts;

  const _ScoreRow({
    required this.label,
    required this.avg,
    required this.attempts,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: context.palette.textNavy),
            ),
          ),
          Text(
            // Same "average% (N attempts)" shape the per-category Rekor
            // tabs used before the leaderboard collapsed to one score —
            // the detail moved here rather than being lost.
            attempts == 0
                ? s.noRecordYet
                : '${avg.toStringAsFixed(1)}% ($attempts×)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: attempts == 0
                  ? context.palette.textNavy.withValues(alpha: 0.4)
                  : context.palette.textNavy,
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens [PublicProfileScreen] for [entry] — the one place both the global
/// tab and the clan ranking route through, so the two stay in step.
void openPublicProfile(BuildContext context, LeaderboardEntry entry) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => PublicProfileScreen(entry: entry)),
  );
}

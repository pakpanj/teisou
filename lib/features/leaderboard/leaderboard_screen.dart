import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/avatars.dart';
import '../../core/localization/app_strings.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_refresh_indicator.dart';
import '../../data/models/leaderboard_entry.dart';
import '../../data/models/user_profile.dart' show AvatarType;
import '../../data/repositories/leaderboard_repository.dart';
import 'leaderboard_providers.dart';
import 'widgets/clan_tab.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    return DefaultTabController(
      length: 7,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆 ', style: TextStyle(fontSize: 18)),
              Text(s.leaderboardTitle),
            ],
          ),
          bottom: TabBar(
            isScrollable: true,
            labelColor: AppColors.primaryCoral,
            unselectedLabelColor: AppColors.textNavy,
            indicatorColor: AppColors.primaryCoral,
            tabs: [
              const Tab(text: 'Kana Mastered'),
              Tab(text: s.tabExamScore),
              Tab(text: s.tabKanaRecord),
              Tab(text: s.tabDokkaiRecord),
              Tab(text: s.tabChoukaiRecord),
              Tab(text: s.tabKanjiComboRecord),
              const Tab(text: 'Clan'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _LeaderboardTab(metric: LeaderboardMetric.totalMastered),
            _LeaderboardTab(metric: LeaderboardMetric.examHighScore),
            _LeaderboardTab(metric: LeaderboardMetric.kanaRecord),
            _LeaderboardTab(metric: LeaderboardMetric.dokkaiRecord),
            _LeaderboardTab(metric: LeaderboardMetric.choukaiRecord),
            _LeaderboardTab(metric: LeaderboardMetric.kanjiComboRecord),
            ClanTab(),
          ],
        ),
      ),
    );
  }
}

/// Renders one metric's value for [entry] as a display string. The two
/// original metrics stay bare numbers (unchanged from before the "Rekor"
/// feature); the four per-category record metrics render as "XX.X% (Nx)"
/// — literally the "Poin Nilai / berapa kali ujian" formula the record is
/// built from, average and attempt count both visible in one line — or
/// "Belum ada" when the user has never attempted that category (rather
/// than a potentially-confusing "0.0% (0x)"). Public so the Clan tab's
/// ranking (which reuses the same six metrics, just scoped to clan
/// members) can render identically.
String leaderboardValueLabel(
  LeaderboardMetric metric,
  LeaderboardEntry entry,
  AppStrings strings,
) {
  switch (metric) {
    case LeaderboardMetric.totalMastered:
      return '${entry.totalMastered}';
    case LeaderboardMetric.examHighScore:
      return '${entry.examHighScore}';
    case LeaderboardMetric.kanaRecord:
      return entry.kanaRecordCount == 0
          ? strings.noRecordYet
          : '${entry.kanaRecordAvg.toStringAsFixed(1)}% (${entry.kanaRecordCount}x)';
    case LeaderboardMetric.dokkaiRecord:
      return entry.dokkaiRecordCount == 0
          ? strings.noRecordYet
          : '${entry.dokkaiRecordAvg.toStringAsFixed(1)}% (${entry.dokkaiRecordCount}x)';
    case LeaderboardMetric.choukaiRecord:
      return entry.choukaiRecordCount == 0
          ? strings.noRecordYet
          : '${entry.choukaiRecordAvg.toStringAsFixed(1)}% (${entry.choukaiRecordCount}x)';
    case LeaderboardMetric.kanjiComboRecord:
      return entry.kanjiComboRecordCount == 0
          ? strings.noRecordYet
          : '${entry.kanjiComboRecordAvg.toStringAsFixed(1)}% (${entry.kanjiComboRecordCount}x)';
  }
}

class _LeaderboardTab extends ConsumerWidget {
  final LeaderboardMetric metric;

  const _LeaderboardTab({required this.metric});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topAsync = ref.watch(leaderboardTopProvider(metric));
    final selfEntryAsync = ref.watch(selfLeaderboardEntryProvider(metric));
    final selfRankAsync = ref.watch(selfRankProvider(metric));
    final s = ref.watch(appStringsProvider);

    return Column(
      children: [
        _SelfHeader(
          entry: selfEntryAsync.valueOrNull,
          rank: selfRankAsync.valueOrNull,
          metric: metric,
          strings: s,
        ),
        Expanded(
          child: AppRefreshIndicator(
            onRefresh: () async {
              ref.invalidate(leaderboardTopProvider(metric));
              await Future.wait([
                ref.refresh(selfLeaderboardEntryProvider(metric).future),
                ref.refresh(selfRankProvider(metric).future),
              ]);
            },
            child: topAsync.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 120),
                        child: Center(
                          child: Text(
                            s.noRankingData,
                            style: const TextStyle(color: AppColors.textNavy),
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => LeaderboardTile(
                    rank: index + 1,
                    entry: entries[index],
                    valueLabel: leaderboardValueLabel(metric, entries[index], s),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text(s.failedToLoadLeaderboard(e))),
            ),
          ),
        ),
      ],
    );
  }
}

class _SelfHeader extends StatelessWidget {
  final LeaderboardEntry? entry;
  final int? rank;
  final LeaderboardMetric metric;
  final AppStrings strings;

  const _SelfHeader({
    required this.entry,
    required this.rank,
    required this.metric,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    if (entry == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryCoral.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryCoral.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Text(
            rank != null ? strings.rankOf(rank!) : strings.notRankedYet,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryCoral,
            ),
          ),
          const SizedBox(width: 8),
          const Text('•', style: TextStyle(color: AppColors.textNavy)),
          const SizedBox(width: 8),
          LeaderboardAvatar(entry: entry!, size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry!.displayName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textNavy),
            ),
          ),
          Text(
            leaderboardValueLabel(metric, entry!, strings),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textNavy,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single ranked row — reused by both the global leaderboard tabs and
/// the Clan tab's scoped ranking (`ClanTab`), which is why this and
/// [LeaderboardAvatar] are public rather than private to this file.
class LeaderboardTile extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;
  final String valueLabel;
  final bool isHost;

  const LeaderboardTile({
    super.key,
    required this.rank,
    required this.entry,
    required this.valueLabel,
    this.isHost = false,
  });

  String get _rankBadge {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '$rank';
    }
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              _rankBadge,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textNavy,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
          LeaderboardAvatar(entry: entry, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isHost)
                      const Text('👑 ', style: TextStyle(fontSize: 13)),
                    Flexible(
                      child: Text(
                        entry.displayName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textNavy,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatDate(entry.updatedAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textNavy.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Text(
            valueLabel,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryCoral,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders a leaderboard/clan row's avatar. Presets are looked up locally
/// (not via `UserAvatar`, which needs a live Firebase `User`) since
/// leaderboard/clan-member entries only carry the resolved
/// avatarType/avatarValue/photoUrl.
class LeaderboardAvatar extends StatelessWidget {
  final LeaderboardEntry entry;
  final double size;

  const LeaderboardAvatar({super.key, required this.entry, required this.size});

  @override
  Widget build(BuildContext context) {
    if (entry.avatarType == AvatarType.presetFree ||
        entry.avatarType == AvatarType.presetPremium) {
      final preset = AvatarPresets.byId(entry.avatarValue);
      if (preset != null) {
        return CircleAvatar(
          radius: size / 2,
          backgroundColor: preset.background,
          child: AvatarPresetArt(
            preset: preset,
            imageSize: size * 0.7,
            emojiFontSize: size * 0.4,
          ),
        );
      }
    }

    final photoUrl = entry.photoUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(photoUrl),
      );
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.hiraganaCardBg,
      child: Text('🐱', style: TextStyle(fontSize: size * 0.5)),
    );
  }
}

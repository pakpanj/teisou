import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/avatars.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/leaderboard_entry.dart';
import '../../data/models/user_profile.dart' show AvatarType;
import '../../data/repositories/leaderboard_repository.dart';
import 'leaderboard_providers.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🏆 ', style: TextStyle(fontSize: 18)),
              Text('Papan Peringkat'),
            ],
          ),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: AppColors.primaryCoral,
            unselectedLabelColor: AppColors.textNavy,
            indicatorColor: AppColors.primaryCoral,
            tabs: [
              Tab(text: 'Kana Mastered'),
              Tab(text: 'Skor Ujian'),
              Tab(text: 'Rekor Kana'),
              Tab(text: 'Rekor Dokkai'),
              Tab(text: 'Rekor Choukai'),
              Tab(text: 'Rekor Kanji-Kombinasi'),
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
          ],
        ),
      ),
    );
  }
}

/// Renders one metric's value for [entry] as a display string. The two
/// original metrics stay bare numbers (unchanged from before this "Rekor"
/// feature); the four new per-category record metrics render as
/// "XX.X% (Nx)" — literally the "Poin Nilai / berapa kali ujian" formula
/// the record is built from, average and attempt count both visible in one
/// line — or "Belum ada" when the user has never attempted that category
/// (rather than a potentially-confusing "0.0% (0x)").
String _valueLabel(LeaderboardMetric metric, LeaderboardEntry entry) {
  switch (metric) {
    case LeaderboardMetric.totalMastered:
      return '${entry.totalMastered}';
    case LeaderboardMetric.examHighScore:
      return '${entry.examHighScore}';
    case LeaderboardMetric.kanaRecord:
      return entry.kanaRecordCount == 0
          ? 'Belum ada'
          : '${entry.kanaRecordAvg.toStringAsFixed(1)}% (${entry.kanaRecordCount}x)';
    case LeaderboardMetric.dokkaiRecord:
      return entry.dokkaiRecordCount == 0
          ? 'Belum ada'
          : '${entry.dokkaiRecordAvg.toStringAsFixed(1)}% (${entry.dokkaiRecordCount}x)';
    case LeaderboardMetric.choukaiRecord:
      return entry.choukaiRecordCount == 0
          ? 'Belum ada'
          : '${entry.choukaiRecordAvg.toStringAsFixed(1)}% (${entry.choukaiRecordCount}x)';
    case LeaderboardMetric.kanjiComboRecord:
      return entry.kanjiComboRecordCount == 0
          ? 'Belum ada'
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

    return Column(
      children: [
        _SelfHeader(
          entry: selfEntryAsync.valueOrNull,
          rank: selfRankAsync.valueOrNull,
          metric: metric,
        ),
        Expanded(
          child: topAsync.when(
            data: (entries) {
              if (entries.isEmpty) {
                return const Center(
                  child: Text(
                    'Belum ada data peringkat.',
                    style: TextStyle(color: AppColors.textNavy),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: entries.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _LeaderboardTile(
                  rank: index + 1,
                  entry: entries[index],
                  valueLabel: _valueLabel(metric, entries[index]),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Center(child: Text('Gagal memuat papan peringkat: $e')),
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

  const _SelfHeader({required this.entry, required this.rank, required this.metric});

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
        border: Border.all(color: AppColors.primaryCoral.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(
            rank != null ? 'Peringkat ke-$rank' : 'Belum berperingkat',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryCoral,
            ),
          ),
          const SizedBox(width: 8),
          const Text('•', style: TextStyle(color: AppColors.textNavy)),
          const SizedBox(width: 8),
          _Avatar(entry: entry!, size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry!.displayName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textNavy),
            ),
          ),
          Text(
            _valueLabel(metric, entry!),
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

class _LeaderboardTile extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;
  final String valueLabel;

  const _LeaderboardTile({
    required this.rank,
    required this.entry,
    required this.valueLabel,
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
          _Avatar(entry: entry, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textNavy,
                  ),
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

/// Renders a leaderboard row's avatar. Presets are looked up locally (not
/// via [UserAvatar], which needs a live Firebase [User]) since leaderboard
/// entries only carry the resolved avatarType/avatarValue/photoUrl.
class _Avatar extends StatelessWidget {
  final LeaderboardEntry entry;
  final double size;

  const _Avatar({required this.entry, required this.size});

  @override
  Widget build(BuildContext context) {
    if (entry.avatarType == AvatarType.presetFree ||
        entry.avatarType == AvatarType.presetPremium) {
      final preset = AvatarPresets.byId(entry.avatarValue);
      if (preset != null) {
        return CircleAvatar(
          radius: size / 2,
          backgroundColor: preset.background,
          child: Text(preset.emoji, style: TextStyle(fontSize: size * 0.4)),
        );
      }
    }

    final photoUrl = entry.photoUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(radius: size / 2, backgroundImage: NetworkImage(photoUrl));
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.hiraganaCardBg,
      child: Text('🐱', style: TextStyle(fontSize: size * 0.5)),
    );
  }
}

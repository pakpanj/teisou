import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/leaderboard_entry.dart';
import '../../data/repositories/leaderboard_repository.dart';

final leaderboardTopProvider =
    StreamProvider.family<List<LeaderboardEntry>, LeaderboardMetric>((
      ref,
      metric,
    ) {
      return ref.watch(leaderboardRepositoryProvider).watchTop(metric);
    });

final selfLeaderboardEntryProvider =
    FutureProvider.family<LeaderboardEntry?, LeaderboardMetric>((
      ref,
      metric,
    ) async {
      final user = await ref.watch(appStartupProvider.future);
      return ref.watch(leaderboardRepositoryProvider).getSelf(user.uid);
    });

final selfRankProvider = FutureProvider.family<int?, LeaderboardMetric>((
  ref,
  metric,
) async {
  final user = await ref.watch(appStartupProvider.future);
  return ref.watch(leaderboardRepositoryProvider).getRank(user.uid, metric);
});

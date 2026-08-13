import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/battle_invite.dart';

/// Live — one user's own pending "Tantang" challenges, small enough to
/// keep streaming so the invites strip updates the instant one arrives,
/// is answered, or (via [BattleInvite.isExpired]'s client-side filter in
/// `BattleInviteRepository.watchMyInvites`) ages out past its 2-minute
/// window.
final myPendingBattleInvitesProvider =
    StreamProvider<List<BattleInvite>>((ref) async* {
  final user = await ref.watch(appStartupProvider.future);
  yield* ref.watch(battleInviteRepositoryProvider).watchMyInvites(user.uid);
});

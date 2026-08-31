import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/user_profile.dart';

/// Pushes a learner's name and avatar to every denormalized copy of it.
///
/// A learner's identity is stored in **four** places: `users/{uid}` (the
/// source of truth), `leaderboard/{uid}`, every clan roster row, and every
/// friend's own copy of them. The last three are denormalized on purpose —
/// a ranking or a chat list would otherwise need one extra read per row —
/// and denormalized data is only correct if something resyncs it.
///
/// **This exists because nothing did, consistently.** Each of the three
/// places a name or avatar can change synced a different subset: the edit
/// dialog and the avatar picker updated the leaderboard and clans but never
/// friends, and linking a Google account — the one moment a real name and
/// photo first exist, replacing the anonymous "Pelajar Kana" — updated only
/// the leaderboard. `syncFriendInfo` was written, documented as mirroring
/// its clan sibling, and then called from nowhere at all, so renaming
/// yourself left every friend's chat list showing the old name for ever.
///
/// Each copy is synced independently and best-effort. That is two decisions:
/// a mirror failing must never undo the change to the source of truth that
/// already succeeded, and one mirror failing must not skip the others — a
/// single try around all three would let a clan hiccup silently cost the
/// friend sync as well.
///
/// **Takes a [ProviderContainer], not a [WidgetRef], on purpose.** This is
/// three sequential awaits, real time for the screen that triggered the
/// sync (a dialog, a bottom sheet, the profile's own Google-link button) to
/// have been popped or navigated away from before it finishes — every
/// caller used to pass its own `WidgetRef`, and a `WidgetRef` throws "Cannot
/// use ref after the widget was disposed" the moment any of these three
/// `ref.read()` calls runs after that widget is gone. Reproduced live
/// (Moto G52J, 2026-08-31) via the Google-link path specifically: linking,
/// then switching tabs before the sync finished. A [ProviderContainer] has
/// no such lifetime — callers resolve one via `rootNavigatorKey` (see that
/// key's own doc comment for the identical reasoning, already established
/// for FCM navigation) instead of their own widget's `ref`.
Future<void> syncIdentityEverywhere(
  ProviderContainer container, {
  required String uid,
  required String displayName,
  String? photoUrl,
  required AvatarType avatarType,
  String? avatarValue,
}) async {
  Future<void> attempt(Future<void> Function() sync) async {
    try {
      await sync();
    } catch (_) {
      // Best-effort by design — see the doc comment above.
    }
  }

  await attempt(
    () => container.read(leaderboardRepositoryProvider).syncProfileInfo(
          uid: uid,
          displayName: displayName,
          photoUrl: photoUrl,
          avatarType: avatarType,
          avatarValue: avatarValue,
        ),
  );
  await attempt(
    () => container.read(clanRepositoryProvider).syncMemberInfo(
          uid: uid,
          displayName: displayName,
          photoUrl: photoUrl,
          avatarType: avatarType,
          avatarValue: avatarValue,
        ),
  );
  await attempt(
    () => container.read(friendRepositoryProvider).syncFriendInfo(
          uid: uid,
          displayName: displayName,
          photoUrl: photoUrl,
          avatarType: avatarType,
          avatarValue: avatarValue,
        ),
  );
}

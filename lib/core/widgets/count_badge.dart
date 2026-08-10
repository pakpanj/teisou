import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// Small pill-shaped count badge pinned to the top-right corner of [child].
///
/// Friend requests and clan invites still don't push a notification of
/// their own (only chat/clan messages and the generic `users/{uid}/
/// notifications` feed do, via `functions/index.js` + `FcmService`) — a
/// request or invite arriving is otherwise only visible once someone
/// happens to open the Leaderboard's "Teman"/"Clan" tab and see the
/// pending-requests strip there. This badge is the honest substitute: a
/// visible count wherever the path to that tab starts (bottom-nav Profil
/// icon, Profile's leaderboard trophy button, the tab itself), so the
/// signal reaches the learner the moment they're anywhere in the app
/// rather than staying invisible until they happen to go looking. The same
/// widget is reused for the unread count on Profile's "Notifikasi" tile,
/// which now *does* have a real push behind it.
///
/// Renders nothing extra when [count] is 0 — [child] alone, unchanged.
class CountBadge extends StatelessWidget {
  final Widget child;
  final int count;

  const CountBadge({super.key, required this.child, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -4,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            decoration: BoxDecoration(
              color: context.palette.errorRed,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              count > 9 ? '9+' : '$count',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

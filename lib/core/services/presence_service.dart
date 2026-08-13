import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/presence_status.dart';

/// Real-time "is this user online right now" — Card Game Mode's friend/
/// clan "Tantang" button needs this to be genuinely live, not "last active
/// at ...", which Firestore has no way to guarantee once a connection
/// drops uncleanly (app force-killed, battery dies, signal lost — see
/// `NOTES_CARD_GAME_MODE.md`'s "Kenapa status online butuh infrastruktur
/// baru, bukan sekadar field"). Realtime Database's `onDisconnect()` is
/// the one thing that can promise that: it fires **server-side** the
/// moment the socket itself drops, not only when the app gets a chance to
/// run its own cleanup code — Firestore has no equivalent.
///
/// **Needs a Realtime Database instance actually provisioned for this
/// Firebase project before any of this does anything live.** This
/// project doesn't have one yet — `firebase_options.dart` carries no
/// `databaseURL`, and creating the instance is a one-time Firebase
/// Console action (plus deploying `database.rules.json`, which is a
/// separate file from `firestore.rules` and isn't live just because it's
/// correct in the repo — same caveat this codebase already carries for
/// `firestore.rules` changes). Deliberately not worked around by
/// fabricating a URL here: same reasoning as this codebase's iOS Firebase
/// gap — a made-up value would turn a clear "not configured yet" state
/// into a confusing runtime failure instead. Until that console step
/// happens, [goOnline] fails silently (caught, logged, never crashes
/// startup) — the code is correct and safe to ship ahead of it.
class PresenceService {
  bool _initialized = false;

  /// Writes this device online and registers the server-side write that
  /// takes over the instant the connection drops. Call once per app
  /// session, from startup — same "best-effort, never blocks the rest of
  /// startup" shape as `FcmService.init`.
  Future<void> goOnline(String uid) async {
    if (_initialized) return;
    _initialized = true;
    try {
      final ref = FirebaseDatabase.instance.ref('presence/$uid');
      // Registered before the online write so a disconnect happening in
      // the gap between the two still leaves the right value behind —
      // the ordering the other way round has no such guarantee.
      await ref.onDisconnect().set({
        'state': 'offline',
        'lastChanged': ServerValue.timestamp,
      });
      await ref.set({'state': 'online', 'lastChanged': ServerValue.timestamp});
    } catch (e) {
      debugPrint('PresenceService.goOnline failed: $e');
    }
  }

  /// Live status for [uid] — any user, not just the signed-in one. Not
  /// called from anywhere yet; exists so a future friend/clan list badge
  /// (see `NOTES_CARD_GAME_MODE.md`'s "efek sampingnya bagus") has
  /// something ready to watch once it's built.
  Stream<PresenceStatus> watchPresence(String uid) {
    return FirebaseDatabase.instance
        .ref('presence/$uid')
        .onValue
        .map((event) => PresenceStatus.fromSnapshotValue(event.snapshot.value));
  }
}

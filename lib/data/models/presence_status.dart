/// Parsed form of a `presence/{uid}` node from Realtime Database — see
/// `PresenceService` and `NOTES_CARD_GAME_MODE.md`'s "Kenapa status
/// online butuh infrastruktur baru" section for why this lives in RTDB
/// and not as a plain Firestore field.
class PresenceStatus {
  final bool isOnline;
  final DateTime? lastChanged;

  PresenceStatus({required this.isOnline, this.lastChanged});

  /// The default for a user who has never had a `presence/{uid}` node
  /// written at all — indistinguishable from "genuinely offline" on
  /// purpose, since both mean the same thing to a caller deciding
  /// whether to enable a "Tantang" button.
  factory PresenceStatus.offline() => PresenceStatus(isOnline: false);

  /// [value] is whatever `DataSnapshot.value` hands back for
  /// `presence/{uid}` — `null` if the node doesn't exist, otherwise a
  /// raw `Map` (not necessarily `Map<String, dynamic>` — the Realtime
  /// Database plugin hands back a loosely-typed map that needs an
  /// explicit re-cast).
  factory PresenceStatus.fromSnapshotValue(Object? value) {
    if (value == null) return PresenceStatus.offline();
    final map = Map<String, dynamic>.from(value as Map);
    final rawLastChanged = map['lastChanged'];
    return PresenceStatus(
      isOnline: map['state'] == 'online',
      lastChanged: rawLastChanged is int
          ? DateTime.fromMillisecondsSinceEpoch(rawLastChanged)
          : null,
    );
  }
}

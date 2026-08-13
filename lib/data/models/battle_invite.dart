import 'package:cloud_firestore/cloud_firestore.dart';

import 'card_game_rank.dart';
import 'user_profile.dart' show AvatarType, AvatarTypeX;

enum BattleInviteStatus { pending, accepted, declined }

extension BattleInviteStatusX on BattleInviteStatus {
  String get key {
    switch (this) {
      case BattleInviteStatus.pending:
        return 'pending';
      case BattleInviteStatus.accepted:
        return 'accepted';
      case BattleInviteStatus.declined:
        return 'declined';
    }
  }

  static BattleInviteStatus fromKey(String? key) {
    switch (key) {
      case 'accepted':
        return BattleInviteStatus.accepted;
      case 'declined':
        return BattleInviteStatus.declined;
      default:
        return BattleInviteStatus.pending;
    }
  }
}

/// Where a [BattleInvite] came from — cosmetic (which list it was sent
/// from) rather than something any rule/logic branches on; kept as a
/// plain field mostly so a future "kamu ditantang oleh Budi (teman)"
/// vs "...(clan)" label doesn't need to guess.
enum BattleInviteSource { friend, clan }

extension BattleInviteSourceX on BattleInviteSource {
  String get key => this == BattleInviteSource.clan ? 'clan' : 'friend';

  static BattleInviteSource fromKey(String? key) =>
      key == 'clan' ? BattleInviteSource.clan : BattleInviteSource.friend;
}

/// A pending "Tantang" challenge at `users/{targetUid}/battleInvites/{id}`
/// — mirrors `ClanInvite`/`FriendRequest`'s shape exactly, per
/// `NOTES_CARD_GAME_MODE.md`'s "Cara mengundang teman/clan bertanding" ->
/// "Bentuk data undangan".
///
/// **Unlike `ClanInvite`/`FriendRequest`, the match this invite points at
/// already exists by the time this document is written** — see
/// [matchId]'s own doc comment for why. This is a deliberate departure
/// from the notes' literal wording ("menerima memicu pertandingan
/// mulai") in favor of reusing Tahap 2's already-built and already
/// on-device-verified join-by-id and timeout-forfeit machinery wholesale,
/// rather than inventing a second "how does the challenger learn the
/// match id once the target accepts" notification path.
class BattleInvite {
  final String id;
  final String fromUid;
  final String fromName;
  final String? fromPhotoUrl;
  final AvatarType fromAvatarType;
  final String? fromAvatarValue;
  final BattleInviteSource source;

  /// The deck content the challenger picked before sending — shown to
  /// the invited player so they "see the cards before accepting" (the
  /// notes' own requirement), even though the literal 20 cards aren't
  /// individually previewable without opening the match.
  final CardTierContent cardTierContent;

  /// The `battleMatches/{matchId}` this invite is a pointer to. Created
  /// by the challenger *before* this invite document is written (both
  /// decks already built, both uids already in `players`), so accepting
  /// is just `BattleScreen(matchId: matchId)` — the same "join an
  /// existing match" flow `BattleTestStartScreen` already has, reusing
  /// its Cloud Function scoring and its timeout-forfeit handling with
  /// zero new match-lifecycle code. A target who never responds (or
  /// declines) simply never joins; the match they were invited to
  /// degrades exactly the way an opponent who force-closes the app
  /// already does (see "Kalau lawan menutup aplikasi di tengah
  /// pertandingan") — the waiting challenger's own client eventually
  /// times out each of the no-show's rounds, same mechanism, no special
  /// case needed for "invite ignored" vs. "opponent went silent
  /// mid-match".
  final String matchId;

  final BattleInviteStatus status;
  final DateTime createdAt;

  /// Created + 2 minutes, per "Kenapa 2 menit" — enforced client-side by
  /// filtering `expiresAt < now` wherever pending invites are listed
  /// (`BattleInviteRepository.watchMyInvites`), the same self-heal-on-
  /// read pattern already used elsewhere in this app (e.g.
  /// `backfillGlobalScore`) rather than a scheduled Cloud Function.
  final DateTime expiresAt;

  BattleInvite({
    required this.id,
    required this.fromUid,
    required this.fromName,
    this.fromPhotoUrl,
    this.fromAvatarType = AvatarType.google,
    this.fromAvatarValue,
    required this.source,
    required this.cardTierContent,
    required this.matchId,
    this.status = BattleInviteStatus.pending,
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory BattleInvite.fromMap(String id, Map<String, dynamic> map) {
    return BattleInvite(
      id: id,
      fromUid: map['fromUid'] as String? ?? '',
      fromName: map['fromName'] as String? ?? 'Pelajar Kana',
      fromPhotoUrl: map['fromPhotoUrl'] as String?,
      fromAvatarType: AvatarTypeX.fromKey(map['fromAvatarType'] as String?),
      fromAvatarValue: map['fromAvatarValue'] as String?,
      source: BattleInviteSourceX.fromKey(map['source'] as String?),
      cardTierContent: CardTierContentX.fromKey(
        map['cardTierContent'] as String?,
      ),
      matchId: map['matchId'] as String? ?? '',
      status: BattleInviteStatusX.fromKey(map['status'] as String?),
      createdAt: _toDateTime(map['createdAt']) ?? DateTime.now(),
      expiresAt: _toDateTime(map['expiresAt']) ??
          DateTime.now().add(const Duration(minutes: 2)),
    );
  }

  Map<String, dynamic> toMap() => {
        'fromUid': fromUid,
        'fromName': fromName,
        'fromPhotoUrl': fromPhotoUrl,
        'fromAvatarType': fromAvatarType.key,
        'fromAvatarValue': fromAvatarValue,
        'source': source.key,
        'cardTierContent': cardTierContent.key,
        'matchId': matchId,
        'status': status.key,
        'createdAt': Timestamp.fromDate(createdAt),
        'expiresAt': Timestamp.fromDate(expiresAt),
      };

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

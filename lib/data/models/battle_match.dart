import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/battle_rules.dart';
import 'card_game_rank.dart';
import 'turn_order_entry.dart';

enum BattleMatchStatus { active, finished }

extension BattleMatchStatusX on BattleMatchStatus {
  String get key => this == BattleMatchStatus.finished ? 'finished' : 'active';

  static BattleMatchStatus fromKey(String? key) =>
      key == 'finished' ? BattleMatchStatus.finished : BattleMatchStatus.active;
}

/// Whether a match is still waiting on an invited player to say yes.
///
/// **Only friend/clan challenges ever leave [none].** A public match is
/// made by `functions/battle_matchmaking.js` once both sides are already
/// queued, and a bot match has nobody to ask — both are live the moment
/// they exist, and read back as [none] because the field is simply
/// absent from their documents. That absence is also what makes this
/// safe to add to a schema that already holds matches: every existing
/// document parses as [none], meaning "already started", which is
/// exactly what those matches are.
enum BattleInviteState { none, pending, accepted, declined }

extension BattleInviteStateX on BattleInviteState {
  String get key => name;

  static BattleInviteState fromKey(String? key) => switch (key) {
    'pending' => BattleInviteState.pending,
    'accepted' => BattleInviteState.accepted,
    'declined' => BattleInviteState.declined,
    _ => BattleInviteState.none,
  };
}

/// A live (or just-finished) Card Game Mode match — `battleMatches/{id}`.
/// See `NOTES_CARD_GAME_MODE.md`'s "Bentuk data" for the full schema
/// this mirrors.
///
/// **`officialScore`, `result`, and `scoredRounds` are Cloud-Function-
/// only fields.** Nothing in this app's own code ever writes them —
/// `firestore.rules` enforces that a client write can never change any
/// of them; only `functions/battle_scoring.js` (Tahap 2 butir 7) does,
/// running with Admin SDK privileges that bypass those rules entirely.
/// They're modeled here (read-only from the client's point of view) so
/// a future match/result screen has something to watch, same
/// "infrastructure ready ahead of the screen that needs it" shape as
/// `presenceProvider`.
class BattleMatch {
  final String id;

  /// Always exactly 2 uids.
  final List<String> players;

  final BattleMatchStatus status;

  /// 0-based index into [turnOrder] — which card is currently up.
  final int currentRound;

  /// Length 20, built once at creation — see [buildTurnOrder] in
  /// `battle_turn_order_builder.dart`.
  final List<TurnOrderEntry> turnOrder;

  /// Server timestamp anchoring the current round's countdown — reset
  /// every time a round advances.
  final DateTime? turnStartedAt;

  /// Computed locally on whichever device notices the match conclude,
  /// purely so that device's "match over" screen can show instantly
  /// instead of waiting for the Cloud Function. Never used for anything
  /// that moves stars — see [result].
  final String? clientResult;

  /// `{uid: score}` — the authoritative score, written only by the
  /// Cloud Function after independently re-validating each answer.
  final Map<String, int> officialScore;

  /// Winner's uid, `'draw'`, or `null` while the match is still running
  /// — written only by the Cloud Function, once every round has been
  /// processed. This, not [clientResult], is what moves stars.
  final String? result;

  /// Which rounds the Cloud Function has already scored — round number
  /// (as a string key) to `true`. Purely internal bookkeeping for
  /// `battle_scoring.js`'s own idempotency/completeness checks (see its
  /// `scoreAnswer` doc comment); nothing in the Flutter app reads this
  /// for anything.
  final Map<String, bool> scoredRounds;

  /// Which tier's content this match's cards were drawn from — set once
  /// at creation, never changes. The bot AI (`functions/battle_bot.js`)
  /// reads this directly to pick its difficulty curve, rather than
  /// re-deriving a tier from `turnOrder`'s card ids on every turn.
  final CardTierContent cardTierContent;

  /// Whether this match is eligible to move stars — see
  /// `NOTES_CARD_GAME_MODE.md`'s "Kecuali lawan teman dan clan — di sana
  /// kartunya bebas dipilih": public and bot matches are ranked (cards
  /// locked to the player's own tier); friend/clan matches, started via
  /// a `BattleInvite`, are never ranked (the challenger picks any card
  /// tier freely, which would make rank an easy shortcut otherwise
  /// ranked play would need to earn honestly). No Cloud Function reads
  /// this yet — star movement itself hasn't been built (that's later in
  /// Tahap 3) — but the field is written now, at creation, so a future
  /// star-movement pass doesn't need a schema migration or an expensive
  /// collection-group query across every `battleInvites` subcollection
  /// just to tell which already-played matches were ranked. Set once at
  /// creation, never changes — same immutable-after-creation treatment
  /// as [cardTierContent].
  final bool rankedMatch;

  /// What the star ladder did to each player when this match concluded,
  /// keyed by uid — written only by `functions/battle_stars.js`, and
  /// absent until it runs (the result screen shows "counting..." in that
  /// gap).
  ///
  /// **The delta comes from the server rather than being worked out
  /// here.** Only the Cloud Function knows the standing *before* the
  /// match, and computing it locally would mean a second copy of the
  /// ladder's arithmetic in Dart — the exact duplication
  /// `card_game_rank.dart` explains this codebase is avoiding. It lives
  /// on the match, not on the player, because it describes one match: a
  /// player who finishes a second match before opening the first one's
  /// result would otherwise be shown the wrong number.
  final Map<String, BattleStarResult> starResult;

  /// Each player's full 20-card hand, keyed by uid — written once at
  /// creation so both devices can draw the same hand, and never changed.
  ///
  /// A player *plays* a card from this hand on their own rounds; what
  /// they have left is this list minus whatever has already gone out.
  final Map<String, List<String>> decks;

  /// The card its owner actually chose for a round, keyed by round.
  ///
  /// **`turnOrder` still carries a card per round and is still fixed at
  /// creation — it is the card that goes out if its owner does not
  /// choose in time.** Choosing writes here instead of rewriting
  /// `turnOrder`, which `firestore.rules` freezes: a client that could
  /// edit the turn order could rewrite a round it had already lost.
  final Map<int, String> playedCards;

  /// When the match document was written. Absent on every match made
  /// before this field existed, which is why the result screen shows a
  /// dash rather than a wrong duration for those.
  final DateTime? createdAt;

  /// Whether an invited opponent has answered yet — see
  /// [BattleInviteState].
  ///
  /// **This lives on the match rather than on the invite**, even though
  /// the invite already has a status of its own, because the invite
  /// document sits at `users/{targetUid}/battleInvites/{id}` and that
  /// subtree is readable by its owner alone. The person who most needs
  /// to know whether the challenge was accepted is the one who sent it,
  /// and they cannot read it there. The match document is the one thing
  /// both players can already see.
  final BattleInviteState inviteState;

  /// Who last left this match, and when — the 30-second reconnect grace
  /// period's own marker (2026-08-30). `null` while nobody has left, or
  /// once the disconnected player has come back (see
  /// `BattleRepository.clearAbandoning`) or the grace period has already
  /// been resolved one way or the other (see `resolveOneAbandonment` in
  /// `functions/battle_abandonment_sweep.js`, which clears/overwrites it
  /// the moment it finalizes the match).
  ///
  /// **Client-writable, unlike `result`/`officialScore`/`scoredRounds`**
  /// — a player marks *themselves* leaving directly, no Cloud Function
  /// round trip needed for that half. `firestore.rules` restricts the
  /// three legal transitions (unchanged / self-mark-from-null /
  /// self-clear-while-still-active) so a player can never mark or clear
  /// their *opponent's* mark — see that rule's own comment.
  final BattleAbandonMarker? abandon;

  BattleMatch({
    required this.id,
    required this.players,
    required this.status,
    required this.currentRound,
    required this.turnOrder,
    this.turnStartedAt,
    this.clientResult,
    required this.officialScore,
    this.result,
    this.scoredRounds = const {},
    this.cardTierContent = CardTierContent.hiragana,
    this.rankedMatch = true,
    this.starResult = const {},
    this.decks = const {},
    this.playedCards = const {},
    this.inviteState = BattleInviteState.none,
    this.createdAt,
    this.abandon,
  });

  /// Nobody should be playing this match yet — the invited player has
  /// not answered. The round clock is not running either; it is started
  /// by the accept (see `BattleRepository.respondToMatchInvite`), so a
  /// challenge left sitting for a minute does not eat the first round.
  bool get isAwaitingAccept => inviteState == BattleInviteState.pending;

  /// A match neither finished nor awaiting an invite's accept, and not
  /// old enough that it should already have resolved one way or another
  /// — the shape `BattleRepository.findResumableMatch` looks for, and
  /// what the Card Game lobby's "Kembali ke Pertandingan" card is offered
  /// a return to.
  ///
  /// [now] is a parameter (defaulting to the real clock) rather than an
  /// implicit `DateTime.now()` purely so this stays a pure, testable
  /// function — every call site outside tests can ignore it entirely.
  ///
  /// **The age ceiling** (AUDIT_ARSITEKTUR_PRESENCE_LIFECYCLE_MODE_KARTU.md's
  /// Bagian 4 finding M3): `status`/`result` alone used to be the whole
  /// definition, with no notion of "too old to still genuinely be worth
  /// resuming" — a match `createdAt` days ago that somehow never reached
  /// `finished` (every legitimate path to that either resolves within the
  /// 30-second [kBattleAbandonGracePeriodSeconds] grace period, or, if
  /// that marker was never written at all, within the bounded worst case
  /// `functions/battle_abandonment_sweep.js`'s own per-round staleness
  /// sweep guarantees — see that file's own doc comment for the
  /// derivation) would otherwise be offered as "still in progress"
  /// forever, indistinguishable from a match genuinely still being
  /// played this minute. [kBattleResumableMaxAge] is set well past that
  /// worst case specifically so a legitimately slow-but-real match is
  /// never the one this cuts off — see that constant's own doc comment
  /// for the actual arithmetic. A match with no `createdAt` at all (every
  /// match created before that field existed) is treated as too old
  /// rather than ageless, matching the existing "no timestamp, no
  /// duration shown" precedent the result screen already has for the
  /// same field.
  bool isResumable({DateTime? now}) {
    if (status != BattleMatchStatus.active) return false;
    if (result != null) return false;
    if (isAwaitingAccept) return false;
    final since = createdAt;
    if (since == null) return false;
    final age = (now ?? DateTime.now()).difference(since);
    return age <= kBattleResumableMaxAge;
  }

  /// The card actually in play for [round]: the owner's choice if they
  /// made one, otherwise the card dealt to that round at creation.
  String? effectiveCardId(int round) {
    if (round < 0 || round >= turnOrder.length) return null;
    return playedCards[round] ?? turnOrder[round].cardId;
  }

  /// Which cards [uid] still holds — their hand minus everything of
  /// theirs already played, whether chosen or dealt by default.
  List<String> remainingHand(String uid) {
    final spent = <String>{
      for (var round = 0; round < currentRound; round++)
        if (round < turnOrder.length && turnOrder[round].deckOwnerUid == uid)
          ?effectiveCardId(round),
    };
    return [
      for (final card in decks[uid] ?? const <String>[])
        if (!spent.contains(card)) card,
    ];
  }

  /// The uid of whichever player is expected to answer
  /// `turnOrder[currentRound]` — always the player who does *not* own
  /// that round's deck.
  String? get currentAnswererUid {
    if (currentRound < 0 || currentRound >= turnOrder.length) return null;
    final deckOwner = turnOrder[currentRound].deckOwnerUid;
    return players.firstWhere(
      (uid) => uid != deckOwner,
      orElse: () => deckOwner,
    );
  }

  factory BattleMatch.fromMap(String id, Map<String, dynamic> map) {
    return BattleMatch(
      id: id,
      players: List<String>.from(map['players'] as List? ?? const []),
      status: BattleMatchStatusX.fromKey(map['status'] as String?),
      currentRound: map['currentRound'] as int? ?? 0,
      turnOrder: (map['turnOrder'] as List? ?? const [])
          .map((e) => TurnOrderEntry.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      turnStartedAt: _toDateTime(map['turnStartedAt']),
      clientResult: map['clientResult'] as String?,
      officialScore: Map<String, int>.from(
        (map['officialScore'] as Map?)?.map(
              (k, v) => MapEntry(k as String, (v as num).toInt()),
            ) ??
            const {},
      ),
      result: map['result'] as String?,
      scoredRounds: Map<String, bool>.from(
        (map['scoredRounds'] as Map?)?.map(
              (k, v) => MapEntry(k as String, v as bool),
            ) ??
            const {},
      ),
      cardTierContent: CardTierContentX.fromKey(
        map['cardTierContent'] as String?,
      ),
      rankedMatch: map['rankedMatch'] as bool? ?? true,
      decks: (map['decks'] as Map?)?.map(
            (k, v) => MapEntry(k as String, List<String>.from(v as List)),
          ) ??
          const {},
      playedCards: (map['playedCards'] as Map?)?.map(
            (k, v) => MapEntry(int.parse(k as String), v as String),
          ) ??
          const {},
      starResult: (map['starResult'] as Map?)?.map(
            (k, v) => MapEntry(
              k as String,
              BattleStarResult.fromMap(Map<String, dynamic>.from(v as Map)),
            ),
          ) ??
          const {},
      inviteState: BattleInviteStateX.fromKey(map['inviteState'] as String?),
      createdAt: _toDateTime(map['createdAt']),
      abandon: map['abandon'] is Map
          ? BattleAbandonMarker.fromMap(
              Map<String, dynamic>.from(map['abandon'] as Map),
            )
          : null,
    );
  }

  /// Only what's needed to create a fresh match — `officialScore`
  /// starts at 0 for both players, `result` starts absent, and
  /// `scoredRounds` starts empty; none of the three is ever included in
  /// a later client update. `cardTierContent`/`rankedMatch` are written
  /// once here and never touched again.
  Map<String, dynamic> toCreateMap() => {
    'players': players,
    'status': status.key,
    'currentRound': currentRound,
    'turnOrder': turnOrder.map((e) => e.toMap()).toList(),
    // Set here even for a match that is still waiting on an accept, so
    // the field always exists — the accept overwrites it, which is what
    // actually starts the clock.
    'turnStartedAt': FieldValue.serverTimestamp(),
    'inviteState': inviteState.key,
    'createdAt': FieldValue.serverTimestamp(),
    'clientResult': null,
    'officialScore': {for (final uid in players) uid: 0},
    'result': null,
    'scoredRounds': <String, bool>{},
    'cardTierContent': cardTierContent.key,
    'rankedMatch': rankedMatch,
    'decks': decks,
    'playedCards': <String, String>{},
  };
  // `starResult` is deliberately absent from the create map: it does not
  // exist until the match is over.

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

/// One player's star movement from a concluded match — see
/// [BattleMatch.starResult]. Read-only; `firestore.rules` rejects any
/// client write that changes it, because this is the only thing the
/// player is shown about their climb and a client able to write it could
/// claim any number it liked.
class BattleStarResult {
  /// Stars actually gained or lost. **Not always the nominal +1/-1**: a
  /// loss at a tier's floor, or any loss at Bronze/Silver, is 0 — the
  /// screen must not claim a star was lost when the standing did not
  /// move.
  final int delta;

  final CardGameTier tier;
  final int division;
  final int stars;
  final int winStreak;

  /// True when this match moved the player up (or down) a division —
  /// including a tier change, which is always also a division change.
  final bool divisionChanged;

  final bool tierChanged;

  /// A loss that cost nothing. Worth saying out loud: a protected player
  /// who loses and sees no change otherwise concludes it is broken.
  final bool lossAbsorbed;

  BattleStarResult({
    required this.delta,
    required this.tier,
    required this.division,
    required this.stars,
    required this.winStreak,
    required this.divisionChanged,
    required this.tierChanged,
    required this.lossAbsorbed,
  });

  factory BattleStarResult.fromMap(Map<String, dynamic> map) {
    return BattleStarResult(
      delta: (map['delta'] as num?)?.toInt() ?? 0,
      tier: CardGameTierX.fromKey(map['tier'] as String?),
      division: (map['division'] as num?)?.toInt() ?? 5,
      stars: (map['stars'] as num?)?.toInt() ?? 0,
      winStreak: (map['winStreak'] as num?)?.toInt() ?? 0,
      divisionChanged: map['divisionChanged'] as bool? ?? false,
      tierChanged: map['tierChanged'] as bool? ?? false,
      lossAbsorbed: map['lossAbsorbed'] as bool? ?? false,
    );
  }

  /// The standing this match ended at, for display.
  CardGameRank get rank => CardGameRank(
    tier: tier,
    division: division,
    stars: stars,
    season: 0,
    winStreak: winStreak,
  );
}

/// "Who left this match, and when" — see [BattleMatch.abandon]'s own
/// doc comment for the full reasoning.
class BattleAbandonMarker {
  final String uid;
  final DateTime? since;

  const BattleAbandonMarker({required this.uid, this.since});

  factory BattleAbandonMarker.fromMap(Map<String, dynamic> map) {
    return BattleAbandonMarker(
      uid: map['uid'] as String? ?? '',
      since: _abandonSince(map['since']),
    );
  }

  /// How long ago this player left, or `null` if the timestamp hasn't
  /// landed yet (a `serverTimestamp()` sentinel briefly reads back as
  /// absent from the client that just wrote it, before the server's own
  /// value round-trips back down — the same latency-compensation gap
  /// every other `serverTimestamp()` field in this app already has).
  Duration? elapsedSince(DateTime now) =>
      since == null ? null : now.difference(since!);
}

DateTime? _abandonSince(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

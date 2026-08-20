import 'package:cloud_functions/cloud_functions.dart';

import '../../data/models/card_game_rank.dart';

/// The client half of the rank-skip exam.
///
/// Deliberately thin. It draws cards and posts answers; it does not
/// decide anything. Both the answer key and the promotion live in
/// `functions/rank_skip.js`, because `firestore.rules` lets a signed-in
/// user write anything under their own `users/{uid}` — a score this app
/// computed and sent would be a score the player could have written by
/// hand.
///
/// So there is no marking here, not even for show: this file never sees
/// a correct answer, and cannot tell a player how they did until the
/// server says.
class RankSkipService {
  RankSkipService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// Draws an exam for [tier].
  ///
  /// Throws [RankSkipCooldown] while a failed attempt is still cooling
  /// down, and [RankSkipUnavailable] for everything else — a caller
  /// showing a message needs those two apart, since one of them has a
  /// time in it and the other is just "not now".
  Future<RankSkipExam> start(CardGameTier tier) async {
    try {
      final result = await _functions.httpsCallable('startRankSkipExam').call({
        'targetTier': tier.key,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      return RankSkipExam(
        sessionId: data['sessionId'] as String,
        targetTier: CardGameTierX.fromKey(data['targetTier'] as String?),
        cardIds: List<String>.from(data['cardIds'] as List),
        passMark: (data['passMark'] as num).toInt(),
      );
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'resource-exhausted') {
        throw RankSkipCooldown(_lockedUntil(e.details));
      }
      throw RankSkipUnavailable(e.code, e.message);
    }
  }

  /// Sends the answers in the order the cards were drawn.
  ///
  /// One entry per card, including the ones left blank — position is
  /// what pairs an answer with its card, so a skipped question has to
  /// take up its own place in the list rather than be left out.
  Future<RankSkipResult> submit({
    required String sessionId,
    required List<String> answers,
  }) async {
    try {
      final result = await _functions.httpsCallable('submitRankSkipExam').call({
        'sessionId': sessionId,
        'answers': answers,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      return RankSkipResult(
        passed: data['passed'] == true,
        promoted: data['promoted'] == true,
        correct: (data['correct'] as num).toInt(),
        total: (data['total'] as num).toInt(),
        passMark: (data['passMark'] as num).toInt(),
        targetTier: CardGameTierX.fromKey(data['targetTier'] as String?),
        lockedUntil: _parse(data['lockedUntil']),
      );
    } on FirebaseFunctionsException catch (e) {
      throw RankSkipUnavailable(e.code, e.message);
    }
  }

  static DateTime? _lockedUntil(Object? details) {
    if (details is Map) return _parse(details['lockedUntil']);
    return null;
  }

  static DateTime? _parse(Object? raw) =>
      raw is String ? DateTime.tryParse(raw)?.toLocal() : null;
}

/// One drawn exam: which cards, and how many must be right.
///
/// The cards are ids, not questions. The app already holds every
/// character in its assets and resolves a battle's `turnOrder` the same
/// way, so sending prompts as well would be sending something the phone
/// already has — and sending answers would be sending the exam.
class RankSkipExam {
  const RankSkipExam({
    required this.sessionId,
    required this.targetTier,
    required this.cardIds,
    required this.passMark,
  });

  final String sessionId;
  final CardGameTier targetTier;
  final List<String> cardIds;
  final int passMark;

  int get questions => cardIds.length;
}

/// What the server made of the answers.
class RankSkipResult {
  const RankSkipResult({
    required this.passed,
    required this.promoted,
    required this.correct,
    required this.total,
    required this.passMark,
    required this.targetTier,
    required this.lockedUntil,
  });

  final bool passed;

  /// Whether the rank actually moved. False on a pass only when the
  /// player was already at or above that tier — winning matches while
  /// the exam was open is enough to do it.
  final bool promoted;

  final int correct;
  final int total;
  final int passMark;
  final CardGameTier targetTier;

  /// When another attempt is allowed, set only after a failure.
  final DateTime? lockedUntil;
}

/// A failed attempt is still cooling down.
class RankSkipCooldown implements Exception {
  const RankSkipCooldown(this.lockedUntil);

  final DateTime? lockedUntil;
}

/// The exam could not be drawn or graded — offline, signed out, or a
/// tier that is not above the player's own.
///
/// Carries [code] as well as [message] because the first version
/// carried neither to the screen, and the first real failure on a device
/// showed "check your connection" for something that had nothing to do
/// with the connection. That is the same red herring
/// `_friendlyGoogleSignInError` served for a year — one catch-all string
/// standing in for every cause, with the real one thrown away. The
/// friendly line is still what a learner reads; the code is shown
/// underneath it in debug builds only.
class RankSkipUnavailable implements Exception {
  const RankSkipUnavailable(this.code, this.message);

  /// The `FirebaseFunctionsException` code — `not-found` when the
  /// callable was never deployed, `unauthenticated` when signed out,
  /// `internal` when the function itself threw.
  final String code;

  final String? message;

  @override
  String toString() => 'RankSkipUnavailable($code): $message';
}

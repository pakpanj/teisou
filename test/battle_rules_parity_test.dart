import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/constants/battle_rules.dart';

/// The Cloud Function that builds a publicly matched game against the
/// app's own rules for one.
///
/// **Two implementations, one set of rules.** `battle_matchmaking.js`
/// builds the match for a real opponent; `battle_turn_order_builder.dart`
/// builds it for a bot or a friend. Both claim to mirror each other, and
/// nothing checked — so the function shipped half-length matches (ten
/// rounds per player against the app's twenty) and no decks at all,
/// neither of which a bot match could ever show, because the app builds
/// those itself.
///
/// This reads the numbers back out of the function's source rather than
/// running it: exercising it for real needs a live Firestore, which is
/// exactly why the drift went unnoticed.
void main() {
  final source = File('functions/battle_matchmaking.js').readAsStringSync();

  int constantIn(String name) {
    final match = RegExp(
      'const $name = '
      r'(\d+);',
    ).firstMatch(source);
    expect(match, isNotNull, reason: '$name is not declared in the function');
    return int.parse(match!.group(1)!);
  }

  test('a matched game is as long as the app says a game is', () {
    expect(
      constantIn('ROUNDS_PER_PLAYER') * 2,
      kBattleTotalRounds,
      reason:
          'a match shorter than kBattleTotalRounds can never reach the '
          'round a drawn game is settled on, so a draw hangs forever',
    );
  });

  test('the main phase fits inside a matched game', () {
    expect(
      constantIn('ROUNDS_PER_PLAYER') * 2,
      greaterThanOrEqualTo(kBattleMainPhaseRounds),
    );
  });

  test('a matched game deals both players their hands', () {
    // The picker shows `remainingHand`, which is the deck minus what has
    // been played. No deck, no hand, no card a player can choose.
    expect(
      source,
      contains('decks:'),
      reason:
          'createRankedMatch writes no decks, so the card picker opens '
          'empty against a real opponent',
    );
  });
}

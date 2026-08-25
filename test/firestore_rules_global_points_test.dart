import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Formula C's anti-farming design (repeat-cycle decay, computed once
/// inside `functions/global_points.js`'s own transaction) is decorative
/// unless `firestore.rules` actually stops the client from writing
/// `globalPoints` directly, or from reaching into the internal state
/// (`globalPointsState/{uid}/repeatCycles`/`pointsAwarded`) the decay
/// math depends on. A compiler cannot see a missing security rule fail —
/// it fails quietly, in production, on someone else's phone.
void main() {
  String read(String path) => File(path).readAsStringSync();

  test('globalPointsState is unreachable from any client — mirrors '
      'rankSkipExams/{uid}\'s own seal exactly, for the same reason', () {
    final rules = read('firestore.rules');
    final block = RegExp(
      r'match /globalPointsState/\{[^}]+\}\s*\{(.*?)\n    \}',
      dotAll: true,
    ).firstMatch(rules);

    expect(block, isNotNull, reason: 'globalPointsState has no rule at all');
    final body = block!.group(1)!;
    expect(
      RegExp(r'allow read, write: if false;').hasMatch(body),
      isTrue,
      reason: 'repeat cycles / award markers are not sealed off from the client',
    );
    expect(
      RegExp(r'allow [a-z, ]+: if (?!false)').hasMatch(body),
      isFalse,
      reason: 'something is allowed on Global Points internal state — a '
          'client able to write repeatCycles could reset its own decay '
          'counter before every attempt, and one able to write '
          'pointsAwarded could fabricate/delete an idempotency marker',
    );
  });

  test('leaderboard/{uid} refuses globalPoints at document creation', () {
    final rules = read('firestore.rules');
    final block = RegExp(
      r'match /leaderboard/\{uid\}\s*\{(.*?)\n    \}',
      dotAll: true,
    ).firstMatch(rules);
    expect(block, isNotNull, reason: 'leaderboard/{uid} has no rule at all');
    final createClause = RegExp(
      r'allow create:.*?;',
      dotAll: true,
    ).firstMatch(block!.group(1)!);
    expect(createClause, isNotNull, reason: 'no allow create clause found');
    expect(
      createClause!.group(0)!.contains("!('globalPoints' in request.resource.data)"),
      isTrue,
      reason: 'a fresh leaderboard doc could be created already carrying '
          'an arbitrary globalPoints value',
    );
  });

  test('leaderboard/{uid} refuses a globalPoints change on update — the '
      'field may only ever be equal before and after a client write', () {
    final rules = read('firestore.rules');
    final block = RegExp(
      r'match /leaderboard/\{uid\}\s*\{(.*?)\n    \}',
      dotAll: true,
    ).firstMatch(rules);
    final updateClause = RegExp(
      r'allow update:.*?;',
      dotAll: true,
    ).firstMatch(block!.group(1)!);
    expect(updateClause, isNotNull, reason: 'no allow update clause found');
    final body = updateClause!.group(0)!;
    expect(
      body.contains("request.resource.data.get('globalPoints', null)") &&
          body.contains("== resource.data.get('globalPoints', null)"),
      isTrue,
      reason: 'a client write could change globalPoints to any value as '
          'long as some other field in the same document is touched too',
    );
  });

  test('every trigger the app relies on is actually exported from '
      'functions/index.js — a name that exists in global_points.js but '
      'is never wired to an export is a function that never runs', () {
    final index = read('functions/index.js');
    for (final name in [
      'onKanaExamHistoryCreated',
      'onDokkaiExamHistoryCreated',
      'onChoukaiExamHistoryCreated',
      'onKanjiComboExamHistoryCreated',
    ]) {
      expect(
        index.contains('exports.$name ='),
        isTrue,
        reason: '$name is not exported from functions/index.js',
      );
    }
  });
}

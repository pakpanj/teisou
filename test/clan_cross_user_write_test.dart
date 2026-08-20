import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `firestore.rules` gives `users/{uid}/{document=**}` to its owner alone,
/// and a Firestore batch is all-or-nothing. So a batch that touches
/// another account's document does not merely lose that one write — the
/// whole operation is refused.
///
/// That is what happened to clan moderation: `kickMember` and
/// `disbandClan` each tried to delete the *other* person's
/// `clanMemberships` row alongside the roster row they were entitled to
/// remove, so **kicking never worked at all**, and disbanding failed for
/// any clan with somebody else in it. Nothing reported an error worth
/// noticing; the member simply stayed.
void main() {
  test('no clan operation writes to another account document', () {
    final source =
        File('lib/data/repositories/clan_repository.dart').readAsStringSync();

    // `_membershipsOf(x)` is `users/{x}/clanMemberships`. Only ever legal
    // when x is the acting user, which in this repository means the host
    // acting on their own row.
    final offenders = <String>[];
    final calls = RegExp(r'_membershipsOf\((\w+)\)');
    for (final match in calls.allMatches(source)) {
      final subject = match.group(1)!;
      if (subject == 'uid' || subject == 'hostUid') continue;
      final line =
          '\n'.allMatches(source.substring(0, match.start)).length + 1;
      offenders.add('line $line: _membershipsOf($subject)');
    }

    expect(
      offenders,
      isEmpty,
      reason: 'rules refuse this and the batch dies whole, so the operation '
          'silently does nothing: ${offenders.join(", ")}',
    );
  });

  test('the leftover is cleaned up by the only account that can', () {
    final source =
        File('lib/data/repositories/clan_repository.dart').readAsStringSync();
    expect(
      source.contains('Future<void> reconcileMemberships('),
      isTrue,
      reason: 'a kicked member keeps a membership nobody can delete, and its '
          'clan chat answers every read with permission-denied for ever',
    );

    final providers = File('lib/core/providers.dart').readAsStringSync();
    expect(
      providers.contains('reconcileMemberships('),
      isTrue,
      reason: 'the repair exists but nothing ever runs it',
    );
  });
}

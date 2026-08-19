import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Sweeps for the bug *classes* this project has actually shipped, rather
/// than for the individual instances already fixed.
///
/// Every check here was written after finding a real defect by hand, and
/// each is a class that recurs because nothing about it fails loudly: the
/// app compiles, the tests pass, and the symptom only appears on someone's
/// phone, usually offline or at the worst moment.
void main() {
  Iterable<File> dartFiles(String dir) => Directory(dir)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  /// A busy flag is set, an await follows, and nothing catches. The flag
  /// gates a disabled button, so the failure is a spinner that never stops
  /// and a control that never comes back — no error, no retry.
  ///
  /// Shipped repeatedly: five progress repositories at once, the kana exam's
  /// submit, the age question (the app's front door, so there was no way in
  /// at all), the Home level-up gift, the clan dialog and both people-search
  /// boxes.
  test('a busy flag is never left set by an unguarded await', () {
    final offenders = <String>[];

    // Deliberately keyword-free. The first version of this matched a list of
    // likely flag names (busy/loading/saving/...) and walked straight past
    // `_claiming`, `_checkingEligibility` and `_searching` — four real dead
    // ends, missed by the very sweep meant to find them. A guard that only
    // looks where you already thought to look is worth very little.
    //
    // What identifies a busy flag is its shape, not its name: set true,
    // awaited across, set false again on the way out.
    final setTrue = RegExp(r'setState\(\(\)\s*(?:=>|\{)\s*(_\w+)\s*=\s*true');
    // A real `try {`, not the letters t-r-y. Searching for the bare
    // substring matched the word "trying" in a comment and blessed the
    // unguarded Home gift button — the second time a substring check has
    // hidden a defect from this file, after `await` inside `unawaited`.
    final guarded = RegExp(r'(?<!\w)try\s*\{');
    final newline = String.fromCharCode(10);

    for (final file in dartFiles('lib')) {
      final source = file.readAsStringSync();
      for (final match in setTrue.allMatches(source)) {
        final flag = match.group(1)!;
        final after = source.substring(match.end);
        final end = after.indexOf('$newline  }');
        final body = end == -1 ? after : after.substring(0, end);
        if (!body.contains('await')) continue;
        if (!body.contains('$flag = false')) continue;
        if (guarded.hasMatch(body)) continue;
        final line =
            newline.allMatches(source.substring(0, match.start)).length + 1;
        offenders.add('${file.path}:$line sets $flag');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'a failed await leaves these spinning for ever: '
          '${offenders.join(" | ")}',
    );
  });

  /// A mirror write is not the source of truth, and must never be able to
  /// fail the operation that already succeeded. Offline this matters twice
  /// over: a Firestore write's Future does not complete until it reaches
  /// the server, so awaiting one unguarded does not throw — it hangs.
  test('every denormalized mirror write is best-effort', () {
    final offenders = <String>[];
    for (final file in dartFiles('lib/data/repositories')) {
      final source = file.readAsStringSync();
      final method = RegExp(r'\n  (?:Future<[^>]*>|void)\s+(\w+)\(');
      for (final match in method.allMatches(source)) {
        final rest = source.substring(match.end);
        final next = RegExp(r'\n  (?:Future<|void |Stream<|})').firstMatch(rest);
        final body = next == null ? rest : rest.substring(0, next.start);
        // Only the local-first repositories: SharedPreferences is the
        // source of truth there and Firestore is explicitly a backup.
        if (!body.contains('SharedPreferences') &&
            !body.contains('_saveLocalList') &&
            !body.contains('prefs')) {
          continue;
        }
        // `(?<!\w)` matters: without it `await` matches inside the word
        // `unawaited`, so the correct fix reads as the defect and this
        // test failed on the very code it exists to bless.
        final mirrors = RegExp(r'(?<!\w)await\s[^;]*\.(set|delete|update)\(');
        if (mirrors.hasMatch(body) && !RegExp(r'(?<!\w)try\s*\{').hasMatch(body)) {
          offenders.add('${file.path} ${match.group(1)}');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'these await a mirror write the local copy does not need: '
          '${offenders.join(" | ")}',
    );
  });

  /// A learner's name and avatar are denormalized into three places, and
  /// every one of them is invisible from the screen that changes it — you
  /// only find out by opening a friend's chat list weeks later.
  ///
  /// `syncFriendInfo` was written, documented as mirroring its clan
  /// sibling, and called from nowhere at all; the Google-link path synced
  /// only the leaderboard. Anything that syncs one copy must sync all.
  test('identity changes reach every denormalized copy', () {
    final helper = File('lib/features/profile/identity_sync.dart');
    expect(helper.existsSync(), isTrue, reason: 'the shared sync is gone');
    final body = helper.readAsStringSync();
    for (final sync in const [
      'syncProfileInfo',
      'syncMemberInfo',
      'syncFriendInfo',
    ]) {
      // An actual call, not a mention. Checking the file for the bare name
      // passed happily with the call deleted, because the doc comment above
      // names all three; the test blessed a helper that synced two copies
      // out of three.
      expect(
        body.contains('.$sync('),
        isTrue,
        reason: '$sync is not called, so that copy goes stale on a rename',
      );
    }

    // No screen may sync one copy directly and quietly forget the others.
    final offenders = <String>[];
    for (final file in dartFiles('lib/features')) {
      if (file.path.endsWith('identity_sync.dart')) continue;
      final source = file.readAsStringSync();
      for (final sync in const [
        'syncProfileInfo',
        'syncMemberInfo',
        'syncFriendInfo',
      ]) {
        if (source.contains('.$sync(')) offenders.add('${file.path} -> $sync');
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'call syncIdentityEverywhere instead — these sync one copy '
          'and leave the rest stale: ${offenders.join(" | ")}',
    );
  });

  /// A cached read that a write never invalidates. The write lands, the
  /// screen keeps showing the old answer, and the learner concludes the
  /// feature is broken — which, from where they are standing, it is.
  ///
  /// Three times here: exam history, the avatar gallery, and the module
  /// gate. Note autoDispose alone would not have saved the last one: a
  /// kept-alive consumer never lets the provider dispose, which is exactly
  /// how the exam-history bug survived its first fix.
  test('granting an ad reward invalidates the gate that reads it', () {
    final offenders = <String>[];
    for (final file in dartFiles('lib')) {
      final source = file.readAsStringSync();
      if (!source.contains('.unlockAdReward(')) continue;
      if (!source.contains('invalidate(moduleAccessProvider')) {
        offenders.add(file.path);
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'the reward is written but the gate keeps its cached "locked" '
          'answer, so the ad buys nothing: ${offenders.join(", ")}',
    );
  });
}

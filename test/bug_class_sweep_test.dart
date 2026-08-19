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
  /// This shipped three times: five progress repositories at once, the kana
  /// exam's submit, and — worst — the age question, which is the app's front
  /// door, so a failure there left the app with no way in at all.
  test('a busy flag is never left set by an unguarded await', () {
    final offenders = <String>[];
    final flag = RegExp(
      r'setState\(\(\) =>\s*_(\w*(?:busy|loading|saving|submitting|toggling'
      r'|marking|sending|joining|creating|buying|watching)\w*)\s*=\s*true\)',
      caseSensitive: false,
    );

    for (final file in dartFiles('lib')) {
      final source = file.readAsStringSync();
      for (final match in flag.allMatches(source)) {
        final after = source.substring(match.end);
        final end = after.indexOf('\n  }');
        final body = end == -1 ? after : after.substring(0, end);
        if (body.contains('await') && !body.contains('try')) {
          final line = '\n'.allMatches(source.substring(0, match.start)).length + 1;
          offenders.add('${file.path}:$line sets _${match.group(1)}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'a failed await leaves these spinning for ever:\n'
          '${offenders.join('\n')}',
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
        final mirrors =
            RegExp(r'(?<!\w)await\s[^;]*\.(set|delete|update)\(');
        if (mirrors.hasMatch(body) && !body.contains('try')) {
          offenders.add('${file.path} ${match.group(1)}');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'these await a mirror write the local copy does not need:\n'
          '${offenders.join('\n')}',
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
      // `.$sync(` — an actual call, not a mention. Checking the file for
      // the bare name passed happily with the call deleted, because the
      // doc comment above names all three; the test blessed a helper that
      // synced two copies out of three.
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
        if (source.contains('.$sync(')) offenders.add('${file.path} → $sync');
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'call syncIdentityEverywhere instead — these sync one copy '
          'and leave the rest stale:\n${offenders.join('\n')}',
    );
  });
}

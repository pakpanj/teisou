import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The rank-skip exam's load-bearing parts are not in Dart, and that is
/// the point: the answer key and the promotion live in Cloud Functions
/// because `firestore.rules` lets a signed-in user write anything under
/// their own `users/{uid}`.
///
/// Which leaves three things nothing else can catch. A compiler cannot
/// see that a security rule went missing, that a callable this app
/// invokes was never deployed, or that grading crept back into the
/// client — and all three fail quietly, in production, on someone
/// else's phone.
void main() {
  String read(String path) => File(path).readAsStringSync();

  test('the answer key is unreachable from any client', () {
    // The collection holds, for each player, the ids of the cards they
    // were dealt *and* the tier being examined. Readable, the exam is a
    // list of answers to look up. Writable, `lockedUntil` — the day's
    // wait after a failure — is something the player can delete.
    final rules = read('firestore.rules');
    final block = RegExp(
      r'match /rankSkipExams/\{[^}]+\}\s*\{(.*?)\n    \}',
      dotAll: true,
    ).firstMatch(rules);

    expect(block, isNotNull, reason: 'rankSkipExams has no rule at all');
    final body = block!.group(1)!;
    expect(
      RegExp(r'allow read, write: if false;').hasMatch(body),
      isTrue,
      reason: 'the exam answers are not sealed off from the client',
    );
    expect(
      RegExp(r'allow [a-z, ]+: if (?!false)').hasMatch(body),
      isFalse,
      reason: 'something is allowed on the answer key',
    );
  });

  test('every callable the app invokes is actually exported', () {
    // A name typed once in Dart and once in JavaScript, never checked
    // against each other by anything. Get it wrong and the exam fails
    // at the tap, on a real device, with `NOT_FOUND` — which looks
    // exactly like being offline.
    final client = read('lib/core/services/rank_skip_service.dart');
    final index = read('functions/index.js');

    final called = RegExp(r"httpsCallable\('([^']+)'\)")
        .allMatches(client)
        .map((m) => m.group(1)!)
        .toSet();

    expect(called, isNotEmpty);
    for (final name in called) {
      expect(
        index.contains('exports.$name ='),
        isTrue,
        reason: '$name is called but never exported',
      );
    }
  });

  test('the app never marks the exam itself', () {
    // The whole design rests on this. The app holds every character in
    // its assets, so marking locally is easy to write and impossible to
    // trust — a score this app computed is a score a modified app can
    // choose. If a correctness check ever appears here, the server has
    // stopped being the authority and nobody will notice.
    for (final path in [
      'lib/core/services/rank_skip_service.dart',
      'lib/features/battle/rank_skip_screen.dart',
    ]) {
      final source = read(path);
      expect(
        source.contains('romaji_converter'),
        isFalse,
        reason: '$path can convert answers, which is half of marking them',
      );
      expect(
        source.contains('resolveCorrectRomaji'),
        isFalse,
        reason: '$path resolves correct answers',
      );
      expect(
        RegExp(r'\bcorrect\s*(\+\+|\+=)').hasMatch(source),
        isFalse,
        reason: '$path counts correct answers of its own',
      );
    }
  });

  test('the exam clock is the match clock, not a looser one', () {
    // A rank is worth roughly thirty won matches. An exam that gave more
    // time per card than the tier's own battles would be an easier test
    // than the thing it admits you to — and the number would drift the
    // moment it was written out as a literal.
    // Checked as a *use*, not a mention. The first version asked
    // whether the file contained the name at all, which the doc comment
    // above the clock satisfies on its own — swapping the real value
    // for 60 left the test perfectly happy. Confirmed by doing exactly
    // that and watching it pass.
    final screen = read('lib/features/battle/rank_skip_screen.dart');
    expect(
      screen.contains('seconds: kBattleMainPhaseSeconds'),
      isTrue,
      reason: 'the exam clock does not come from the match clock',
    );
    // Anything longer than a few seconds written as a literal is a
    // per-card limit in disguise. One-second durations are left alone:
    // that is the clock's own tick, not a rule.
    final literals = RegExp(r'Duration\(seconds: (\d+)\)')
        .allMatches(screen)
        .map((m) => int.parse(m.group(1)!))
        .where((seconds) => seconds > 5);
    expect(
      literals,
      isEmpty,
      reason: 'a hard-coded time limit crept into the exam',
    );
  });

  test('the server allows enough time for the cards it deals', () {
    // Two numbers in two languages that have to agree. The per-card
    // clock lives in Dart, the whole-exam ceiling in JavaScript, and
    // nothing connects them: raise the per-card time and the server
    // starts cutting exams off partway through, which the player sees as
    // "that exam expired" with no idea why.
    final rules = read('lib/core/constants/battle_rules.dart');
    final server = read('functions/rank_skip.js');

    int number(String source, RegExp pattern) =>
        int.parse(pattern.firstMatch(source)!.group(1)!);

    final perCard =
        number(rules, RegExp(r'kBattleMainPhaseSeconds = (\d+)'));
    final questions = number(server, RegExp(r'QUESTIONS = (\d+)'));
    final sessionMinutes =
        number(server, RegExp(r'SESSION_MINUTES = (\d+)'));

    expect(
      questions * perCard,
      lessThanOrEqualTo(sessionMinutes * 60),
      reason: 'the exam cannot be finished inside the session it is given',
    );
  });
}

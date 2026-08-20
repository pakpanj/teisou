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
}

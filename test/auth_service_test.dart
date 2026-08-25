import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The Guest → Google conflict `linkWithGoogle` used to resolve on its
/// own: a Google account already linked to a *different* Firebase user
/// used to be switched to silently, abandoning whatever the current
/// (Guest) account held — including a Premium purchase made moments
/// earlier — with nothing telling the person it happened. This is
/// exactly "Guest UID = Premium, Google UID baru = Free" from a real
/// account-linking bug, not a hypothetical.
///
/// Read as source rather than exercised against a live `FirebaseAuth`:
/// this project does not mock Firebase Auth in its test suite (the same
/// choice `test/iap_test.dart` already makes for Firestore/Play), so what
/// is pinned here is the *shape* of the fix — that the silent switch is
/// gone and a caller is handed something to decide with instead — not a
/// live account-linking round trip.
void main() {
  final authService =
      File('lib/core/services/auth_service.dart').readAsStringSync();
  final profileScreen =
      File('lib/features/profile/profile_screen.dart').readAsStringSync();

  group('the Guest to Google conflict is no longer resolved silently', () {
    test('credential-already-in-use no longer auto-signs-in to the other '
        'account — scoped to the conflict branch specifically, since '
        'linkWithGoogle legitimately calls signInWithCredential elsewhere '
        '(the ordinary non-anonymous-user path, unrelated to this '
        'conflict)', () {
      final start = authService.indexOf("e.code == 'credential-already-in-use'");
      expect(start, greaterThan(-1));
      final rethrowIndex = authService.indexOf('rethrow;', start);
      expect(rethrowIndex, greaterThan(start));
      final conflictBranch = authService.substring(start, rethrowIndex);

      expect(
        conflictBranch.contains('signInWithCredential'),
        isFalse,
        reason: 'the conflict branch still signs in to the conflicting '
            'account on its own, silently abandoning the current one',
      );
      expect(
        conflictBranch.contains('throw GoogleAccountConflictException(credential)'),
        isTrue,
        reason: 'the conflict is not surfaced to the caller at all',
      );
    });

    test('the conflict carries the credential so the caller can retry '
        'without making the person pick their Google account again', () {
      expect(
        authService.contains('class GoogleAccountConflictException'),
        isTrue,
      );
      expect(authService.contains('final AuthCredential credential'), isTrue);
    });

    test('a confirmed switch is a real, separate method — not something '
        'that can happen without the caller explicitly calling it', () {
      expect(
        authService.contains(
          'Future<User?> confirmSwitchToExistingGoogleAccount(',
        ),
        isTrue,
      );
    });
  });

  group('ProfileScreen actually shows the conflict before switching', () {
    test('the conflict is caught and turned into a real confirmation, not '
        'a generic error snackbar that hides what is actually happening',
        () {
      expect(
        profileScreen.contains('on GoogleAccountConflictException catch'),
        isTrue,
      );
      expect(profileScreen.contains('showDialog<bool>'), isTrue);
    });

    test('declining the dialog does not switch accounts', () {
      final start = profileScreen.indexOf('_handleGoogleAccountConflict');
      expect(start, greaterThan(-1));
      final body = profileScreen.substring(start, start + 2000);
      expect(body.contains('if (confirmed != true) return;'), isTrue);
    });

    test('confirming actually calls the confirmed-switch method, not the '
        'silent one that used to exist', () {
      expect(
        profileScreen.contains('confirmSwitchToExistingGoogleAccount'),
        isTrue,
      );
    });
  });
}

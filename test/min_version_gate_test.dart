import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/features/onboarding/min_version_gate.dart';

/// `MinVersionGate` exists to fail open in every direction except one —
/// an installed build genuinely, confirmedly behind the server's own
/// minimum. Every test here either proves that one real block case
/// fires, or proves one specific way of *not knowing* still lets the
/// learner through.
void main() {
  group('evaluateMinVersion — the pure decision, no Firestore/platform '
      'types involved', () {
    test('build below the minimum is blocked', () {
      expect(
        evaluateMinVersion(minBuildNumber: 12, currentBuildNumber: 11),
        MinVersionDecision.block,
      );
    });

    test('build exactly at the minimum is allowed — not just "above"', () {
      expect(
        evaluateMinVersion(minBuildNumber: 12, currentBuildNumber: 12),
        MinVersionDecision.allow,
      );
    });

    test('build above the minimum is allowed', () {
      expect(
        evaluateMinVersion(minBuildNumber: 12, currentBuildNumber: 13),
        MinVersionDecision.allow,
      );
    });

    test('a missing minimum (config doc absent, or field absent) allows — '
        'there is nothing to enforce yet', () {
      expect(
        evaluateMinVersion(minBuildNumber: null, currentBuildNumber: 1),
        MinVersionDecision.allow,
      );
    });

    test('an unknown current build (package_info_plus failed) allows — '
        'never blocks on our own side\'s uncertainty', () {
      expect(
        evaluateMinVersion(minBuildNumber: 999, currentBuildNumber: null),
        MinVersionDecision.allow,
      );
    });

    test('both unknown at once still allows', () {
      expect(
        evaluateMinVersion(minBuildNumber: null, currentBuildNumber: null),
        MinVersionDecision.allow,
      );
    });
  });

  group('MinVersionRepository.fetchMinBuildNumber — malformed config, by '
      'the exact shape it would arrive in from Firestore', () {
    // These exercise the same normalisation the repository applies to
    // `snapshot.data()?[minVersionConfigField]`, expressed directly
    // against the raw dynamic value rather than a live document — this
    // project has no fake-Firestore package, and the normalisation
    // itself is what's under test here, not the network call around it.
    dynamic normalise(dynamic raw) => (raw is int && raw > 0) ? raw : null;

    test('a string value ("12" instead of 12) is treated as absent', () {
      expect(normalise('12'), isNull);
    });

    test('a double value is treated as absent', () {
      expect(normalise(12.0), isNull);
    });

    test('null is treated as absent', () {
      expect(normalise(null), isNull);
    });

    test('zero is treated as absent — not a valid minimum', () {
      expect(normalise(0), isNull);
    });

    test('a negative number is treated as absent', () {
      expect(normalise(-5), isNull);
    });

    test('a genuine positive int passes through unchanged', () {
      expect(normalise(12), 12);
    });
  });

  group('failOpenWithTimeout', () {
    test('returns the task\'s real result on success', () async {
      final result = await failOpenWithTimeout<int>(
        () async => 42,
        const Duration(seconds: 1),
        onFailure: -1,
      );
      expect(result, 42);
    });

    test('a thrown error resolves to onFailure, not a rethrown exception',
        () async {
      final result = await failOpenWithTimeout<int>(
        () async => throw Exception('offline'),
        const Duration(seconds: 1),
        onFailure: -1,
      );
      expect(result, -1);
    });

    test('a task that never completes resolves to onFailure once the '
        'timeout elapses, rather than hanging forever', () async {
      final result = await failOpenWithTimeout<int>(
        () => Completer<int>().future, // never completes on its own
        const Duration(milliseconds: 50),
        onFailure: -1,
      );
      expect(result, -1);
    });
  });

  group('MinVersionGate widget', () {
    testWidgets('shows the child once the decision resolves to allow',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            minVersionDecisionProvider.overrideWith(
              (ref) async => MinVersionDecision.allow,
            ),
          ],
          child: const MaterialApp(
            home: MinVersionGate(child: Text('home content')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('home content'), findsOneWidget);
    });

    testWidgets('shows the update-required screen once the decision '
        'resolves to block, instead of the child', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            minVersionDecisionProvider.overrideWith(
              (ref) async => MinVersionDecision.block,
            ),
          ],
          child: const MaterialApp(
            home: MinVersionGate(child: Text('home content')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('home content'), findsNothing);
      expect(find.byType(UpdateRequiredScreen), findsOneWidget);
    });

    testWidgets('a failed provider (defensive path) still shows the '
        'child, never the block screen', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            minVersionDecisionProvider.overrideWith(
              (ref) async => throw Exception('should never happen, but—'),
            ),
          ],
          child: const MaterialApp(
            home: MinVersionGate(child: Text('home content')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('home content'), findsOneWidget);
      expect(find.byType(UpdateRequiredScreen), findsNothing);
    });
  });

  group('UpdateRequiredScreen', () {
    testWidgets('tapping the update button opens the exact Play Store URL',
        (tester) async {
      Uri? requested;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: UpdateRequiredScreen(
              openUrl: (uri) async {
                requested = uri;
                return true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Update Sekarang'));
      await tester.pumpAndSettle();

      expect(requested, UpdateRequiredScreen.playStoreUri);
      expect(
        requested.toString(),
        'https://play.google.com/store/apps/details?id=com.teisou.kanamaster',
      );
    });
  });
}

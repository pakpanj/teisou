import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/providers.dart';
import 'package:kana_master/data/models/ad_audience.dart';
import 'package:kana_master/data/repositories/ad_audience_repository.dart';
import 'package:kana_master/features/onboarding/age_question_screen.dart';

/// A store that refuses to write — a full disk, a corrupt preferences file,
/// a platform channel that fails on a cold start.
class _BrokenAdAudienceRepository implements AdAudienceRepository {
  @override
  Future<AdAudience> getAudience({DateTime? now}) async => const AdAudience();

  @override
  Future<void> setBirthYear(int year) async => throw Exception('disk full');
}

void main() {
  /// This screen is the app's front door: it is `home:` until the age
  /// question has an answer, and its button is disabled while saving. So an
  /// unguarded failure here was not a lost message — it was a spinner that
  /// never stopped on a screen with nothing behind it, and the only way out
  /// was clearing the app's data.
  ///
  /// The failure cannot be reproduced on a device (there is no way to make
  /// SharedPreferences fail on demand), which is exactly why it needs to be
  /// reproduced here.
  testWidgets('a failed save gives the button back instead of locking the app',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adAudienceRepositoryProvider
              .overrideWithValue(_BrokenAdAudienceRepository()),
        ],
        child: const MaterialApp(home: AgeQuestionScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Pick a year, then continue.
    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    // The first year in the list — later years are off-screen in the menu
    // and cannot be tapped without scrolling it.
    await tester.tap(find.text('${DateTime.now().year}').last);
    await tester.pumpAndSettle();

    final button = find.byType(FilledButton);
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);

    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(
      find.byType(CircularProgressIndicator),
      findsNothing,
      reason: 'the spinner never stopped — the app is unusable from here',
    );
    expect(
      tester.widget<FilledButton>(button).onPressed,
      isNotNull,
      reason: 'the only control on the app front door is dead, with no retry',
    );
    expect(find.byType(SnackBar), findsOneWidget, reason: 'failed silently');
  });
}

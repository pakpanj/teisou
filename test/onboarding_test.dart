import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kana_master/core/localization/app_strings.dart';
import 'package:kana_master/core/theme/app_theme.dart';
import 'package:kana_master/core/widgets/mascot_widget.dart';
import 'package:kana_master/data/models/app_language.dart';
import 'package:kana_master/data/repositories/onboarding_repository.dart';
import 'package:kana_master/features/onboarding/onboarding_screen.dart';

/// The mascot's first-run tutorial.
///
/// The failure that matters here is not a broken screen — it is a tutorial
/// that shows up again on every launch, or one a child cannot get out of.
/// Both look fine in a single screenshot of step one.
void main() {
  final id = AppStrings(AppLanguage.indonesian);
  final en = AppStrings(AppLanguage.english);

  Widget wrap(VoidCallback onFinished) => ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: OnboardingScreen(onFinished: onFinished),
        ),
      );

  group('the walkthrough', () {
    testWidgets('opens with the mascot greeting the learner', (tester) async {
      await tester.pumpWidget(wrap(() {}));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(MascotWidget), findsOneWidget);
      expect(find.text(id.tutorialGreeting), findsOneWidget);
    });

    testWidgets('advances one step at a time', (tester) async {
      await tester.pumpWidget(wrap(() {}));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text(id.tutorialNext));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text(id.tutorialGreeting), findsNothing);
      expect(find.text(id.tutorialKana), findsOneWidget);
    });

    testWidgets('finishes only at the end, not before', (tester) async {
      // A tutorial that reported itself done early would mark the flag and
      // the learner would never see the rest of it.
      var finished = 0;
      await tester.pumpWidget(wrap(() => finished++));
      await tester.pump(const Duration(milliseconds: 400));

      final steps = onboardingSteps(id).length;
      for (var i = 0; i < steps - 1; i++) {
        await tester.tap(find.text(id.tutorialNext));
        await tester.pump(const Duration(milliseconds: 400));
        expect(finished, 0, reason: 'still on step ${i + 2} of $steps');
      }

      await tester.tap(find.text(id.tutorialStart));
      await tester.pump();
      expect(finished, 1);
    });

    testWidgets('can be left at any point', (tester) async {
      // A tutorial a child cannot escape is a wall, not a welcome.
      var finished = 0;
      await tester.pumpWidget(wrap(() => finished++));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text(id.tutorialSkip));
      await tester.pump();
      expect(finished, 1);
    });

    testWidgets('does not finish twice if the last button is double-tapped',
        (tester) async {
      // The route does not change until the caller acts, so both taps land
      // on a live button — and two finishes means two pops.
      var finished = 0;
      await tester.pumpWidget(wrap(() => finished++));
      await tester.pump(const Duration(milliseconds: 400));

      for (var i = 0; i < onboardingSteps(id).length - 1; i++) {
        await tester.tap(find.text(id.tutorialNext));
        await tester.pump(const Duration(milliseconds: 400));
      }
      await tester.tap(find.text(id.tutorialStart));
      await tester.tap(find.text(id.tutorialStart));
      await tester.pump();

      expect(finished, 1);
    });
  });

  group('the steps themselves', () {
    test('every step shows a different expression from the one before', () {
      // The mascot changing face is the whole reason this is a character
      // talking rather than a slideshow.
      final moods = onboardingSteps(id).map((s) => s.mood).toList();
      for (var i = 1; i < moods.length; i++) {
        expect(moods[i], isNot(moods[i - 1]));
      }
    });

    test('are written in whichever language the app is set to', () {
      final indonesian = onboardingSteps(id).map((s) => s.message).toList();
      final english = onboardingSteps(en).map((s) => s.message).toList();
      expect(indonesian.length, english.length);
      for (var i = 0; i < indonesian.length; i++) {
        expect(indonesian[i], isNot(english[i]));
      }
    });

    test('none is empty', () {
      for (final step in onboardingSteps(id)) {
        expect(step.message.trim(), isNotEmpty);
      }
    });
  });

  group('remembering that it was shown', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('a fresh install has not seen it', () async {
      expect(await OnboardingRepository().hasSeenTutorial(), isFalse);
    });

    test('once marked, it stays marked', () async {
      // The actual bug this guards: a tutorial that reappears on every
      // launch because the flag never stuck.
      final repository = OnboardingRepository();
      await repository.markTutorialSeen();
      expect(await repository.hasSeenTutorial(), isTrue);

      // A second repository instance, standing in for the next launch.
      expect(await OnboardingRepository().hasSeenTutorial(), isTrue);
    });

    test('can be reset so it can be watched again', () async {
      final repository = OnboardingRepository();
      await repository.markTutorialSeen();
      await repository.resetTutorial();
      expect(await repository.hasSeenTutorial(), isFalse);
    });
  });
}

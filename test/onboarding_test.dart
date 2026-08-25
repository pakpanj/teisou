import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kana_master/core/localization/app_strings.dart';
import 'package:kana_master/core/theme/app_theme.dart';
import 'package:kana_master/core/widgets/mascot_widget.dart';
import 'package:kana_master/data/models/app_language.dart';
import 'package:kana_master/data/repositories/onboarding_repository.dart';
import 'package:kana_master/features/onboarding/module_tours.dart';
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
      expect(await OnboardingRepository().hasSeen(TutorialId.home), isFalse);
    });

    test('once marked, it stays marked', () async {
      // The actual bug this guards: a tutorial that reappears on every
      // launch because the flag never stuck.
      final repository = OnboardingRepository();
      await repository.markSeen(TutorialId.home);
      expect(await repository.hasSeen(TutorialId.home), isTrue);

      // A second repository instance, standing in for the next launch.
      expect(await OnboardingRepository().hasSeen(TutorialId.home), isTrue);
    });

    test('can be reset so it can be watched again', () async {
      final repository = OnboardingRepository();
      await repository.markSeen(TutorialId.home);
      await repository.reset(TutorialId.home);
      expect(await repository.hasSeen(TutorialId.home), isFalse);
    });

    test('the two walkthroughs are remembered apart', () async {
      // Card Game Mode explains a star ladder, tier-locked cards and a
      // ten-second choosing window — none of which the home tour
      // mentions. Sharing one flag would mean anyone who had used the
      // app before the mode existed never got told any of it.
      final repository = OnboardingRepository();
      await repository.markSeen(TutorialId.home);

      expect(await repository.hasSeen(TutorialId.cardGame), isFalse);

      await repository.markSeen(TutorialId.cardGame);
      await repository.reset(TutorialId.home);

      expect(await repository.hasSeen(TutorialId.cardGame), isTrue,
          reason: 'resetting one walkthrough cleared the other');
    });

    test('the home tour keeps the key it always had', () async {
      // Renaming this to something tidier would read as "never seen" for
      // every learner already using the app, and replay the whole tour
      // in front of all of them on the next update. The value is checked
      // literally, because that is the only thing protecting them.
      expect(TutorialId.home.prefsKey, 'onboarding_seen_v1');

      SharedPreferences.setMockInitialValues({'onboarding_seen_v1': true});
      expect(await OnboardingRepository().hasSeen(TutorialId.home), isTrue);
    });
  });

  group('the card mode walkthrough', () {
    final id = AppStrings(AppLanguage.indonesian);

    test('covers the rules a player would otherwise lose to', () {
      final messages =
          cardGameTutorialSteps(id).map((step) => step.message).join(' ');
      // Not a wording check — a coverage one. Each of these is a rule
      // with a cost attached, and a player who was never told finds it
      // out the hard way.
      expect(messages, contains('bintang'));
      expect(messages, contains('10 detik'));
      expect(messages, contains('rank'));
    });

    test('every step has something to say', () {
      for (final step in cardGameTutorialSteps(id)) {
        expect(step.message.trim(), isNotEmpty);
      }
    });

    test('it opens and closes on the mascot, like the home tour', () {
      final steps = cardGameTutorialSteps(id);
      expect(steps.first.mood, MascotMood.battleReady);
      expect(steps.last.mood, MascotMood.cheering);
    });
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/localization/app_strings.dart';
import 'package:kana_master/data/models/app_language.dart';
import 'package:kana_master/data/repositories/onboarding_repository.dart';
import 'package:kana_master/features/onboarding/coach_mark_tour.dart';
import 'package:kana_master/features/onboarding/module_tours.dart';

/// One walkthrough per module, and each one actually mounted somewhere.
///
/// A tour that is written but never wired reads as finished — the module
/// simply opens, which is what it did before. So the check that matters
/// is not "does the tour exist" but "does some screen play it", and
/// "does the screen it plays on carry the anchors it points at".
void main() {
  final s = AppStrings(AppLanguage.indonesian);

  final tours = <TutorialId, List<CoachStep>>{
    TutorialId.kana: kanaTourSteps(s),
    TutorialId.bab: babTourSteps(s),
    TutorialId.kotoba: kotobaTourSteps(s),
    TutorialId.kanji: kanjiTourSteps(s),
    TutorialId.kaiwa: kaiwaTourSteps(s),
    TutorialId.dokkai: dokkaiTourSteps(s),
    TutorialId.choukai: choukaiTourSteps(s),
    TutorialId.bunpou: bunpouTourSteps(s),
    TutorialId.particle: particleTourSteps(s),
  };

  /// Every screen file, read once.
  final sources = <String, String>{
    for (final f in Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart')))
      f.path.replaceAll(r'\', '/'): f.readAsStringSync(),
  };

  test('every module has a walkthrough', () {
    // Home and cardGame are covered by their own tests; everything else
    // in the enum is a module and owes the learner an explanation.
    final covered = {...tours.keys, TutorialId.home, TutorialId.cardGame};
    expect(TutorialId.values.toSet().difference(covered), isEmpty,
        reason: 'a TutorialId with no tour is a module that silently opens '
            'with no walkthrough at all');
  });

  test('every walkthrough is played by a screen', () {
    for (final id in tours.keys) {
      final played = sources.values
          .any((src) => src.contains('TutorialId.${id.name}'));
      expect(played, isTrue,
          reason: '${id.name}: the tour is written but no screen shows it');
    }
  });

  test('the screen that plays a tour carries the anchors it points at', () {
    for (final entry in tours.entries) {
      final screen = sources.entries.firstWhere(
        (e) => e.value.contains('TutorialId.${entry.key.name}'),
        orElse: () => throw StateError('${entry.key.name} is not played'),
      );
      for (final step in entry.value) {
        expect(screen.value, contains(_constantFor(step.anchorId)),
            reason: '${entry.key.name} points at ${step.anchorId}, which '
                '${screen.key} never mounts — the step would skip itself '
                'and the tour would quietly be shorter than it reads');
      }
    }
  });

  test('each module is remembered under its own key', () {
    final keys = TutorialId.values.map((id) => id.prefsKey).toList();
    expect(keys.toSet().length, keys.length,
        reason: 'two modules sharing a key means seeing one hides the other');
  });

  test('every step says something in both languages', () {
    for (final language in AppLanguage.values) {
      final strings = AppStrings(language);
      final all = [
        kanaTourSteps(strings),
        babTourSteps(strings),
        kotobaTourSteps(strings),
        kanjiTourSteps(strings),
        kaiwaTourSteps(strings),
        dokkaiTourSteps(strings),
        choukaiTourSteps(strings),
        bunpouTourSteps(strings),
        particleTourSteps(strings),
      ].expand((t) => t);
      for (final step in all) {
        expect(step.message.trim(), isNotEmpty);
      }
    }
  });

  test('the quiz icon is explained wherever there is one', () {
    // The icon is the least discoverable control in the app: no label, no
    // colour, top-right corner. Any screen that has one should be saying
    // so on first visit.
    final unexplained = <String>[];
    for (final entry in sources.entries) {
      if (!entry.value.contains('Icons.quiz_outlined')) continue;
      if (entry.value.contains(_constantFor(kTutorialQuizIcon))) continue;
      unexplained.add(entry.key);
    }
    expect(unexplained, isEmpty,
        reason: 'these screens hide a quiz behind an unlabelled icon and '
            'never mention it: $unexplained');
  });
}

String _constantFor(String anchorId) {
  const named = {
    'module.quizIcon': 'kTutorialQuizIcon',
    'module.firstItem': 'kTutorialFirstItem',
    'module.secondItem': 'kTutorialSecondItem',
  };
  return named[anchorId]!;
}

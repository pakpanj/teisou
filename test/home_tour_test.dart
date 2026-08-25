import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/localization/app_strings.dart';
import 'package:kana_master/data/models/app_language.dart';
import 'package:kana_master/features/onboarding/home_tour.dart';

/// The home tour against the home screen it describes.
///
/// A coach mark cannot fail loudly: a step whose anchor was never mounted
/// is skipped on purpose, so a card added to the home screen without one
/// simply never gets mentioned and the tour still looks complete. That is
/// the failure this file exists to catch. It reads the source because the
/// home screen needs Firebase to build.
void main() {
  final section =
      File('lib/features/home/widgets/modules_section.dart').readAsStringSync();
  final home = File('lib/features/home/home_screen.dart').readAsStringSync();
  final wired = section + home;
  final steps = homeTourSteps(AppStrings(AppLanguage.indonesian));

  test('every step points at an anchor that is actually mounted', () {
    for (final step in steps) {
      expect(wired, contains(_constantFor(step.anchorId)),
          reason: '${step.anchorId} is in the tour but nothing on the home '
              'screen carries that id, so the step silently skips itself');
    }
  });

  test('every card that opens a screen is inside a TutorialTarget', () {
    // Cards deliberately left out do not navigate at all: Cam Detector is
    // locked while its bugs are open, and the two Segera Hadir tiles have
    // nothing behind them yet.

    // Two cards keep their tap handler inside their own private widget,
    // far below the list that places them, so their anchor is at the
    // placement rather than anywhere near the handler.
    final wrapped = RegExp(r'TutorialTarget\(\s*id:[^)]*?child:\s*(_\w+)\(')
        .allMatches(section)
        .map((m) => m.group(1)!)
        .toSet();

    final lines = section.split('\n');
    final missed = <int>[];
    for (var i = 0; i < lines.length; i++) {
      if (!lines[i].contains('AppNavigator.slideFrom')) continue;
      // The anchor wraps the card, so it sits above the tap handler —
      // within a card's worth of lines, not the whole file.
      final from = (i - 40).clamp(0, lines.length);
      if (lines.sublist(from, i).join('\n').contains('TutorialTarget(')) {
        continue;
      }
      final owner = RegExp(r'class (_\w+)')
          .allMatches(lines.sublist(0, i).join('\n'))
          .map((m) => m.group(1)!)
          .lastOrNull;
      if (owner == null || !wrapped.contains(owner)) missed.add(i + 1);
    }
    expect(missed, isEmpty,
        reason: 'these home cards open a screen the tour never mentions; '
            'wrap them in a TutorialTarget and add a step, at lines $missed');
  });

  test('the Toko bottom-nav tab (index 2) has a real anchor, not null — '
      'the gap a prior audit found: Ujian and Profil were both wired but '
      'Toko silently fell through to the `_ => null` default', () {
    final match = RegExp(
      r'final anchorId = switch \(index\) \{(.*?)\};',
      dotAll: true,
    ).firstMatch(home);
    expect(match, isNotNull, reason: 'the bottom nav anchor switch was not found');
    final body = match!.group(1)!;
    final index2 = RegExp(r'2\s*=>\s*(\w+),').firstMatch(body);
    expect(index2, isNotNull, reason: 'index 2 has no case at all in the switch');
    expect(index2!.group(1), 'kTutorialShop',
        reason: 'index 2 (Toko) still maps to something other than its own anchor');
  });

  test('no card is pointed at twice', () {
    final ids = steps.map((s) => s.anchorId).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('every step says something, in whichever language is set', () {
    for (final language in AppLanguage.values) {
      for (final step in homeTourSteps(AppStrings(language))) {
        expect(step.message.trim(), isNotEmpty);
      }
    }
  });

  test('the two languages say a different thing, not the same string twice',
      () {
    // A missed `_t` gives the English learner the Indonesian sentence, and
    // nothing about that looks wrong until someone switches language.
    final id = homeTourSteps(AppStrings(AppLanguage.indonesian));
    final en = homeTourSteps(AppStrings(AppLanguage.english));
    for (var i = 0; i < id.length; i++) {
      expect(en[i].message, isNot(id[i].message),
          reason: 'step ${i + 1} (${id[i].anchorId}) is untranslated');
    }
  });

  test('the steps follow the page down, not back and forth', () {
    // Screen order is what makes a fourteen-stop tour bearable: each step
    // is a short scroll from the last. Reordering the steps without
    // reordering the cards puts the learner back to bouncing up and down
    // the page.
    final at = <int>[];
    for (final step in steps) {
      final found = section.indexOf('id: ${_constantFor(step.anchorId)}');
      if (found >= 0) at.add(found);
    }
    expect(at.length, greaterThan(5), reason: 'sanity: the anchors were found');
    expect(at, orderedEquals(List.of(at)..sort()));
  });
}

/// The constant name the source uses for an anchor id.
String _constantFor(String anchorId) {
  final name = anchorId.split('.').last;
  return 'kTutorial${name[0].toUpperCase()}${name.substring(1)}';
}

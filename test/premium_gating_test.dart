import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/data/models/jlpt_level.dart';
import 'package:kana_master/features/paywall/module_access.dart';

/// What is sold and what is not.
///
/// **A gate fails open, quietly.** Every failure here looks like the app
/// working: a module that should cost money simply opens, and nobody
/// files a bug about getting something for free. There is no crash, no
/// analyzer warning, and no screenshot that looks wrong — which is why
/// the split is pinned here rather than left to the screens that
/// implement it.
void main() {
  group('the free/paid line', () {
    /// Kana, Kotoba, Bab, the dictionary and the exams are free, and the
    /// first levels of Kanji and Bunpou with them. A beginner has to be
    /// able to get properly started before anything is asked for, and
    /// these are the levels a beginner spends months in.
    test('the beginning of every path is free', () {
      expect(isFreeLevel(JlptLevel.n5, freeThrough: kKanjiFreeThrough), isTrue);
      expect(isFreeLevel(JlptLevel.n4, freeThrough: kKanjiFreeThrough), isTrue);
      expect(
        isFreeLevel(JlptLevel.n5, freeThrough: kBunpouFreeThrough),
        isTrue,
      );
    });

    test('the depth is what is sold', () {
      for (final level in [JlptLevel.n3, JlptLevel.n2, JlptLevel.n1]) {
        expect(
          isFreeLevel(level, freeThrough: kKanjiFreeThrough),
          isFalse,
          reason: 'kanji ${level.key}',
        );
      }
      for (final level in [JlptLevel.n4, JlptLevel.n3, JlptLevel.n2, JlptLevel.n1]) {
        expect(
          isFreeLevel(level, freeThrough: kBunpouFreeThrough),
          isFalse,
          reason: 'bunpou ${level.key}',
        );
      }
    });

    /// The comparison is on `JlptLevel.values` order, so a level list
    /// reordered from easiest-first would silently invert the whole
    /// gate — every paid level free and every free level paid.
    test('JlptLevel still runs easiest-first', () {
      expect(JlptLevel.values.first, JlptLevel.n5);
      expect(JlptLevel.values.last, JlptLevel.n1);
    });
  });

  group('the gates are actually wired', () {
    /// The gate that was removed for testing and left removed for a
    /// year. It is not enough that `moduleAccessProvider` exists — the
    /// screens have to ask it, and a card reverting to
    /// `_AvailableModuleCard` is exactly the edit that would undo this
    /// without touching anything named "premium".
    test('every premium module is gated where it is entered', () {
      final section = File(
        'lib/features/home/widgets/modules_section.dart',
      ).readAsStringSync();
      for (final module in [
        PremiumModules.particle,
        PremiumModules.kaiwa,
        PremiumModules.choukai,
      ]) {
        expect(
          section.contains('PremiumModules.$module'),
          isTrue,
          reason: '$module is reachable from the module list without a gate',
        );
      }
    });

    test('the level-gated modules ask before opening a paid level', () {
      for (final entry in {
        'lib/features/kanji/kanji_home_screen.dart': PremiumModules.kanji,
        'lib/features/bunpou/bunpou_home_screen.dart': PremiumModules.bunpou,
      }.entries) {
        final source = File(entry.key).readAsStringSync();
        expect(
          source.contains('moduleAccessProvider'),
          isTrue,
          reason: '${entry.key} never checks access',
        );
        expect(
          source.contains('PaywallScreen'),
          isTrue,
          reason: '${entry.key} locks a level with no way to buy it',
        );
      }
    });
  });
}

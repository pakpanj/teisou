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

  group('defense-in-depth — the destination screens re-check too '
      '(RISK-04, closed)', () {
    /// Before this, `moduleAccessProvider` was only ever asked at the
    /// *tap site* (the card on Home) — once `KaiwaHomeScreen`/
    /// `ChoukaiHomeScreen`/`ParticleHomeScreen` itself was on screen,
    /// nothing checked again. Not exploitable through this app's own UI
    /// (only one navigation path exists into any of them), but a single
    /// point of enforcement rather than layered ones — a future second
    /// path (a deep link, a notification tap) could silently reopen the
    /// module for free. `ModuleAccessGate` closes it by re-asking the
    /// same question inside the screen itself.
    test('every whole-module screen wraps its own content in '
        'ModuleAccessGate', () {
      for (final entry in {
        'lib/features/kaiwa/kaiwa_home_screen.dart': PremiumModules.kaiwa,
        'lib/features/choukai/choukai_home_screen.dart':
            PremiumModules.choukai,
        'lib/features/particle/particle_home_screen.dart':
            PremiumModules.particle,
      }.entries) {
        final source = File(entry.key).readAsStringSync();
        expect(
          source.contains('ModuleAccessGate('),
          isTrue,
          reason: '${entry.key} has no internal re-check — a second '
              'navigation path into it would skip the gate entirely',
        );
        expect(
          source.contains("moduleId: PremiumModules.${entry.value}"),
          isTrue,
          reason: '${entry.key} wraps with ModuleAccessGate but for the '
              'wrong moduleId',
        );
      }
    });

    /// Kanji's own destination screen (`KanjiLevelScreen`, reached with a
    /// specific `jlptLevel` already chosen) needs the same re-check, but
    /// shaped differently — free levels must never even ask
    /// `moduleAccessProvider`, only the paid ones route through
    /// `ModuleAccessGate`, mirroring the tap site's own
    /// free-before-premium ordering exactly.
    test('KanjiLevelScreen re-checks the level-gate, not just the module '
        'list', () {
      final source =
          File('lib/features/kanji/kanji_level_screen.dart').readAsStringSync();
      expect(source.contains('isFreeLevel('), isTrue,
          reason: 'must skip the gate entirely for free levels (N5-N4)');
      expect(source.contains('ModuleAccessGate('), isTrue,
          reason: 'must gate the paid levels (N3-N1) with the same '
              'backstop the whole-module screens use');
      expect(source.contains('moduleId: PremiumModules.kanji'), isTrue);
    });
  });
}

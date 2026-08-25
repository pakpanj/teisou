import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the interim mixed-state mascot mapping for Card Battle, decided
/// in `AUDIT_CARD_BATTLE_MASCOT_MAPPING_IMPACT.md` after `excited`,
/// `searching`, `worried`, and `encouraging` were found to have no
/// costumed pose:
///
/// - `excited`     → reused as the costumed `determined` pose
/// - `searching`   → reused as the costumed `thinking` pose in
///                   `SearchRadar` only — `mascot_mood_coverage_test.dart`
///                   caught that remapping `searching`'s *other* call
///                   site too would leave the mood selected nowhere in
///                   the app at all, so `battle_invite_waiting_screen.dart`
///                   keeps the real `searching` mood, just on standard
///                   (uncostumed) art
/// - `worried`     → the real standard `worried.png` (no costume, no emoji)
/// - `encouraging` → the real standard `encouraging.png` (no costume, no emoji)
///
/// Source-inspection style, matching this project's existing convention
/// for this class of guarantee (`coach_wiring_test.dart`,
/// `theme_consistency_test.dart`, `shop_screen_gesture_test.dart`) — a
/// widget pump of these screens would need Firebase/matchmaking
/// infrastructure this suite doesn't mock, the same reasoning already
/// applied to the shop-gesture regression test.
void main() {
  final matchmaking = File(
    'lib/features/battle/battle_matchmaking_screen.dart',
  ).readAsStringSync();
  final searchRadar = File(
    'lib/features/battle/widgets/search_radar.dart',
  ).readAsStringSync();
  final inviteWaiting = File(
    'lib/features/battle/battle_invite_waiting_screen.dart',
  ).readAsStringSync();
  final battleScreen = File(
    'lib/features/battle/battle_screen.dart',
  ).readAsStringSync();

  group('the four moods with no costume are reassigned, not left broken', () {
    test('excited is reused as the costumed determined pose', () {
      expect(matchmaking, contains('mood: MascotMood.determined'));
      expect(matchmaking, isNot(contains('MascotMood.excited')));
    });

    test('SearchRadar\'s searching is reused as the costumed thinking pose', () {
      expect(searchRadar, contains('mood: MascotMood.thinking'));
      expect(searchRadar, isNot(contains('MascotMood.searching')));
    });

    test(
      'invite-waiting keeps the real searching mood, on standard art — '
      'reusing thinking at both of searching\'s call sites would orphan '
      'the mood app-wide',
      () {
        expect(
          inviteWaiting,
          contains('mood: done ? MascotMood.worried : MascotMood.searching'),
        );
        expect(inviteWaiting, contains('cardBattleSkin: false'));
      },
    );

    test(
      'battle result screen resolves a mood and a matching skin flag '
      'together, not two independent booleans that could drift apart',
      () {
        expect(battleScreen, contains('final resultMood'));
        expect(
          battleScreen,
          contains('resultMood != MascotMood.encouraging'),
        );
        expect(battleScreen, contains('mood: resultMood'));
        expect(battleScreen, contains('cardBattleSkin: resultMascotSkin'));
      },
    );
  });

  group('worried and encouraging never fall back to an emoji', () {
    test(
      'worried and searching both fall back to real standard art in '
      'battle_invite_waiting_screen.dart, not costume',
      () {
        // Neither branch of this screen's MascotWidget is costumed — a
        // stray `cardBattleSkin: true` here would silently request a
        // nonexistent card_battle/{mood}.png and land on the emoji
        // fallback, exactly what this mapping exists to prevent.
        expect(inviteWaiting, contains('cardBattleSkin: false'));
        for (final mood in ['worried', 'searching']) {
          expect(
            File('assets/mascot/$mood.png').existsSync(),
            isTrue,
            reason: 'the standard fallback for `$mood` must be real art '
                'on disk, not a promise',
          );
          expect(
            File('assets/mascot/card_battle/$mood.png').existsSync(),
            isFalse,
            reason: 'confirms `$mood` genuinely has no costume yet — if '
                'this ever starts passing, the mapping should switch back '
                'to the real costume instead of the standard-art fallback',
          );
        }
      },
    );

    test('encouraging falls back to the real standard art, not costume', () {
      expect(
        File('assets/mascot/encouraging.png').existsSync(),
        isTrue,
        reason: 'the standard fallback for `encouraging` must be real art '
            'on disk, not a promise',
      );
      expect(
        File('assets/mascot/card_battle/encouraging.png').existsSync(),
        isFalse,
        reason: 'confirms this mood genuinely has no costume yet — if '
            'this ever starts passing, the mapping should switch back to '
            'the real costume instead of the standard-art fallback',
      );
    });

    test('determined and thinking really do have costumed art to reuse', () {
      // The other half of the same guarantee: the two moods the mapping
      // reuses actually have art at the path MascotWidget will ask for.
      expect(File('assets/mascot/card_battle/determined.png').existsSync(), isTrue);
      expect(File('assets/mascot/card_battle/thinking.png').existsSync(), isTrue);
    });
  });

  group('everything outside Card Battle stays on the standard mascot', () {
    test('cardBattleSkin is never set anywhere outside lib/features/battle/', () {
      final libFiles = Directory(
        'lib',
      ).listSync(recursive: true).whereType<File>().where(
        (f) => f.path.endsWith('.dart'),
      );

      final offenders = <String>[];
      for (final file in libFiles) {
        final normalized = file.path.replaceAll('\\', '/');
        if (normalized.contains('lib/features/battle/')) continue;
        if (normalized.endsWith('lib/core/widgets/mascot_widget.dart')) {
          continue; // declares the parameter itself
        }
        if (normalized.endsWith('lib/features/onboarding/coach_mark_tour.dart') ||
            normalized.endsWith(
              'lib/features/onboarding/first_visit_tutorial.dart',
            )) {
          // Both only ever thread a caller-supplied flag through —
          // covered separately by mascot_mood_coverage_test.dart-style
          // wiring checks; their own default stays false.
          continue;
        }
        final content = file.readAsStringSync();
        if (content.contains('cardBattleSkin: true')) {
          offenders.add(normalized);
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'only screens genuinely inside Card Battle may opt into '
            'the costumed skin: $offenders',
      );
    });
  });
}

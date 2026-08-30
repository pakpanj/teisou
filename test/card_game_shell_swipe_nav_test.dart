import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Source-inspection regression test — mirrors this codebase's existing
/// convention for pinning a structural property that's awkward to mount
/// in a real widget test (`no_hardcoded_ui_strings_test.dart`,
/// `mascot_mood_coverage_test.dart`, `coach_wiring_test.dart`).
///
/// **What this guards**: `CardGameShell`'s own bottom-tab navigation used
/// to be tap-only (`IndexedStack`), a deliberate choice at the time to
/// avoid a nested-gesture conflict with the rest of the app's swipeable
/// main tabs. Per an explicit user report ("untuk berpindah tidak bisa
/// dengan sistem geser" — can't switch by swiping), it moved to a real
/// swipeable `PageView`, mirroring `HomeScreen`'s own bottom-tab
/// `PageView` exactly, `_KeepAlivePage` included so the Battle tab's live
/// matchmaking listener survives a swipe the same way it survived a tap.
///
/// Swiping needed one carve-out, not a blanket enable: the Skin tab has
/// its own horizontal filter-chip strip
/// (`card_skin_picker_screen.dart`'s `SingleChildScrollView(scrollDirection:
/// Axis.horizontal)`), and a swipeable `PageView` sitting behind it would
/// reproduce the exact nested-same-axis-scrollable conflict
/// `AUDIT_GESTURE_CONFLICT.md` found and fixed for Toko's `TabBarView`.
/// Unlike Toko, the chip row has no second, tap-only way to reach an
/// overflowing chip, so the fix here is the audit's own "option 1" for
/// this conflict shape: disable the *outer* swipe specifically while the
/// Skin tab (index 3) is showing, rather than touching the chip row's own
/// scroll at all.
void main() {
  final source = File(
    'lib/features/battle/card_game_shell.dart',
  ).readAsStringSync();

  test('CardGameShell uses a swipeable PageView, not IndexedStack', () {
    expect(
      source,
      contains('body: PageView('),
      reason: 'the bottom-tab body must be a PageView so swiping between '
          'tabs works, matching HomeScreen\'s own bottom-tab navigation',
    );
    expect(
      source,
      isNot(contains('body: IndexedStack(')),
      reason: 'this is exactly the tap-only shape being replaced — if this '
          'reappears, swipe navigation silently regressed',
    );
  });

  test('every tab is wrapped in _KeepAlivePage, so none loses state on a '
      'swipe', () {
    final keepAliveCount = '_KeepAlivePage(child:'.allMatches(source).length;
    expect(
      keepAliveCount,
      4,
      reason: 'all four tabs (Beranda, Deck, Battle, Skin) must be wrapped, '
          'or an unwrapped one (Battle specifically) would cancel its live '
          'matchmaking listener the moment a learner swipes away from it',
    );
  });

  test('swipe is disabled specifically while the Skin tab (index 3) is '
      'showing, to avoid fighting its own horizontal filter-chip scroll',
      () {
    expect(
      source,
      contains("physics: _tab == 3"),
      reason: 'Skin (CardSkinPickerBody) has its own horizontal '
          'SingleChildScrollView filter strip — an unconditionally '
          'swipeable PageView behind it reproduces the exact '
          'nested-same-axis-scrollable conflict AUDIT_GESTURE_CONFLICT.md '
          'found for Toko',
    );
    expect(source, contains('NeverScrollableScrollPhysics'));
  });

  test('programmatic tab jumps (nav bar tap, the lobby\'s find-opponent '
      'button) animate the PageController, not just setState', () {
    expect(
      source,
      contains('_pageController.animateToPage('),
      reason: 'a tap-driven jump has to move the PageView too, or the nav '
          'bar\'s selected index and the actually-visible page would '
          'disagree the moment a tap-driven jump happens',
    );
  });

  test('the PageController is disposed', () {
    expect(source, contains('_pageController.dispose();'));
  });
}

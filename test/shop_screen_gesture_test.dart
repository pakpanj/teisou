import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the fix for a real reported bug: swiping Home ↔ Ujian ↔ Toko ↔
/// Profil worked at first, then silently stopped working once inside
/// Toko — because Toko's own category switcher (Skin Kartu / Avatar /
/// Bingkai / Sampul) used to be a [TabBarView], itself a horizontal
/// [PageView], nested directly inside `HomeScreen`'s own horizontal
/// [PageView]. Two same-axis scrollables with no arbitration between them
/// is exactly the shape Flutter's gesture arena resolves inconsistently —
/// see `AUDIT_GESTURE_CONFLICT.md` for the full trace.
///
/// A widget test pumping the real [ShopScreen] would need Firebase/IAP
/// platform channels this suite doesn't mock (`iapServiceProvider`
/// constructs a real `IapService`, which is a heavier dependency than any
/// other battle-feature test in this project takes on — every one of
/// `battle_deck_builder_test.dart`/`battle_hand_test.dart`/etc. is a
/// pure-logic test for exactly this reason). So this is a source check,
/// matching the pattern already used by `coach_wiring_test.dart` and
/// `theme_consistency_test.dart` for the same class of "did we
/// accidentally reintroduce the wrong architecture" guarantee — reading
/// the file as text and asserting on it is what actually catches a
/// regression here, not a widget pump that would need heavy mocking to
/// even build.
void main() {
  final shopScreen = File('lib/features/shop/shop_screen.dart').readAsStringSync();
  final homeScreen = File('lib/features/home/home_screen.dart').readAsStringSync();

  group('Toko category selection', () {
    test('is still driven by TabBar taps, not lost along with the swipe', () {
      // A TabController exists, is handed to TabBar, and drives an
      // IndexedStack's index — tapping a category chip still switches
      // what's showing, the same as it did through the old TabBarView.
      expect(shopScreen, contains('TabController'));
      expect(
        RegExp(r'TabBar\(\s*controller:\s*_tabController').hasMatch(shopScreen),
        isTrue,
        reason: 'TabBar must still be wired to a controller — that is what '
            'category selection by tapping runs on.',
      );
      expect(
        RegExp(r'IndexedStack\(\s*index:\s*_index').hasMatch(shopScreen),
        isTrue,
        reason: 'the visible category body must be driven by the same '
            'index the TabBar controller reports.',
      );
    });

    test(
      'no longer uses a horizontal scrollable child for category switching',
      () {
        // TabBarView is a PageView internally — either one being
        // *constructed* here again (not just named in the doc comment
        // explaining why they were removed) means the nested-scrollable
        // conflict is back.
        expect(shopScreen, isNot(contains('TabBarView(')));
        expect(shopScreen, isNot(contains('PageView(')));
        // DefaultTabController existed only to hand the same controller
        // to both TabBar and TabBarView — with TabBarView gone, an
        // explicit controller replaces it. Its reappearance would be a
        // sign the old wiring crept back in.
        expect(shopScreen, isNot(contains('DefaultTabController(')));
      },
    );

    test('every category still renders through the same picker widgets', () {
      // Confirms this is a genuine swap of the switching mechanism, not a
      // widget that silently stopped showing one of the four categories.
      for (final widget in [
        'ShopTab()',
        'AvatarPickerBody(popOnSelect: false, shopMode: true)',
        'FramePickerBody(popOnSelect: false, shopMode: true)',
        'CoverPickerBody(popOnSelect: false, shopMode: true)',
      ]) {
        expect(
          shopScreen,
          contains(widget),
          reason: '$widget must still be one of the four category bodies',
        );
      }
    });
  });

  group('outer app navigation', () {
    test('Home/Ujian/Toko/Profil still swipe via one PageView', () {
      expect(
        RegExp(r'body:\s*PageView\(').hasMatch(homeScreen),
        isTrue,
        reason: 'the fix must not have touched the outer navigation — it '
            'was never the broken half.',
      );
      expect(homeScreen, contains('_KeepAlivePage(child: _HomeTabBody())'));
      expect(
        homeScreen,
        contains('_KeepAlivePage(child: ExamModePickerScreen())'),
      );
      expect(homeScreen, contains('_KeepAlivePage(child: ShopScreen())'));
      expect(homeScreen, contains('_KeepAlivePage(child: ProfileScreen())'));
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/providers.dart';
import 'package:kana_master/core/services/kana_keyboard_input.dart';
import 'package:kana_master/core/widgets/kana_keyboard.dart';
import 'package:kana_master/data/models/kana_character.dart';
import 'package:kana_master/data/models/kana_type.dart';
import 'package:kana_master/data/repositories/kana_repository.dart';

/// Widget-level smoke test — [KanaKeyboardInput]'s own logic already has
/// full coverage in kana_keyboard_input_test.dart against the real dataset;
/// this only needs to confirm the widget wires taps to `onChanged`
/// correctly and disables/enables modifier keys as expected.
///
/// The hiragana list is fetched **once**, outside any `pumpWidget` cycle,
/// then handed to every test via provider overrides instead of letting
/// each test's own `KanaKeyboard` trigger a real
/// `rootBundle.loadString` through `kanaListProvider`. Two back-to-back
/// tests both doing that real asset load inside `testWidgets` were
/// reproducibly flaky here — the first test's load would resolve, the
/// second would never settle even after generous `runAsync` polling
/// (the same asset-load-vs-fake-clock class of gotcha this codebase
/// already documents for `kanji_data.json`, just worse: it didn't even
/// reproduce in isolation, only back-to-back). Overriding with an
/// already-resolved `Future.value` sidesteps needing real IO inside the
/// pump cycle at all, so there's nothing left to race.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<KanaCharacter> hiragana;

  setUpAll(() async {
    hiragana = await KanaRepository().getByType(KanaType.hiragana);
  });

  List<Override> overridesFor(List<KanaCharacter> list) => [
    kanaListProvider(
      KanaType.hiragana,
    ).overrideWith((ref) => Future.value(list)),
    kanaKeyboardInputProvider.overrideWith(
      (ref) => Future.value(KanaKeyboardInput.fromAll(list)),
    ),
  ];

  testWidgets('tapping a base key appends its character', (tester) async {
    String? result;
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(hiragana),
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 500,
              child: KanaKeyboard(value: '', onChanged: (v) => result = v),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    // あ appears twice — once as its group's key, once as the character
    // itself in the row below, since あ is the group open by default.
    // `.last` is the character key.
    await tester.tap(find.text('あ').last);
    await tester.pump();

    expect(result, 'あ');
  });

  /// The regression this keyboard was rebuilt for: it used to lay all
  /// eleven gojūon rows out at once, so a caller with a phone-sized slot
  /// got twelve stacked rows about twelve pixels tall and every character
  /// spilled out of its key. A height check would not catch a return to
  /// that — the widget fills whatever it is given either way. What
  /// distinguishes the two layouts is *how many characters are on screen
  /// at once*, so that is what is asserted.
  testWidgets('only the selected group is laid out, not all 46 kana', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(hiragana),
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 500,
              child: KanaKeyboard(value: '', onChanged: (_) {}),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    // あ's group is open, so its five are all reachable.
    for (final k in ['い', 'う', 'え', 'お']) {
      expect(find.text(k), findsOneWidget, reason: '$k should be on screen');
    }
    // き is inside か's group, which is not open — it has no key at all.
    // か itself is present, but only as the group key.
    expect(find.text('き'), findsNothing);
    expect(find.text('か'), findsOneWidget);
  });

  /// The other half of the same regression, and the half a behavioural
  /// test cannot see: whether a key is big enough to hit. The old layout
  /// was not *wrong*, it was unusable — 12 rows inside the battle screen's
  /// 220dp slot left each key about 12dp tall with an 18pt character in
  /// it. Pinned at the real height the battle screen passes, so a future
  /// caller shrinking the slot fails here rather than on a phone.
  testWidgets('keys stay finger-sized at the height the battle screen gives', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(hiragana),
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 160,
              child: KanaKeyboard(value: '', onChanged: (_) {}),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final key = tester.getSize(
      find.ancestor(of: find.text('い'), matching: find.byType(InkWell)).first,
    );
    expect(
      key.height,
      greaterThanOrEqualTo(36),
      reason: 'a key shorter than this cannot hold its own character',
    );
    // Guards the guard: if the finder ever resolved to the keyboard
    // itself rather than one key, the assertion above would pass no
    // matter how the rows were laid out.
    expect(key.height, lessThan(160 / 3));
  });

  testWidgets('a character outside the open group takes its group key first', (
    tester,
  ) async {
    String? result;
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(hiragana),
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 500,
              child: KanaKeyboard(value: '', onChanged: (v) => result = v),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('か'));
    await tester.pump();

    // Selecting a group must never type anything by itself — otherwise
    // every character would come out as two.
    expect(result, isNull);

    await tester.tap(find.text('き'));
    await tester.pump();

    expect(result, 'き');
  });

  testWidgets('tenten key is disabled when the buffer has no tenten form', (
    tester,
  ) async {
    String? result;
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(hiragana),
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 500,
              child: KanaKeyboard(value: 'あ', onChanged: (v) => result = v),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('゛'));
    await tester.pump();

    expect(result, isNull);
  });

  testWidgets('tenten key applies when the buffer ends in a voiceable kana', (
    tester,
  ) async {
    String? result;
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(hiragana),
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 500,
              child: KanaKeyboard(value: 'か', onChanged: (v) => result = v),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('゛'));
    await tester.pump();

    expect(result, 'が');
  });

  testWidgets('backspace is disabled on an empty buffer', (tester) async {
    var callCount = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(hiragana),
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 500,
              child: KanaKeyboard(value: '', onChanged: (_) => callCount++),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump();

    expect(callCount, 0);
  });

  testWidgets('backspace drops the last character when the buffer is not '
      'empty', (tester) async {
    String? result;
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(hiragana),
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 500,
              child: KanaKeyboard(
                value: 'がくせい',
                onChanged: (v) => result = v,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump();

    expect(result, 'がくせ');
  });
}

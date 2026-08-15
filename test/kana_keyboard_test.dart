import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/providers.dart';
import 'package:kana_master/core/services/kana_keyboard_input.dart';
import 'package:kana_master/core/widgets/kana_keyboard.dart';
import 'package:kana_master/data/models/kana_character.dart';
import 'package:kana_master/data/models/kana_type.dart';
import 'package:kana_master/data/repositories/kana_repository.dart';

/// Widget-level tests for the flick keyboard. [KanaKeyboardInput]'s own
/// logic already has full coverage in kana_keyboard_input_test.dart
/// against the real dataset; what needs covering here is the part that
/// only exists in the widget — **which direction produces which
/// character**, since that mapping is the entire keyboard.
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

  /// Pumps the keyboard at the height the battle screen actually gives
  /// it, and returns a setter for the last value it reported.
  Future<void> pumpKeyboard(
    WidgetTester tester, {
    String value = '',
    required ValueChanged<String> onChanged,
    double height = 200,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(hiragana),
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: height,
              child: KanaKeyboard(value: value, onChanged: onChanged),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  /// Presses [key], drags [by], and lets go — the gesture this keyboard
  /// is built around. A zero offset is a plain tap.
  Future<void> flick(
    WidgetTester tester,
    String key,
    Offset by,
  ) async {
    final gesture = await tester.startGesture(tester.getCenter(find.text(key)));
    if (by != Offset.zero) {
      await gesture.moveBy(by);
      await tester.pump();
    }
    await gesture.up();
    await tester.pump();
  }

  testWidgets('tapping a key gives its group first character', (tester) async {
    String? result;
    await pumpKeyboard(tester, onChanged: (v) => result = v);

    await flick(tester, 'あ', Offset.zero);

    expect(result, 'あ');
  });

  /// The mapping is the keyboard. Getting a direction wrong here would
  /// not crash, would not fail analysis, and would not look wrong in a
  /// screenshot — it would just quietly type the wrong vowel, which on a
  /// timed answer reads to a learner as their own mistake.
  testWidgets('each direction gives that group its own vowel', (tester) async {
    // Deliberately spelled out per direction rather than looped over the
    // dataset: a loop that derived the expectation the same way the
    // widget does would agree with it even when both are wrong.
    const expected = <(Offset, String)>[
      (Offset(-40, 0), 'き'),
      (Offset(0, -40), 'く'),
      (Offset(40, 0), 'け'),
      (Offset(0, 40), 'こ'),
    ];

    for (final (direction, character) in expected) {
      String? result;
      await pumpKeyboard(tester, onChanged: (v) => result = v);
      await flick(tester, 'か', direction);
      expect(result, character, reason: 'flick $direction');
    }
  });

  /// ん is the one character placed by hand rather than read out of the
  /// dataset's own row/column scheme — it has its own row there, but
  /// every real flick keyboard puts it on わ. If that override is ever
  /// dropped, ん becomes untypeable and nothing else notices.
  testWidgets('ん is reachable on わ, and を below it', (tester) async {
    String? result;
    await pumpKeyboard(tester, onChanged: (v) => result = v);
    await flick(tester, 'わ', const Offset(0, -40));
    expect(result, 'ん');

    await pumpKeyboard(tester, onChanged: (v) => result = v);
    await flick(tester, 'わ', const Offset(-40, 0));
    expect(result, 'を');
  });

  testWidgets('a flick into an empty direction types nothing', (tester) async {
    var calls = 0;
    await pumpKeyboard(tester, onChanged: (_) => calls++);

    // や has no い or え column. Falling back to the centre character
    // would be worse than doing nothing: nothing is obviously a miss,
    // a silent や is mistaken for a correct keypress.
    await flick(tester, 'や', const Offset(-40, 0));

    expect(calls, 0);
  });

  testWidgets('pressing a key previews the whole group', (tester) async {
    await pumpKeyboard(tester, onChanged: (_) {});

    // Nothing on screen but the group's first character until pressed —
    // this is what keeps the board to sixteen big keys.
    expect(find.text('き'), findsNothing);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('か')),
    );
    await tester.pump();

    for (final k in ['き', 'く', 'け', 'こ']) {
      expect(find.text(k), findsOneWidget, reason: '$k should be previewed');
    }

    await gesture.up();
    await tester.pump();
    expect(find.text('き'), findsNothing);
  });

  testWidgets('tenten key is disabled when the buffer has no tenten form', (
    tester,
  ) async {
    String? result;
    await pumpKeyboard(tester, value: 'あ', onChanged: (v) => result = v);

    await tester.tap(find.text('゛'));
    await tester.pump();

    expect(result, isNull);
  });

  testWidgets('tenten key applies when the buffer ends in a voiceable kana', (
    tester,
  ) async {
    String? result;
    await pumpKeyboard(tester, value: 'か', onChanged: (v) => result = v);

    await tester.tap(find.text('゛'));
    await tester.pump();

    expect(result, 'が');
  });

  testWidgets('the small-kana key stays dead until youon is possible', (
    tester,
  ) async {
    var calls = 0;
    await pumpKeyboard(tester, value: 'あ', onChanged: (_) => calls++);
    await flick(tester, '小', Offset.zero);
    expect(calls, 0, reason: 'あゃ is not a thing');

    await pumpKeyboard(tester, value: 'き', onChanged: (_) => calls++);
    await flick(tester, '小', Offset.zero);
    expect(calls, 1, reason: 'きゃ is');
  });

  testWidgets('backspace is disabled on an empty buffer', (tester) async {
    var callCount = 0;
    await pumpKeyboard(tester, onChanged: (_) => callCount++);

    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump();

    expect(callCount, 0);
  });

  testWidgets('backspace drops the last character when the buffer is not '
      'empty', (tester) async {
    String? result;
    await pumpKeyboard(tester, value: 'がくせい', onChanged: (v) => result = v);

    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump();

    expect(result, 'がくせ');
  });

  /// The other half of the regression this keyboard was rebuilt for, and
  /// the half no behavioural test can see: whether a key is big enough to
  /// hit. The old layout was not *wrong*, it was unusable — twelve rows
  /// inside the battle screen's slot left each key about twelve pixels
  /// tall with a full-size character in it. Pinned at the real height the
  /// battle screen passes, so a caller shrinking the slot fails here
  /// rather than on a phone.
  testWidgets('keys stay finger-sized at the height the battle screen gives', (
    tester,
  ) async {
    await pumpKeyboard(tester, onChanged: (_) {});

    final key = tester.getSize(
      find.ancestor(of: find.text('あ'), matching: find.byType(Material)).first,
    );
    expect(
      key.height,
      greaterThanOrEqualTo(36),
      reason: 'a key shorter than this cannot hold its own character',
    );
    // Guards the guard: if the finder ever resolved to the keyboard
    // itself rather than one key, the assertion above would pass no
    // matter how the rows were laid out.
    expect(key.height, lessThan(200 / 4));
  });
}

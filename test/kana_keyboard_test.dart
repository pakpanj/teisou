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

    await tester.tap(find.text('あ'));
    await tester.pump();

    expect(result, 'あ');
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

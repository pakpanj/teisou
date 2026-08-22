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
  Future<void> flick(WidgetTester tester, String key, Offset by) async {
    final gesture = await tester.startGesture(tester.getCenter(find.text(key)));
    if (by != Offset.zero) {
      await gesture.moveBy(by);
      await tester.pump();
    }
    await gesture.up();
    await tester.pump();
  }

  /// A keyboard whose buffer actually changes as it is typed into, plus
  /// a clock the test moves by hand.
  ///
  /// The tests above can get away with a fixed `value` because one
  /// gesture types one character. Repeat-tapping cannot: the second tap
  /// has to see what the first one typed, and how long ago.
  Future<({List<String> typed, void Function(Duration) advance})> pumpLive(
    WidgetTester tester, {
    String value = '',
  }) async {
    final typed = <String>[];
    var now = DateTime(2026, 1, 1, 12);
    var current = value;
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(hiragana),
        child: MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => SizedBox(
                height: 200,
                child: KanaKeyboard(
                  value: current,
                  clock: () => now,
                  onChanged: (v) {
                    typed.add(v);
                    setState(() => current = v);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    return (typed: typed, advance: (Duration d) => now = now.add(d));
  }

  /// The whole point of the feature: reaching い without knowing that a
  /// flick exists. A child who has only ever used a phone keypad, or who
  /// simply has not been taught the gesture, can still type every vowel.
  testWidgets('tapping the same key again walks through its vowels', (
    tester,
  ) async {
    final board = await pumpLive(tester);

    await flick(tester, 'あ', Offset.zero);
    expect(board.typed.last, 'あ');

    await flick(tester, 'あ', Offset.zero);
    expect(board.typed.last, 'い', reason: 'second tap');

    await flick(tester, 'あ', Offset.zero);
    expect(board.typed.last, 'う', reason: 'third tap');

    await flick(tester, 'あ', Offset.zero);
    await flick(tester, 'あ', Offset.zero);
    expect(board.typed.last, 'お', reason: 'fifth tap');
  });

  testWidgets('a repeat replaces the character rather than adding one', (
    tester,
  ) async {
    // Not あい on the way to い: the buffer must never briefly hold a
    // character the learner did not ask for, because on a timed answer
    // that is what they would see and try to delete.
    final board = await pumpLive(tester);

    await flick(tester, 'か', Offset.zero);
    await flick(tester, 'か', Offset.zero);

    expect(board.typed, ['か', 'き']);
  });

  testWidgets('the run wraps back to the first character', (tester) async {
    final board = await pumpLive(tester);

    for (var i = 0; i < 6; i++) {
      await flick(tester, 'あ', Offset.zero);
    }

    expect(board.typed.last, 'あ', reason: 'six taps through five vowels');
  });

  testWidgets('taps skip directions the group does not have', (tester) async {
    // や holds only や, ゆ, よ. A run that counted the empty slots would
    // type nothing on the second tap and look broken.
    final board = await pumpLive(tester);

    await flick(tester, 'や', Offset.zero);
    await flick(tester, 'や', Offset.zero);
    expect(board.typed.last, 'ゆ');

    await flick(tester, 'や', Offset.zero);
    expect(board.typed.last, 'よ');
  });

  testWidgets('waiting types the same character twice instead', (tester) async {
    // How ああ is typed. Without this the second あ is unreachable by
    // tapping at all.
    final board = await pumpLive(tester);

    await flick(tester, 'あ', Offset.zero);
    board.advance(const Duration(seconds: 2));
    await flick(tester, 'あ', Offset.zero);

    expect(board.typed.last, 'ああ');
  });

  testWidgets('a different key starts its own character', (tester) async {
    final board = await pumpLive(tester);

    await flick(tester, 'あ', Offset.zero);
    await flick(tester, 'か', Offset.zero);

    expect(board.typed.last, 'あか');
  });

  testWidgets('a flick ends the run rather than counting as a tap', (
    tester,
  ) async {
    // The case that actually distinguishes the two: tap to い, then flick
    // to another い. The buffer now ends in the very character the run
    // was sitting on, so a run left running would treat the next tap as
    // its third — replacing the flicked い with う, eating a character
    // the learner deliberately typed.
    final board = await pumpLive(tester);

    await flick(tester, 'あ', Offset.zero);
    await flick(tester, 'あ', Offset.zero);
    expect(board.typed.last, 'い');

    await flick(tester, 'あ', const Offset(-40, 0));
    expect(board.typed.last, 'いい', reason: 'the flick adds, never replaces');

    await flick(tester, 'あ', Offset.zero);
    expect(board.typed.last, 'いいあ', reason: 'the next tap starts over');
  });

  testWidgets('a modifier ends the run', (tester) async {
    // か tapped, voiced to が, then か tapped again. Treating that second
    // tap as a repeat would replace the が the learner just made.
    final board = await pumpLive(tester);

    await flick(tester, 'か', Offset.zero);
    await tester.tap(find.text('゛'));
    await tester.pump();
    expect(board.typed.last, 'が');

    await flick(tester, 'か', Offset.zero);
    expect(board.typed.last, 'がか');
  });

  testWidgets('backspace ends the run', (tester) async {
    final board = await pumpLive(tester);

    await flick(tester, 'あ', Offset.zero);
    await flick(tester, 'あ', Offset.zero);
    expect(board.typed.last, 'い');

    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump();
    expect(board.typed.last, '');

    await flick(tester, 'あ', Offset.zero);
    expect(board.typed.last, 'あ', reason: 'not う — the run is over');
  });

  testWidgets('the small-kana key can be tapped through too', (tester) async {
    // 小 goes dead as soon as it has typed a ゃ, because a small kana
    // cannot follow a small kana — so unless it stays live for its own
    // run, ゅ and ょ are flick-only.
    final board = await pumpLive(tester, value: 'き');

    await flick(tester, '小', Offset.zero);
    expect(board.typed.last, 'きゃ');

    await flick(tester, '小', Offset.zero);
    expect(board.typed.last, 'きゅ');

    await flick(tester, '小', Offset.zero);
    expect(board.typed.last, 'きょ');
  });

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

    final gesture = await tester.startGesture(tester.getCenter(find.text('か')));
    await tester.pump();

    for (final k in ['き', 'く', 'け', 'こ']) {
      expect(find.text(k), findsOneWidget, reason: '$k should be previewed');
    }

    await gesture.up();
    await tester.pump();
    expect(find.text('き'), findsNothing);
  });

  /// Found on a device, and worth a permanent guard because it is
  /// invisible from the code: あ, た and ま were in the leftmost column,
  /// so their left-flick preview had nowhere to open and was clamped back
  /// on top of the key being pressed — い, ち and み sat under the user's
  /// own thumb. The keyboard "worked": it typed the right character, the
  /// tests passed, and only someone actually flicking on a phone could
  /// see that the option was unreachable to the eye.
  ///
  /// Asserting on the rect rather than on the layout means this stays
  /// true however the columns are rearranged later.
  testWidgets('a left flick opens where it can be seen, not under the '
      'thumb', (tester) async {
    for (final (key, flicked) in const [('あ', 'い'), ('た', 'ち'), ('ま', 'み')]) {
      await pumpKeyboard(tester, onChanged: (_) {});
      final keyRect = tester.getRect(find.text(key));

      final gesture = await tester.startGesture(keyRect.center);
      await gesture.moveBy(const Offset(-40, 0));
      await tester.pump();

      expect(find.text(flicked), findsOneWidget);
      final previewRect = tester.getRect(find.text(flicked));
      expect(
        previewRect.overlaps(keyRect),
        isFalse,
        reason: '$flicked is hidden behind the $key key',
      );

      await gesture.up();
      await tester.pump();
    }
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

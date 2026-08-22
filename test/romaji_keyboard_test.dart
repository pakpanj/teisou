import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/theme/app_theme.dart';
import 'package:kana_master/core/widgets/keyboard_look.dart';
import 'package:kana_master/core/widgets/romaji_keyboard.dart';

/// The app's own romaji keyboard.
///
/// It replaced the system keyboard on the cards that ask for a latin
/// reading, so the things that used to come free — every letter reaches
/// the buffer, backspace deletes one — are now this widget's job and
/// nobody else's.
void main() {
  Future<({List<String> typed, void Function(String) set})> pump(
    WidgetTester tester, {
    String value = '',
    double height = 190,
  }) async {
    final typed = <String>[];
    var current = value;
    late void Function(void Function()) rebuild;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return SizedBox(
                height: height,
                child: RomajiKeyboard(
                  value: current,
                  onChanged: (v) {
                    typed.add(v);
                    setState(() => current = v);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    return (typed: typed, set: (String v) => rebuild(() => current = v));
  }

  testWidgets('every letter of the alphabet is reachable', (tester) async {
    // The layout is written out as three strings; a typo there drops a
    // letter, and the only symptom is a card nobody can answer.
    final board = await pump(tester);
    for (final letter in 'abcdefghijklmnopqrstuvwxyz'.split('')) {
      expect(
        find.text(letter),
        findsOneWidget,
        reason: '$letter is not on the keyboard',
      );
    }
    expect(board.typed, isEmpty);
  });

  testWidgets('a letter is appended to what is already typed', (tester) async {
    final board = await pump(tester);

    await tester.tap(find.text('s'));
    await tester.pump();
    await tester.tap(find.text('h'));
    await tester.pump();
    await tester.tap(find.text('i'));
    await tester.pump();

    expect(board.typed, ['s', 'sh', 'shi']);
  });

  testWidgets('backspace drops the last letter', (tester) async {
    final board = await pump(tester, value: 'tsu');

    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump();

    expect(board.typed.last, 'ts');
  });

  testWidgets('backspace is dead on an empty buffer', (tester) async {
    final board = await pump(tester);

    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump();

    expect(board.typed, isEmpty);
  });

  testWidgets('no space bar, so an answer cannot carry one', (tester) async {
    // Every answer this keyboard is asked for is a single word, and a
    // stray space is a wrong answer the learner cannot see.
    await pump(tester);
    expect(find.text(' '), findsNothing);
  });

  testWidgets('keys stay finger-sized at the height the battle screen gives', (
    tester,
  ) async {
    // Same guard the kana keyboard carries: this widget is flexed, so a
    // caller giving it too little height silently shrinks the keys
    // rather than overflowing, and nothing fails.
    await pump(tester, height: 190);

    final key = tester.getSize(
      find.ancestor(of: find.text('q'), matching: find.byType(Material)).first,
    );
    expect(key.height, greaterThan(40), reason: 'key height');
    expect(key.width, greaterThan(24), reason: 'key width');
  });

  testWidgets('the keys sit on a tray rather than on the screen behind', (
    tester,
  ) async {
    // Without one the keys float directly on whatever is behind the
    // keyboard — in Card Game Mode, a photograph of Fuji with sakura
    // drifting between the letters — and read as scattered buttons
    // rather than as one keyboard.
    await pump(tester);

    expect(find.byType(KeyboardPanel), findsOneWidget);
  });

  testWidgets('the tray can run to the bottom without moving the keys', (
    tester,
  ) async {
    // The battle screen used to hand the whole column to a SafeArea, so
    // the keyboard stopped short of the navigation bar and a strip of
    // the battle background showed underneath it. Now the tray takes
    // that inset as extra height instead — and the keys have to end up
    // in exactly the same place either way, because that is where a
    // thumb has learned they are.
    const inset = 48.0;

    Future<Rect> keysWith({
      required double padding,
      required double extra,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: padding),
                child: SizedBox(
                  height: 190 + extra,
                  child: RomajiKeyboard(
                    value: '',
                    onChanged: (_) {},
                    bottomInset: extra,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      return tester.getRect(find.text('q'));
    }

    // Old shape: a SafeArea holds the keyboard clear of the bar.
    final safeArea = await keysWith(padding: inset, extra: 0);
    final safeAreaTray = tester.getRect(find.byType(KeyboardPanel));

    // New shape: the keyboard runs to the bottom, tray padded instead.
    final extended = await keysWith(padding: 0, extra: inset);
    final extendedTray = tester.getRect(find.byType(KeyboardPanel));

    expect(
      extended.top,
      closeTo(safeArea.top, 0.5),
      reason: 'the keys moved when only the tray was supposed to',
    );
    expect(
      extendedTray.bottom - safeAreaTray.bottom,
      closeTo(inset, 0.5),
      reason: 'the tray did not reach any further down than before',
    );
  });

  testWidgets('a skin can repaint the tray as well as the keys', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            height: 190,
            child: RomajiKeyboard(
              value: '',
              onChanged: (_) {},
              look: const KeyboardLook(panel: Color(0xFF203040)),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(KeyboardPanel),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect(
      (box.decoration as BoxDecoration).color,
      const Color(0xFF203040),
      reason: 'a keyboard skin that cannot repaint the tray is half a skin',
    );
  });

  testWidgets('a skin can repaint the keys without touching the layout', (
    tester,
  ) async {
    // The reason `look` exists. If a keyboard skin cannot change a key's
    // colour, there is nothing to sell.
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            height: 190,
            child: RomajiKeyboard(
              value: '',
              onChanged: (_) {},
              look: const KeyboardLook(
                face: Color(0xFF102030),
                text: Color(0xFFFFEEDD),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final material = tester.widget<Material>(
      find.ancestor(of: find.text('q'), matching: find.byType(Material)).first,
    );
    expect(material.color, const Color(0xFF102030));

    final text = tester.widget<Text>(find.text('q'));
    expect(text.style?.color, const Color(0xFFFFEEDD));
  });
}

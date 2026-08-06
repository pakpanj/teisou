import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/services/spoken_script.dart';
import 'package:kana_master/data/models/kaiwa_line.dart';

/// Splitting a Choukai clip into speaker turns.
///
/// The bug: every clip is a script — `男：すみません…女：今、三時半です。` —
/// and the whole string went to the TTS engine as one utterance. So the
/// learner heard the words "otoko" and "onna" read aloud between the
/// lines, in a single voice, for what are mostly two-person dialogues.
void main() {
  group('parsing', () {
    test('splits a two-speaker clip into its turns', () {
      final turns = parseSpokenScript(
        '男：すみません、今何時ですか。女：今、三時半です。',
      );
      expect(turns, [
        const ScriptTurn(
            gender: KaiwaGender.male, text: 'すみません、今何時ですか。'),
        const ScriptTurn(gender: KaiwaGender.female, text: '今、三時半です。'),
      ]);
    });

    test('never leaves the marker in the spoken text', () {
      // The actual complaint: the engine was pronouncing 男 and 女.
      final turns = parseSpokenScript('男：はい。女：いいえ。男：どうも。');
      for (final turn in turns) {
        expect(turn.text, isNot(contains('男')));
        expect(turn.text, isNot(contains('女')));
        expect(turn.text, isNot(contains('：')));
      }
    });

    test('keeps consecutive turns by the same speaker apart', () {
      final turns = parseSpokenScript('男：ええ。男：そうですね。');
      expect(turns.length, 2);
      expect(turns.every((t) => t.gender == KaiwaGender.male), isTrue);
    });

    test('accepts a halfwidth colon too', () {
      // Not in the dataset today, but the sort of thing that slips into
      // hand-typed content, and it would silently break the split.
      final turns = parseSpokenScript('男:はい。女:いいえ。');
      expect(turns.length, 2);
      expect(turns.first.gender, KaiwaGender.male);
    });

    test('text with no markers comes back as one unattributed turn', () {
      final turns = parseSpokenScript('こんにちは。');
      expect(turns, [const ScriptTurn(gender: null, text: 'こんにちは。')]);
    });

    test('a bare 男 that is not a marker stays in the speech', () {
      // 男 followed by anything but a colon is a word, not a stage
      // direction, and dropping it would corrupt the sentence.
      final turns = parseSpokenScript('女：男の人が来ました。');
      expect(turns.length, 1);
      expect(turns.first.gender, KaiwaGender.female);
      expect(turns.first.text, '男の人が来ました。');
    });

    test('empty and whitespace-only text produce nothing', () {
      expect(parseSpokenScript(''), isEmpty);
      expect(parseSpokenScript('   '), isEmpty);
      expect(parseSpokenScript('男：'), isEmpty);
    });
  });

  group('against the real dataset', () {
    late List<dynamic> clips;

    setUpAll(() {
      clips = json.decode(
        File('assets/data/choukai_data.json').readAsStringSync(),
      ) as List<dynamic>;
    });

    test('every clip parses into at least one attributed turn', () {
      for (final clip in clips) {
        final map = clip as Map<String, dynamic>;
        final turns = parseSpokenScript(map['audioText'] as String);
        expect(turns, isNotEmpty, reason: '${map['id']} produced no speech');
        expect(turns.first.gender, isNotNull,
            reason: '${map['id']} does not name its first speaker');
      }
    });

    test('no marker survives into anything that gets spoken', () {
      // One escaped marker means one clip that still says "otoko" out
      // loud, and there are 150 of them to check by ear otherwise.
      for (final clip in clips) {
        final map = clip as Map<String, dynamic>;
        for (final turn in parseSpokenScript(map['audioText'] as String)) {
          expect(turn.text, isNot(startsWith('男')),
              reason: 'marker left in ${map['id']}');
          expect(turn.text, isNot(startsWith('女')),
              reason: 'marker left in ${map['id']}');
          expect(turn.text, isNot(contains('：')),
              reason: 'marker left in ${map['id']}');
        }
      }
    });

    test('most clips really are two-speaker dialogues', () {
      // The reason picking one voice per clip could never have been
      // right: 122 of 150 have both speakers in them.
      var both = 0;
      for (final clip in clips) {
        final map = clip as Map<String, dynamic>;
        final genders = parseSpokenScript(map['audioText'] as String)
            .map((t) => t.gender)
            .toSet();
        if (genders.length > 1) both++;
      }
      expect(both, greaterThan(clips.length ~/ 2));
    });

    test('nothing spoken is left empty', () {
      for (final clip in clips) {
        final map = clip as Map<String, dynamic>;
        for (final turn in parseSpokenScript(map['audioText'] as String)) {
          expect(turn.text.trim(), isNotEmpty);
        }
      }
    });
  });
}

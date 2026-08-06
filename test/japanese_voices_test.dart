import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/services/japanese_voices.dart';
import 'package:kana_master/data/models/kaiwa_line.dart';

/// Choosing a male and a female Japanese voice from a device's TTS list.
///
/// The bug this replaces was invisible from the code: the old version
/// searched voice names for "male" and "female", which no Google Japanese
/// voice contains, so it silently found neither and every line in the app
/// — Kaiwa's men, Choukai's clips, everything — came out of the one
/// default voice. Nothing threw. Nothing logged. It just sounded like the
/// same woman reading the whole app.
void main() {
  /// The nine ja-JP voices actually installed on the test device, copied
  /// from its `getVoices` output.
  List<VoiceMap> googleVoices() => [
        {'name': 'ja-JP-language', 'locale': 'ja-JP'},
        {'name': 'ja-jp-x-jab-network', 'locale': 'ja-JP'},
        {'name': 'ja-jp-x-htm-network', 'locale': 'ja-JP'},
        {'name': 'ja-jp-x-jad-network', 'locale': 'ja-JP'},
        {'name': 'ja-jp-x-jab-local', 'locale': 'ja-JP'},
        {'name': 'ja-jp-x-jad-local', 'locale': 'ja-JP'},
        {'name': 'ja-jp-x-jac-local', 'locale': 'ja-JP'},
        {'name': 'ja-jp-x-jac-network', 'locale': 'ja-JP'},
        {'name': 'ja-jp-x-htm-local', 'locale': 'ja-JP'},
      ];

  group("Google's Japanese voices", () {
    test('finds a male and a female voice', () {
      final voices = JapaneseVoices.from(googleVoices());
      expect(voices.hasBoth, isTrue,
          reason: 'the whole point: this list is what a real device has');
    });

    test('picks the deepest male and highest female of the four', () {
      // Measured medians: htm 304, jab 270, jad 180, jac 163. Picking by
      // whichever the engine happened to list first gave jad, a whole
      // musical third closer to the female voice than jac is — a pair a
      // child is meant to tell apart on a phone speaker.
      final voices = JapaneseVoices.from(googleVoices());
      expect(voices.male!['name'], contains('-jac-'));
      expect(voices.female!['name'], contains('-htm-'));
    });

    test('preference order beats the order the device lists voices in', () {
      // Same nine voices, shuffled: the answer must not move.
      final shuffled = googleVoices().reversed.toList();
      final voices = JapaneseVoices.from(shuffled);
      expect(voices.male!['name'], contains('-jac-'));
      expect(voices.female!['name'], contains('-htm-'));
    });

    test('the female voice is not secretly the same voice', () {
      // ja-JP-language synthesised a byte-identical file to
      // ja-jp-x-jab-local, so "default plus one other" was never two
      // voices at all.
      final voices = JapaneseVoices.from(googleVoices());
      expect(voices.female!['name'], isNot(voices.male!['name']));
    });

    test('prefers the offline copy of each voice', () {
      // A -network voice needs a live connection for every line, and this
      // is an app children use on the bus.
      final voices = JapaneseVoices.from(googleVoices());
      expect(voices.male!['name'], isNot(contains('network')));
      expect(voices.female!['name'], isNot(contains('network')));
    });
  });

  group('other engines', () {
    test('still reads a name that spells the gender out', () {
      final voices = JapaneseVoices.from([
        {'name': 'ja-JP-SMTf-female', 'locale': 'ja-JP'},
        {'name': 'ja-JP-SMTm-male', 'locale': 'ja-JP'},
      ]);
      expect(voices.male!['name'], contains('-male'));
      expect(voices.female!['name'], contains('female'));
    });

    test('does not read "female" as a male voice', () {
      // The substring trap: "female" contains "male".
      final voices = JapaneseVoices.from([
        {'name': 'ja-JP-female-1', 'locale': 'ja-JP'},
        {'name': 'ja-JP-female-2', 'locale': 'ja-JP'},
      ]);
      expect(voices.male, isNull);
    });

    test('one voice only means no gendered voices at all', () {
      // Better to report nothing and let the caller shift pitch than to
      // hand back the same voice twice and call them different speakers.
      final voices = JapaneseVoices.from([
        {'name': 'ja-JP-language', 'locale': 'ja-JP'},
      ]);
      expect(voices.hasBoth, isFalse);
    });

    test('an empty list does not throw', () {
      expect(() => JapaneseVoices.from([]), returnsNormally);
      expect(JapaneseVoices.from([]).hasBoth, isFalse);
    });
  });

  group('speakers the content leaves genderless', () {
    test('an authored gender always wins', () {
      expect(
        voiceForSpeaker(
          dialogueId: 'kaiwa_x',
          speaker: 'Pak Tanaka',
          authored: KaiwaGender.male,
        ),
        KaiwaGender.male,
      );
      expect(
        voiceForSpeaker(
          dialogueId: 'kaiwa_x',
          speaker: 'Sari',
          authored: KaiwaGender.female,
        ),
        KaiwaGender.female,
      );
    });

    test('the same speaker in the same dialogue never changes voice', () {
      // A doctor who switches sex between two lines of one conversation
      // is worse than a doctor who is always the wrong one.
      final first =
          voiceForSpeaker(dialogueId: 'kaiwa_rumah_sakit_3', speaker: 'Dokter');
      for (var i = 0; i < 50; i++) {
        expect(
          voiceForSpeaker(
              dialogueId: 'kaiwa_rumah_sakit_3', speaker: 'Dokter'),
          first,
        );
      }
    });

    test('the same role in different dialogues can differ', () {
      // Two different doctors sounding different is correct — and the
      // reason the app stops being one voice throughout.
      final voices = <KaiwaGender>{};
      for (var i = 0; i < 40; i++) {
        voices.add(voiceForSpeaker(dialogueId: 'kaiwa_d$i', speaker: 'Dokter'));
      }
      expect(voices.length, 2, reason: 'both voices should turn up');
    });

    test('splits roughly evenly across a real-sized set of dialogues', () {
      // A hash that leant 90% one way would leave the app still sounding
      // like one narrator, which is the complaint that started this.
      var male = 0;
      const total = 600;
      for (var i = 0; i < total; i++) {
        if (voiceForSpeaker(dialogueId: 'kaiwa_$i', speaker: 'Teman') ==
            KaiwaGender.male) {
          male++;
        }
      }
      expect(male, greaterThan(total ~/ 3));
      expect(male, lessThan(total * 2 ~/ 3));
    });
  });
}

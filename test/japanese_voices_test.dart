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

    test('takes the deepest male and the cleaner of the two women', () {
      // Measured medians: htm 304, jab 270, jad 180, jac 163. htm is the
      // shrillest voice the engine has, and using it for every woman is
      // what "cempreng banget" was describing — so the female pick is
      // deliberately jab, not the highest.
      final voices = JapaneseVoices.from(googleVoices());
      expect(voices.male!['name'], contains('-jac-'));
      expect(voices.female!['name'], contains('-jab-'));
      expect(voices.female!['name'], isNot(contains('-htm-')));
    });

    test('preference order beats the order the device lists voices in', () {
      // Same nine voices, shuffled: the answer must not move.
      final shuffled = googleVoices().reversed.toList();
      final voices = JapaneseVoices.from(shuffled);
      expect(voices.male!['name'], contains('-jac-'));
      expect(voices.female!['name'], contains('-jab-'));
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

  /// What an iPhone's `getVoices` returns for ja-JP: real names, no family
  /// code, and — the part that matters — an explicit `gender` key, which
  /// Android's implementation of the same call does not send at all.
  List<VoiceMap> appleVoices() => [
        {
          'name': 'Kyoko',
          'locale': 'ja-JP',
          'quality': 'default',
          'gender': 'female',
          'identifier': 'com.apple.voice.compact.ja-JP.Kyoko',
        },
        {
          'name': 'Otoya',
          'locale': 'ja-JP',
          'quality': 'default',
          'gender': 'male',
          'identifier': 'com.apple.voice.compact.ja-JP.Otoya',
        },
        {
          'name': 'Hattori',
          'locale': 'ja-JP',
          'quality': 'default',
          'gender': 'male',
          'identifier': 'com.apple.voice.enhanced.ja-JP.Hattori',
        },
      ];

  group("Apple's Japanese voices", () {
    test('finds a male and a female voice on an iPhone', () {
      // The regression this guards: every check in the picker was written
      // against Google's naming, so an iPhone matched none of them, both
      // voices stayed null, and the entire app spoke in one default voice
      // — the exact complaint the Google work had already fixed once.
      final voices = JapaneseVoices.from(appleVoices());
      expect(voices.hasBoth, isTrue);
      expect(voices.female!['name'], 'Kyoko');
      expect(voices.male!['name'], 'Otoya');
    });

    test('no Apple voice name carries a signal the older checks look for',
        () {
      // Proves the gender key is genuinely needed rather than belt and
      // braces: if any of these names happened to contain a family code
      // or the word "male", the bug would never have shown up.
      for (final v in appleVoices()) {
        final name = (v['name'] ?? '').toLowerCase();
        expect(name, isNot(contains('male')));
        for (final family in ['jab', 'jac', 'jad', 'htm']) {
          expect(name, isNot(contains('-$family-')));
        }
      }
    });

    test('an unspecified gender is not mistaken for an answer', () {
      final voices = JapaneseVoices.from([
        {'name': 'Kyoko', 'locale': 'ja-JP', 'gender': 'female'},
        {'name': 'Nanami', 'locale': 'ja-JP', 'gender': 'unspecified'},
      ]);
      expect(voices.female!['name'], 'Kyoko');
      expect(voices.male, isNull,
          reason: 'unspecified is not male; pitch shifting is the fallback');
    });

    test('Android is untouched — the gender pass never outranks Google', () {
      // Android sends no gender key, so this cannot fire there in
      // practice. Pinned anyway so a future engine that sends both still
      // gets the measured Google choice rather than a vaguer one.
      final hybrid = [
        {'name': 'ja-jp-x-jac-local', 'locale': 'ja-JP', 'gender': 'female'},
        {'name': 'ja-jp-x-jab-local', 'locale': 'ja-JP', 'gender': 'male'},
      ];
      final voices = JapaneseVoices.from(hybrid);
      expect(voices.male!['name'], 'ja-jp-x-jac-local',
          reason: 'jac was measured at 163 Hz — it is the male voice');
      expect(voices.female!['name'], 'ja-jp-x-jab-local');
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

  group('how old a speaker sounds', () {
    test('a friend sounds like a peer', () {
      expect(registerForSpeaker('Teman'), VoiceRegister.peer);
      expect(registerForSpeaker('Teman Sekelas'), VoiceRegister.peer);
      expect(registerForSpeaker('Rekan Kerja'), VoiceRegister.peer);
    });

    test('a teacher does not', () {
      // The request that started this: teachers and their like should
      // sound like an adult with some standing.
      expect(registerForSpeaker('Guru'), VoiceRegister.mature);
      expect(registerForSpeaker('Bu Guru'), VoiceRegister.mature);
      expect(registerForSpeaker('Pak Dokter'), VoiceRegister.mature);
      expect(registerForSpeaker('Atasan'), VoiceRegister.mature);
    });

    test('a Pak or Bu is enough on its own', () {
      // Nobody calls a peer "Pak", so a named elder is caught without
      // having to list every name in the dataset.
      expect(registerForSpeaker('Pak Tanaka'), VoiceRegister.mature);
      expect(registerForSpeaker('Bu Sato'), VoiceRegister.mature);
    });

    test('counter staff are left as peers', () {
      // A cashier is as likely to be twenty as fifty, and ageing every
      // service worker would be its own kind of wrong.
      expect(registerForSpeaker('Kasir'), VoiceRegister.peer);
      expect(registerForSpeaker('Pelayan'), VoiceRegister.peer);
      expect(registerForSpeaker('Petugas Bank'), VoiceRegister.peer);
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

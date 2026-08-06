import 'package:flutter_tts/flutter_tts.dart';

import '../../data/models/kaiwa_line.dart';
import 'japanese_voices.dart';
import 'spoken_script.dart';

/// Wraps [FlutterTts] configured for Japanese pronunciation of kana
/// characters and example words. MVP uses on-device TTS, not real audio
/// recordings.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  /// One male and one female ja-JP voice, resolved once from the device's
  /// installed voices and cached — never re-queried per `speak()`. Either
  /// may be null on an engine that ships a single Japanese voice, which is
  /// an expected outcome, not an error: [speak] then shifts pitch instead.
  ///
  /// See [JapaneseVoices] for how they are chosen, and for the pitch
  /// measurements the choice is based on.
  JapaneseVoices _voices = const JapaneseVoices();
  bool _voiceLookupAttempted = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _tts.setLanguage('ja-JP');
    await _tts.setSpeechRate(0.4);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _initialized = true;
  }

  Future<void> _ensureVoicesResolved() async {
    if (_voiceLookupAttempted) return;
    _voiceLookupAttempted = true;
    try {
      final raw = await _tts.getVoices;
      final jaVoices = <VoiceMap>[];
      for (final v in (raw as List? ?? const [])) {
        if (v is! Map) continue;
        final locale = v['locale']?.toString() ?? '';
        if (!locale.toLowerCase().startsWith('ja')) continue;
        jaVoices.add(v.map((k, val) => MapEntry(k.toString(), val.toString())));
      }
      _voices = JapaneseVoices.from(jaVoices);
    } catch (_) {
      // getVoices unsupported or empty on this engine — both stay null and
      // speak() falls back to the default voice plus a pitch nudge.
    }
  }

  /// Speaks [text] in Japanese, in [gender]'s voice where the device has
  /// one.
  ///
  /// **[gender] is resolved for every call, not just Kaiwa's.** It used to
  /// be optional and effectively unused, so every line in the app — kana
  /// readings, Choukai clips, Kaiwa NPCs of both sexes — came out of the
  /// single default voice, which on Google's engine is female. Callers
  /// that genuinely have no character behind the audio (a kana reading is
  /// not a person) pass nothing and keep the default.
  ///
  /// Every voice and pitch call below is wrapped in try/catch and always
  /// falls through to [FlutterTts.speak] regardless of outcome —
  /// `clearVoice`/`setVoice` are not universally supported, and an
  /// unguarded failure here used to abort before `speak()` ever ran, going
  /// silent on every screen rather than just the gendered ones. When no
  /// specific voice is being set, `setLanguage('ja-JP')` is re-asserted
  /// every time so a previous call that left the engine elsewhere
  /// self-heals on the next one instead of staying wrong all session.
  Future<void> speak(
    String text, {
    KaiwaGender? gender,
    VoiceRegister register = VoiceRegister.peer,
  }) async {
    await _ensureInitialized();
    await _tts.stop();

    VoiceMap? voice;
    if (gender != null) {
      await _ensureVoicesResolved();
      voice = gender == KaiwaGender.female ? _voices.female : _voices.male;
    }

    try {
      if (voice != null) {
        await _tts.setVoice(voice);
        await _tts.setPitch(_pitchFor(gender, register));
      } else {
        await _tts.clearVoice();
        await _tts.setLanguage('ja-JP');
        // Only a consolation prize: a shifted female voice does not sound
        // like a man, it sounds like a slowed recording. Worth doing so
        // two speakers are at least distinguishable, not worth mistaking
        // for the real thing.
        await _tts.setPitch(gender == KaiwaGender.male ? 0.85 : 1.0);
      }
    } catch (_) {
      // Voice or pitch switching failed on this device — fall through and
      // still speak with whatever state the engine is in, rather than
      // dropping the audio entirely.
    }

    await _tts.speak(text);
  }

  /// How far to drop the chosen voice for an older-sounding speaker.
  ///
  /// The engine has one usable voice per gender, so age has to come from
  /// pitch. The drops are deliberately unequal: the female voice starts at
  /// 270 Hz and has room to come down into a warmer register, while the
  /// male voice is already at 163 Hz and taking it much lower stops
  /// sounding like a person and starts sounding like a slowed tape.
  static double _pitchFor(KaiwaGender? gender, VoiceRegister register) {
    if (register == VoiceRegister.peer) return 1.0;
    return gender == KaiwaGender.male ? 0.94 : 0.82;
  }

  /// Reads a multi-speaker script, each turn in its own voice.
  ///
  /// Choukai clips are scripts with `男：`/`女：` markers in them. Passing
  /// the whole string to [speak] made the engine pronounce those markers
  /// as words, in one voice, for what are mostly two-person dialogues.
  ///
  /// Turns play in order, each awaiting the previous one — which needs
  /// `awaitSpeakCompletion`, since `speak()` otherwise returns the moment
  /// the utterance is queued and every turn would talk over the last.
  ///
  /// **Interruptible.** A five-turn clip takes half a minute, and a
  /// learner who taps again, or leaves the screen, must not be followed
  /// by the rest of it. Each run takes a token; a newer run or a [stop]
  /// invalidates the older one, which then abandons its remaining turns
  /// rather than fighting for the speaker.
  Future<void> speakScript(String script) async {
    final turns = parseSpokenScript(script);
    if (turns.isEmpty) return;
    if (turns.length == 1 && turns.first.gender == null) {
      // No markers: nothing gained by the sequential path.
      return speak(turns.first.text);
    }

    await _ensureInitialized();
    await _ensureVoicesResolved();
    final token = ++_scriptGeneration;
    await _tts.stop();

    try {
      await _tts.awaitSpeakCompletion(true);
    } catch (_) {
      // Unsupported here — the turns will overlap, which is worse than
      // ideal but still better than reading the markers aloud.
    }

    for (final turn in turns) {
      if (token != _scriptGeneration) return;
      await _speakTurn(turn.text, turn.gender);
    }
  }

  /// One turn, with the voice already chosen. Deliberately does not call
  /// `_tts.stop()` the way [speak] does — stopping between turns of the
  /// same script would cut off the turn that is still playing.
  Future<void> _speakTurn(String text, KaiwaGender? gender) async {
    // Choukai scripts name a sex but never a role, so every turn is a
    // peer — there is nothing in the text that would justify ageing one.
    final voice = gender == null
        ? null
        : (gender == KaiwaGender.female ? _voices.female : _voices.male);
    try {
      if (voice != null) {
        await _tts.setVoice(voice);
        await _tts.setPitch(1.0);
      } else {
        await _tts.clearVoice();
        await _tts.setLanguage('ja-JP');
        await _tts.setPitch(gender == KaiwaGender.male ? 0.85 : 1.0);
      }
    } catch (_) {
      // Same reasoning as speak(): never let voice switching silence the
      // line entirely.
    }
    await _tts.speak(text);
  }

  /// Bumped by every new script and by [stop], so an in-flight script
  /// knows it has been superseded.
  int _scriptGeneration = 0;

  Future<void> stop() {
    _scriptGeneration++;
    return _tts.stop();
  }
}

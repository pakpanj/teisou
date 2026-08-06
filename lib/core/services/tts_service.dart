import 'package:flutter_tts/flutter_tts.dart';

import '../../data/models/kaiwa_line.dart';
import 'japanese_voices.dart';

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
  Future<void> speak(String text, {KaiwaGender? gender}) async {
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
        await _tts.setPitch(1.0);
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

  Future<void> stop() => _tts.stop();
}

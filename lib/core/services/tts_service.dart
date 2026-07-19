import 'package:flutter_tts/flutter_tts.dart';

import '../../data/models/kaiwa_line.dart';

/// Wraps [FlutterTts] configured for Japanese pronunciation of kana
/// characters and example words. MVP uses on-device TTS, not real audio
/// recordings.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  // Per-gender ja-JP voice, resolved once via getVoices() and cached —
  // never re-queried on every speak() call. Android's flutter_tts doesn't
  // expose a gender field on voices (only name/locale — see the package's
  // own getVoices doc comment, iOS-only for gender), so this is a
  // best-effort name-string heuristic ("...female...")/("...male..."):
  // many OEM voice packs do encode gender in the voice name, but not all,
  // so both may end up null on a given device — that's an expected,
  // gracefully-handled outcome, not an error.
  Map<String, String>? _maleVoice;
  Map<String, String>? _femaleVoice;
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
      final jaVoices = <Map<String, String>>[];
      for (final v in (raw as List? ?? const [])) {
        if (v is! Map) continue;
        final locale = v['locale']?.toString() ?? '';
        if (!locale.toLowerCase().startsWith('ja')) continue;
        jaVoices.add(v.map((k, val) => MapEntry(k.toString(), val.toString())));
      }
      for (final v in jaVoices) {
        final name = (v['name'] ?? '').toLowerCase();
        if (_femaleVoice == null && name.contains('female')) {
          _femaleVoice = v;
        } else if (_maleVoice == null &&
            name.contains('male') &&
            !name.contains('female')) {
          _maleVoice = v;
        }
      }
    } catch (_) {
      // getVoices unsupported/empty on this device/engine — both stay
      // null, speak() below falls back to the default voice + pitch nudge.
    }
  }

  /// Speaks [text] in Japanese. [gender], when given (Kaiwa NPC lines
  /// only), picks a distinct-sounding voice if this device has one for
  /// ja-JP; otherwise falls back to the single default voice with a pitch
  /// nudge so male/female lines still sound at least somewhat different.
  Future<void> speak(String text, {KaiwaGender? gender}) async {
    await _ensureInitialized();
    await _ensureVoicesResolved();
    await _tts.stop();

    final voice = switch (gender) {
      KaiwaGender.female => _femaleVoice,
      KaiwaGender.male => _maleVoice,
      null => null,
    };

    if (voice != null) {
      await _tts.clearVoice();
      await _tts.setVoice(voice);
      await _tts.setPitch(1.0);
    } else if (gender == KaiwaGender.male) {
      await _tts.clearVoice();
      await _tts.setPitch(0.85);
    } else {
      await _tts.clearVoice();
      await _tts.setPitch(1.0);
    }

    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();
}

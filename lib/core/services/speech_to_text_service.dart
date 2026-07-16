import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Wraps [stt.SpeechToText], the OS's on-device speech recognizer, for
/// Kaiwa's spoken dialogue answers. Mirrors `TtsService`'s shape (lazy
/// init, `ja-JP` locale) but for the input direction instead of output.
class SpeechToTextService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;

  /// Requests the mic permission (via the `speech_to_text` plugin's own
  /// platform check) and initializes the recognizer. Returns false if the
  /// device has no speech recognizer available or the user denies the
  /// permission — callers should fall back to typed input in that case.
  Future<bool> _ensureInitialized() async {
    if (_initialized) return true;
    _initialized = await _speech.initialize();
    return _initialized;
  }

  /// Starts listening and calls [onResult] with the recognized text once
  /// the recognizer reports a final result. Returns false immediately
  /// (without calling [onResult]) if initialization fails.
  Future<bool> listen({required void Function(String text) onResult}) async {
    final ready = await _ensureInitialized();
    if (!ready) return false;
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) onResult(result.recognizedWords);
      },
      listenOptions: stt.SpeechListenOptions(localeId: 'ja_JP'),
    );
    return true;
  }

  bool get isListening => _speech.isListening;

  Future<void> stop() => _speech.stop();
}

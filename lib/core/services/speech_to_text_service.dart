import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Wraps [stt.SpeechToText], the OS's on-device speech recognizer, for
/// Kaiwa's spoken dialogue answers. Mirrors `TtsService`'s shape (lazy
/// init, `ja-JP` locale) but for the input direction instead of output.
class SpeechToTextService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;

  /// Called once, from [listen], when the current session has definitely
  /// stopped — via a final result, a recognition error, or an explicit
  /// [stop]/[cancel] — so a caller's "listening" UI state can always be
  /// reset. Plain instance field rather than a per-call parameter passed
  /// down to [_speech]'s `onError`/`onStatus`, since [initialize] only
  /// wires those callbacks once and needs a stable place to forward to
  /// whichever session is currently active.
  void Function()? _onSessionDone;

  /// Initializes the recognizer once (idempotent) and wires its
  /// `onError`/`onStatus` callbacks to [_onSessionDone].
  ///
  /// This matters because the plugin only ever reports a recognition
  /// error (no speech detected, timeout, audio error, ...) through
  /// `onError` — never through `listen`'s own `onResult` callback. Without
  /// wiring `onError` here, a failed or silent listen attempt would never
  /// call [listen]'s `onResult`, leaving any caller that only resets its
  /// "listening" state inside `onResult` stuck forever with no way to
  /// retry.
  Future<bool> _ensureInitialized() async {
    if (_initialized) return true;
    try {
      _initialized = await _speech.initialize(
        onError: (_) => _onSessionDone?.call(),
        onStatus: (status) {
          if (status == stt.SpeechToText.doneStatus ||
              status == stt.SpeechToText.notListeningStatus) {
            _onSessionDone?.call();
          }
        },
      );
    } catch (_) {
      _initialized = false;
    }
    return _initialized;
  }

  /// Starts listening and calls [onResult] with the recognized text once
  /// the recognizer reports a final result. Calls [onDone] exactly once
  /// when the session has stopped for *any* reason (final result,
  /// recognition error, timeout, or an explicit [stop]) — callers should
  /// reset their "listening" UI state there rather than only in
  /// [onResult], since an error never reaches [onResult] at all.
  ///
  /// Returns false immediately (without calling either callback) if
  /// initialization fails, a session is already active, or the platform
  /// call itself throws.
  Future<bool> listen({
    required void Function(String text) onResult,
    required void Function() onDone,
  }) async {
    if (_speech.isListening) return false;
    final ready = await _ensureInitialized();
    if (!ready) return false;

    var doneCalled = false;
    void callDoneOnce() {
      if (doneCalled) return;
      doneCalled = true;
      onDone();
    }

    _onSessionDone = callDoneOnce;
    try {
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
            callDoneOnce();
          }
        },
        listenOptions: stt.SpeechListenOptions(localeId: 'ja_JP'),
      );
    } catch (_) {
      callDoneOnce();
      return false;
    }
    return true;
  }

  bool get isListening => _speech.isListening;

  /// Stops the active session, if any. Per the plugin's own contract this
  /// still delivers one last final result through [listen]'s `onResult` —
  /// combined with the `onDone` wiring above, a caller can always treat
  /// `stop()` as a safe way to cancel out of a stuck "listening" state.
  Future<void> stop() => _speech.stop();
}

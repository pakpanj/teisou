import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Blocks screenshots and screen recording while a screen that asks for it
/// is on top, via Android's `FLAG_SECURE` (see `MainActivity.kt`).
///
/// **Reference counted on purpose.** A screen that simply set the flag on
/// and cleared it on dispose would unlock the window too early the moment
/// two protected screens overlap — push a second one, pop it, and the first
/// is left unprotected while still showing questions. Counting means the
/// flag drops only when the last holder lets go.
///
/// Every platform call is best-effort. A screen must never fail to open, or
/// fail to close, because a window flag would not move: on a platform with
/// no such flag the calls simply do nothing.
///
/// **The two platforms protect different things, and the difference is
/// real rather than an implementation gap.**
///
/// - Android blocks screenshots *and* recording outright, via
///   `FLAG_SECURE`. Nothing is reported back, because nothing gets
///   through.
/// - iOS blocks recording and mirroring with a documented API, and blanks
///   screenshots with an undocumented one (see `AppDelegate.swift`): the
///   window's layer is moved under a secure text field's capture-exempt
///   layer, so the image comes out empty. That part is deliberately
///   fail-open — if a future iOS rearranges those internals it undoes
///   itself and leaves the screen alone — so it must not be relied on the
///   way `FLAG_SECURE` can be.
///
/// iOS also reports every screenshot gesture through
/// [onScreenshotDetected], whether or not the resulting image came out
/// blank: the system tells us the buttons were pressed, not what was
/// captured.
class SecureScreenService {
  SecureScreenService({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('teisou/secure_screen') {
    _channel.setMethodCallHandler(_handlePlatformCall);
  }

  final MethodChannel _channel;
  int _holders = 0;

  /// Called when the platform reports a screenshot gesture.
  ///
  /// Only ever fires on iOS, which reports the gesture rather than the
  /// result — so this arrives even when the captured image was blanked
  /// successfully. On Android it stays silent, because the capture is
  /// refused outright and there is nothing to report. A screen showing a
  /// notice here must expect that silence to be the protection working,
  /// not the callback failing.
  void Function()? onScreenshotDetected;

  Future<dynamic> _handlePlatformCall(MethodCall call) async {
    if (call.method == 'screenshotTaken') onScreenshotDetected?.call();
    return null;
  }

  /// Visible for tests: how many screens currently want the window secured.
  @visibleForTesting
  int get holders => _holders;

  /// Marks one more screen as needing protection, enabling the flag if this
  /// is the first.
  Future<void> acquire() async {
    _holders++;
    if (_holders == 1) await _invoke('enable');
  }

  /// Releases one screen's claim, clearing the flag once none are left.
  ///
  /// Guards against dropping below zero, so a double release (a dispose
  /// racing a manual call, say) can never leave the counter negative and
  /// wedge the flag on for the rest of the session.
  Future<void> release() async {
    if (_holders == 0) return;
    _holders--;
    if (_holders == 0) await _invoke('disable');
  }

  Future<void> _invoke(String method) async {
    try {
      await _channel.invokeMethod<bool>(method);
    } catch (error) {
      // Platform without the channel, or a window that refused the flag.
      // Nothing here can usefully recover, and the screen must still work.
      debugPrint('SecureScreenService.$method failed: $error');
    }
  }
}

final secureScreenServiceProvider = Provider<SecureScreenService>(
  (ref) => SecureScreenService(),
);

/// Mix into a screen's [ConsumerState] to keep screenshots blocked for as
/// long as that screen is alive.
///
/// The service is captured in [initState] rather than read again in
/// [dispose], so releasing cannot depend on the provider still being
/// reachable while the element is being torn down.
mixin SecureScreenMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  SecureScreenService? _secureScreen;
  void Function()? _previousListener;

  /// Override to react to a capture the platform could not prevent.
  ///
  /// Stays silent on Android, where the screenshot simply does not happen.
  /// Only iOS reaches this — see
  /// [SecureScreenService.onScreenshotDetected].
  void onScreenshotDetected() {}

  @override
  void initState() {
    super.initState();
    final service = ref.read(secureScreenServiceProvider);
    _secureScreen = service;
    // Restored rather than cleared on dispose, so a protected screen opened
    // over another one hands the listener back instead of leaving the
    // screen underneath deaf for the rest of the session.
    _previousListener = service.onScreenshotDetected;
    service.onScreenshotDetected = () {
      if (mounted) onScreenshotDetected();
    };
    service.acquire();
  }

  @override
  void dispose() {
    _secureScreen?.onScreenshotDetected = _previousListener;
    _secureScreen?.release();
    _secureScreen = null;
    _previousListener = null;
    super.dispose();
  }
}

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
/// **Android only.** iOS has no equivalent window flag — the usual trick
/// there is hiding content on `UIApplicationUserDidTakeScreenshot`, which
/// notifies *after* the capture and so cannot prevent it. Rather than
/// implement something that looks like protection but is not, iOS is left
/// unprotected and honest about it. See CLAUDE.md's iOS section: no iOS
/// build has ever been run for this project anyway.
class SecureScreenService {
  SecureScreenService({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('teisou/secure_screen');

  final MethodChannel _channel;
  int _holders = 0;

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

  @override
  void initState() {
    super.initState();
    final service = ref.read(secureScreenServiceProvider);
    _secureScreen = service;
    service.acquire();
  }

  @override
  void dispose() {
    _secureScreen?.release();
    _secureScreen = null;
    super.dispose();
  }
}

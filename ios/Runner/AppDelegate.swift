import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Held for the app's lifetime so its notification observers outlive the
  /// call that created them.
  private var secureScreen: SecureScreenController?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Via the registrar rather than reaching for the engine's messenger
    // directly: `registrar(forPlugin:)` has been stable across Flutter
    // versions for years, which matters for a file that cannot be compiled
    // from this project's development machine.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "TeisouSecureScreen") {
      let channel = FlutterMethodChannel(
        name: "teisou/secure_screen",
        binaryMessenger: registrar.messenger()
      )
      let controller = SecureScreenController(channel: channel)
      secureScreen = controller
      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "enable":
          controller.enable()
          result(true)
        case "disable":
          controller.disable()
          result(true)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
  }
}

/// The iOS half of `teisou/secure_screen`, deliberately honest about what
/// this platform can and cannot do.
///
/// **Screen recording and mirroring are genuinely blocked.** `isCaptured`
/// is true while the screen is being recorded or sent to AirPlay, and the
/// system reports every change, so covering the window keeps the quiz out
/// of the recording. That is the real counterpart to Android's
/// `FLAG_SECURE`, built from a plain `UIView` covering the window — no
/// layer surgery, nothing that can crash.
///
/// **Screenshots are reported, not blanked.** An earlier version of this
/// class also tried to blank the screenshot image itself, by moving the
/// window's own `CALayer` underneath a secure `UITextField`'s
/// capture-exempt layer — the trick banking apps use, but applied to the
/// whole window rather than to one sensitive subview. That is much riskier
/// than the usual version of the trick: a `UIWindow`'s backing layer is
/// treated specially by the system compositor, and real users hit a crash
/// right after finishing the Bab gate quiz on iOS with it in place. A first
/// fix tried deferring the teardown to dodge a race with the exit
/// transition; the crash was still reported afterwards. With no iOS device
/// or crash log reachable from this environment to narrow it down further,
/// removing the layer reparenting entirely is the responsible call — a
/// screenshot that shows real content is a far smaller problem than an app
/// that crashes right after a learner passes an exam. If this is ever
/// revisited, the safer version of the technique embeds the *sensitive
/// content view* inside the secure field's own layer tree instead of
/// moving the window's layer into it.
///
/// `userDidTakeScreenshotNotification` still fires and is still reported
/// through [onScreenshotDetected] on the Dart side, so the quiz's "a
/// screenshot was taken" notice keeps working even though the image itself
/// is no longer blanked.
///
/// Lives in AppDelegate.swift rather than its own file on purpose — a new
/// Swift file must be added to the Xcode target in `project.pbxproj`, and
/// hand-editing that from outside Xcode is its own failure mode.
private final class SecureScreenController {
  private let channel: FlutterMethodChannel
  private var observers: [NSObjectProtocol] = []
  private var cover: UIView?

  init(channel: FlutterMethodChannel) {
    self.channel = channel
  }

  /// Idempotent, matching the reference-counted Dart service: a second
  /// `enable` while already active must not stack another set of observers
  /// that a single `disable` would then fail to remove.
  func enable() {
    guard observers.isEmpty else { return }

    let center = NotificationCenter.default
    observers.append(
      center.addObserver(
        forName: UIScreen.capturedDidChangeNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        self?.applyCaptureState()
      }
    )
    observers.append(
      center.addObserver(
        forName: UIApplication.userDidTakeScreenshotNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        self?.channel.invokeMethod("screenshotTaken", arguments: nil)
      }
    )

    // Recording may already have been running before the quiz opened.
    applyCaptureState()
  }

  func disable() {
    let center = NotificationCenter.default
    observers.forEach { center.removeObserver($0) }
    observers.removeAll()
    removeCover()
  }

  private func applyCaptureState() {
    if isCaptured() {
      addCover()
    } else {
      removeCover()
    }
  }

  private func keyWindow() -> UIWindow? {
    return UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
  }

  private func isCaptured() -> Bool {
    return keyWindow()?.screen.isCaptured ?? false
  }

  private func addCover() {
    guard cover == nil, let window = keyWindow() else { return }
    let view = UIView(frame: window.bounds)
    view.backgroundColor = .black
    view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    window.addSubview(view)
    cover = view
  }

  private func removeCover() {
    cover?.removeFromSuperview()
    cover = nil
  }
}

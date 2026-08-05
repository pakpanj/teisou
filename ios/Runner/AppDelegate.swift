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
/// `FLAG_SECURE`.
///
/// **Screenshots come out blank, by borrowing what UIKit already does to
/// password fields.** iOS has no window flag for screenshots, so this uses
/// the technique banking apps use: a `UITextField` with `isSecureTextEntry`
/// owns a layer the system deliberately omits from screen captures, and the
/// window's own layer is moved underneath it. The screen still renders and
/// still responds normally — only the captured image comes out empty.
///
/// This moves **layers, not views**. Touch handling walks the view
/// hierarchy, which is left exactly as it was, so input cannot break the
/// way it could if the Flutter view itself were reparented.
///
/// It leans on an undocumented UIKit layer arrangement, so every step is
/// guarded and the whole thing is optional: if the secure layer cannot be
/// found — a future iOS changing its internals, most likely — it undoes
/// what it did and leaves the screen exactly as it found it. Protection
/// then degrades to recording-blocking plus after-the-fact reporting rather
/// than breaking the app. **Not verified on a device: this project has
/// never been built for iOS, so treat the blanking as unproven until
/// someone runs it on real hardware.**
///
/// `userDidTakeScreenshotNotification` still fires either way — iOS reports
/// the gesture, not whether the image had anything in it — so the quiz's
/// notice appears whether or not the capture came out blank.
///
/// Lives in AppDelegate.swift rather than its own file on purpose — a new
/// Swift file must be added to the Xcode target in `project.pbxproj`, and
/// hand-editing that from outside Xcode is its own failure mode.
private final class SecureScreenController {
  private let channel: FlutterMethodChannel
  private var observers: [NSObjectProtocol] = []
  private var cover: UIView?

  /// Retained for as long as the blanking is in force: dropping the field
  /// would take its secure layer — and the window's layer with it — away.
  private var secureField: UITextField?
  private var protectedWindow: UIWindow?
  private var originalWindowSuperlayer: CALayer?

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
    startBlankingScreenshots()
  }

  func disable() {
    let center = NotificationCenter.default
    observers.forEach { center.removeObserver($0) }
    observers.removeAll()
    removeCover()
    stopBlankingScreenshots()
  }

  /// Moves the window's layer under a secure text field's capture-exempt
  /// layer. Every failure path restores what it touched and returns, so the
  /// worst outcome is no screenshot protection rather than a broken screen.
  private func startBlankingScreenshots() {
    guard secureField == nil, let window = keyWindow() else { return }

    let field = UITextField()
    field.isSecureTextEntry = true
    // Purely a carrier for its layer: it must never take a touch or draw
    // anything over the quiz.
    field.isUserInteractionEnabled = false
    field.backgroundColor = .clear
    field.frame = window.bounds
    window.addSubview(field)
    // The secure layer is created during layout, so it does not exist yet
    // on a field that has only just been added.
    window.layoutIfNeeded()

    guard let host = window.layer.superlayer,
          let secureLayer = field.layer.sublayers?.last else {
      // UIKit did not lay this out the way this technique expects.
      field.removeFromSuperview()
      return
    }

    host.addSublayer(field.layer)
    secureLayer.addSublayer(window.layer)

    secureField = field
    protectedWindow = window
    originalWindowSuperlayer = host
  }

  private func stopBlankingScreenshots() {
    guard let field = secureField else { return }

    // Put the window's layer back where it was before unwinding the field,
    // so the screen is never left with its layer parented to something that
    // is about to be removed.
    if let window = protectedWindow, let host = originalWindowSuperlayer {
      host.addSublayer(window.layer)
    }
    field.layer.removeFromSuperlayer()
    field.removeFromSuperview()

    secureField = nil
    protectedWindow = nil
    originalWindowSuperlayer = nil
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

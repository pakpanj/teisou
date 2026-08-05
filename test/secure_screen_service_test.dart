import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/services/secure_screen_service.dart';

/// Screenshot blocking during the Bab gate quiz.
///
/// The failure that matters most here is not "the flag never turned on" —
/// that is visible the first time anyone tries. It is the flag being left
/// *on* after the quiz closes, which silently makes the rest of the app
/// uncapturable and would most likely be reported as an unrelated bug weeks
/// later. Every test below is really about the counter reaching zero.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('teisou/secure_screen');
  late List<String> calls;

  setUp(() {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return true;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('the first acquire enables and the last release disables', () async {
    final service = SecureScreenService(channel: channel);

    await service.acquire();
    expect(calls, ['enable']);

    await service.release();
    expect(calls, ['enable', 'disable']);
    expect(service.holders, 0);
  });

  test('overlapping screens keep the flag on until the last one leaves',
      () async {
    final service = SecureScreenService(channel: channel);

    await service.acquire();
    await service.acquire();
    expect(calls, ['enable'], reason: 'the second holder must not re-enable');

    await service.release();
    expect(calls, ['enable'],
        reason: 'one screen leaving must not unlock the other');

    await service.release();
    expect(calls, ['enable', 'disable']);
  });

  test('a release with nothing held cannot push the count negative',
      () async {
    // A double dispose, or a manual release racing the mixin's, must not
    // leave the counter at -1 — the next acquire would then never reach 1
    // and the flag would stay off for the rest of the session.
    final service = SecureScreenService(channel: channel);

    await service.release();
    expect(calls, isEmpty);
    expect(service.holders, 0);

    await service.acquire();
    expect(calls, ['enable'], reason: 'protection still works afterwards');
  });

  test('a platform that rejects the call does not throw at the caller',
      () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'unavailable');
    });
    final service = SecureScreenService(channel: channel);

    // A screen must open and close normally on a platform with no such
    // flag; failing to secure is not a reason to fail to render.
    await expectLater(service.acquire(), completes);
    await expectLater(service.release(), completes);
    expect(service.holders, 0);
  });

  test('a platform screenshot report reaches the listener', () async {
    // iOS cannot block the capture, so it tells Dart afterwards. Android
    // never sends this, which is why the listener must be optional rather
    // than something screens are required to handle.
    final service = SecureScreenService(channel: channel);
    var reported = 0;
    service.onScreenshotDetected = () => reported++;

    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(const MethodCall('screenshotTaken')),
      (_) {},
    );

    expect(reported, 1);
  });

  test('an unknown platform call is ignored rather than thrown at', () async {
    final service = SecureScreenService(channel: channel);
    var reported = 0;
    service.onScreenshotDetected = () => reported++;

    await expectLater(
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        channel.name,
        channel.codec.encodeMethodCall(const MethodCall('somethingElse')),
        (_) {},
      ),
      completes,
    );
    expect(reported, 0);
  });

  testWidgets('a screenshot report reaches the screen that is showing',
      (tester) async {
    final service = SecureScreenService(channel: channel);
    final container = ProviderContainer(
      overrides: [secureScreenServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: _SecureProbe(),
        ),
      ),
    );
    service.onScreenshotDetected?.call();
    expect(_SecureProbeState.screenshotReports, 1);

    // Once the screen is gone the listener must go with it, or a later
    // report would fire against a dead element.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.shrink(),
        ),
      ),
    );
    service.onScreenshotDetected?.call();
    expect(_SecureProbeState.screenshotReports, 1,
        reason: 'a disposed screen must stop hearing reports');
  });

  testWidgets('the mixin secures for exactly the lifetime of its screen',
      (tester) async {
    final service = SecureScreenService(channel: channel);
    final container = ProviderContainer(
      overrides: [secureScreenServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: _SecureProbe(),
        ),
      ),
    );
    expect(calls, ['enable']);
    expect(service.holders, 1);

    // Replacing the screen is how the real quiz exits, via
    // AppNavigator.replaceFadeScale.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump();

    expect(calls, ['enable', 'disable'],
        reason: 'leaving the quiz must unlock the window again');
    expect(service.holders, 0);
  });
}

class _SecureProbe extends ConsumerStatefulWidget {
  const _SecureProbe();

  @override
  ConsumerState<_SecureProbe> createState() => _SecureProbeState();
}

class _SecureProbeState extends ConsumerState<_SecureProbe>
    with SecureScreenMixin {
  static int screenshotReports = 0;

  @override
  void initState() {
    screenshotReports = 0;
    super.initState();
  }

  @override
  void onScreenshotDetected() => screenshotReports++;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

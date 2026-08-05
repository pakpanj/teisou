import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/navigation/tts_stop_observer.dart';

/// Eleven screens read Japanese aloud through one app-wide TTS engine,
/// and none of them used to stop it — so a sentence started on a detail
/// screen kept playing over the home screen, over the next chapter, and
/// over a Choukai listening-exam result page.
///
/// The fix lives at the navigator instead of in each screen (four of the
/// eleven are `ConsumerWidget`s with no `dispose()`), which is exactly
/// what makes it worth pinning: nothing on any individual screen would
/// fail if this observer stopped being wired up.
void main() {
  late int stops;

  Widget appWith(Widget home) => MaterialApp(
        navigatorObservers: [TtsStopObserver(() => stops++)],
        home: home,
      );

  setUp(() => stops = 0);

  testWidgets('speech stops when the learner navigates forward and back',
      (tester) async {
    await tester.pumpWidget(appWith(
      Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const Text('detail')),
          ),
          child: const Text('open'),
        ),
      ),
    ));
    // The home route's own push happens before any of this.
    stops = 0;

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(stops, 1, reason: 'pushing away from a speaking screen');

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(stops, 2, reason: 'popping back from a speaking screen');
  });

  testWidgets('speech stops when a route is replaced', (tester) async {
    // ChoukaiExamScreen ends with AppNavigator.replaceFadeScale, so a
    // learner who answers the last question while the clip is still
    // playing would otherwise hear it over the result screen.
    await tester.pumpWidget(appWith(
      Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const Text('result')),
          ),
          child: const Text('finish'),
        ),
      ),
    ));
    stops = 0;

    await tester.tap(find.text('finish'));
    await tester.pumpAndSettle();

    expect(find.text('result'), findsOneWidget);
    expect(stops, greaterThanOrEqualTo(1));
  });

  testWidgets('speech stops when a route is removed', (tester) async {
    late Route<void> pushed;
    await tester.pumpWidget(appWith(
      Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(
            pushed = MaterialPageRoute<void>(builder: (_) => const Text('mid')),
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    stops = 0;

    tester.state<NavigatorState>(find.byType(Navigator)).removeRoute(pushed);
    await tester.pumpAndSettle();
    expect(stops, 1);
  });
}

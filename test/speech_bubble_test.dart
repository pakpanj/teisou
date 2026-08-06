import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/theme/app_theme.dart';
import 'package:kana_master/core/widgets/mascot_guide_bubble.dart';
import 'package:kana_master/core/widgets/mascot_widget.dart';
import 'package:kana_master/core/widgets/speech_bubble.dart';

/// The mascot's speech bubble.
///
/// Worth a test because of how its first version failed. The tail's
/// position was clamped between a minimum and a maximum, and on a
/// single-line bubble the maximum came out *below* the minimum — which
/// `clamp` rejects. A painter that throws paints nothing and takes its
/// child with it, so the bubble vanished from every screen at once with no
/// visible error and nothing in logcat. A wrong number would have been
/// obvious; total silence was not.
void main() {
  Widget wrap(Widget child) => ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Padding(padding: const EdgeInsets.all(20), child: child),
          ),
        ),
      );

  testWidgets('a one-line message still renders', (tester) async {
    // The exact case that broke: short enough that the tail margins do not
    // fit, which is most of the guide messages in the app.
    await tester.pumpWidget(wrap(const MascotGuideBubble(
      mood: MascotMood.happy,
      message: 'Pilih satu bab untuk mulai belajar.',
    )));
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(find.text('Pilih satu bab untuk mulai belajar.'), findsOneWidget);
  });

  testWidgets('a long multi-line message still renders', (tester) async {
    await tester.pumpWidget(wrap(const MascotGuideBubble(
      mood: MascotMood.excited,
      message: 'Kerja bagus! Kamu sudah menyelesaikan bab ini dengan sangat '
          'baik, jadi ayo lanjut ke bab berikutnya dan terus berlatih '
          'setiap hari sedikit demi sedikit.',
    )));
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(find.byType(SpeechBubble), findsOneWidget);
  });

  testWidgets('a bubble squeezed to almost nothing does not throw',
      (tester) async {
    // Guards the boundary directly rather than through the mascot, so the
    // painter stays safe even if the bubble is reused somewhere tighter.
    await tester.pumpWidget(wrap(
      SizedBox(
        height: 12,
        child: SpeechBubble(
          color: const Color(0xFFFFFFFF),
          padding: EdgeInsets.zero,
          child: const SizedBox.shrink(),
        ),
      ),
    ));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('the message is visible once the entrance settles',
      (tester) async {
    // The bubble scales in from zero, so "renders" has to mean after the
    // animation, not during it — otherwise a bubble stuck at scale 0 would
    // still pass.
    await tester.pumpWidget(wrap(const MascotGuideBubble(
      mood: MascotMood.proud,
      message: 'Halo!',
    )));
    // Not pumpAndSettle: the mascot's idle loop repeats forever, so
    // nothing involving it ever settles and pumpAndSettle times out.
    // Pumping past the entrance duration is what "finished" means here.
    await tester.pump(const Duration(milliseconds: 600));

    final scale = tester.widget<ScaleTransition>(
      find.byType(ScaleTransition).first,
    );
    expect(scale.scale.value, closeTo(1, 0.001),
        reason: 'a bubble left mid-animation is an invisible bubble');
  });
}

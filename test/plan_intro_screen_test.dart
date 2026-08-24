import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kana_master/features/onboarding/plan_intro_screen.dart';

/// The Free-vs-Premium screen shown once per device, right after the
/// age question — see `main.dart`'s `_PlanIntroGate`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  // The default 800x600 test surface is shorter than this screen's
  // content (mascot + two plan cards + security note + button), which
  // left the "Lanjutkan" button laid out below the visible viewport —
  // real, since a SingleChildScrollView still sizes its child to full
  // content height regardless of viewport. A realistic phone-sized
  // surface is what actually exercises the button a real device shows
  // without scrolling.
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: PlanIntroFlow())),
    );
    await tester.pump();
  }

  // Not pumpAndSettle: MascotWidget's idle pose animation loops
  // continuously by design, so "settled" never actually arrives. A
  // single pump(300ms+) also isn't enough — PageController's animated
  // scroll needs several frame ticks to actually reach the target page,
  // not just one big time jump — so this steps the clock in several
  // smaller frames instead, well past the page-change animation's own
  // 300ms.
  Future<void> settlePageChange(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('opens on the welcome page with both plans summarised', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Selamat datang di Teisou!'), findsOneWidget);
    expect(find.text('FREE PLAN'), findsOneWidget);
    expect(find.text('PREMIUM PLAN'), findsOneWidget);
    expect(find.text('Lanjutkan'), findsOneWidget);
    // The compare page's own content is not built into view yet — this
    // is a PageView, not both pages stacked.
    expect(find.text('Mulai Premium'), findsNothing);
  });

  testWidgets('"Lanjutkan" advances to the comparison + purchase page', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text('Lanjutkan'));
    await settlePageChange(tester);

    expect(find.text('Pilih paket terbaik untuk kebutuhanmu'), findsOneWidget);
    // The picker opens on Premium, so the single dynamic CTA button reads
    // "Mulai Premium" — "Gunakan Free Plan" only appears once the picker
    // is switched to Free.
    expect(find.text('Mulai Premium'), findsOneWidget);
    expect(find.text('Gunakan Free Plan'), findsNothing);
    // The skip button was removed outright — the picker below the back
    // arrow is the only way to move between plans now.
    expect(find.text('Lewati'), findsNothing);
  });

  testWidgets('switching the picker to Free swaps the CTA to "Gunakan '
      'Free Plan"', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Lanjutkan'));
    await settlePageChange(tester);

    await tester.tap(find.text('FREE PLAN'));
    await tester.pump();

    expect(find.text('Gunakan Free Plan'), findsOneWidget);
    expect(find.text('Mulai Premium'), findsNothing);
  });

  // Marking the intro seen now writes to the signed-in account's Firestore
  // doc (see `PlanIntroState`/`ProgressRepository.markPlanIntroSeen`) —
  // this project has no Firestore/Auth test double, so that write can't
  // be exercised here the way the old SharedPreferences-backed flag was.
  // What *can* be verified without one: `_finish()` guards on
  // `appStartupProvider` actually having a signed-in user first, so
  // tapping through with none (this bare `ProviderScope`, same as every
  // other test in this file) is a graceful no-op rather than a crash.
  testWidgets('"Gunakan Free Plan" completes without throwing when no '
      'account is signed in', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Lanjutkan'));
    await settlePageChange(tester);
    await tester.tap(find.text('FREE PLAN'));
    await tester.pump();
    await tester.tap(find.text('Gunakan Free Plan'));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('the comparison table uses Teisou\'s real features, not a '
      'clan/tournament template', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Lanjutkan'));
    await settlePageChange(tester);

    expect(find.text('Modul Kanji'), findsOneWidget);
    expect(find.text('Modul Bunpou'), findsOneWidget);
    expect(find.text('Partikel, Kaiwa, Choukai'), findsOneWidget);
    expect(find.text('Skin Battle Card'), findsOneWidget);
    // Nothing from the reference mockup's clan/tournament content, which
    // this app has neither of.
    expect(find.textContaining('Turnamen'), findsNothing);
    expect(find.textContaining('Clan'), findsNothing);
    expect(find.textContaining('Custom Branding'), findsNothing);
  });
}

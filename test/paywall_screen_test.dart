import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/constants/iap_products.dart';
import 'package:kana_master/features/paywall/paywall_screen.dart';

void main() {
  testWidgets('PaywallScreen shows the benefits and a way through', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: PaywallScreen(moduleId: 'kanji', moduleTitle: 'Kanji N5'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Buka Semua Modul!'), findsOneWidget);
    expect(find.text('⭐ Skin Battle Card eksklusif'), findsOneWidget);
    expect(find.text('📚 Materi pembelajaran lengkap'), findsOneWidget);
    expect(find.text('📝 Latihan soal premium'), findsOneWidget);
    expect(find.text('🚫 Bebas iklan'), findsOneWidget);
    // The buy button follows the master switch: offering a purchase that
    // cannot complete reads as a broken app, not as a shop that has not
    // opened yet.
    expect(
      find.textContaining('Upgrade Premium'),
      IapProducts.purchasesEnabled ? findsOneWidget : findsNothing,
    );
    // The rewarded ad is the one thing that must survive either way —
    // without it, a gated module is a dead end while nothing is on sale.
    expect(find.text('Nonton Iklan untuk Preview 24 Jam'), findsOneWidget);
  });
}

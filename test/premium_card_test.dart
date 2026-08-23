import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/providers.dart';
import 'package:kana_master/data/models/subscription.dart';
import 'package:kana_master/features/profile/widgets/premium_card.dart';

/// Profile used to have no real Premium entry point at all — just a
/// small tier pill next to the display name — so this card is the
/// first place a free learner can actually buy Premium from Profile,
/// and the first place a subscriber sees anything acknowledging it.
void main() {
  Future<void> pump(WidgetTester tester, Subscription subscription) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionProvider.overrideWith((ref) => Stream.value(subscription)),
        ],
        child: const MaterialApp(home: Scaffold(body: PremiumCard())),
      ),
    );
  }

  testWidgets('a free learner sees a real offer with a buy button, not '
      'just a badge', (tester) async {
    await pump(tester, Subscription.free());
    await tester.pump();

    expect(find.text('Upgrade ke Premium'), findsOneWidget);
    expect(find.textContaining('Upgrade Premium'), findsOneWidget);
    // Nothing claiming they already have it.
    expect(find.text('Kamu Premium! 🎉'), findsNothing);
  });

  testWidgets('a Premium subscriber sees a thank-you, not another sales '
      'pitch', (tester) async {
    await pump(
      tester,
      Subscription(tier: SubscriptionTier.premium),
    );
    await tester.pump();

    expect(find.text('Kamu Premium! 🎉'), findsOneWidget);
    expect(find.text('Upgrade ke Premium'), findsNothing);
    expect(find.textContaining('Upgrade Premium'), findsNothing);
  });
}

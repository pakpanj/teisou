import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/localization/app_strings.dart';
import 'package:kana_master/data/models/app_language.dart';
import 'package:kana_master/data/models/battle_match.dart';
import 'package:kana_master/data/models/card_game_rank.dart';
import 'package:kana_master/data/models/turn_order_entry.dart';
import 'package:kana_master/features/battle/widgets/star_result_card.dart';

/// The star change is the only thing a player is ever told about their
/// climb, and every one of these states is reachable in a normal match —
/// including two that look like nothing happened (a draw, and a
/// protected loss) and would read as a bug if left blank.
void main() {
  const s = AppStrings(AppLanguage.indonesian);

  BattleMatch match({
    bool ranked = true,
    Map<String, BattleStarResult> stars = const {},
  }) {
    return BattleMatch(
      id: 'm1',
      players: const ['me', 'them'],
      status: BattleMatchStatus.finished,
      currentRound: 20,
      turnOrder: const <TurnOrderEntry>[],
      officialScore: const {'me': 5, 'them': 0},
      result: 'me',
      rankedMatch: ranked,
      starResult: stars,
    );
  }

  BattleStarResult star({
    required int delta,
    CardGameTier tier = CardGameTier.bronze,
    int division = 5,
    int stars = 1,
    bool divisionChanged = false,
    bool tierChanged = false,
    bool lossAbsorbed = false,
  }) {
    return BattleStarResult(
      delta: delta,
      tier: tier,
      division: division,
      stars: stars,
      winStreak: 0,
      divisionChanged: divisionChanged,
      tierChanged: tierChanged,
      lossAbsorbed: lossAbsorbed,
    );
  }

  Future<void> pump(WidgetTester tester, BattleMatch m) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StarResultCard(match: m, myUid: 'me', strings: s),
        ),
      ),
    );
  }

  testWidgets('waits while the Cloud Function has not answered yet', (
    tester,
  ) async {
    await pump(tester, match());
    expect(find.text('Menghitung bintang...'), findsOneWidget);
  });

  testWidgets('stops waiting rather than spinning forever', (tester) async {
    // A failed function or a device that went offline between finishing
    // and reading would otherwise leave this counting for good.
    await pump(tester, match());
    await tester.pump(const Duration(seconds: 13));
    expect(find.text('Menghitung bintang...'), findsNothing);
    expect(
      find.textContaining('Bintangmu sedang diperbarui'),
      findsOneWidget,
    );
  });

  testWidgets('a friendly match says stars do not move, rather than '
      'leaving a gap', (tester) async {
    await pump(tester, match(ranked: false));
    expect(find.textContaining('Pertandingan santai'), findsOneWidget);
    // ...and never waits for a delta that is never coming.
    expect(find.text('Menghitung bintang...'), findsNothing);
  });

  testWidgets('shows the gain and the standing it left', (tester) async {
    await pump(
      tester,
      match(stars: {'me': star(delta: 1, stars: 2)}),
    );
    expect(find.text('+1 bintang'), findsOneWidget);
    expect(find.textContaining('Bronze V'), findsOneWidget);
    expect(find.textContaining('2/3 bintang'), findsOneWidget);
  });

  testWidgets('a streak win shows +2, not +1', (tester) async {
    await pump(tester, match(stars: {'me': star(delta: 2)}));
    expect(find.text('+2 bintang'), findsOneWidget);
  });

  testWidgets('a tier promotion is celebrated as a tier, not a division', (
    tester,
  ) async {
    await pump(
      tester,
      match(
        stars: {
          'me': star(
            delta: 1,
            tier: CardGameTier.silver,
            stars: 0,
            divisionChanged: true,
            tierChanged: true,
          ),
        },
      ),
    );
    expect(find.textContaining('Naik tingkat'), findsOneWidget);
    expect(find.textContaining('Naik divisi'), findsNothing);
  });

  testWidgets('a division promotion is reported without claiming a tier', (
    tester,
  ) async {
    await pump(
      tester,
      match(
        stars: {'me': star(delta: 1, division: 4, stars: 0, divisionChanged: true)},
      ),
    );
    expect(find.textContaining('Naik divisi — Bronze IV'), findsOneWidget);
  });

  testWidgets('a loss that cost nothing says so, and says why', (
    tester,
  ) async {
    // The case most likely to be read as broken: the player lost, and
    // the number did not move.
    await pump(
      tester,
      match(stars: {'me': star(delta: 0, stars: 0, lossAbsorbed: true)}),
    );
    expect(find.text('Bintang tidak berubah'), findsOneWidget);
    expect(find.textContaining('tidak kehilangan bintang'), findsOneWidget);
  });

  testWidgets('a loss above Silver shows the star actually lost', (
    tester,
  ) async {
    await pump(
      tester,
      match(
        stars: {'me': star(delta: -1, tier: CardGameTier.gold, stars: 2)},
      ),
    );
    expect(find.text('-1 bintang'), findsOneWidget);
    // The protection note belongs only where protection applies.
    expect(find.textContaining('tidak kehilangan bintang'), findsNothing);
  });
}

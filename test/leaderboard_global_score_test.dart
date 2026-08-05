import 'package:flutter_test/flutter_test.dart';
import 'package:kana_master/core/localization/app_strings.dart';
import 'package:kana_master/data/models/app_language.dart';
import 'package:kana_master/data/models/leaderboard_entry.dart';
import 'package:kana_master/features/leaderboard/leaderboard_screen.dart';

/// Covers the leaderboard's single global-score metric: that its total is
/// genuinely the four category records added together (the whole premise of
/// the ranking), that "never attempted" stays distinguishable from a real
/// zero, and that both the total and its breakdown follow the language
/// toggle — the gap the older per-metric version of this test guarded,
/// back when two labels were hardcoded English literals in an
/// Indonesian-first app.
void main() {
  const id = AppStrings(AppLanguage.indonesian);
  const en = AppStrings(AppLanguage.english);

  LeaderboardEntry entry({
    double kana = 0,
    int kanaCount = 0,
    double dokkai = 0,
    int dokkaiCount = 0,
    double choukai = 0,
    int choukaiCount = 0,
    double kanjiCombo = 0,
    int kanjiComboCount = 0,
  }) =>
      LeaderboardEntry(
        uid: 'u1',
        displayName: 'Budi',
        totalMastered: 0,
        examHighScore: 0,
        kanaRecordAvg: kana,
        kanaRecordCount: kanaCount,
        dokkaiRecordAvg: dokkai,
        dokkaiRecordCount: dokkaiCount,
        choukaiRecordAvg: choukai,
        choukaiRecordCount: choukaiCount,
        kanjiComboRecordAvg: kanjiCombo,
        kanjiComboRecordCount: kanjiComboCount,
        updatedAt: DateTime(2026, 8, 3),
      );

  test('global score sums all four category records', () {
    final e = entry(
      kana: 80,
      kanaCount: 2,
      dokkai: 70,
      dokkaiCount: 1,
      kanjiCombo: 60,
      kanjiComboCount: 3,
    );
    // Choukai never attempted contributes 0 rather than dragging the total
    // down as a divisor would — it currently ships with no content at all.
    expect(e.computedGlobalScore, 210);
    expect(globalScoreLabel(e, id), '210 poin');
    expect(globalScoreLabel(e, en), '210 pts');
  });

  test('a user who has attempted nothing reads as "no record", not zero', () {
    final e = entry();
    expect(e.hasAnyRecord, isFalse);
    expect(globalScoreLabel(e, id), 'Belum ada');
    expect(globalScoreLabel(e, en), 'No record yet');
    expect(globalScoreBreakdown(e, id), isEmpty);
  });

  test('a genuine zero still ranks as a scored entry', () {
    // Attempted once and scored 0% — must not collapse into "Belum ada",
    // which is what a bare `computedGlobalScore == 0` check would do.
    final e = entry(kanaCount: 1);
    expect(e.hasAnyRecord, isTrue);
    expect(globalScoreLabel(e, id), '0 poin');
  });

  test('breakdown lists all four parts and follows the language toggle', () {
    final e = entry(kana: 80, kanaCount: 1, dokkai: 70, dokkaiCount: 1);
    expect(globalScoreBreakdown(e, id), 'Kana 80 · Dokkai 70 · Choukai 0 · Kanji 0');
    expect(globalScoreBreakdown(e, en), 'Kana 80 · Dokkai 70 · Choukai 0 · Kanji 0');
  });

  test('an absent stored sort key is distinguishable from a stored zero', () {
    // Firestore's orderBy omits docs missing the sorted field, so
    // backfillGlobalScore keys off exactly this distinction — a user whose
    // real score is 0 but whose doc never carried the field must still be
    // seen as needing a write, not as "already in sync at 0".
    final absent = LeaderboardEntry.fromMap('u1', {'displayName': 'Budi'});
    expect(absent.globalScore, isNull);
    expect(absent.computedGlobalScore, 0);

    final storedZero = LeaderboardEntry.fromMap(
      'u1',
      {'displayName': 'Budi', 'globalScore': 0},
    );
    expect(storedZero.globalScore, 0);
  });

  test('tab labels are non-empty in both languages', () {
    for (final strings in [id, en]) {
      expect(strings.tabGlobalScore, isNotEmpty);
      expect(strings.tabClan, isNotEmpty);
    }
    expect(id.tabGlobalScore, 'Skor Global');
    expect(en.tabGlobalScore, 'Global Score');
  });
}

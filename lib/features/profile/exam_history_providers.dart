import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/providers.dart';
import '../../data/models/exam_mode.dart';
import '../../data/models/exam_result.dart';
import '../../data/models/simple_exam_result.dart';

/// One row for the full "Riwayat Ujian" screen — a category-labelled,
/// already-localized view over either an [ExamResult] (kana) or a
/// [SimpleExamResult] (Dokkai/Choukai/Kanji-Kombinasi), since those two
/// source types don't share a base class and the history screen needs to
/// render all four exam categories in one merged, chronologically-sorted
/// list.
class UnifiedExamHistoryEntry {
  final String label;
  final int score;
  final int total;
  final DateTime completedAt;

  UnifiedExamHistoryEntry({
    required this.label,
    required this.score,
    required this.total,
    required this.completedAt,
  });

  double get percentage => total == 0 ? 0 : (score / total) * 100;
}

String kanaModeLabel(ExamMode mode, AppStrings s) {
  switch (mode) {
    case ExamMode.hiragana:
      return s.examHiraganaTitle;
    case ExamMode.katakana:
      return s.examKatakanaTitle;
    case ExamMode.mixed:
      return s.examMixedTitle;
  }
}

/// Merges every source list into one newest-first list of at most [limit]
/// entries. Deliberately a pure function (no Firestore/Riverpod
/// dependency) so the merge-and-sort logic can be unit tested with plain
/// constructed lists instead of mocking four Firestore collections.
List<UnifiedExamHistoryEntry> mergeExamHistory({
  required List<ExamResult> kana,
  required List<SimpleExamResult> dokkai,
  required List<SimpleExamResult> choukai,
  required List<SimpleExamResult> kanjiCombo,
  required AppStrings s,
  int limit = 30,
}) {
  final entries = <UnifiedExamHistoryEntry>[
    for (final r in kana)
      UnifiedExamHistoryEntry(
        label: kanaModeLabel(r.mode, s),
        score: r.score,
        total: r.total,
        completedAt: r.completedAt,
      ),
    for (final r in dokkai)
      UnifiedExamHistoryEntry(
        label: '${s.examCategoryDokkai} ${r.jlptLevel}',
        score: r.score,
        total: r.total,
        completedAt: r.completedAt,
      ),
    for (final r in choukai)
      UnifiedExamHistoryEntry(
        label: '${s.examCategoryChoukai} ${r.jlptLevel}',
        score: r.score,
        total: r.total,
        completedAt: r.completedAt,
      ),
    // itemId is 'combo_{level}' or 'single_{level}' — see
    // KanjiComboExamScreen._onComplete, the only writer of this
    // collection — so the combination-vs-single distinction (not stored
    // as its own field) is recovered from that prefix.
    for (final r in kanjiCombo)
      UnifiedExamHistoryEntry(
        label: '${r.itemId.startsWith('combo_') ? s.examCategoryKanjiComboCombination : s.examCategoryKanjiComboSingle} ${r.jlptLevel}',
        score: r.score,
        total: r.total,
        completedAt: r.completedAt,
      ),
  ];
  entries.sort((a, b) => b.completedAt.compareTo(a.completedAt));
  return entries.length > limit ? entries.sublist(0, limit) : entries;
}

/// Fetches all four exam-category collections once (not four live
/// listeners — same one-shot-on-open-and-pull-to-refresh reasoning as the
/// Clan ranking's `getMembersOnce`) and merges them via [mergeExamHistory].
/// `autoDispose` so a fresh fetch happens every time the history screen is
/// reopened, and [ExamHistoryScreen]'s `AppRefreshIndicator` drives manual
/// refresh via `ref.refresh(fullExamHistoryProvider.future)`.
final fullExamHistoryProvider =
    FutureProvider.autoDispose<List<UnifiedExamHistoryEntry>>((ref) async {
  final user = await ref.watch(appStartupProvider.future);
  final s = ref.watch(appStringsProvider);
  final uid = user.uid;

  // Start all four fetches concurrently (none is awaited until after every
  // future is created), then await each in turn — avoids Future.wait's
  // type-inference footgun when the futures' element types differ
  // (ExamResult vs. SimpleExamResult) without losing concurrency.
  final kanaFuture = ref.watch(examRepositoryProvider).getRecentHistory(uid);
  final dokkaiFuture =
      ref.watch(dokkaiExamHistoryRepositoryProvider).getRecent(uid);
  final choukaiFuture =
      ref.watch(choukaiExamHistoryRepositoryProvider).getRecent(uid);
  final kanjiComboFuture =
      ref.watch(kanjiComboExamHistoryRepositoryProvider).getRecent(uid);

  return mergeExamHistory(
    kana: await kanaFuture,
    dokkai: await dokkaiFuture,
    choukai: await choukaiFuture,
    kanjiCombo: await kanjiComboFuture,
    s: s,
  );
});

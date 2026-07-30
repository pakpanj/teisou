import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'exam_history_providers.dart';

/// Top 3 of [fullExamHistoryProvider]'s merged, newest-first list — so the
/// "3 terakhir" preview on ProfileScreen reflects the most recent attempt
/// across all four exam categories (Kana/Dokkai/Choukai/Kanji-Kombinasi),
/// not just Kana. Was previously scoped to kana-only via
/// `ExamRepository.watchRecentHistory`, which meant this section stayed
/// empty forever for a user whose only attempts were Dokkai/Choukai/
/// Kanji-Kombinasi — see the "riwayat ujian tidak menampilkan apa apa"
/// bug report this fixed.
final recentExamHistoryProvider =
    Provider<AsyncValue<List<UnifiedExamHistoryEntry>>>((ref) {
  final full = ref.watch(fullExamHistoryProvider);
  return full.whenData((list) => list.take(3).toList());
});

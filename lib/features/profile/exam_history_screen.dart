import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_refresh_indicator.dart';
import 'exam_history_providers.dart';
import 'widgets/exam_history_empty_illustration.dart';
import 'widgets/exam_history_tile.dart';

/// Full "Riwayat Ujian" list — merges and shows the most recent attempts
/// across all four exam categories (Kana, Dokkai, Choukai,
/// Kanji-Kombinasi), newest first. Previously a hard-coded
/// [SimplePlaceholderScreen] that never read any data at all, regardless
/// of how many exams the user had actually taken — see
/// [fullExamHistoryProvider] for the merge logic.
class ExamHistoryScreen extends ConsumerWidget {
  const ExamHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final historyAsync = ref.watch(fullExamHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(s.examHistory)),
      body: historyAsync.when(
        data: (entries) => AppRefreshIndicator(
          onRefresh: () => ref.refresh(fullExamHistoryProvider.future),
          child: entries.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 80),
                    Center(child: const ExamHistoryEmptyIllustration()),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        s.noExamHistory,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textNavy.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  itemBuilder: (context, index) =>
                      ExamHistoryTile(entry: entries[index]),
                ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(s.failedToLoadExamHistory)),
      ),
    );
  }
}

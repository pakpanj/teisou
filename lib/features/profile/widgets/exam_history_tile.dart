import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../exam_history_providers.dart';

/// One row in an exam-history list — category label, score/total, and
/// date. Shared by ProfileScreen's "3 terakhir" mini-list and the full
/// [ExamHistoryScreen] so both render the same [UnifiedExamHistoryEntry]
/// shape identically instead of keeping two near-duplicate widgets.
class ExamHistoryTile extends StatelessWidget {
  final UnifiedExamHistoryEntry entry;

  const ExamHistoryTile({super.key, required this.entry});

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              entry.label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textNavy,
              ),
            ),
          ),
          Text(
            '${entry.score}/${entry.total}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryCoral,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatDate(entry.completedAt),
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textNavy.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

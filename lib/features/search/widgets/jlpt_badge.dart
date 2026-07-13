import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/jlpt_level.dart';

/// Small pill badge showing a dictionary entry's JLPT level, reused across
/// the search results list and both detail screens.
class JlptBadge extends StatelessWidget {
  final JlptLevel level;

  const JlptBadge({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.secondaryBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        level.key,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.secondaryBlue,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/widgets/simple_placeholder_screen.dart';

/// Full exam history list — empty container for now (Batch 2 only wires up
/// the "3 terakhir" preview on ProfileScreen). The data already exists in
/// Firestore's `examHistory` subcollection; this screen will query and
/// paginate it in a later batch.
class ExamHistoryScreen extends ConsumerWidget {
  const ExamHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    return SimplePlaceholderScreen(
      title: s.examHistory,
      icon: Icons.history,
      message: s.examHistoryPlaceholderMessage,
    );
  }
}

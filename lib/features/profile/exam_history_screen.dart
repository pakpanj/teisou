import 'package:flutter/material.dart';

import '../../core/widgets/simple_placeholder_screen.dart';

/// Full exam history list — empty container for now (Batch 2 only wires up
/// the "3 terakhir" preview on ProfileScreen). The data already exists in
/// Firestore's `examHistory` subcollection; this screen will query and
/// paginate it in a later batch.
class ExamHistoryScreen extends StatelessWidget {
  const ExamHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimplePlaceholderScreen(
      title: 'Riwayat Ujian',
      icon: Icons.history,
      message: 'Daftar lengkap riwayat ujianmu akan tersedia di sini.',
    );
  }
}

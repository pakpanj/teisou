import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/dokkai_passage.dart';
import '../../data/models/jlpt_level.dart';
import 'dokkai_exam_screen.dart';
import 'dokkai_providers.dart';

/// Passage list for one Dokkai JLPT level.
class DokkaiLevelScreen extends ConsumerWidget {
  final JlptLevel level;
  final String levelName;

  const DokkaiLevelScreen({
    super.key,
    required this.level,
    required this.levelName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passagesAsync = ref.watch(dokkaiByLevelProvider(level));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Dokkai $levelName')),
      body: passagesAsync.when(
        data: (passages) => passages.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Bacaan untuk level ini belum tersedia.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textNavy),
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  for (final passage in passages) ...[
                    _PassageCard(passage: passage),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat bacaan: $e')),
      ),
    );
  }
}

class _PassageCard extends StatelessWidget {
  final DokkaiPassage passage;

  const _PassageCard({required this.passage});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => AppNavigator.slideFromRight(
          context,
          DokkaiExamScreen(passage: passage),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passage.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${passage.questions.length} soal',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textNavy.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.primaryCoral),
            ],
          ),
        ),
      ),
    );
  }
}

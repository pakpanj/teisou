import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/theme/app_palette.dart';
import '../../data/models/choukai_clip.dart';
import '../../data/models/jlpt_level.dart';
import 'choukai_exam_screen.dart';
import 'choukai_providers.dart';

/// Clip list for one Choukai JLPT level.
class ChoukaiLevelScreen extends ConsumerWidget {
  final JlptLevel level;
  final String levelName;

  const ChoukaiLevelScreen({
    super.key,
    required this.level,
    required this.levelName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clipsAsync = ref.watch(choukaiByLevelProvider(level));

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: Text('Choukai $levelName')),
      body: clipsAsync.when(
        data: (clips) => clips.isEmpty
            ? Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Klip untuk level ini belum tersedia.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.palette.textNavy),
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  for (final clip in clips) ...[
                    _ClipCard(clip: clip),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat klip: $e')),
      ),
    );
  }
}

class _ClipCard extends StatelessWidget {
  final ChoukaiClip clip;

  const _ClipCard({required this.clip});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.cardWhite,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => AppNavigator.slideFromRight(
          context,
          ChoukaiExamScreen(clip: clip),
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
                      clip.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.palette.textNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${clip.questions.length} soal',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.palette.textNavy.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.palette.primaryCoral),
            ],
          ),
        ),
      ),
    );
  }
}

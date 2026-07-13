import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/kotoba_category.dart';
import '../../data/models/kotoba_entry.dart';
import 'kotoba_providers.dart';
import 'kotoba_quiz_screen.dart';
import 'kotoba_word_detail_screen.dart';
import 'widgets/kotoba_image.dart';

/// Word list for one Kotoba category. Tapping a word opens
/// [KotobaWordDetailScreen] with the whole list + tapped index, so
/// next/prev navigation there doesn't need a second data load.
class KotobaCategoryScreen extends ConsumerWidget {
  final KotobaCategory category;

  const KotobaCategoryScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordsAsync = ref.watch(kotobaVocabCategoryProvider(category.id));
    final learnedIds = ref.watch(kotobaLearnedIdsProvider).valueOrNull ?? const <String>{};

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(category.icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(category.name),
          ],
        ),
        actions: [
          wordsAsync.maybeWhen(
            data: (words) => words.length < 4
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Mulai Kuis',
                    icon: const Icon(Icons.quiz_outlined),
                    onPressed: () => AppNavigator.slideFromRight(
                      context,
                      KotobaQuizScreen(category: category, words: words),
                    ),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: wordsAsync.when(
        data: (words) {
          if (words.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Kata untuk kategori ini belum tersedia.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textNavy),
                ),
              ),
            );
          }
          final learnedCount = words.where((w) => learnedIds.contains(w.id)).length;
          return Column(
            children: [
              _ProgressBar(learned: learnedCount, total: words.length),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: words.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _WordTile(
                    entry: words[index],
                    categoryIcon: category.icon,
                    learned: learnedIds.contains(words[index].id),
                    onTap: () => AppNavigator.slideFromRight(
                      context,
                      KotobaWordDetailScreen(
                        entries: words,
                        initialIndex: index,
                        categoryIcon: category.icon,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat kata: $e')),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int learned;
  final int total;

  const _ProgressBar({required this.learned, required this.total});

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : learned / total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$learned/$total dipelajari',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textNavy.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(AppColors.secondaryBlue),
            ),
          ),
        ],
      ),
    );
  }
}

class _WordTile extends StatelessWidget {
  final KotobaEntry entry;
  final String categoryIcon;
  final bool learned;
  final VoidCallback onTap;

  const _WordTile({
    required this.entry,
    required this.categoryIcon,
    required this.learned,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayWord = entry.kanji ?? entry.word;

    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              KotobaImage(
                imagePath: entry.imagePath,
                categoryIcon: categoryIcon,
                size: 52,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayWord,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textNavy,
                      ),
                    ),
                    Text(
                      '${entry.reading} · ${entry.romaji}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textNavy.withValues(alpha: 0.6),
                      ),
                    ),
                    Text(
                      entry.meaning,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: AppColors.textNavy),
                    ),
                  ],
                ),
              ),
              if (learned) ...[
                const Icon(Icons.check_circle, color: AppColors.secondaryBlue, size: 20),
                const SizedBox(width: 4),
              ],
              const Icon(Icons.chevron_right, color: AppColors.freeBadgeGrey),
            ],
          ),
        ),
      ),
    );
  }
}

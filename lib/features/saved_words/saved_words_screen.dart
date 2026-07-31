import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_refresh_indicator.dart';
import '../../data/models/saved_word.dart';
import 'saved_words_providers.dart';

/// Lists words saved either from Cam Detector's "Simpan ke Daftar Belajar"
/// button (local, `SavedWordsRepository`) or the bookmark icon on the
/// search-flow Kanji/Kotoba detail screens (`savedItems` in Firestore) —
/// see [unifiedSavedWordsProvider] for why both need merging here.
class SavedWordsScreen extends ConsumerWidget {
  const SavedWordsScreen({super.key});

  Future<void> _delete(BuildContext context, WidgetRef ref, SavedWord word) async {
    final uid = ref.read(appStartupProvider).valueOrNull?.uid;
    if (word.source == 'kanji' || word.source == 'kotoba') {
      if (uid != null) {
        await ref.read(progressRepositoryProvider).removeSavedItem(uid, word.id);
      }
    } else {
      await ref.read(savedWordsRepositoryProvider).remove(word.id, uid: uid);
    }
    ref.invalidate(unifiedSavedWordsProvider);
  }

  void _openDetail(BuildContext context, SavedWord word) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SavedWordDetailSheet(word: word),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, AppStrings s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteWordConfirmTitle),
        content: Text(s.deleteWordConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete, style: const TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final wordsAsync = ref.watch(unifiedSavedWordsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(s.savedWords)),
      body: wordsAsync.when(
        data: (words) => AppRefreshIndicator(
          onRefresh: () => ref.refresh(unifiedSavedWordsProvider.future),
          child: words.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 120),
                  children: [
                    Text(
                      s.noSavedWordsMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textNavy),
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: words.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final word = words[index];
                    return Dismissible(
                      key: ValueKey('${word.source}_${word.id}'),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) => _confirmDelete(context, s),
                      onDismissed: (_) => _delete(context, ref, word),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: AppColors.errorRed,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: _SavedWordTile(
                        word: word,
                        onTap: () => _openDetail(context, word),
                      ),
                    );
                  },
                ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(s.noSavedWordsMessage)),
      ),
    );
  }
}

class _SavedWordTile extends StatelessWidget {
  final SavedWord word;
  final VoidCallback onTap;

  const _SavedWordTile({required this.word, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word.text,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textNavy,
                      ),
                    ),
                    Text(
                      '${word.romaji} · ${word.meaning}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textNavy.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.freeBadgeGrey),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedWordDetailSheet extends ConsumerWidget {
  final SavedWord word;

  const _SavedWordDetailSheet({required this.word});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  word.text,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textNavy,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up, color: AppColors.primaryCoral, size: 28),
                onPressed: () => ref.read(ttsServiceProvider).speak(word.text),
              ),
            ],
          ),
          Text(
            word.romaji,
            style: TextStyle(fontSize: 15, color: AppColors.textNavy.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 16),
          Text(word.meaning, style: const TextStyle(color: AppColors.textNavy, fontSize: 16)),
          if (word.exampleSentence != null) ...[
            const SizedBox(height: 16),
            Text(
              word.exampleSentence!,
              style: const TextStyle(color: AppColors.textNavy),
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

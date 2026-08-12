import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_refresh_indicator.dart';
import '../../data/models/saved_word.dart';
import 'saved_words_providers.dart';
import '../../core/widgets/app_loading.dart';

/// Lists words saved either from Cam Detector's "Simpan ke Daftar Belajar"
/// button (local, `SavedWordsRepository`) or the bookmark icon on the
/// search-flow Kanji/Kotoba detail screens (`savedItems` in Firestore) —
/// see [unifiedSavedWordsProvider] for why both need merging here.
class SavedWordsScreen extends ConsumerWidget {
  const SavedWordsScreen({super.key});

  Future<void> _delete(BuildContext context, WidgetRef ref, SavedWord word) async {
    final uid = ref.read(appStartupProvider).valueOrNull?.uid;
    if (uid == null) return;
    if (word.source == 'cam_detector') {
      await ref.read(savedWordsRepositoryProvider).remove(uid, word.id);
    } else {
      // 'kanji' / 'kotoba' / 'bunpou' / 'particle' — all dictionary
      // bookmarks, all stored the same way regardless of type.
      await ref.read(progressRepositoryProvider).removeSavedItem(uid, word.id);
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
            child: Text(s.delete, style: TextStyle(color: context.palette.errorRed)),
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
      backgroundColor: context.palette.background,
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
                      style: TextStyle(color: context.palette.textNavy),
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
                          color: context.palette.errorRed,
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
        loading: () => const AppLoading(),
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
      color: context.palette.cardWhite,
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.palette.textNavy,
                      ),
                    ),
                    Text(
                      '${word.romaji} · ${word.meaning}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.palette.textNavy.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.palette.freeBadgeGrey),
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
      decoration: BoxDecoration(
        color: context.palette.background,
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
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: context.palette.textNavy,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.volume_up, color: context.palette.primaryCoral, size: 28),
                onPressed: () => ref.read(ttsServiceProvider).speak(word.text),
              ),
            ],
          ),
          Text(
            word.romaji,
            style: TextStyle(fontSize: 15, color: context.palette.textNavy.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 16),
          Text(word.meaning, style: TextStyle(color: context.palette.textNavy, fontSize: 16)),
          if (word.exampleSentence != null) ...[
            const SizedBox(height: 16),
            Text(
              word.exampleSentence!,
              style: TextStyle(color: context.palette.textNavy),
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

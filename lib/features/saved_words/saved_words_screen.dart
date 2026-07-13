import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/saved_word.dart';

/// Lists words saved from Cam Detector's "Simpan ke Daftar Belajar"
/// button. Reads straight from local storage (SharedPreferences, via
/// SavedWordsRepository) — the Firestore copy is a best-effort mirror,
/// not the source of truth this screen displays from.
class SavedWordsScreen extends ConsumerStatefulWidget {
  const SavedWordsScreen({super.key});

  @override
  ConsumerState<SavedWordsScreen> createState() => _SavedWordsScreenState();
}

class _SavedWordsScreenState extends ConsumerState<SavedWordsScreen> {
  late Future<List<SavedWord>> _future = _load();

  Future<List<SavedWord>> _load() =>
      ref.read(savedWordsRepositoryProvider).getLocal();

  Future<void> _delete(SavedWord word) async {
    final uid = ref.read(appStartupProvider).valueOrNull?.uid;
    await ref.read(savedWordsRepositoryProvider).remove(word.id, uid: uid);
    setState(() => _future = _load());
  }

  void _openDetail(SavedWord word) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SavedWordDetailSheet(word: word),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Daftar Belajar')),
      body: FutureBuilder<List<SavedWord>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final words = snapshot.data!;
          if (words.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Belum ada kata tersimpan. Simpan kata dari Cam Detector '
                  'untuk melihatnya di sini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textNavy),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: words.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final word = words[index];
              return Dismissible(
                key: ValueKey(word.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) => _confirmDelete(context),
                onDismissed: (_) => _delete(word),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: _SavedWordTile(word: word, onTap: () => _openDetail(word)),
              );
            },
          );
        },
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus kata ini?'),
        content: const Text('Kata yang dihapus tidak bisa dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
    return confirmed ?? false;
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

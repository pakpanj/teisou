import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/kotoba_entry.dart';
import '../../data/models/speech_register.dart';
import 'widgets/jlpt_badge.dart';

class KotobaDetailScreen extends ConsumerWidget {
  final KotobaEntry entry;

  const KotobaDetailScreen({super.key, required this.entry});

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final uid = ref.read(appStartupProvider).valueOrNull?.uid;
    if (uid == null) return;
    await ref
        .read(progressRepositoryProvider)
        .saveDictionaryItem(uid, itemId: entry.id, type: 'kotoba');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tersimpan ke Daftar Belajar!')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayWord = entry.kanji ?? entry.word;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(displayWord),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            tooltip: 'Simpan ke Daftar Belajar',
            onPressed: () => _save(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (entry.imageAsset != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(entry.imageAsset!, height: 140),
                ),
              ),
            Text(
              displayWord,
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: AppColors.textNavy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${entry.reading} (${entry.romaji})',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textNavy.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            JlptBadge(level: entry.jlptLevel),
            const SizedBox(height: 16),
            _AudioButton(
              onTap: () => ref.read(ttsServiceProvider).speak(entry.word),
            ),
            const SizedBox(height: 24),
            _SectionTitle('Arti'),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                entry.meaning,
                style: const TextStyle(fontSize: 16, color: AppColors.textNavy),
              ),
            ),
            if (entry.registers.isNotEmpty) ...[
              const SizedBox(height: 24),
              _SectionTitle('Register / Cara Pakai'),
              const SizedBox(height: 8),
              ...SpeechRegister.values
                  .where((r) => entry.registers.containsKey(r))
                  .map(
                    (r) => _RegisterTile(
                      register: r,
                      value: entry.registers[r]!,
                      onSpeak: () => ref.read(ttsServiceProvider).speak(entry.registers[r]!),
                    ),
                  ),
            ],
            if (entry.sentenceExample != null) ...[
              const SizedBox(height: 24),
              _SectionTitle('Contoh Kalimat'),
              const SizedBox(height: 8),
              _SentenceCard(
                japanese: entry.sentenceExample!.japanese,
                translation: entry.sentenceExample!.translation,
                onSpeak: () =>
                    ref.read(ttsServiceProvider).speak(entry.sentenceExample!.japanese),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textNavy,
        ),
      ),
    );
  }
}

class _AudioButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AudioButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryCoral,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Icon(Icons.volume_up, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

class _RegisterTile extends StatelessWidget {
  final SpeechRegister register;
  final String value;
  final VoidCallback onSpeak;

  const _RegisterTile({
    required this.register,
    required this.value,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(register.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          SizedBox(
            width: 64,
            child: Text(
              register.label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textNavy,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: AppColors.textNavy)),
          ),
          IconButton(
            icon: const Icon(Icons.volume_up, size: 18, color: AppColors.primaryCoral),
            onPressed: onSpeak,
          ),
        ],
      ),
    );
  }
}

class _SentenceCard extends StatelessWidget {
  final String japanese;
  final String translation;
  final VoidCallback onSpeak;

  const _SentenceCard({
    required this.japanese,
    required this.translation,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(japanese, style: const TextStyle(color: AppColors.textNavy, fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  translation,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textNavy.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.volume_up, color: AppColors.primaryCoral),
            onPressed: onSpeak,
          ),
        ],
      ),
    );
  }
}

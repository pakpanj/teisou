import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/kanji_glyph.dart';
import '../../data/models/kanji_entry.dart';
import 'widgets/jlpt_badge.dart';

class KanjiDetailScreen extends ConsumerWidget {
  final KanjiEntry entry;

  const KanjiDetailScreen({super.key, required this.entry});

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final uid = ref.read(appStartupProvider).valueOrNull?.uid;
    if (uid == null) return;
    await ref
        .read(progressRepositoryProvider)
        .saveDictionaryItem(uid, itemId: entry.id, type: 'kanji');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tersimpan ke Daftar Belajar!')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(entry.character),
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
            KanjiGlyph(
              character: entry.character,
              svgAsset: entry.svgAsset,
              size: 140,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [
                JlptBadge(level: entry.jlptLevel),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${entry.strokeCount} goresan',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.tertiaryAmber,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _AudioButton(
              onTap: () => ref.read(ttsServiceProvider).speak(entry.character),
            ),
            const SizedBox(height: 28),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _ReadingColumn(title: "On'yomi", readings: entry.onyomi),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ReadingColumn(title: "Kun'yomi", readings: entry.kunyomi),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionTitle('Arti'),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: entry.meanings
                    .map((m) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• $m',
                            style: const TextStyle(color: AppColors.textNavy),
                          ),
                        ))
                    .toList(),
              ),
            ),
            if (entry.examples.isNotEmpty) ...[
              const SizedBox(height: 24),
              _SectionTitle('Contoh Kata'),
              const SizedBox(height: 8),
              ...entry.examples.map(
                (example) => _ExampleCard(
                  word: example.word,
                  reading: example.reading,
                  meaning: example.meaning,
                  sentence: example.sentence,
                  sentenceTranslation: example.sentenceTranslation,
                  onSpeak: () => ref.read(ttsServiceProvider).speak(example.word),
                ),
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

class _ReadingColumn extends StatelessWidget {
  final String title;
  final List<String> readings;

  const _ReadingColumn({required this.title, required this.readings});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryCoral,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            readings.isEmpty ? '-' : readings.join('、'),
            style: const TextStyle(color: AppColors.textNavy),
          ),
        ],
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

class _ExampleCard extends StatelessWidget {
  final String word;
  final String reading;
  final String meaning;
  final String sentence;
  final String sentenceTranslation;
  final VoidCallback onSpeak;

  const _ExampleCard({
    required this.word,
    required this.reading,
    required this.meaning,
    required this.sentence,
    required this.sentenceTranslation,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$word ($reading)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textNavy,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up, size: 20, color: AppColors.primaryCoral),
                onPressed: onSpeak,
              ),
            ],
          ),
          Text(meaning, style: const TextStyle(color: AppColors.textNavy)),
          if (sentence.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(sentence, style: const TextStyle(color: AppColors.textNavy)),
            Text(
              sentenceTranslation,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textNavy.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

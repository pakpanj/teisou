import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../data/models/dictionary_word.dart';
import '../../data/models/kanji_entry.dart';
import 'kanji_detail_screen.dart';

/// Detail view for a [DictionaryWord] from the comprehensive search-only
/// dictionary — deliberately lighter than [KotobaDetailScreen]: no image,
/// no category, no speech registers, since this dataset is text-only by
/// design. Any kanji character in the word that happens to be in the
/// curated 2425-entry Kanji dataset becomes a tappable chip through to
/// [KanjiDetailScreen] for stroke order / full detail — best-effort, not
/// every character will resolve.
class DictionaryWordDetailScreen extends ConsumerWidget {
  final DictionaryWord entry;

  const DictionaryWordDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: Text(entry.display)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    entry.display,
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: context.palette.textNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.reading,
                    style: TextStyle(
                      fontSize: 15,
                      color: context.palette.textNavy.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _AudioButton(
                    onTap: () =>
                        ref.read(ttsServiceProvider).speak(entry.reading),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _SectionTitle(s.meaningSectionTitle),
            const SizedBox(height: 8),
            Text(
              entry.localizedMeaning(s.language),
              style: TextStyle(fontSize: 16, color: context.palette.textNavy),
            ),
            if (entry.kanjiCharacters.isNotEmpty) ...[
              const SizedBox(height: 24),
              const _SectionTitle('Kanji'),
              const SizedBox(height: 8),
              _KanjiCharacterRow(characters: entry.kanjiCharacters),
            ],
            const SizedBox(height: 24),
            _SectionTitle(s.sentenceExamplesTitle),
            const SizedBox(height: 8),
            _SentenceCard(
              japanese: entry.example.japanese,
              translation: entry.example.localizedTranslation(s.language),
              onSpeak: () =>
                  ref.read(ttsServiceProvider).speak(entry.example.japanese),
            ),
          ],
        ),
      ),
    );
  }
}

/// One chip per kanji character; resolves lazily against
/// [kanjiRepositoryProvider] and only becomes tappable if that character
/// is a real (non-placeholder) entry in the curated Kanji dataset.
class _KanjiCharacterRow extends ConsumerWidget {
  final List<String> characters;

  const _KanjiCharacterRow({required this.characters});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: characters
          .map((char) => _KanjiChip(character: char))
          .toList(),
    );
  }
}

class _KanjiChip extends ConsumerWidget {
  final String character;

  const _KanjiChip({required this.character});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<KanjiEntry?>(
      future: ref.read(kanjiRepositoryProvider).findByCharacter(character),
      builder: (context, snapshot) {
        final found = snapshot.data;
        final tappable = found != null;
        return Material(
          color: tappable
              ? context.palette.primaryCoral.withValues(alpha: 0.12)
              : context.palette.progressTrack,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: tappable
                ? () => AppNavigator.slideFromRight(
                    context,
                    KanjiDetailScreen(entry: found),
                  )
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              child: Text(
                character,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: tappable
                      ? context.palette.primaryCoral
                      : context.palette.textNavy.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: context.palette.textNavy,
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
      color: context.palette.primaryCoral,
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
        color: context.palette.cardWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  japanese,
                  style: TextStyle(
                    color: context.palette.textNavy,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  translation,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.palette.textNavy.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.volume_up, color: context.palette.primaryCoral),
            onPressed: onSpeak,
          ),
        ],
      ),
    );
  }
}

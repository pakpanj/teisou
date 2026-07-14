import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/stroke_order_animator.dart';
import '../../data/models/jlpt_level.dart';
import '../../data/models/kanji_entry.dart';
import '../../data/models/sentence_example.dart';
import '../search/widgets/jlpt_badge.dart';
import 'kanji_providers.dart';

/// Full detail view for one kanji, with next/prev navigation across the
/// [entries] list it was opened from (so paging through a level's grid
/// doesn't need a second data load). Distinct from
/// `search/kanji_detail_screen.dart`, which is the search-flow detail
/// screen (static glyph, no next/prev) — this one is the browse-flow
/// screen, with the animated stroke order and level paging.
class KanjiWordDetailScreen extends ConsumerStatefulWidget {
  final List<KanjiEntry> entries;
  final int initialIndex;
  final String levelName;

  const KanjiWordDetailScreen({
    super.key,
    required this.entries,
    required this.initialIndex,
    required this.levelName,
  });

  @override
  ConsumerState<KanjiWordDetailScreen> createState() => _KanjiWordDetailScreenState();
}

class _KanjiWordDetailScreenState extends ConsumerState<KanjiWordDetailScreen> {
  late int _index = widget.initialIndex;
  bool _togglingLearned = false;

  KanjiEntry get _entry => widget.entries[_index];

  void _goNext() {
    if (_index >= widget.entries.length - 1) return;
    setState(() => _index = _index + 1);
  }

  void _goPrev() {
    if (_index <= 0) return;
    setState(() => _index = _index - 1);
  }

  Future<void> _toggleLearned(bool currentlyLearned) async {
    setState(() => _togglingLearned = true);
    final uid = ref.read(appStartupProvider).valueOrNull?.uid;
    final repo = ref.read(kanjiProgressRepositoryProvider);
    if (currentlyLearned) {
      await repo.unmarkLearned(_entry.id, uid: uid);
    } else {
      await repo.markLearned(_entry.id, _entry.jlptLevel.key, uid: uid);
    }
    ref.invalidate(kanjiLearnedIdsProvider);
    if (!mounted) return;
    setState(() => _togglingLearned = false);
  }

  @override
  Widget build(BuildContext context) {
    final entry = _entry;
    final learnedIds = ref.watch(kanjiLearnedIdsProvider).valueOrNull ?? const <String>{};
    final isLearned = learnedIds.contains(entry.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('${_index + 1} / ${widget.entries.length}')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  children: [
                    StrokeOrderAnimator(
                      key: ValueKey(entry.id),
                      character: entry.character,
                      svgAssetPath: entry.svgAsset,
                      size: 200,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        JlptBadge(level: entry.jlptLevel),
                        _Pill(text: '${entry.strokeCount} goresan', color: AppColors.tertiaryAmber),
                        if (entry.radical != null)
                          _Pill(text: 'Radikal ${entry.radical}', color: AppColors.secondaryBlue),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _AudioButton(
                      onTap: () => ref.read(ttsServiceProvider).speak(entry.character),
                    ),
                    const SizedBox(height: 16),
                    _LearnedButton(
                      learned: isLearned,
                      busy: _togglingLearned,
                      onTap: _togglingLearned ? null : () => _toggleLearned(isLearned),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _ReadingColumn(title: "On'yomi", readings: entry.onyomi)),
                        const SizedBox(width: 16),
                        Expanded(child: _ReadingColumn(title: "Kun'yomi", readings: entry.kunyomi)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const _SectionTitle('Arti'),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: entry.meanings
                            .map((m) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text('• $m', style: const TextStyle(color: AppColors.textNavy)),
                                ))
                            .toList(),
                      ),
                    ),
                    if (entry.relatedBunpou.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const _SectionTitle('Bunpou Terkait'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: entry.relatedBunpou
                            .map((b) => _Pill(text: b, color: AppColors.primaryCoral))
                            .toList(),
                      ),
                    ],
                    if (entry.wordExamples.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const _SectionTitle('Contoh Kata'),
                      const SizedBox(height: 8),
                      ...entry.wordExamples.map(
                        (example) => _WordExampleCard(
                          word: example.word,
                          reading: example.reading,
                          meaning: example.meaning,
                          onSpeak: () => ref.read(ttsServiceProvider).speak(example.word),
                        ),
                      ),
                    ],
                    if (entry.sentenceExamples.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const _SectionTitle('Contoh Kalimat'),
                      const SizedBox(height: 8),
                      ...entry.sentenceExamples.map(
                        (example) => _SentenceExampleCard(
                          example: example,
                          onSpeak: () => ref.read(ttsServiceProvider).speak(example.japanese),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            _NavRow(
              hasPrev: _index > 0,
              hasNext: _index < widget.entries.length - 1,
              onPrev: _goPrev,
              onNext: _goNext,
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;

  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
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

class _LearnedButton extends StatelessWidget {
  final bool learned;
  final bool busy;
  final VoidCallback? onTap;

  const _LearnedButton({required this.learned, required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: learned ? AppColors.secondaryBlue : Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: learned ? null : Border.all(color: AppColors.secondaryBlue),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  learned ? Icons.check_circle : Icons.check_circle_outline,
                  size: 18,
                  color: learned ? Colors.white : AppColors.secondaryBlue,
                ),
              const SizedBox(width: 8),
              Text(
                learned ? 'Sudah Dipelajari' : 'Tandai Sudah Dipelajari',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: learned ? Colors.white : AppColors.secondaryBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WordExampleCard extends StatelessWidget {
  final String word;
  final String reading;
  final String meaning;
  final VoidCallback onSpeak;

  const _WordExampleCard({
    required this.word,
    required this.reading,
    required this.meaning,
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$word ($reading)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(meaning, style: const TextStyle(color: AppColors.textNavy)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.volume_up, size: 20, color: AppColors.primaryCoral),
            onPressed: onSpeak,
          ),
        ],
      ),
    );
  }
}

class _SentenceExampleCard extends StatelessWidget {
  final SentenceExample example;
  final VoidCallback onSpeak;

  const _SentenceExampleCard({required this.example, required this.onSpeak});

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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  example.japanese,
                  style: const TextStyle(fontSize: 16, color: AppColors.textNavy),
                ),
                if (example.romaji != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    example.romaji!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textNavy.withValues(alpha: 0.5),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  example.translation,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textNavy.withValues(alpha: 0.7),
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

class _NavRow extends StatelessWidget {
  final bool hasPrev;
  final bool hasNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _NavRow({
    required this.hasPrev,
    required this.hasNext,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavButton(
            icon: Icons.arrow_back,
            background: Colors.grey.shade300,
            iconColor: AppColors.textNavy,
            onTap: hasPrev ? onPrev : null,
          ),
          _NavButton(
            icon: Icons.arrow_forward,
            background: AppColors.primaryCoral,
            iconColor: Colors.white,
            onTap: hasNext ? onNext : null,
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color iconColor;
  final VoidCallback? onTap;

  const _NavButton({
    required this.icon,
    required this.background,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Material(
      color: disabled ? background.withValues(alpha: 0.4) : background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Icon(icon, color: iconColor),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/furigana_text.dart';
import '../../core/widgets/stroke_order_animator.dart';
import '../../core/widgets/swipe_navigator.dart';
import '../../data/models/jlpt_level.dart';
import '../../data/models/kanji_entry.dart';
import '../../data/models/sentence_example.dart';
import '../../data/models/xp_progress.dart';
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

  /// See `KotobaWordDetailScreen.showFurigana` — same Bab-only,
  /// N5-N3-only teaching aid, applied here to the sentence examples.
  final bool showFurigana;

  const KanjiWordDetailScreen({
    super.key,
    required this.entries,
    required this.initialIndex,
    required this.levelName,
    this.showFurigana = false,
  });

  @override
  ConsumerState<KanjiWordDetailScreen> createState() =>
      _KanjiWordDetailScreenState();
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

  Future<void> _save(AppStrings s) async {
    final uid = ref.read(appStartupProvider).valueOrNull?.uid;
    if (uid == null) return;
    await ref
        .read(progressRepositoryProvider)
        .saveDictionaryItem(uid, itemId: _entry.id, type: 'kanji');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.savedToLearningList)),
    );
  }

  Future<void> _toggleLearned(bool currentlyLearned) async {
    final uid = ref.read(appStartupProvider).valueOrNull?.uid;
    if (uid == null) return;
    setState(() => _togglingLearned = true);
    try {
      final repo = ref.read(kanjiProgressRepositoryProvider);
      if (currentlyLearned) {
        await repo.unmarkLearned(uid, _entry.id);
      } else {
        await repo.markLearned(uid, _entry.id, _entry.jlptLevel.key);
        // Only on the way to learned, never on unmark — toggling back and
        // forth must not farm XP.
        await ref
            .read(progressRepositoryProvider)
            .addXp(uid, XpAction.wordLearned);
        ref.invalidate(xpProgressProvider);
      }
      ref.invalidate(kanjiLearnedIdsProvider);
    } finally {
      // The screen owns this spinner, so it clears it whatever
      // happens. The repositories below do swallow their own
      // mirror-write failures today, but that is their promise to
      // keep and not this screen's to lean on — an await added here
      // later must not be able to strand the button.
      if (mounted) setState(() => _togglingLearned = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = _entry;
    final learnedIds =
        ref.watch(kanjiLearnedIdsProvider).valueOrNull ?? const <String>{};
    final isLearned = learnedIds.contains(entry.id);
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        title: Text('${_index + 1} / ${widget.entries.length}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            tooltip: s.saveToLearningList,
            onPressed: () => _save(s),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SwipeNavigator(
                onSwipeLeft: _index < widget.entries.length - 1
                    ? _goNext
                    : null,
                onSwipeRight: _index > 0 ? _goPrev : null,
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
                          _Pill(
                            text: s.strokeCountPill(entry.strokeCount),
                            color: context.palette.tertiaryAmber,
                          ),
                          if (entry.radical != null)
                            _Pill(
                              text: s.radicalPill(entry.radical!),
                              color: context.palette.secondaryBlue,
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _AudioButton(
                        onTap: () =>
                            ref.read(ttsServiceProvider).speak(entry.character),
                      ),
                      const SizedBox(height: 16),
                      _LearnedButton(
                        learned: isLearned,
                        busy: _togglingLearned,
                        strings: s,
                        onTap: _togglingLearned
                            ? null
                            : () => _toggleLearned(isLearned),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _ReadingColumn(
                              title: "On'yomi",
                              readings: entry.onyomi,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _ReadingColumn(
                              title: "Kun'yomi",
                              readings: entry.kunyomi,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _SectionTitle(s.meaningSectionTitle),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: entry
                              .localizedMeanings(s.language)
                              .map(
                                (m) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '• $m',
                                    style: TextStyle(
                                      color: context.palette.textNavy,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      if (entry.relatedBunpou.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _SectionTitle(s.relatedBunpouTitle),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: entry.relatedBunpou
                              .map(
                                (b) => _Pill(
                                  text: b,
                                  color: context.palette.primaryCoral,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      if (entry.wordExamples.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _SectionTitle(s.wordExamplesTitle),
                        const SizedBox(height: 8),
                        ...entry.wordExamples.map(
                          (example) => _WordExampleCard(
                            word: example.word,
                            reading: example.reading,
                            meaning: example.localizedMeaning(s.language),
                            onSpeak: () => ref
                                .read(ttsServiceProvider)
                                .speak(example.word),
                          ),
                        ),
                      ],
                      if (entry.sentenceExamples.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _SectionTitle(s.sentenceExamplesTitle),
                        const SizedBox(height: 8),
                        ...entry.sentenceExamples.map(
                          (example) => _SentenceExampleCard(
                            example: example,
                            showFurigana: widget.showFurigana,
                            onSpeak: () => ref
                                .read(ttsServiceProvider)
                                .speak(example.japanese),
                          ),
                        ),
                      ],
                    ],
                  ),
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
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
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
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: context.palette.textNavy,
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
        color: context.palette.cardWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: context.palette.primaryCoral,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            readings.isEmpty ? '-' : readings.join('、'),
            style: TextStyle(color: context.palette.textNavy),
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

class _LearnedButton extends StatelessWidget {
  final bool learned;
  final bool busy;
  final AppStrings strings;
  final VoidCallback? onTap;

  const _LearnedButton({
    required this.learned,
    required this.busy,
    required this.strings,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: learned ? context.palette.secondaryBlue : Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: learned ? null : Border.all(color: context.palette.secondaryBlue),
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
                  color: learned ? Colors.white : context.palette.secondaryBlue,
                ),
              const SizedBox(width: 8),
              Text(
                learned ? strings.markedLearned : strings.markAsLearned,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: learned ? Colors.white : context.palette.secondaryBlue,
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
                  '$word ($reading)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.palette.textNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  meaning,
                  style: TextStyle(color: context.palette.textNavy),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.volume_up,
              size: 20,
              color: context.palette.primaryCoral,
            ),
            onPressed: onSpeak,
          ),
        ],
      ),
    );
  }
}

class _SentenceExampleCard extends ConsumerWidget {
  final SentenceExample example;
  final bool showFurigana;
  final VoidCallback onSpeak;

  const _SentenceExampleCard({
    required this.example,
    required this.onSpeak,
    this.showFurigana = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final japaneseStyle = TextStyle(
      fontSize: 16,
      color: context.palette.textNavy,
    );
    final dictionary =
        showFurigana ? ref.watch(furiganaDictionaryProvider).valueOrNull : null;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
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
                dictionary != null
                    ? FuriganaSentence(
                        text: example.japanese,
                        dictionary: dictionary,
                        style: japaneseStyle,
                      )
                    : Text(example.japanese, style: japaneseStyle),
                if (example.romaji != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    example.romaji!,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.palette.textNavy.withValues(alpha: 0.5),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  example.localizedTranslation(
                      ref.watch(appStringsProvider).language),
                  style: TextStyle(
                    fontSize: 13,
                    color: context.palette.textNavy.withValues(alpha: 0.7),
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
            background: context.palette.progressTrack,
            iconColor: context.palette.textNavy,
            onTap: hasPrev ? onPrev : null,
          ),
          _NavButton(
            icon: Icons.arrow_forward,
            background: context.palette.primaryCoral,
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

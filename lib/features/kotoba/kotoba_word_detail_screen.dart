import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/swipe_navigator.dart';
import '../../data/models/kotoba_entry.dart';
import '../../data/models/sentence_example.dart';
import 'kotoba_providers.dart';
import 'widgets/kotoba_image.dart';

/// Full detail view for one Kotoba word, with next/prev navigation across
/// the [entries] list it was opened from (so paging through a category
/// doesn't need a second data load per word).
class KotobaWordDetailScreen extends ConsumerStatefulWidget {
  final List<KotobaEntry> entries;
  final int initialIndex;
  final String categoryIcon;

  const KotobaWordDetailScreen({
    super.key,
    required this.entries,
    required this.initialIndex,
    this.categoryIcon = '📚',
  });

  @override
  ConsumerState<KotobaWordDetailScreen> createState() =>
      _KotobaWordDetailScreenState();
}

class _KotobaWordDetailScreenState
    extends ConsumerState<KotobaWordDetailScreen> {
  late int _index = widget.initialIndex;
  bool _togglingLearned = false;

  KotobaEntry get _entry => widget.entries[_index];

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
        .saveDictionaryItem(uid, itemId: _entry.id, type: 'kotoba');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.savedToLearningList)),
    );
  }

  Future<void> _toggleLearned(bool currentlyLearned) async {
    setState(() => _togglingLearned = true);
    final uid = ref.read(appStartupProvider).valueOrNull?.uid;
    final repo = ref.read(kotobaProgressRepositoryProvider);
    if (currentlyLearned) {
      await repo.unmarkLearned(_entry.id, uid: uid);
    } else {
      await repo.markLearned(_entry.id, _entry.category, uid: uid);
    }
    ref.invalidate(kotobaLearnedIdsProvider);
    if (!mounted) return;
    setState(() => _togglingLearned = false);
  }

  @override
  Widget build(BuildContext context) {
    final entry = _entry;
    final learnedIds =
        ref.watch(kotobaLearnedIdsProvider).valueOrNull ?? const <String>{};
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
                      KotobaImage(
                        imagePath: entry.imagePath,
                        categoryIcon: widget.categoryIcon,
                        size: 180,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      const SizedBox(height: 20),
                      _WordHeading(entry: entry),
                      const SizedBox(height: 4),
                      Text(
                        entry.romaji,
                        style: TextStyle(
                          fontSize: 15,
                          color: context.palette.textNavy.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _AudioButton(
                        onTap: () => ref
                            .read(ttsServiceProvider)
                            .speak(entry.kanji ?? entry.word),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        entry.localizedMeaning(s.language),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: context.palette.textNavy,
                        ),
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
                      if (entry.sentenceExamples.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _SectionTitle(s.sentenceExamplesTitle),
                        const SizedBox(height: 8),
                        ...entry.sentenceExamples.map(
                          (example) => _ExampleCard(
                            example: example,
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

/// Kanji shown with its hiragana reading stacked above it, approximating
/// furigana — Flutter has no built-in ruby-text support. Kana-only words
/// (no kanji) just show the word itself at the same large size.
class _WordHeading extends StatelessWidget {
  final KotobaEntry entry;

  const _WordHeading({required this.entry});

  @override
  Widget build(BuildContext context) {
    final kanji = entry.kanji;
    if (kanji == null) {
      return Text(
        entry.word,
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: context.palette.textNavy,
        ),
      );
    }
    return Column(
      children: [
        Text(
          entry.reading,
          style: TextStyle(
            fontSize: 14,
            color: context.palette.textNavy.withValues(alpha: 0.7),
          ),
        ),
        Text(
          kanji,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: context.palette.textNavy,
          ),
        ),
      ],
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

class _ExampleCard extends ConsumerWidget {
  final SentenceExample example;
  final VoidCallback onSpeak;

  const _ExampleCard({required this.example, required this.onSpeak});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  example.japanese,
                  style: TextStyle(
                    fontSize: 16,
                    color: context.palette.textNavy,
                  ),
                ),
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

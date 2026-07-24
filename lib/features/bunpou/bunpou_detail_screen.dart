import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/swipe_navigator.dart';
import '../../data/models/bunpou_entry.dart';
import '../../data/models/jlpt_level.dart';
import '../../data/models/sentence_example.dart';
import '../search/widgets/jlpt_badge.dart';
import 'bunpou_providers.dart';

/// Full detail view for one grammar pattern, with next/prev navigation
/// across the [entries] list it was opened from — mirrors
/// `kanji/kanji_word_detail_screen.dart`'s paging shape, just without the
/// stroke-order animator/radical pill (not applicable to grammar).
class BunpouDetailScreen extends ConsumerStatefulWidget {
  final List<BunpouEntry> entries;
  final int initialIndex;
  final String levelName;

  const BunpouDetailScreen({
    super.key,
    required this.entries,
    required this.initialIndex,
    required this.levelName,
  });

  @override
  ConsumerState<BunpouDetailScreen> createState() => _BunpouDetailScreenState();
}

class _BunpouDetailScreenState extends ConsumerState<BunpouDetailScreen> {
  late int _index = widget.initialIndex;
  bool _togglingLearned = false;

  BunpouEntry get _entry => widget.entries[_index];

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
    final repo = ref.read(bunpouProgressRepositoryProvider);
    if (currentlyLearned) {
      await repo.unmarkLearned(_entry.id, uid: uid);
    } else {
      await repo.markLearned(_entry.id, _entry.jlptLevel.key, uid: uid);
    }
    ref.invalidate(bunpouLearnedIdsProvider);
    if (!mounted) return;
    setState(() => _togglingLearned = false);
  }

  @override
  Widget build(BuildContext context) {
    final entry = _entry;
    final learnedIds =
        ref.watch(bunpouLearnedIdsProvider).valueOrNull ?? const <String>{};
    final isLearned = learnedIds.contains(entry.id);
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('${_index + 1} / ${widget.entries.length}')),
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
                      _PatternDisplay(key: ValueKey(entry.id), entry: entry),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        alignment: WrapAlignment.center,
                        children: [JlptBadge(level: entry.jlptLevel)],
                      ),
                      const SizedBox(height: 16),
                      _AudioButton(
                        onTap: () =>
                            ref.read(ttsServiceProvider).speak(entry.pattern),
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
                      _SectionTitle(s.meaningSectionTitle),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          entry.localizedMeaning(s.language),
                          style: const TextStyle(color: AppColors.textNavy),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _SectionTitle(s.formationSectionTitle),
                      const SizedBox(height: 8),
                      _InfoCard(text: entry.formation),
                      const SizedBox(height: 24),
                      _SectionTitle(s.usageNotesSectionTitle),
                      const SizedBox(height: 8),
                      _InfoCard(text: entry.localizedUsageNotes(s.language)),
                      if (entry.similarPatterns.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _SectionTitle(s.similarPatternsTitle),
                        const SizedBox(height: 8),
                        _SimilarPatternsRow(ids: entry.similarPatterns),
                      ],
                      if (entry.sentenceExamples.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _SectionTitle(s.sentenceExamplesTitle),
                        const SizedBox(height: 8),
                        ...entry.sentenceExamples.map(
                          (example) => _SentenceExampleCard(
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

class _PatternDisplay extends StatelessWidget {
  final BunpouEntry entry;

  const _PatternDisplay({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            entry.pattern,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textNavy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            entry.patternRomaji,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textNavy.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String text;

  const _InfoCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(color: AppColors.textNavy, height: 1.4),
        ),
      ),
    );
  }
}

/// Resolves [ids] (raw `BunpouEntry.id` values) to their display pattern
/// text via [bunpouAllProvider] before rendering as pills — falls back to
/// the raw id only if a lookup genuinely can't find a match (shouldn't
/// happen given the seed data's own cross-check, but safer than crashing).
class _SimilarPatternsRow extends ConsumerWidget {
  final List<String> ids;

  const _SimilarPatternsRow({required this.ids});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync = ref.watch(bunpouAllProvider);
    return allAsync.when(
      data: (all) {
        final byId = {for (final e in all) e.id: e.pattern};
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ids
              .map(
                (id) =>
                    _Pill(text: byId[id] ?? id, color: AppColors.primaryCoral),
              )
              .toList(),
        );
      },
      loading: () => const SizedBox(
        height: 24,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
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
                learned ? strings.markedLearned : strings.markAsLearned,
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

class _SentenceExampleCard extends ConsumerWidget {
  final SentenceExample example;
  final VoidCallback onSpeak;

  const _SentenceExampleCard({required this.example, required this.onSpeak});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textNavy,
                  ),
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
                  example.localizedTranslation(
                      ref.watch(appStringsProvider).language),
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

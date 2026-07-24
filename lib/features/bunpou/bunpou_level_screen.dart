import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_refresh_indicator.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../data/models/bunpou_entry.dart';
import '../../data/models/jlpt_level.dart';
import 'bunpou_detail_screen.dart';
import 'bunpou_providers.dart';
import 'bunpou_quiz_screen.dart';

enum _LearnFilter { semua, belum, sudah }

/// List of grammar patterns for one JLPT level, with a learned-status
/// filter (no sort-mode toggle — patterns don't have a Kanji-like
/// "stroke count" axis, so dataset order is the only order). Tapping a
/// tile opens [BunpouDetailScreen] with the *filtered* list + tapped
/// index, so next/prev there follows whatever's currently on screen.
class BunpouLevelScreen extends ConsumerStatefulWidget {
  final JlptLevel jlptLevel;
  final String levelName;

  const BunpouLevelScreen({
    super.key,
    required this.jlptLevel,
    required this.levelName,
  });

  @override
  ConsumerState<BunpouLevelScreen> createState() => _BunpouLevelScreenState();
}

class _BunpouLevelScreenState extends ConsumerState<BunpouLevelScreen> {
  _LearnFilter _filter = _LearnFilter.semua;

  List<BunpouEntry> _applyFilters(
    List<BunpouEntry> all,
    Set<String> learnedIds,
  ) {
    var result = all.where((b) => !b.placeholder).toList();
    switch (_filter) {
      case _LearnFilter.belum:
        result = result.where((b) => !learnedIds.contains(b.id)).toList();
      case _LearnFilter.sudah:
        result = result.where((b) => learnedIds.contains(b.id)).toList();
      case _LearnFilter.semua:
        break;
    }
    return result;
  }

  void _openQuizPicker(List<BunpouEntry> entries) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _QuizModeSheet(levelName: widget.levelName, entries: entries),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bunpouAsync = ref.watch(bunpouByLevelProvider(widget.jlptLevel));
    final learnedIds =
        ref.watch(bunpouLearnedIdsProvider).valueOrNull ?? const <String>{};
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(s.bunpouLevelTitle(widget.levelName)),
        actions: [
          bunpouAsync.maybeWhen(
            data: (all) {
              final real = all.where((b) => !b.placeholder).toList();
              if (real.length < 4) return const SizedBox.shrink();
              return IconButton(
                tooltip: s.startQuizTooltip,
                icon: const Icon(Icons.quiz_outlined),
                onPressed: () => _openQuizPicker(real),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: bunpouAsync.when(
        data: (all) {
          final realTotal = all.where((b) => !b.placeholder).length;
          if (realTotal == 0) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  s.noBunpouForLevel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textNavy),
                ),
              ),
            );
          }
          final filtered = _applyFilters(all, learnedIds);
          final learnedCount = all
              .where((b) => !b.placeholder && learnedIds.contains(b.id))
              .length;
          return Column(
            children: [
              _ProgressBar(learned: learnedCount, total: realTotal, strings: s),
              _FilterRow(
                filter: _filter,
                strings: s,
                onFilterChanged: (v) => setState(() => _filter = v),
              ),
              Expanded(
                child: AppRefreshIndicator(
                  onRefresh: () {
                    ref.invalidate(bunpouLearnedIdsProvider);
                    return ref.refresh(
                      bunpouByLevelProvider(widget.jlptLevel).future,
                    );
                  },
                  child: filtered.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 120),
                              child: Center(
                                child: Text(
                                  s.noBunpouMatchesFilter,
                                  style: TextStyle(
                                    color: AppColors.textNavy.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) => _BunpouTile(
                            entry: filtered[index],
                            learned: learnedIds.contains(filtered[index].id),
                            onTap: () => AppNavigator.slideFromRight(
                              context,
                              BunpouDetailScreen(
                                entries: filtered,
                                initialIndex: index,
                                levelName: widget.levelName,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              const FreeTierBannerAd(),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(s.failedToLoadBunpou(e))),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int learned;
  final int total;
  final AppStrings strings;

  const _ProgressBar({
    required this.learned,
    required this.total,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : learned / total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.progressLearned(learned, total),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textNavy.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(AppColors.secondaryBlue),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final _LearnFilter filter;
  final AppStrings strings;
  final ValueChanged<_LearnFilter> onFilterChanged;

  const _FilterRow({
    required this.filter,
    required this.strings,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final labels = {
      _LearnFilter.semua: strings.filterAll,
      _LearnFilter.belum: strings.filterNotLearned,
      _LearnFilter.sudah: strings.filterLearned,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _LearnFilter.values.map((f) {
            final isSelected = f == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(labels[f]!),
                selected: isSelected,
                selectedColor: AppColors.primaryCoral.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? AppColors.primaryCoral
                      : AppColors.textNavy,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (_) => onFilterChanged(f),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _BunpouTile extends ConsumerWidget {
  final BunpouEntry entry;
  final bool learned;
  final VoidCallback onTap;

  const _BunpouTile({
    required this.entry,
    required this.learned,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
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
                      entry.pattern,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.localizedMeaning(ref.watch(appStringsProvider).language),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textNavy.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (learned)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.check_circle,
                    size: 18,
                    color: AppColors.secondaryBlue,
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

class _QuizModeSheet extends ConsumerWidget {
  final String levelName;
  final List<BunpouEntry> entries;

  const _QuizModeSheet({required this.levelName, required this.entries});

  void _start(BuildContext context, BunpouQuizMode mode) {
    Navigator.of(context).pop();
    AppNavigator.slideFromBottom(
      context,
      BunpouQuizScreen(levelName: levelName, entries: entries, mode: mode),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            s.chooseQuizMode,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textNavy,
            ),
          ),
          const SizedBox(height: 16),
          _ModeTile(
            icon: Icons.text_fields,
            color: AppColors.primaryCoral,
            title: s.patternToMeaningTitle,
            subtitle: s.patternToMeaningSubtitle,
            onTap: () => _start(context, BunpouQuizMode.patternToMeaning),
          ),
          const SizedBox(height: 10),
          _ModeTile(
            icon: Icons.translate,
            color: AppColors.secondaryBlue,
            title: s.meaningToPatternTitle,
            subtitle: s.meaningToPatternSubtitle,
            onTap: () => _start(context, BunpouQuizMode.meaningToPattern),
          ),
        ],
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModeTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textNavy,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textNavy.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

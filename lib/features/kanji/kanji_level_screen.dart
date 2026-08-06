import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_refresh_indicator.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../data/models/jlpt_level.dart';
import '../../data/models/kanji_entry.dart';
import 'kanji_providers.dart';
import 'kanji_quiz_screen.dart';
import 'kanji_word_detail_screen.dart';
import '../../core/widgets/app_loading.dart';

enum _SortMode { urutan, goresan }

enum _LearnFilter { semua, belum, sudah }

/// Grid of kanji characters for one JLPT level, with sort (dataset order /
/// stroke count) and learned-status filter. Tapping a tile opens
/// [KanjiWordDetailScreen] with the *filtered* list + tapped index, so
/// next/prev there follows whatever's currently on screen.
class KanjiLevelScreen extends ConsumerStatefulWidget {
  final JlptLevel jlptLevel;
  final String levelName;

  const KanjiLevelScreen({
    super.key,
    required this.jlptLevel,
    required this.levelName,
  });

  @override
  ConsumerState<KanjiLevelScreen> createState() => _KanjiLevelScreenState();
}

class _KanjiLevelScreenState extends ConsumerState<KanjiLevelScreen> {
  _SortMode _sort = _SortMode.urutan;
  _LearnFilter _filter = _LearnFilter.semua;

  List<KanjiEntry> _applyFilters(List<KanjiEntry> all, Set<String> learnedIds) {
    var result = all.where((k) => !k.placeholder).toList();
    switch (_filter) {
      case _LearnFilter.belum:
        result = result.where((k) => !learnedIds.contains(k.id)).toList();
      case _LearnFilter.sudah:
        result = result.where((k) => learnedIds.contains(k.id)).toList();
      case _LearnFilter.semua:
        break;
    }
    if (_sort == _SortMode.goresan) {
      result = [...result]
        ..sort((a, b) => a.strokeCount.compareTo(b.strokeCount));
    }
    return result;
  }

  void _openQuizPicker(List<KanjiEntry> kanji) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuizModeSheet(levelName: widget.levelName, kanji: kanji),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kanjiAsync = ref.watch(kanjiByLevelProvider(widget.jlptLevel));
    final learnedIds =
        ref.watch(kanjiLearnedIdsProvider).valueOrNull ?? const <String>{};
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        title: Text(s.kanjiLevelAppBarTitle(widget.levelName)),
        actions: [
          kanjiAsync.maybeWhen(
            data: (all) {
              final real = all.where((k) => !k.placeholder).toList();
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
      body: kanjiAsync.when(
        data: (all) {
          final realTotal = all.where((k) => !k.placeholder).length;
          if (realTotal == 0) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  s.noKanjiForLevel,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.palette.textNavy),
                ),
              ),
            );
          }
          final filtered = _applyFilters(all, learnedIds);
          final learnedCount = all
              .where((k) => !k.placeholder && learnedIds.contains(k.id))
              .length;
          return Column(
            children: [
              _ProgressBar(learned: learnedCount, total: realTotal, strings: s),
              _ControlsRow(
                sort: _sort,
                filter: _filter,
                strings: s,
                onSortChanged: (v) => setState(() => _sort = v),
                onFilterChanged: (v) => setState(() => _filter = v),
              ),
              Expanded(
                child: AppRefreshIndicator(
                  onRefresh: () {
                    ref.invalidate(kanjiLearnedIdsProvider);
                    return ref.refresh(
                      kanjiByLevelProvider(widget.jlptLevel).future,
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
                                  s.noKanjiMatchesFilter,
                                  style: TextStyle(
                                    color: context.palette.textNavy.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : GridView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.85,
                              ),
                          itemBuilder: (context, index) => _KanjiTile(
                            entry: filtered[index],
                            learned: learnedIds.contains(filtered[index].id),
                            onTap: () => AppNavigator.slideFromRight(
                              context,
                              KanjiWordDetailScreen(
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
        loading: () => const AppLoading(),
        error: (e, _) => Center(
          child: Text(ref.read(appStringsProvider).failedToLoadKanji(e)),
        ),
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
              color: context.palette.textNavy.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: context.palette.progressTrack,
              valueColor: AlwaysStoppedAnimation(context.palette.secondaryBlue),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlsRow extends StatelessWidget {
  final _SortMode sort;
  final _LearnFilter filter;
  final AppStrings strings;
  final ValueChanged<_SortMode> onSortChanged;
  final ValueChanged<_LearnFilter> onFilterChanged;

  const _ControlsRow({
    required this.sort,
    required this.filter,
    required this.strings,
    required this.onSortChanged,
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
      child: Row(
        children: [
          Expanded(
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
                      selectedColor: context.palette.primaryCoral.withValues(
                        alpha: 0.2,
                      ),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? context.palette.primaryCoral
                            : context.palette.textNavy,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      onSelected: (_) => onFilterChanged(f),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          PopupMenuButton<_SortMode>(
            tooltip: strings.sortTooltip,
            initialValue: sort,
            onSelected: onSortChanged,
            icon: Icon(Icons.sort, color: context.palette.textNavy),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _SortMode.urutan,
                child: Text(strings.sortDefault),
              ),
              PopupMenuItem(
                value: _SortMode.goresan,
                child: Text(strings.sortByStrokeCount),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KanjiTile extends StatelessWidget {
  final KanjiEntry entry;
  final bool learned;
  final VoidCallback onTap;

  const _KanjiTile({
    required this.entry,
    required this.learned,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.cardWhite,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Stack(
          children: [
            Center(
              child: Text(
                entry.character,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: context.palette.textNavy,
                ),
              ),
            ),
            if (learned)
              Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  Icons.check_circle,
                  size: 14,
                  color: context.palette.secondaryBlue,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuizModeSheet extends ConsumerWidget {
  final String levelName;
  final List<KanjiEntry> kanji;

  const _QuizModeSheet({required this.levelName, required this.kanji});

  void _start(BuildContext context, KanjiQuizMode mode) {
    Navigator.of(context).pop();
    AppNavigator.slideFromBottom(
      context,
      KanjiQuizScreen(levelName: levelName, kanji: kanji, mode: mode),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: context.palette.background,
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
                color: context.palette.textNavy.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            s.chooseQuizMode,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.palette.textNavy,
            ),
          ),
          const SizedBox(height: 16),
          _ModeTile(
            icon: Icons.text_fields,
            color: context.palette.primaryCoral,
            title: s.kanjiToMeaningTitle,
            subtitle: s.kanjiToMeaningSubtitle,
            onTap: () => _start(context, KanjiQuizMode.kanjiToMeaning),
          ),
          const SizedBox(height: 10),
          _ModeTile(
            icon: Icons.translate,
            color: context.palette.secondaryBlue,
            title: s.meaningToKanjiTitle,
            subtitle: s.meaningToKanjiSubtitle,
            onTap: () => _start(context, KanjiQuizMode.meaningToKanji),
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: context.palette.textNavy,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.palette.textNavy.withValues(alpha: 0.6),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_refresh_indicator.dart';
import '../../data/models/kaiwa_entry.dart';
import 'kaiwa_dialogue_screen.dart';
import 'kaiwa_providers.dart';

enum _LearnFilter { semua, belum, sudah }

/// List of dialogues for one Kaiwa category, with a learned-status filter —
/// no sort-mode toggle, dataset order is the only order (mirrors
/// ParticleCategoryScreen). Tapping a tile opens KaiwaDialogueScreen with
/// the *filtered* list + tapped index, so next/prev there follows whatever
/// is currently on screen.
class KaiwaCategoryScreen extends ConsumerStatefulWidget {
  final String category;
  final String categoryName;

  const KaiwaCategoryScreen({
    super.key,
    required this.category,
    required this.categoryName,
  });

  @override
  ConsumerState<KaiwaCategoryScreen> createState() =>
      _KaiwaCategoryScreenState();
}

class _KaiwaCategoryScreenState extends ConsumerState<KaiwaCategoryScreen> {
  _LearnFilter _filter = _LearnFilter.semua;

  List<KaiwaEntry> _applyFilters(List<KaiwaEntry> all, Set<String> learnedIds) {
    var result = all.where((e) => !e.placeholder).toList();
    switch (_filter) {
      case _LearnFilter.belum:
        result = result.where((e) => !learnedIds.contains(e.id)).toList();
      case _LearnFilter.sudah:
        result = result.where((e) => learnedIds.contains(e.id)).toList();
      case _LearnFilter.semua:
        break;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final kaiwaAsync = ref.watch(kaiwaByCategoryProvider(widget.category));
    final learnedIds =
        ref.watch(kaiwaLearnedIdsProvider).valueOrNull ?? const <String>{};
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: Text(widget.categoryName)),
      body: kaiwaAsync.when(
        data: (all) {
          final realTotal = all.where((e) => !e.placeholder).length;
          if (realTotal == 0) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  s.noDialoguesForCategory,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.palette.textNavy),
                ),
              ),
            );
          }
          final filtered = _applyFilters(all, learnedIds);
          final learnedCount = all
              .where((e) => !e.placeholder && learnedIds.contains(e.id))
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
                    ref.invalidate(kaiwaLearnedIdsProvider);
                    return ref.refresh(
                      kaiwaByCategoryProvider(widget.category).future,
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
                                  s.noDialoguesMatchFilter,
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
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) => _DialogueTile(
                            entry: filtered[index],
                            learned: learnedIds.contains(filtered[index].id),
                            onTap: () => AppNavigator.slideFromRight(
                              context,
                              KaiwaDialogueScreen(
                                entries: filtered,
                                initialIndex: index,
                                categoryName: widget.categoryName,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(s.failedToLoadDialogues(e))),
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
                selectedColor: context.palette.primaryCoral.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? context.palette.primaryCoral
                      : context.palette.textNavy,
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

class _DialogueTile extends ConsumerWidget {
  final KaiwaEntry entry;
  final bool learned;
  final VoidCallback onTap;

  const _DialogueTile({
    required this.entry,
    required this.learned,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: context.palette.cardWhite,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.palette.primaryCoral.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.chat_bubble_outline,
                  size: 18,
                  color: context.palette.primaryCoral,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.localizedTitle(ref.watch(appStringsProvider).language),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.palette.textNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.localizedDescription(ref.watch(appStringsProvider).language),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.palette.textNavy.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (learned)
                Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.check_circle,
                    size: 18,
                    color: context.palette.secondaryBlue,
                  ),
                ),
              Icon(Icons.chevron_right, color: context.palette.freeBadgeGrey),
            ],
          ),
        ),
      ),
    );
  }
}

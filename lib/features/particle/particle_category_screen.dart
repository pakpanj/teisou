import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_refresh_indicator.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../data/models/particle_entry.dart';
import 'particle_detail_screen.dart';
import 'particle_providers.dart';
import 'particle_quiz_screen.dart';
import '../../core/widgets/app_loading.dart';

enum _LearnFilter { semua, belum, sudah }

/// List of particles for one category, with a learned-status filter — no
/// sort-mode toggle, dataset order is the only order (mirrors
/// [BunpouLevelScreen]). Tapping a tile opens [ParticleDetailScreen] with
/// the *filtered* list + tapped index, so next/prev there follows whatever
/// is currently on screen. The quiz icon pushes [ParticleQuizScreen]
/// directly — unlike Bunpou's two-mode quiz, the cloze mini-game only has
/// one mode, so a mode-picker sheet would just be an extra unnecessary tap.
class ParticleCategoryScreen extends ConsumerStatefulWidget {
  final String category;
  final String categoryName;

  const ParticleCategoryScreen({
    super.key,
    required this.category,
    required this.categoryName,
  });

  @override
  ConsumerState<ParticleCategoryScreen> createState() =>
      _ParticleCategoryScreenState();
}

class _ParticleCategoryScreenState
    extends ConsumerState<ParticleCategoryScreen> {
  _LearnFilter _filter = _LearnFilter.semua;

  List<ParticleEntry> _applyFilters(
    List<ParticleEntry> all,
    Set<String> learnedIds,
  ) {
    var result = all.where((p) => !p.placeholder).toList();
    switch (_filter) {
      case _LearnFilter.belum:
        result = result.where((p) => !learnedIds.contains(p.id)).toList();
      case _LearnFilter.sudah:
        result = result.where((p) => learnedIds.contains(p.id)).toList();
      case _LearnFilter.semua:
        break;
    }
    return result;
  }

  void _openQuiz(List<ParticleEntry> entries) {
    AppNavigator.slideFromBottom(
      context,
      ParticleQuizScreen(categoryName: widget.categoryName, entries: entries),
    );
  }

  @override
  Widget build(BuildContext context) {
    final particleAsync = ref.watch(
      particleByCategoryProvider(widget.category),
    );
    final learnedIds =
        ref.watch(particleLearnedIdsProvider).valueOrNull ?? const <String>{};
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        title: Text(widget.categoryName),
        actions: [
          particleAsync.maybeWhen(
            data: (all) {
              final real = all.where((p) => !p.placeholder).toList();
              if (real.length < 4) return const SizedBox.shrink();
              return IconButton(
                tooltip: s.startQuizTooltip,
                icon: const Icon(Icons.quiz_outlined),
                onPressed: () => _openQuiz(real),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: particleAsync.when(
        data: (all) {
          final realTotal = all.where((p) => !p.placeholder).length;
          if (realTotal == 0) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  s.noParticlesForCategory,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.palette.textNavy),
                ),
              ),
            );
          }
          final filtered = _applyFilters(all, learnedIds);
          final learnedCount = all
              .where((p) => !p.placeholder && learnedIds.contains(p.id))
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
                    ref.invalidate(particleLearnedIdsProvider);
                    return ref.refresh(
                      particleByCategoryProvider(widget.category).future,
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
                                  s.noParticlesMatchFilter,
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
                          itemBuilder: (context, index) => _ParticleTile(
                            entry: filtered[index],
                            learned: learnedIds.contains(filtered[index].id),
                            onTap: () => AppNavigator.slideFromRight(
                              context,
                              ParticleDetailScreen(
                                entries: filtered,
                                initialIndex: index,
                                categoryName: widget.categoryName,
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
        error: (e, _) => Center(child: Text(s.failedToLoadParticles(e))),
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

class _ParticleTile extends ConsumerWidget {
  final ParticleEntry entry;
  final bool learned;
  final VoidCallback onTap;

  const _ParticleTile({
    required this.entry,
    required this.learned,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
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
                  color: context.palette.tertiaryAmber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  entry.particle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.palette.tertiaryAmber,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.particle} (${entry.particleRomaji})',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.palette.textNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.localizedOverview(language),
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

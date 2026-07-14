import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/jlpt_level.dart';
import '../../data/models/kanji_entry.dart';
import 'kanji_providers.dart';
import 'kanji_quiz_screen.dart';
import 'kanji_word_detail_screen.dart';

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
      result = [...result]..sort((a, b) => a.strokeCount.compareTo(b.strokeCount));
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
    final learnedIds = ref.watch(kanjiLearnedIdsProvider).valueOrNull ?? const <String>{};

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Kanji ${widget.levelName}'),
        actions: [
          kanjiAsync.maybeWhen(
            data: (all) {
              final real = all.where((k) => !k.placeholder).toList();
              if (real.length < 4) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'Mulai Kuis',
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
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Kanji untuk level ini belum tersedia.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textNavy),
                ),
              ),
            );
          }
          final filtered = _applyFilters(all, learnedIds);
          final learnedCount =
              all.where((k) => !k.placeholder && learnedIds.contains(k.id)).length;
          return Column(
            children: [
              _ProgressBar(learned: learnedCount, total: realTotal),
              _ControlsRow(
                sort: _sort,
                filter: _filter,
                onSortChanged: (v) => setState(() => _sort = v),
                onFilterChanged: (v) => setState(() => _filter = v),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'Tidak ada kanji yang cocok dengan filter.',
                          style: TextStyle(color: AppColors.textNavy.withValues(alpha: 0.6)),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat kanji: $e')),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int learned;
  final int total;

  const _ProgressBar({required this.learned, required this.total});

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : learned / total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$learned/$total dipelajari',
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

class _ControlsRow extends StatelessWidget {
  final _SortMode sort;
  final _LearnFilter filter;
  final ValueChanged<_SortMode> onSortChanged;
  final ValueChanged<_LearnFilter> onFilterChanged;

  const _ControlsRow({
    required this.sort,
    required this.filter,
    required this.onSortChanged,
    required this.onFilterChanged,
  });

  static const _labels = {
    _LearnFilter.semua: 'Semua',
    _LearnFilter.belum: 'Belum Dipelajari',
    _LearnFilter.sudah: 'Sudah Dipelajari',
  };

  @override
  Widget build(BuildContext context) {
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
                      label: Text(_labels[f]!),
                      selected: isSelected,
                      selectedColor: AppColors.primaryCoral.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: isSelected ? AppColors.primaryCoral : AppColors.textNavy,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) => onFilterChanged(f),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          PopupMenuButton<_SortMode>(
            tooltip: 'Urutkan',
            initialValue: sort,
            onSelected: onSortChanged,
            icon: const Icon(Icons.sort, color: AppColors.textNavy),
            itemBuilder: (context) => const [
              PopupMenuItem(value: _SortMode.urutan, child: Text('Urutan Dasar')),
              PopupMenuItem(value: _SortMode.goresan, child: Text('Jumlah Goresan')),
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

  const _KanjiTile({required this.entry, required this.learned, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Stack(
          children: [
            Center(
              child: Text(
                entry.character,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textNavy,
                ),
              ),
            ),
            if (learned)
              const Positioned(
                top: 4,
                right: 4,
                child: Icon(Icons.check_circle, size: 14, color: AppColors.secondaryBlue),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuizModeSheet extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
          const Text(
            'Pilih Mode Kuis',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textNavy),
          ),
          const SizedBox(height: 16),
          _ModeTile(
            icon: Icons.text_fields,
            color: AppColors.primaryCoral,
            title: 'Kanji → Arti',
            subtitle: 'Lihat kanji, pilih artinya',
            onTap: () => _start(context, KanjiQuizMode.kanjiToMeaning),
          ),
          const SizedBox(height: 10),
          _ModeTile(
            icon: Icons.translate,
            color: AppColors.secondaryBlue,
            title: 'Arti → Kanji',
            subtitle: 'Lihat artinya, pilih kanjinya',
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
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textNavy),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: AppColors.textNavy.withValues(alpha: 0.6)),
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

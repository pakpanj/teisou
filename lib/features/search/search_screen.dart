import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/jlpt_level.dart';
import '../../data/models/kanji_entry.dart';
import '../../data/models/kotoba_entry.dart';
import 'kanji_detail_screen.dart';
import 'kotoba_detail_screen.dart';
import 'widgets/jlpt_badge.dart';

enum _TypeFilter { all, kanji, kotoba }

/// Either a [KanjiEntry] or a [KotobaEntry] — a UI-only union so the
/// results list can render both kinds without two separate ListViews.
/// Not a persisted model, just a display-layer wrapper.
class _SearchResult {
  final KanjiEntry? kanji;
  final KotobaEntry? kotoba;

  const _SearchResult.kanji(KanjiEntry entry)
      : kanji = entry,
        kotoba = null;

  const _SearchResult.kotoba(KotobaEntry entry)
      : kanji = null,
        kotoba = entry;

  JlptLevel get level => kanji?.jlptLevel ?? kotoba!.jlptLevel;
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  _TypeFilter _typeFilter = _TypeFilter.all;
  JlptLevel? _levelFilter;
  Future<List<_SearchResult>>? _resultsFuture;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _query = value.trim();
        _refresh();
      });
    });
  }

  void _refresh() {
    final shouldSearch =
        _query.isNotEmpty || _typeFilter != _TypeFilter.all || _levelFilter != null;
    _resultsFuture = shouldSearch ? _runSearch() : null;
  }

  Future<List<_SearchResult>> _runSearch() async {
    final results = <_SearchResult>[];

    if (_typeFilter != _TypeFilter.kotoba) {
      final kanjiRepo = ref.read(kanjiRepositoryProvider);
      final kanjiResults = _query.isEmpty
          ? await kanjiRepo.getAll()
          : await kanjiRepo.search(_query);
      results.addAll(
        kanjiResults
            .where((k) => !k.placeholder && (_levelFilter == null || k.jlptLevel == _levelFilter))
            .map(_SearchResult.kanji),
      );
    }

    if (_typeFilter != _TypeFilter.kanji) {
      final kotobaRepo = ref.read(kotobaRepositoryProvider);
      final kotobaResults = _query.isEmpty
          ? await kotobaRepo.getAll()
          : await kotobaRepo.search(_query);
      results.addAll(
        kotobaResults
            .where((k) => _levelFilter == null || k.jlptLevel == _levelFilter)
            .map(_SearchResult.kotoba),
      );
    }

    return results;
  }

  void _openResult(_SearchResult result) {
    if (result.kanji != null) {
      AppNavigator.slideFromRight(context, KanjiDetailScreen(entry: result.kanji!));
    } else {
      AppNavigator.slideFromRight(context, KotobaDetailScreen(entry: result.kotoba!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onQueryChanged,
          decoration: const InputDecoration(
            hintText: 'Cari kanji, hiragana, romaji, atau arti...',
            border: InputBorder.none,
          ),
        ),
      ),
      body: Column(
        children: [
          _FilterChipsRow<_TypeFilter>(
            values: _TypeFilter.values,
            selected: _typeFilter,
            labelOf: (v) => switch (v) {
              _TypeFilter.all => 'Semua',
              _TypeFilter.kanji => 'Kanji',
              _TypeFilter.kotoba => 'Kotoba',
            },
            onSelected: (v) => setState(() {
              _typeFilter = v;
              _refresh();
            }),
          ),
          _FilterChipsRow<JlptLevel?>(
            values: const [null, ...JlptLevel.values],
            selected: _levelFilter,
            labelOf: (v) => v?.key ?? 'Semua',
            onSelected: (v) => setState(() {
              _levelFilter = v;
              _refresh();
            }),
          ),
          const Divider(height: 1),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final future = _resultsFuture;
    if (future == null) {
      return const _HintMessage(
        'Ketik kanji, hiragana, romaji, atau arti untuk mencari',
      );
    }

    return FutureBuilder<List<_SearchResult>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final results = snapshot.data ?? [];
        if (results.isEmpty) {
          return const _HintMessage('Tidak ditemukan. Coba kata kunci lain.');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final result = results[index];
            return result.kanji != null
                ? _KanjiResultTile(entry: result.kanji!, onTap: () => _openResult(result))
                : _KotobaResultTile(entry: result.kotoba!, onTap: () => _openResult(result));
          },
        );
      },
    );
  }
}

class _FilterChipsRow<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  const _FilterChipsRow({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: values.map((v) {
          final isSelected = v == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(labelOf(v)),
              selected: isSelected,
              selectedColor: AppColors.primaryCoral.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primaryCoral : AppColors.textNavy,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (_) => onSelected(v),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HintMessage extends StatelessWidget {
  final String message;

  const _HintMessage(this.message);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textNavy.withValues(alpha: 0.6)),
        ),
      ),
    );
  }
}

class _KanjiResultTile extends StatelessWidget {
  final KanjiEntry entry;
  final VoidCallback onTap;

  const _KanjiResultTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final reading = entry.kunyomi.isNotEmpty
        ? entry.kunyomi.first
        : (entry.onyomi.isNotEmpty ? entry.onyomi.first : '');

    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: Text(
                  entry.character,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textNavy,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reading, style: const TextStyle(color: AppColors.textNavy)),
                    Text(
                      entry.meanings.join(', '),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textNavy.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              JlptBadge(level: entry.jlptLevel),
            ],
          ),
        ),
      ),
    );
  }
}

class _KotobaResultTile extends StatelessWidget {
  final KotobaEntry entry;
  final VoidCallback onTap;

  const _KotobaResultTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
                      entry.kanji ?? entry.word,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textNavy,
                      ),
                    ),
                    Text(
                      '${entry.reading} · ${entry.meaning}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textNavy.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              JlptBadge(level: entry.jlptLevel),
            ],
          ),
        ),
      ),
    );
  }
}

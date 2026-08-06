import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../data/models/app_language.dart';
import '../../data/models/dictionary_word.dart';
import '../../data/models/jlpt_level.dart';
import '../../data/models/kanji_entry.dart';
import '../../data/models/kotoba_entry.dart';
import 'dictionary_word_detail_screen.dart';
import 'kanji_detail_screen.dart';
import 'kotoba_detail_screen.dart';
import 'widgets/jlpt_badge.dart';
import '../../core/widgets/mascot_widget.dart';

enum _TypeFilter { all, kanji, kotoba }

/// Either a [KanjiEntry], a [KotobaEntry], or a [DictionaryWord] — a
/// UI-only union so the results list can render all three kinds without
/// three separate ListViews. Not a persisted model, just a display-layer
/// wrapper. [DictionaryWord] results are treated as "kotoba" for the
/// type filter (they're vocabulary too, just from the bigger, text-only
/// comprehensive dataset instead of the curated 519-word module) and are
/// excluded whenever a JLPT level filter is active, since that dataset
/// carries no level metadata.
class _SearchResult {
  final KanjiEntry? kanji;
  final KotobaEntry? kotoba;
  final DictionaryWord? dictionary;

  const _SearchResult.kanji(KanjiEntry entry)
      : kanji = entry,
        kotoba = null,
        dictionary = null;

  const _SearchResult.kotoba(KotobaEntry entry)
      : kanji = null,
        kotoba = entry,
        dictionary = null;

  const _SearchResult.dictionary(DictionaryWord entry)
      : kanji = null,
        kotoba = null,
        dictionary = entry;
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

      // Comprehensive text-only dictionary — no JLPT metadata, so it only
      // contributes results when no level filter is narrowing the search.
      if (_levelFilter == null) {
        final dictionaryRepo = ref.read(dictionaryRepositoryProvider);
        final dictionaryResults = _query.isEmpty
            ? await dictionaryRepo.getAll()
            : await dictionaryRepo.search(_query);
        results.addAll(dictionaryResults.map(_SearchResult.dictionary));
      }
    }

    return results;
  }

  void _openResult(_SearchResult result) {
    if (result.kanji != null) {
      AppNavigator.slideFromRight(context, KanjiDetailScreen(entry: result.kanji!));
    } else if (result.kotoba != null) {
      AppNavigator.slideFromRight(context, KotobaDetailScreen(entry: result.kotoba!));
    } else {
      AppNavigator.slideFromRight(
        context,
        DictionaryWordDetailScreen(entry: result.dictionary!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onQueryChanged,
          decoration: InputDecoration(
            hintText: s.searchHint,
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
              _TypeFilter.all => s.filterAll,
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
            labelOf: (v) => v?.key ?? s.filterAll,
            onSelected: (v) => setState(() {
              _levelFilter = v;
              _refresh();
            }),
          ),
          const Divider(height: 1),
          Expanded(child: _buildResults(s)),
        ],
      ),
    );
  }

  Widget _buildResults(AppStrings s) {
    final future = _resultsFuture;
    if (future == null) {
      // Curious: nothing has been typed yet, so the mascot is asking
      // rather than reporting.
      return _HintMessage(s.searchHintMessage, mood: MascotMood.curious);
    }

    return FutureBuilder<List<_SearchResult>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final results = snapshot.data ?? [];
        if (results.isEmpty) {
          // Thinking: a search that found nothing is a puzzle, not a
          // failure to apologise for.
          return _HintMessage(s.searchNoResults, mood: MascotMood.thinking);
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final result = results[index];
            if (result.kanji != null) {
              return _KanjiResultTile(
                entry: result.kanji!,
                language: s.language,
                onTap: () => _openResult(result),
              );
            }
            if (result.kotoba != null) {
              return _KotobaResultTile(
                entry: result.kotoba!,
                language: s.language,
                onTap: () => _openResult(result),
              );
            }
            return _DictionaryResultTile(
              entry: result.dictionary!,
              onTap: () => _openResult(result),
            );
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
              selectedColor: context.palette.primaryCoral.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? context.palette.primaryCoral : context.palette.textNavy,
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
  final MascotMood mood;

  const _HintMessage(this.message, {required this.mood});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MascotWidget(mood: mood, size: 150, showBackdrop: false),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.palette.textNavy.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KanjiResultTile extends StatelessWidget {
  final KanjiEntry entry;
  final AppLanguage language;
  final VoidCallback onTap;

  const _KanjiResultTile({
    required this.entry,
    required this.language,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final reading = entry.kunyomi.isNotEmpty
        ? entry.kunyomi.first
        : (entry.onyomi.isNotEmpty ? entry.onyomi.first : '');

    return Material(
      color: context.palette.cardWhite,
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
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: context.palette.textNavy,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reading, style: TextStyle(color: context.palette.textNavy)),
                    Text(
                      entry.localizedMeanings(language).join(', '),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.palette.textNavy.withValues(alpha: 0.6),
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
  final AppLanguage language;
  final VoidCallback onTap;

  const _KotobaResultTile({
    required this.entry,
    required this.language,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.cardWhite,
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.palette.textNavy,
                      ),
                    ),
                    Text(
                      '${entry.reading} · ${entry.localizedMeaning(language)}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.palette.textNavy.withValues(alpha: 0.6),
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

/// Result tile for the comprehensive text-only dictionary — same layout
/// as [_KotobaResultTile] minus the JLPT badge (that dataset has no
/// level metadata) and a small "Kamus" tag instead, so it's visually
/// distinguishable from the curated 519-word Kotoba module's results.
class _DictionaryResultTile extends ConsumerWidget {
  final DictionaryWord entry;
  final VoidCallback onTap;

  const _DictionaryResultTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    return Material(
      color: context.palette.cardWhite,
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
                      entry.display,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.palette.textNavy,
                      ),
                    ),
                    Text(
                      '${entry.reading} · ${entry.meaning}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.palette.textNavy.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: context.palette.freeBadgeGrey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  s.dictionaryTag,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: context.palette.freeBadgeGrey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/app_navigator.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/japanese_text_filter.dart';
import '../../../data/models/kanji_entry.dart';
import '../../../data/models/kotoba_entry.dart';
import '../../../data/models/saved_word.dart';
import '../../../data/models/speech_register.dart';
import '../../search/kanji_detail_screen.dart';
import '../../search/kotoba_detail_screen.dart';
import '../../search/widgets/jlpt_badge.dart';

class _CharBreakdown {
  final String character;
  final String description;

  _CharBreakdown({required this.character, required this.description});
}

/// Outcome of looking [text] up against the existing Batch 4 dictionary
/// repositories. Exactly one of [kotoba]/[kanji]/[breakdown] is set,
/// matching the priority: exact kotoba word > single kanji > per-character
/// fallback.
class _LookupResult {
  final String romaji;
  final KotobaEntry? kotoba;
  final KanjiEntry? kanji;
  final List<_CharBreakdown>? breakdown;

  _LookupResult.kotoba(this.kotoba, this.romaji)
      : kanji = null,
        breakdown = null;

  _LookupResult.kanji(this.kanji, this.romaji)
      : kotoba = null,
        breakdown = null;

  _LookupResult.breakdown(this.breakdown, this.romaji)
      : kotoba = null,
        kanji = null;

  String get meaningSummary {
    if (kotoba != null) return kotoba!.meaning;
    if (kanji != null) return kanji!.meanings.join(', ');
    return breakdown!.map((b) => '${b.character}: ${b.description}').join(' · ');
  }

  String? get exampleSentence {
    final sentence = kotoba?.sentenceExample;
    if (sentence != null) return '${sentence.japanese} (${sentence.translation})';
    final kanjiExamples = kanji?.examples;
    if (kanjiExamples != null && kanjiExamples.isNotEmpty) {
      final ex = kanjiExamples.first;
      return '${ex.sentence} (${ex.sentenceTranslation})';
    }
    return null;
  }
}

/// Bottom sheet shown when the user taps a detected block in
/// CamDetectorScreen. Looks [text] up against the existing dictionary
/// repositories from Batch 4 (no duplicate models) and falls back to a
/// per-character breakdown when there's no exact match.
class DetectionResultSheet extends ConsumerStatefulWidget {
  final String text;

  const DetectionResultSheet({super.key, required this.text});

  @override
  ConsumerState<DetectionResultSheet> createState() => _DetectionResultSheetState();
}

class _DetectionResultSheetState extends ConsumerState<DetectionResultSheet> {
  late final Future<_LookupResult> _future = _lookup();
  bool _saving = false;

  Future<_LookupResult> _lookup() async {
    final kotobaRepo = ref.read(kotobaRepositoryProvider);
    final kanjiRepo = ref.read(kanjiRepositoryProvider);
    final romajiConverter = ref.read(romajiConverterProvider);
    final text = widget.text;

    final kotoba = await kotobaRepo.findExact(text);
    if (kotoba != null) {
      return _LookupResult.kotoba(kotoba, await romajiConverter.convert(text));
    }

    if (isSingleKanji(text)) {
      final kanji = await kanjiRepo.findByCharacter(text);
      if (kanji != null) {
        final reading = kanji.kunyomi.isNotEmpty
            ? kanji.kunyomi.first.replaceAll('-', '')
            : (kanji.onyomi.isNotEmpty ? kanji.onyomi.first : text);
        return _LookupResult.kanji(kanji, reading);
      }
    }

    final breakdown = <_CharBreakdown>[];
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      final kanaRomaji = await romajiConverter.romajiForChar(char);
      if (kanaRomaji != null) {
        breakdown.add(_CharBreakdown(character: char, description: kanaRomaji));
        continue;
      }
      if (isSingleKanji(char)) {
        final kanji = await kanjiRepo.findByCharacter(char);
        breakdown.add(_CharBreakdown(
          character: char,
          description: kanji != null ? kanji.meanings.join(', ') : 'Arti belum tersedia',
        ));
      } else {
        breakdown.add(_CharBreakdown(character: char, description: char));
      }
    }
    return _LookupResult.breakdown(breakdown, await romajiConverter.convert(text));
  }

  Future<void> _save(_LookupResult result) async {
    setState(() => _saving = true);
    final word = SavedWord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: widget.text,
      romaji: result.romaji,
      meaning: result.meaningSummary,
      exampleSentence: result.exampleSentence,
      source: 'cam_detector',
      createdAt: DateTime.now(),
    );
    final uid = ref.read(appStartupProvider).valueOrNull?.uid;
    await ref.read(savedWordsRepositoryProvider).add(word, uid: uid);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tersimpan ke Daftar Belajar!')),
    );
    Navigator.of(context).pop();
  }

  void _openFullDetail(_LookupResult result) {
    Navigator.of(context).pop();
    if (result.kotoba != null) {
      AppNavigator.slideFromRight(context, KotobaDetailScreen(entry: result.kotoba!));
    } else if (result.kanji != null) {
      AppNavigator.slideFromRight(context, KanjiDetailScreen(entry: result.kanji!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: FutureBuilder<_LookupResult>(
            future: _future,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return _buildContent(scrollController, snapshot.data!);
            },
          ),
        );
      },
    );
  }

  Widget _buildContent(ScrollController scrollController, _LookupResult result) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textNavy.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                widget.text,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textNavy,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.volume_up, color: AppColors.primaryCoral, size: 28),
              onPressed: () => ref.read(ttsServiceProvider).speak(widget.text),
            ),
          ],
        ),
        Text(
          result.romaji,
          style: TextStyle(fontSize: 15, color: AppColors.textNavy.withValues(alpha: 0.7)),
        ),
        if (result.kanji != null) ...[
          const SizedBox(height: 8),
          JlptBadge(level: result.kanji!.jlptLevel),
        ] else if (result.kotoba != null) ...[
          const SizedBox(height: 8),
          JlptBadge(level: result.kotoba!.jlptLevel),
        ],
        const SizedBox(height: 20),
        const _SectionLabel('Arti'),
        const SizedBox(height: 6),
        Text(result.meaningSummary, style: const TextStyle(color: AppColors.textNavy, fontSize: 16)),
        if (result.kotoba != null && result.kotoba!.registers.isNotEmpty) ...[
          const SizedBox(height: 20),
          const _SectionLabel('Register / Cara Pakai'),
          const SizedBox(height: 6),
          ...SpeechRegister.values
              .where((r) => result.kotoba!.registers.containsKey(r))
              .map((r) => _RegisterRow(register: r, value: result.kotoba!.registers[r]!)),
        ],
        if (result.exampleSentence != null) ...[
          const SizedBox(height: 20),
          const _SectionLabel('Contoh Kalimat'),
          const SizedBox(height: 6),
          Text(result.exampleSentence!, style: const TextStyle(color: AppColors.textNavy)),
        ],
        const SizedBox(height: 24),
        if (result.kotoba != null || result.kanji != null)
          OutlinedButton(
            onPressed: () => _openFullDetail(result),
            child: const Text('Lihat Detail Lengkap'),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _saving ? null : () => _save(result),
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.bookmark_add_outlined),
            label: const Text('Simpan ke Daftar Belajar'),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.textNavy,
      ),
    );
  }
}

class _RegisterRow extends StatelessWidget {
  final SpeechRegister register;
  final String value;

  const _RegisterRow({required this.register, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(register.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              register.label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppColors.textNavy,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(color: AppColors.textNavy))),
        ],
      ),
    );
  }
}

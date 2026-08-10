import 'package:flutter/material.dart';

import '../../data/models/jlpt_level.dart';
import '../services/furigana_dictionary.dart';

/// Which JLPT levels get furigana in the Bab curriculum.
///
/// N5-N3 do; N2-N1 don't. The split is a teaching decision, not a technical
/// one: a beginner who has never studied kanji can't read the vocabulary at
/// all without a reading above it, while an N2 learner is expected to read
/// unaided and would be robbed of the practice by a permanent crutch.
bool showFuriganaFor(JlptLevel level) =>
    level == JlptLevel.n5 || level == JlptLevel.n4 || level == JlptLevel.n3;

/// Renders [text] with [reading] set above it, the way furigana appears in
/// a textbook.
///
/// Deliberately annotates the **whole word** rather than per-character. Doing
/// it properly per kanji needs to know which part of the reading belongs to
/// which character, and this app has no such data: vocabulary carries only a
/// whole-word `reading` (鮪 -> まぐろ), and sentences carry only a whole-
/// sentence romaji. Splitting まぐろ across 鮪's single glyph is trivial, but
/// the same guess across 食べ物 would be invented, not derived — so the
/// honest rendering is one reading centred over the whole word.
///
/// Falls back to plain [text] when [reading] is empty or identical to it
/// (kana-only vocabulary, where a reading above would just be the same
/// characters twice).
class FuriganaText extends StatelessWidget {
  final String text;
  final String? reading;
  final TextStyle? style;
  final Color? readingColor;

  const FuriganaText({
    super.key,
    required this.text,
    required this.reading,
    this.style,
    this.readingColor,
  });

  @override
  Widget build(BuildContext context) {
    final r = reading?.trim();
    final showReading = r != null && r.isNotEmpty && r != text;
    final baseStyle = style ?? DefaultTextStyle.of(context).style;

    if (!showReading) return Text(text, style: baseStyle);

    final rubySize = (baseStyle.fontSize ?? 14) * 0.6;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          r,
          style: TextStyle(
            fontSize: rubySize,
            height: 1.1,
            color: readingColor ?? baseStyle.color?.withValues(alpha: 0.65),
          ),
        ),
        Text(text, style: baseStyle),
      ],
    );
  }
}

/// Renders a full sentence with furigana over each kanji run it recognizes,
/// via [FuriganaDictionary.segment]. Wraps segment-by-segment (a [Wrap], not
/// one [Text]) so a reading sitting above a two-character run doesn't force
/// the whole sentence onto one unbroken line — each segment is its own
/// mini ruby unit and can break independently, the same as real furigana
/// typesetting.
class FuriganaSentence extends StatelessWidget {
  final String text;
  final FuriganaDictionary dictionary;
  final TextStyle? style;

  const FuriganaSentence({
    super.key,
    required this.text,
    required this.dictionary,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    final segments = dictionary.segment(text);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        for (final segment in segments)
          FuriganaText(
            text: segment.text,
            reading: segment.reading,
            style: baseStyle,
          ),
      ],
    );
  }
}

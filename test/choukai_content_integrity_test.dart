import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/data/models/jlpt_level.dart';
import 'package:kana_master/data/repositories/choukai_repository.dart';

/// Choukai is the one module whose content is *only ever heard*, never
/// read: `ChoukaiExamScreen` plays `audioText` through TTS and deliberately
/// never renders it. That makes a corrupt script uniquely hard to notice —
/// it does not look wrong on screen, it sounds wrong out loud, to a child.
///
/// Six times across four authoring sessions a foreign word leaked into a
/// script (Cyrillic, Hangul, an English word, always followed by a
/// self-correction as if spoken mid-sentence). `generate_choukai_seed.py`
/// now guards against that, but the guard only runs when someone
/// regenerates. These tests check the shipped JSON itself, so a hand-edit
/// or a stale regeneration cannot slip past.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Latin legitimately appears in Japanese — 「血液型はO型」, 「SNS」, 「CD」 —
  // so only these three are ever wrong here. An earlier, stricter rule
  // flagged 164 correct strings across Kaiwa and Dokkai.
  final cyrillic = RegExp(r'[Ѐ-ӿ]');
  final hangul = RegExp(r'[가-힯ᄀ-ᇿ]');
  final latinWord = RegExp(r'[a-z]{3,}');

  String? foreignIn(String text) {
    if (cyrillic.hasMatch(text)) return 'Cyrillic';
    if (hangul.hasMatch(text)) return 'Hangul';
    if (latinWord.hasMatch(text)) return 'a lowercase Latin word';
    return null;
  }

  test('no clip script, prompt or option contains foreign text', () async {
    final clips = await ChoukaiRepository().getAll();
    expect(clips, isNotEmpty);

    final bad = <String>[];
    for (final clip in clips) {
      final inScript = foreignIn(clip.audioText);
      if (inScript != null) bad.add('${clip.id} audioText: $inScript');
      for (final q in clip.questions) {
        final inPrompt = foreignIn(q.prompt);
        if (inPrompt != null) bad.add('${q.id} prompt: $inPrompt');
        for (final option in q.options) {
          final inOption = foreignIn(option);
          if (inOption != null) bad.add('${q.id} option "$option": $inOption');
        }
      }
    }
    expect(bad, isEmpty, reason: 'foreign text would be read aloud by TTS');
  });

  test('every clip is answerable: questions exist, options are distinct, '
      'and the correct index points at a real option', () async {
    final clips = await ChoukaiRepository().getAll();
    final problems = <String>[];

    for (final clip in clips) {
      if (clip.questions.isEmpty) {
        problems.add('${clip.id} has no questions');
      }
      for (final q in clip.questions) {
        if (q.options.length < 2) {
          problems.add('${q.id} has ${q.options.length} option(s)');
        }
        if (q.options.toSet().length != q.options.length) {
          problems.add('${q.id} has a duplicate option');
        }
        if (q.correctIndex < 0 || q.correctIndex >= q.options.length) {
          problems.add('${q.id} correctIndex ${q.correctIndex} is out of '
              'range for ${q.options.length} options');
        }
      }
    }
    expect(problems, isEmpty);
  });

  test('clip and question ids are unique across the whole dataset', () async {
    final clips = await ChoukaiRepository().getAll();
    final clipIds = clips.map((c) => c.id).toList();
    expect(clipIds.toSet().length, clipIds.length,
        reason: 'duplicate clip id');

    final questionIds =
        clips.expand((c) => c.questions.map((q) => q.id)).toList();
    expect(questionIds.toSet().length, questionIds.length,
        reason: 'duplicate question id');
  });

  test('every clip carries a script and a translation for the review screen',
      () async {
    final clips = await ChoukaiRepository().getAll();
    for (final clip in clips) {
      expect(clip.audioText.trim(), isNotEmpty, reason: '${clip.id} script');
      expect(clip.audioTranslation.trim(), isNotEmpty,
          reason: '${clip.id} translation — shown on the result screen, so a '
              'learner who missed the audio has no way back without it');
      expect(clip.title.trim(), isNotEmpty, reason: '${clip.id} title');
    }
  });

  test('scripts get longer as the level rises', () async {
    final clips = await ChoukaiRepository().getAll();
    final meanByLevel = <String, double>{};
    for (final key in ['N5', 'N4', 'N3', 'N2', 'N1']) {
      final atLevel =
          clips.where((c) => c.jlptLevel.key == key).toList();
      if (atLevel.isEmpty) continue;
      final total =
          atLevel.fold<int>(0, (sum, c) => sum + c.audioText.length);
      meanByLevel[key] = total / atLevel.length;
    }

    // Difficulty has to be visible in the material, not just in the label:
    // a learner who clears N5 should meet noticeably longer audio at N4.
    final order = meanByLevel.keys.toList();
    for (var i = 1; i < order.length; i++) {
      expect(
        meanByLevel[order[i]]!,
        greaterThan(meanByLevel[order[i - 1]]!),
        reason: '${order[i]} scripts average '
            '${meanByLevel[order[i]]!.round()} characters, which is not '
            'longer than ${order[i - 1]}\'s '
            '${meanByLevel[order[i - 1]]!.round()}',
      );
    }
  });
}

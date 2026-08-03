import 'dart:math';

import '../../data/models/app_language.dart';
import 'bab_providers.dart';

/// One multiple-choice question for a Bab "gerbang" (gate) quiz — built at
/// runtime from real, already-authored Kotoba/Bunpou/Partikel content, the
/// same "mine existing data, ship no new dataset" approach
/// `KanjiComboRepository` already uses for Ujian's Kanji-Kombinasi category.
///
/// [context] is a real example sentence the word/pattern/particle already
/// appears in (from that entry's own `sentenceExamples`) — shown above
/// [prompt] so the learner answers from reading real usage, not from
/// isolated multiple-choice recall. Null only for the rare candidate whose
/// entry has no authored example sentence to draw from.
class GateQuestion {
  final String? context;
  final String prompt;
  final List<String> options;
  final int correctIndex;

  GateQuestion({
    required this.context,
    required this.prompt,
    required this.options,
    required this.correctIndex,
  });
}

/// Builds the question pool for the gate quiz that must be passed (100%,
/// see [BabGateQuizScreen]) to unlock the chapter right after [upToOrder] —
/// i.e. the quiz covers every chapter from order 1 through [upToOrder]
/// inclusive, exactly matching the "Bab N -> Bab N+1 needs Bab 1..N"
/// progression the curriculum lock is built around.
///
/// Distractors are drawn from [allResolved] as a whole (every chapter in
/// the level, not just the ones in scope) rather than only the in-scope
/// pool, so there's always enough plausible wrong answers even when
/// unlocking chapter 2 — whose own pool is just chapter 1's handful of
/// items, nowhere near enough to pick 3 distinct distractors from itself.
List<GateQuestion> buildGateQuestions({
  required List<ResolvedBab> allResolved,
  required int upToOrder,
  required AppLanguage language,
  int targetCount = 10,
  Random? random,
}) {
  final rng = random ?? Random();

  final kotobaById = <String, ({String prompt, String answer, String? context})>{};
  final bunpouById = <String, ({String prompt, String answer, String? context})>{};
  final particleFnById = <String, ({String prompt, String answer, String? context})>{};

  final scopedKotobaIds = <String>{};
  final scopedBunpouIds = <String>{};
  final scopedParticleFnIds = <String>{};

  String? pickContext(List<String> sentences) =>
      sentences.isEmpty ? null : sentences[rng.nextInt(sentences.length)];

  for (final resolved in allResolved) {
    final inScope = resolved.bab.order <= upToOrder;
    for (final k in resolved.kotoba) {
      final headword = k.kanji ?? k.word;
      kotobaById[k.id] = (
        prompt: headword == k.reading ? '「$headword」' : '「$headword」(${k.reading})',
        answer: k.localizedMeaning(language),
        context: pickContext(k.sentenceExamples.map((e) => e.japanese).toList()),
      );
      if (inScope) scopedKotobaIds.add(k.id);
    }
    for (final b in resolved.bunpou) {
      bunpouById[b.id] = (
        prompt: '「${b.pattern}」(${b.patternRomaji})',
        answer: b.localizedMeaning(language),
        context: pickContext(b.sentenceExamples.map((e) => e.japanese).toList()),
      );
      if (inScope) scopedBunpouIds.add(b.id);
    }
    for (final p in resolved.particles) {
      for (final fn in p.functions) {
        particleFnById[fn.id] = (
          prompt: '「${p.particle}」',
          answer: fn.localizedTitle(language),
          context: pickContext(fn.sentenceExamples.map((e) => e.japanese).toList()),
        );
        if (inScope) scopedParticleFnIds.add(fn.id);
      }
    }
  }

  final allKotobaMeanings =
      kotobaById.values.map((e) => e.answer).toSet().toList();
  final allBunpouMeanings =
      bunpouById.values.map((e) => e.answer).toSet().toList();
  final allParticleTitles =
      particleFnById.values.map((e) => e.answer).toSet().toList();

  final isEnglish = language == AppLanguage.english;
  final meansWhatPlain = isEnglish ? 'means?' : 'artinya?';
  final meansWhatInContext =
      isEnglish ? 'in this sentence means?' : 'pada kalimat ini artinya?';
  final patternPrefix = isEnglish ? 'The pattern' : 'Pola';
  final particleFnPlain = isEnglish
      ? (String p) => 'One function of the particle $p is...'
      : (String p) => 'Salah satu fungsi partikel $p adalah...';
  final particleFnInContext = isEnglish
      ? (String p) => 'The particle $p in this sentence functions as...'
      : (String p) => 'Partikel $p pada kalimat ini berfungsi sebagai...';

  List<String> distractorsFor(List<String> pool, String correct) {
    final options = pool.where((m) => m != correct).toList()..shuffle(rng);
    return options.take(3).toList();
  }

  GateQuestion buildQuestion(
    String? context,
    String prompt,
    String correct,
    List<String> distractorPool,
  ) {
    final distractors = distractorsFor(distractorPool, correct);
    final options = {correct, ...distractors}.toList()..shuffle(rng);
    return GateQuestion(
      context: context,
      prompt: prompt,
      options: options,
      correctIndex: options.indexOf(correct),
    );
  }

  final candidates = <GateQuestion Function()>[
    for (final id in scopedKotobaIds)
      () {
        final e = kotobaById[id]!;
        return buildQuestion(
          e.context,
          e.context != null
              ? '${e.prompt} $meansWhatInContext'
              : '${e.prompt} $meansWhatPlain',
          e.answer,
          allKotobaMeanings,
        );
      },
    for (final id in scopedBunpouIds)
      () {
        final e = bunpouById[id]!;
        return buildQuestion(
          e.context,
          e.context != null
              ? '$patternPrefix ${e.prompt} $meansWhatInContext'
              : '$patternPrefix ${e.prompt} $meansWhatPlain',
          e.answer,
          allBunpouMeanings,
        );
      },
    for (final id in scopedParticleFnIds)
      () {
        final e = particleFnById[id]!;
        return buildQuestion(
          e.context,
          e.context != null ? particleFnInContext(e.prompt) : particleFnPlain(e.prompt),
          e.answer,
          allParticleTitles,
        );
      },
  ];

  candidates.shuffle(rng);
  final count = min(targetCount, candidates.length);
  return [for (final build in candidates.take(count)) build()];
}

import 'dart:math';

import '../../data/models/app_language.dart';
import 'bab_providers.dart';

/// One multiple-choice question for a Bab "gerbang" (gate) quiz — built at
/// runtime from real, already-authored Kotoba/Bunpou/Partikel content, the
/// same "mine existing data, ship no new dataset" approach
/// `KanjiComboRepository` already uses for Ujian's Kanji-Kombinasi category.
///
/// [context] is a real example sentence the word/pattern/particle already
/// appears in — shown above [prompt] so the learner answers from reading
/// real usage, not from isolated multiple-choice recall. Null only for the
/// rare candidate with no example sentence to draw from at all.
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

/// Minimum literal-match length before a token is trusted to widen a
/// candidate's context-sentence pool by scanning the rest of the
/// curriculum. Below this, a substring search would mostly return noise —
/// a single hiragana particle character (は/か/を/で/...) appears inside
/// countless unrelated words, so widening on those would attach a
/// genuinely wrong "example" to the question far too often. Two chars is
/// the same bar the earlier cross-content sync-fix pass used for exactly
/// the same reason (see the CROSS-CONTENT SYNC PASS note in
/// scripts/bab_lists.py) — kanji words already clear it, and most
/// multi-character bunpou pattern tokens do too; only bare single-particle
/// patterns/particles fall back to just their own authored examples.
const _minWidenLength = 2;

/// Splits a Bunpou `pattern` field into its individual literal forms — many
/// patterns bundle 2-6 related forms with ／, /, or ・ (e.g. "だ／です",
/// "これ／それ／あれ・この／その／あの") since no single one of them would
/// ever literally appear in a real sentence together. Each token is
/// matched independently against the curriculum's sentence pool.
List<String> _patternTokens(String pattern) => pattern
    .split(RegExp('[／/・]'))
    .map((t) => t.trim())
    .where((t) => t.isNotEmpty)
    .toList();

/// How many questions a gate quiz asks, given how many chapters it covers.
/// Grows with the curriculum so a late chapter isn't gated by the same
/// 10-question sample an early one is — but capped, because the quiz demands
/// a near-perfect score and the curriculum runs to 358 chapters, where an
/// uncapped curve would be unsittable. Bab 1 -> 10, Bab 25 -> 20, Bab 50 and
/// beyond -> 30.
int gateQuestionCount(int upToOrder) =>
    min(10 + (upToOrder * 2) ~/ 5, 30);

/// How many correct answers a gate quiz needs to pass: 90%, rounded up.
/// It used to be all of them. That was already harsh at 10 questions, and
/// with the count now scaling to 30 it would mean a single slip anywhere
/// restarts the whole thing — the kind of wall a child stops climbing.
/// Rounding up keeps it strict: 10 -> 9, 20 -> 18, 30 -> 27.
int gatePassMark(int totalQuestions) => (totalQuestions * 0.9).ceil();

/// Builds the question pool for the gate quiz that must be passed (see
/// [gatePassMark]) to unlock the chapter right after [upToOrder] —
/// i.e. the quiz covers every chapter from order 1 through [upToOrder]
/// inclusive, exactly matching the "Bab N -> Bab N+1 needs Bab 1..N"
/// progression the curriculum lock is built around.
///
/// Distractors are drawn from [allResolved] as a whole (every chapter in
/// the level, not just the ones in scope) rather than only the in-scope
/// pool, so there's always enough plausible wrong answers even when
/// unlocking chapter 2 — whose own pool is just chapter 1's handful of
/// items, nowhere near enough to pick 3 distinct distractors from itself.
///
/// Context sentences work the same way, for the same reason: relying only
/// on each entry's own 2-3 authored `sentenceExamples` means the same
/// handful of sentences repeat every time a chapter's gate quiz is
/// retried. Every real sentence anywhere in the curriculum — every Kaiwa
/// dialogue line, every Kotoba/Bunpou/Partikel example — is pooled once
/// per candidate word/pattern/particle via a literal substring match (see
/// [_minWidenLength] for why short single-particle patterns don't widen),
/// so a retry can surface a genuinely different, still-accurate sentence
/// instead of cycling the same 2-3.
List<GateQuestion> buildGateQuestions({
  required List<ResolvedBab> allResolved,
  required int upToOrder,
  required AppLanguage language,
  int? targetCount,
  Random? random,
}) {
  final rng = random ?? Random();

  // Every real Japanese sentence anywhere in the curriculum, deduplicated —
  // the pool [_extraContextsFor] scans for additional matches.
  final curriculumSentences = <String>{};
  for (final resolved in allResolved) {
    for (final k in resolved.kotoba) {
      curriculumSentences.addAll(k.sentenceExamples.map((e) => e.japanese));
    }
    for (final b in resolved.bunpou) {
      curriculumSentences.addAll(b.sentenceExamples.map((e) => e.japanese));
    }
    for (final p in resolved.particles) {
      for (final fn in p.functions) {
        curriculumSentences.addAll(fn.sentenceExamples.map((e) => e.japanese));
      }
    }
    for (final entry in resolved.kaiwa) {
      for (final line in entry.lines) {
        if (line.isUserTurn) {
          curriculumSentences.addAll(line.options.map((o) => o.japanese));
        } else if (line.npcLine != null) {
          curriculumSentences.add(line.npcLine!.japanese);
        }
      }
    }
  }
  final curriculumSentenceList = curriculumSentences.toList();

  /// Every sentence containing [tokens] anywhere in the curriculum, plus
  /// [ownExamples] — [tokens] shorter than [_minWidenLength] are skipped
  /// (see its doc comment), so a candidate matched only by a bare particle
  /// falls back to just its own authored examples.
  List<String> contextPoolFor(List<String> tokens, List<String> ownExamples) {
    final widenable = tokens.where((t) => t.length >= _minWidenLength);
    final extra = widenable.isEmpty
        ? const <String>[]
        : curriculumSentenceList
            .where((s) => widenable.any((t) => s.contains(t)))
            .toList();
    return {...ownExamples, ...extra}.toList();
  }

  final kotobaById = <String, ({String prompt, String answer, List<String> contextPool})>{};
  final bunpouById = <String, ({String prompt, String answer, List<String> contextPool})>{};
  final particleFnById = <String, ({String prompt, String answer, List<String> contextPool})>{};

  // id -> the *highest* chapter order (within scope) that teaches it. Highest
  // rather than lowest on purpose: a word reused by the chapter being
  // unlocked is legitimately that chapter's material, and the stratified
  // draw below needs to see it as recent, not as leftovers from chapter 3.
  final kotobaOrder = <String, int>{};
  final bunpouOrder = <String, int>{};
  final particleFnOrder = <String, int>{};

  void note(Map<String, int> orders, String id, int order) {
    final existing = orders[id];
    if (existing == null || order > existing) orders[id] = order;
  }

  for (final resolved in allResolved) {
    final order = resolved.bab.order;
    final inScope = order <= upToOrder;
    for (final k in resolved.kotoba) {
      final headword = k.kanji ?? k.word;
      kotobaById[k.id] = (
        prompt: headword == k.reading ? '「$headword」' : '「$headword」(${k.reading})',
        answer: k.localizedMeaning(language),
        contextPool: contextPoolFor(
          [headword],
          k.sentenceExamples.map((e) => e.japanese).toList(),
        ),
      );
      if (inScope) note(kotobaOrder, k.id, order);
    }
    for (final b in resolved.bunpou) {
      bunpouById[b.id] = (
        prompt: '「${b.pattern}」(${b.patternRomaji})',
        answer: b.localizedMeaning(language),
        contextPool: contextPoolFor(
          _patternTokens(b.pattern),
          b.sentenceExamples.map((e) => e.japanese).toList(),
        ),
      );
      if (inScope) note(bunpouOrder, b.id, order);
    }
    for (final p in resolved.particles) {
      for (final fn in p.functions) {
        particleFnById[fn.id] = (
          prompt: '「${p.particle}」',
          answer: fn.localizedTitle(language),
          contextPool: contextPoolFor(
            [p.particle],
            fn.sentenceExamples.map((e) => e.japanese).toList(),
          ),
        );
        if (inScope) note(particleFnOrder, fn.id, order);
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

  String? pickContext(List<String> pool) =>
      pool.isEmpty ? null : pool[rng.nextInt(pool.length)];

  List<String> distractorsFor(List<String> pool, String correct) {
    final options = pool.where((m) => m != correct).toList()..shuffle(rng);
    return options.take(3).toList();
  }

  GateQuestion buildQuestion(
    List<String> contextPool,
    String prompt,
    String correct,
    List<String> distractorPool,
  ) {
    final distractors = distractorsFor(distractorPool, correct);
    final options = {correct, ...distractors}.toList()..shuffle(rng);
    return GateQuestion(
      context: pickContext(contextPool),
      prompt: prompt,
      options: options,
      correctIndex: options.indexOf(correct),
    );
  }

  final candidates = <({int order, GateQuestion Function() build})>[
    for (final entry in kotobaOrder.entries)
      (order: entry.value, build: () {
        final id = entry.key;
        final e = kotobaById[id]!;
        final hasContext = e.contextPool.isNotEmpty;
        return buildQuestion(
          e.contextPool,
          hasContext
              ? '${e.prompt} $meansWhatInContext'
              : '${e.prompt} $meansWhatPlain',
          e.answer,
          allKotobaMeanings,
        );
      }),
    for (final entry in bunpouOrder.entries)
      (order: entry.value, build: () {
        final e = bunpouById[entry.key]!;
        final hasContext = e.contextPool.isNotEmpty;
        return buildQuestion(
          e.contextPool,
          hasContext
              ? '$patternPrefix ${e.prompt} $meansWhatInContext'
              : '$patternPrefix ${e.prompt} $meansWhatPlain',
          e.answer,
          allBunpouMeanings,
        );
      }),
    for (final entry in particleFnOrder.entries)
      (order: entry.value, build: () {
        final e = particleFnById[entry.key]!;
        final hasContext = e.contextPool.isNotEmpty;
        return buildQuestion(
          e.contextPool,
          hasContext ? particleFnInContext(e.prompt) : particleFnPlain(e.prompt),
          e.answer,
          allParticleTitles,
        );
      }),
  ];

  final count = min(targetCount ?? gateQuestionCount(upToOrder), candidates.length);

  // Stratified draw, not a flat shuffle. A flat `shuffle().take(10)` over the
  // whole 1..upToOrder pool is what made a Bab 25 gate quiz sometimes ask
  // nothing at all about Bab 25: by chapter 25 the earlier chapters
  // outnumber the newest one roughly 24:1, so uniform sampling almost never
  // reaches it. Passing a gate that never tested the chapter just studied
  // proves nothing, so the newest chapter gets a reserved share first and
  // the remainder is filled from everything before it.
  final recent = <GateQuestion Function()>[];
  final earlier = <GateQuestion Function()>[];
  for (final c in candidates) {
    (c.order == upToOrder ? recent : earlier).add(c.build);
  }
  recent.shuffle(rng);
  earlier.shuffle(rng);

  // Reserve ~40% for the newest chapter — enough that it's always genuinely
  // represented, low enough that the quiz stays cumulative rather than
  // turning into a single-chapter test. Chapters with fewer candidates than
  // their share simply contribute all they have; `earlier` covers the rest.
  final recentTarget = min(max(1, (count * 0.4).round()), recent.length);
  final picked = <GateQuestion Function()>[
    ...recent.take(recentTarget),
    ...earlier.take(count - recentTarget),
  ];
  // A short `earlier` pool (early chapters, or a level whose first chapters
  // are thin) can leave the quiz under target — top it up from whatever
  // recent candidates weren't already reserved.
  if (picked.length < count) {
    picked.addAll(recent.skip(recentTarget).take(count - picked.length));
  }

  picked.shuffle(rng);
  return [for (final build in picked) build()];
}

import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/data/models/jlpt_level.dart';
import 'package:kana_master/data/repositories/dokkai_repository.dart';

/// Dokkai ships 500 passages and, unlike Choukai and Kaiwa, had no
/// integrity test at all.
///
/// That matters because `McQuizFlow` — shared by Dokkai, Choukai and Kanji
/// Combo — trusts its inputs completely. A passage with no questions makes
/// `DokkaiExamScreen` hand it `totalQuestions: 0`, and its first build
/// reads `optionsOf(0)` out of an empty list and divides by zero for the
/// progress bar. A `correctIndex` past the end of `options` marks every
/// answer wrong instead. Neither shows up in `flutter analyze`, and
/// Dokkai's exam screen picks passages at random, so a single bad entry
/// out of 500 would surface as an intermittent crash nobody can reproduce.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every passage is answerable', () async {
    final passages = await DokkaiRepository().getAll();
    expect(passages, isNotEmpty);

    final problems = <String>[];
    for (final p in passages) {
      if (p.questions.isEmpty) {
        problems.add('${p.id} has no questions — McQuizFlow would crash on '
            'its first build');
      }
      for (final q in p.questions) {
        if (q.options.length < 2) {
          problems.add('${q.id} has ${q.options.length} option(s)');
        }
        if (q.options.toSet().length != q.options.length) {
          problems.add('${q.id} has a duplicate option, so two taps are '
              'equally correct');
        }
        if (q.correctIndex < 0 || q.correctIndex >= q.options.length) {
          problems.add('${q.id} correctIndex ${q.correctIndex} is out of '
              'range for ${q.options.length} options');
        }
        if (q.prompt.trim().isEmpty) problems.add('${q.id} has an empty prompt');
      }
    }
    expect(problems, isEmpty);
  });

  test('passage and question ids are unique across the whole dataset',
      () async {
    final passages = await DokkaiRepository().getAll();
    final ids = passages.map((p) => p.id).toList();
    expect(ids.toSet().length, ids.length, reason: 'duplicate passage id');

    final questionIds =
        passages.expand((p) => p.questions.map((q) => q.id)).toList();
    expect(questionIds.toSet().length, questionIds.length,
        reason: 'duplicate question id');
  });

  test('every passage carries text a learner can actually read', () async {
    final passages = await DokkaiRepository().getAll();
    for (final p in passages) {
      expect(p.passageJapanese.trim(), isNotEmpty, reason: '${p.id} passage');
      expect(p.passageTranslation.trim(), isNotEmpty,
          reason: '${p.id} translation');
      expect(p.title.trim(), isNotEmpty, reason: '${p.id} title');
    }
  });

  test('passages get longer as the level rises', () async {
    // The same check Choukai's clips get: difficulty has to be visible in
    // the material, not just in the label.
    final passages = await DokkaiRepository().getAll();
    final meanByLevel = <String, double>{};
    for (final key in ['N5', 'N4', 'N3', 'N2', 'N1']) {
      final atLevel = passages.where((p) => p.jlptLevel.key == key).toList();
      if (atLevel.isEmpty) continue;
      final total =
          atLevel.fold<int>(0, (sum, p) => sum + p.passageJapanese.length);
      meanByLevel[key] = total / atLevel.length;
    }

    final order = meanByLevel.keys.toList();
    for (var i = 1; i < order.length; i++) {
      expect(
        meanByLevel[order[i]]!,
        greaterThan(meanByLevel[order[i - 1]]!),
        reason: '${order[i]} passages average '
            '${meanByLevel[order[i]]!.round()} characters, which is not '
            'longer than ${order[i - 1]}\'s '
            '${meanByLevel[order[i - 1]]!.round()}',
      );
    }
  });
}

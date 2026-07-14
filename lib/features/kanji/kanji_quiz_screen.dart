import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/kanji_entry.dart';

enum KanjiQuizMode { kanjiToMeaning, meaningToKanji }

/// Multiple-choice quiz over one level's kanji list, in one of two modes:
/// shown the kanji and asked to pick its meaning, or shown the meaning and
/// asked to pick the matching kanji. Standalone practice tool — quiz
/// results don't affect the "Sudah Dipelajari" marks from
/// [KanjiWordDetailScreen].
class KanjiQuizScreen extends StatefulWidget {
  final String levelName;
  final List<KanjiEntry> kanji;
  final KanjiQuizMode mode;

  const KanjiQuizScreen({
    super.key,
    required this.levelName,
    required this.kanji,
    required this.mode,
  });

  @override
  State<KanjiQuizScreen> createState() => _KanjiQuizScreenState();
}

class _QuizQuestion {
  final KanjiEntry entry;
  final List<String> options;
  final int correctIndex;

  _QuizQuestion({required this.entry, required this.options, required this.correctIndex});
}

class _KanjiQuizScreenState extends State<KanjiQuizScreen> {
  static const _questionCount = 10;

  late final List<_QuizQuestion> _questions = _buildQuestions();
  int _index = 0;
  int _score = 0;
  int? _selected;

  bool get _isKanjiToMeaning => widget.mode == KanjiQuizMode.kanjiToMeaning;

  String _valueOf(KanjiEntry entry) => _isKanjiToMeaning ? entry.meanings.first : entry.character;

  List<_QuizQuestion> _buildQuestions() {
    final random = Random();
    final pool = List<KanjiEntry>.from(widget.kanji)..shuffle(random);
    final chosen = pool.take(min(_questionCount, pool.length)).toList();

    return chosen.map((entry) {
      final distractorPool = widget.kanji.where((k) => k.id != entry.id).toList()..shuffle(random);
      final distractors = distractorPool.take(3).map(_valueOf);
      final correctValue = _valueOf(entry);
      final options = [correctValue, ...distractors]..shuffle(random);
      return _QuizQuestion(
        entry: entry,
        options: options,
        correctIndex: options.indexOf(correctValue),
      );
    }).toList();
  }

  void _select(int optionIndex) {
    if (_selected != null) return;
    setState(() {
      _selected = optionIndex;
      if (optionIndex == _questions[_index].correctIndex) _score++;
    });
  }

  void _next() {
    if (_index >= _questions.length - 1) {
      setState(() => _index = _questions.length);
      return;
    }
    setState(() {
      _index++;
      _selected = null;
    });
  }

  void _restart() {
    setState(() {
      _questions
        ..clear()
        ..addAll(_buildQuestions());
      _index = 0;
      _score = 0;
      _selected = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final finished = _index >= _questions.length;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Kuis · Kanji ${widget.levelName}')),
      body: SafeArea(
        child: finished
            ? _ResultView(score: _score, total: _questions.length, onRestart: _restart)
            : _buildQuestion(),
      ),
    );
  }

  Widget _buildQuestion() {
    final question = _questions[_index];
    final answered = _selected != null;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Soal ${_index + 1} / ${_questions.length}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textNavy.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_index) / _questions.length,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(AppColors.primaryCoral),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            _isKanjiToMeaning ? 'Apa arti kanji ini?' : 'Kanji mana yang berarti ini?',
            style: TextStyle(fontSize: 14, color: AppColors.textNavy.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Column(
              children: [
                Text(
                  _isKanjiToMeaning ? question.entry.character : question.entry.meanings.first,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _isKanjiToMeaning ? 48 : 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textNavy,
                  ),
                ),
                if (_isKanjiToMeaning) ...[
                  const SizedBox(height: 4),
                  Text(
                    [...question.entry.onyomi, ...question.entry.kunyomi].join('、'),
                    style: TextStyle(fontSize: 14, color: AppColors.textNavy.withValues(alpha: 0.6)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: question.options.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _OptionTile(
                text: question.options[i],
                large: !_isKanjiToMeaning,
                state: !answered
                    ? _OptionState.neutral
                    : i == question.correctIndex
                        ? _OptionState.correct
                        : i == _selected
                            ? _OptionState.wrong
                            : _OptionState.disabled,
                onTap: () => _select(i),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: answered ? _next : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryCoral,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(_index >= _questions.length - 1 ? 'Lihat Skor' : 'Lanjut'),
            ),
          ),
        ],
      ),
    );
  }
}

enum _OptionState { neutral, correct, wrong, disabled }

class _OptionTile extends StatelessWidget {
  final String text;
  final bool large;
  final _OptionState state;
  final VoidCallback onTap;

  const _OptionTile({
    required this.text,
    required this.large,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color background;
    Color textColor = AppColors.textNavy;
    Color borderColor = Colors.transparent;
    IconData? icon;

    switch (state) {
      case _OptionState.neutral:
        background = AppColors.cardWhite;
      case _OptionState.correct:
        background = AppColors.secondaryBlue.withValues(alpha: 0.15);
        borderColor = AppColors.secondaryBlue;
        icon = Icons.check_circle;
      case _OptionState.wrong:
        background = AppColors.errorRed.withValues(alpha: 0.12);
        borderColor = AppColors.errorRed;
        icon = Icons.cancel;
      case _OptionState.disabled:
        background = AppColors.cardWhite;
        textColor = AppColors.textNavy.withValues(alpha: 0.4);
    }

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: state == _OptionState.neutral ? onTap : null,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: large ? 10 : 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(fontSize: large ? 24 : 14, color: textColor),
                ),
              ),
              if (icon != null)
                Icon(
                  icon,
                  size: 20,
                  color: state == _OptionState.correct ? AppColors.secondaryBlue : AppColors.errorRed,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final int score;
  final int total;
  final VoidCallback onRestart;

  const _ResultView({required this.score, required this.total, required this.onRestart});

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : score / total;
    final message = ratio >= 0.8
        ? 'Luar biasa!'
        : ratio >= 0.5
            ? 'Bagus, terus berlatih!'
            : 'Yuk, pelajari lagi kanjinya!';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textNavy),
          ),
          const SizedBox(height: 8),
          Text(
            'Skor: $score / $total',
            style: TextStyle(fontSize: 15, color: AppColors.textNavy.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Selesai'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onRestart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryCoral,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Ulangi'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

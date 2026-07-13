import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/kotoba_category.dart';
import '../../data/models/kotoba_entry.dart';

/// Multiple-choice quiz over one category's word list: shows the word,
/// asks the user to pick its meaning from 4 shuffled options. Standalone
/// practice tool — quiz results don't affect the "Sudah Dipelajari" marks
/// from [KotobaWordDetailScreen], which stay a deliberate user action.
class KotobaQuizScreen extends StatefulWidget {
  final KotobaCategory category;
  final List<KotobaEntry> words;

  const KotobaQuizScreen({super.key, required this.category, required this.words});

  @override
  State<KotobaQuizScreen> createState() => _KotobaQuizScreenState();
}

class _QuizQuestion {
  final KotobaEntry entry;
  final List<String> options;
  final int correctIndex;

  _QuizQuestion({required this.entry, required this.options, required this.correctIndex});
}

class _KotobaQuizScreenState extends State<KotobaQuizScreen> {
  static const _questionCount = 10;

  late final List<_QuizQuestion> _questions = _buildQuestions();
  int _index = 0;
  int _score = 0;
  int? _selected;

  List<_QuizQuestion> _buildQuestions() {
    final random = Random();
    final pool = List<KotobaEntry>.from(widget.words)..shuffle(random);
    final chosen = pool.take(min(_questionCount, pool.length)).toList();

    return chosen.map((entry) {
      final distractorPool = widget.words.where((w) => w.id != entry.id).toList()..shuffle(random);
      final distractors = distractorPool.take(3).map((w) => w.meaning).toList();
      final options = [entry.meaning, ...distractors]..shuffle(random);
      return _QuizQuestion(
        entry: entry,
        options: options,
        correctIndex: options.indexOf(entry.meaning),
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
      appBar: AppBar(
        title: Text('Kuis · ${widget.category.name}'),
      ),
      body: SafeArea(
        child: finished ? _ResultView(score: _score, total: _questions.length, onRestart: _restart) : _buildQuestion(),
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
            'Apa arti kata ini?',
            style: TextStyle(fontSize: 14, color: AppColors.textNavy.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Column(
              children: [
                Text(
                  question.entry.kanji ?? question.entry.word,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  question.entry.reading,
                  style: TextStyle(fontSize: 14, color: AppColors.textNavy.withValues(alpha: 0.6)),
                ),
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
  final _OptionState state;
  final VoidCallback onTap;

  const _OptionTile({required this.text, required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color background;
    Color textColor = AppColors.textNavy;
    Color borderColor = Colors.transparent;
    IconData? icon;

    switch (state) {
      case _OptionState.neutral:
        background = AppColors.cardWhite;
        break;
      case _OptionState.correct:
        background = AppColors.secondaryBlue.withValues(alpha: 0.15);
        borderColor = AppColors.secondaryBlue;
        icon = Icons.check_circle;
        break;
      case _OptionState.wrong:
        background = AppColors.errorRed.withValues(alpha: 0.12);
        borderColor = AppColors.errorRed;
        icon = Icons.cancel;
        break;
      case _OptionState.disabled:
        background = AppColors.cardWhite;
        textColor = AppColors.textNavy.withValues(alpha: 0.4);
        break;
    }

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: state == _OptionState.neutral ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(text, style: TextStyle(fontSize: 14, color: textColor)),
              ),
              if (icon != null)
                Icon(icon, size: 20, color: state == _OptionState.correct ? AppColors.secondaryBlue : AppColors.errorRed),
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
            : 'Yuk, pelajari lagi kata-katanya!';

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

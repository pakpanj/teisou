import 'app_language.dart';
import 'cloze_example.dart';
import 'sentence_example.dart';

/// One distinct grammatical function/nuance of a [ParticleEntry] — e.g. に
/// alone covers location, direction, time, and more, each modeled as its
/// own [ParticleFunction] nested inside the same particle.
class ParticleFunction {
  final String id;
  final String title;
  final String explanation;
  final String formation;

  /// English renderings of the prose fields above, null until authored.
  final String? titleEn;
  final String? explanationEn;

  /// Full example sentences for the notes/encyclopedia display.
  final List<SentenceExample> sentenceExamples;

  /// Fill-in-the-blank sentences feeding the mini-game's question pool.
  final List<ClozeExample> clozeExamples;

  ParticleFunction({
    required this.id,
    required this.title,
    required this.explanation,
    required this.formation,
    this.titleEn,
    this.explanationEn,
    this.sentenceExamples = const [],
    this.clozeExamples = const [],
  });

  String localizedTitle(AppLanguage language) => _pick(language, title, titleEn);

  String localizedExplanation(AppLanguage language) =>
      _pick(language, explanation, explanationEn);

  static String _pick(AppLanguage language, String id, String? en) =>
      language == AppLanguage.english && en != null && en.isNotEmpty ? en : id;

  factory ParticleFunction.fromJson(Map<String, dynamic> json) =>
      ParticleFunction(
        id: json['id'] as String,
        title: json['title'] as String,
        explanation: json['explanation'] as String,
        formation: json['formation'] as String,
        titleEn: json['titleEn'] as String?,
        explanationEn: json['explanationEn'] as String?,
        sentenceExamples: (json['sentenceExamples'] as List? ?? [])
            .map((e) => SentenceExample.fromJson(e as Map<String, dynamic>))
            .toList(),
        clozeExamples: (json['clozeExamples'] as List? ?? [])
            .map((e) => ClozeExample.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

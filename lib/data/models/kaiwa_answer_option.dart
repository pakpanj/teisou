import 'app_language.dart';

/// One multiple-choice option for a [KaiwaLine] user turn — the learner
/// taps the option they think is the correct reply, they never type or
/// speak an answer. Exactly one option per turn has [isCorrect] true; the
/// rest are hand-authored plausible-but-wrong distractors (same reasoning
/// as `ClozeExample`'s before/after split — content like this is authored
/// explicitly rather than derived at runtime).
class KaiwaAnswerOption {
  final String japanese;
  final String? romaji;
  final String translation;

  /// English rendering of [translation], null until authored.
  final String? translationEn;

  final bool isCorrect;

  /// Tag naming the emotional tone this phrasing conveys (e.g. 'semangat'
  /// for 頑張ります), resolved to an emoji reaction by
  /// `kaiwaExpressionEmoji` — null for a neutral phrasing with no reaction.
  /// Only meaningful on the correct option.
  final String? expressionTag;

  /// Optional short grammar/vocab note, revealed alongside the option once
  /// the learner picks it correctly.
  final String? note;

  KaiwaAnswerOption({
    required this.japanese,
    required this.translation,
    required this.isCorrect,
    this.translationEn,
    this.romaji,
    this.expressionTag,
    this.note,
  });

  String localizedTranslation(AppLanguage language) =>
      language == AppLanguage.english &&
              translationEn != null &&
              translationEn!.isNotEmpty
          ? translationEn!
          : translation;

  factory KaiwaAnswerOption.fromJson(Map<String, dynamic> json) =>
      KaiwaAnswerOption(
        japanese: json['japanese'] as String,
        translation: json['translation'] as String,
        translationEn: json['translationEn'] as String?,
        isCorrect: json['isCorrect'] as bool? ?? false,
        romaji: json['romaji'] as String?,
        expressionTag: json['expressionTag'] as String?,
        note: json['note'] as String?,
      );
}

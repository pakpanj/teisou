/// One accepted way to respond to a [KaiwaLine] user turn — a dialogue turn
/// can have several correct phrasings (casual/formal, with/without a
/// particle), each checked against the learner's typed or spoken input by
/// `KaiwaAnswerMatcher`.
class KaiwaAcceptedAnswer {
  final String japanese;
  final String? romaji;
  final String translation;

  /// Additional Japanese phrasings considered correct for the same turn
  /// (hand-authored, same reasoning as `ClozeExample`'s before/after split —
  /// deriving variants at runtime would be fragile for short Japanese text).
  final List<String> variants;

  /// Tag naming the emotional tone this phrasing conveys (e.g. 'semangat'
  /// for 頑張ります), resolved to an emoji reaction by
  /// `kaiwaExpressionEmoji` — null for a neutral phrasing with no reaction.
  final String? expressionTag;

  KaiwaAcceptedAnswer({
    required this.japanese,
    required this.translation,
    this.romaji,
    this.variants = const [],
    this.expressionTag,
  });

  factory KaiwaAcceptedAnswer.fromJson(Map<String, dynamic> json) =>
      KaiwaAcceptedAnswer(
        japanese: json['japanese'] as String,
        translation: json['translation'] as String,
        romaji: json['romaji'] as String?,
        variants: (json['variants'] as List? ?? []).cast<String>(),
        expressionTag: json['expressionTag'] as String?,
      );
}

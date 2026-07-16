import '../../../data/models/kaiwa_accepted_answer.dart';

/// Result of checking a learner's input against a dialogue turn's accepted
/// answers.
class KaiwaMatchResult {
  final bool isCorrect;
  final KaiwaAcceptedAnswer? matchedAnswer;

  const KaiwaMatchResult({required this.isCorrect, this.matchedAnswer});
}

/// Offline matcher for Kaiwa's interactive dialogue turns — no network or
/// LLM call, just normalized string comparison against hand-authored
/// accepted answers (the same "hand-author rather than derive" reasoning as
/// `ClozeExample`'s before/after split, since Japanese input from typing or
/// on-device speech-to-text is too noisy for confident runtime derivation).
class KaiwaAnswerMatcher {
  const KaiwaAnswerMatcher();

  KaiwaMatchResult check(String input, List<KaiwaAcceptedAnswer> accepted) {
    final normalizedInput = _normalize(input);
    if (normalizedInput.isEmpty) {
      return const KaiwaMatchResult(isCorrect: false);
    }
    for (final answer in accepted) {
      final candidates = [
        answer.japanese,
        if (answer.romaji != null) answer.romaji!,
        ...answer.variants,
      ];
      for (final candidate in candidates) {
        if (_normalize(candidate) == normalizedInput) {
          return KaiwaMatchResult(isCorrect: true, matchedAnswer: answer);
        }
      }
    }
    return const KaiwaMatchResult(isCorrect: false);
  }

  /// Trims, lowercases (so typed romaji matches case-insensitively), and
  /// strips whitespace/common Japanese punctuation so minor formatting
  /// differences (a trailing 。, extra spaces from voice input) don't fail
  /// an otherwise-correct answer.
  String _normalize(String text) {
    return text.trim().toLowerCase().replaceAll(RegExp(r'[\s、。！?？!]'), '');
  }
}

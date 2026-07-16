import 'kaiwa_accepted_answer.dart';
import 'sentence_example.dart';

/// One turn in a [KaiwaEntry] dialogue. Either a scripted NPC line
/// ([npcLine] populated, [isUserTurn] false) or a learner turn the user must
/// answer by typing or speaking ([acceptedAnswers] populated, [isUserTurn]
/// true) — kept as one class with nullable fields rather than a sealed
/// hierarchy since a dialogue is just a flat ordered list of these.
class KaiwaLine {
  final String id;
  final String speaker;
  final bool isUserTurn;
  final SentenceExample? npcLine;
  final List<KaiwaAcceptedAnswer> acceptedAnswers;

  /// Short hint shown above the input for a user turn, e.g. "Balas sapaan
  /// ini" — null for NPC lines.
  final String? promptHint;

  /// Optional short grammar/vocab note for this line, shown as a small
  /// caption under the bubble.
  final String? note;

  KaiwaLine({
    required this.id,
    required this.speaker,
    required this.isUserTurn,
    this.npcLine,
    this.acceptedAnswers = const [],
    this.promptHint,
    this.note,
  });

  factory KaiwaLine.fromJson(Map<String, dynamic> json) => KaiwaLine(
        id: json['id'] as String,
        speaker: json['speaker'] as String,
        isUserTurn: json['isUserTurn'] as bool? ?? false,
        npcLine: json['npcLine'] == null
            ? null
            : SentenceExample.fromJson(
                json['npcLine'] as Map<String, dynamic>,
              ),
        acceptedAnswers: (json['acceptedAnswers'] as List? ?? [])
            .map(
              (e) => KaiwaAcceptedAnswer.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
        promptHint: json['promptHint'] as String?,
        note: json['note'] as String?,
      );
}

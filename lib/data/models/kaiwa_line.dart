import 'kaiwa_answer_option.dart';
import 'sentence_example.dart';

/// One turn in a [KaiwaEntry] dialogue. Either a scripted NPC line
/// ([npcLine] + [imagePath] populated, [isUserTurn] false — rendered as
/// just an image and a speak button, no visible text) or a learner turn
/// ([options] populated, [isUserTurn] true) — the learner taps the
/// multiple-choice option they think is the correct reply rather than
/// typing or speaking one. Kept as one class with nullable fields rather
/// than a sealed hierarchy since a dialogue is just a flat ordered list of
/// these.
class KaiwaLine {
  final String id;
  final String speaker;
  final bool isUserTurn;
  final SentenceExample? npcLine;

  /// Firebase Storage path for this NPC line's illustration (e.g.
  /// `kaiwa_images/perkenalan/kaiwa_kenalan_teman_baru_1.png`) — resolved
  /// on-demand by `KaiwaImage`, same on-demand + placeholder-fallback
  /// pattern as Kotoba's vocab illustrations. Null for user turns.
  final String? imagePath;

  final List<KaiwaAnswerOption> options;

  KaiwaLine({
    required this.id,
    required this.speaker,
    required this.isUserTurn,
    this.npcLine,
    this.imagePath,
    this.options = const [],
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
        imagePath: json['imagePath'] as String?,
        options: (json['options'] as List? ?? [])
            .map((e) => KaiwaAnswerOption.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

import '../../data/models/kaiwa_line.dart';

/// One speaker's turn in a listening clip.
class ScriptTurn {
  const ScriptTurn({required this.gender, required this.text});

  /// Null when the clip does not say who is talking.
  final KaiwaGender? gender;
  final String text;

  @override
  bool operator ==(Object other) =>
      other is ScriptTurn && other.gender == gender && other.text == text;

  @override
  int get hashCode => Object.hash(gender, text);
}

/// Fullwidth colon. Japanese scripts use `男：`, not `男:`, and every marker
/// in the Choukai dataset is the fullwidth form — but the halfwidth one is
/// accepted too, since it is the sort of thing that slips into hand-typed
/// content and would silently break the split.
const _colons = ['：', ':'];

/// Splits a Choukai clip into speaker turns.
///
/// **This exists because the app was reading the stage directions out
/// loud.** Every clip in the dataset is a script — `男：すみません、今何時
/// ですか。女：今、三時半です。` — and the whole string, markers included,
/// was handed to the TTS engine as one utterance. So a learner heard
/// "otoko" and "onna" pronounced as words between the lines, in a single
/// voice, which is exactly what was reported.
///
/// The markers are also the answer to who is speaking, which no amount of
/// guessing from a clip id could have got right: 122 of the 150 clips are
/// two-person dialogues, so there is no single correct voice for the clip
/// at all — each turn has its own.
///
/// Splitting is safe here because the data was checked first: all 150
/// clips begin with a marker, there are 552 markers in total, and 男/女
/// appear **nowhere else** in any clip's text, so nothing that is really
/// part of the speech can be mistaken for a marker.
///
/// Text with no markers comes back as a single turn with a null gender —
/// the caller then falls back to whatever it would have done before.
List<ScriptTurn> parseSpokenScript(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return const [];

  final turns = <ScriptTurn>[];
  final buffer = StringBuffer();
  KaiwaGender? current;

  void flush() {
    final spoken = buffer.toString().trim();
    buffer.clear();
    if (spoken.isEmpty) return;
    turns.add(ScriptTurn(gender: current, text: spoken));
  }

  for (var i = 0; i < text.length; i++) {
    final char = text[i];
    final isMarker = (char == '男' || char == '女') &&
        i + 1 < text.length &&
        _colons.contains(text[i + 1]);

    if (isMarker) {
      flush();
      current = char == '男' ? KaiwaGender.male : KaiwaGender.female;
      i++; // skip the colon as well, so it is never spoken
      continue;
    }
    buffer.write(char);
  }
  flush();

  return turns;
}

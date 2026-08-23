/// Whether an exam runs against a clock.
///
/// **Both are real exam modes, not a setting.** A timed run is what a JLPT
/// paper actually feels like and is the one worth bragging about; an
/// untimed run is for a learner who is still working out *how* to answer
/// and would simply be beaten by a clock. Offering only the first turns
/// every early attempt into a loss; offering only the second never
/// prepares anyone for the real thing.
enum ExamTiming { timed, untimed }

/// What kind of exam is being timed — each starts from its own suggested
/// pace.
enum ExamKind { kana, kanji, dokkai, choukai }

/// **The clock runs per question, not per paper.**
///
/// A single budget for the whole paper lets a learner spend it wherever
/// they like, which is how a real exam works — but it also means the
/// clock can quietly run out during question three and end a paper the
/// learner thought they were doing well at. Per question, the pressure is
/// the same on every question, running out costs exactly one question,
/// and the number on screen means something a child can act on: *this*
/// question has this long left.
///
/// The choices a learner can pick from, in seconds. Wide enough to cover
/// both a drill (5 seconds, recall or nothing) and a careful reading pace
/// (2 minutes), because the same exam is used for both.
const kExamPerQuestionChoices = <int>[5, 10, 15, 20, 30, 45, 60, 90, 120];

/// Where the picker starts before the learner changes it.
///
/// Different per kind rather than one number for all four: recognising a
/// kana is a glance, while a Dokkai question means reading a passage
/// first. Generous on purpose — the clock is meant to add a little
/// pressure to someone who already knows the material, not to be the
/// thing that decides the score.
int examDefaultSecondsPerQuestion(ExamKind kind) => switch (kind) {
  ExamKind.kana => 15,
  ExamKind.kanji => 20,
  // Listening: the clip has to play before the question can even be
  // considered, and a learner may replay it once.
  ExamKind.choukai => 45,
  // Reading: a passage plus its question.
  ExamKind.dokkai => 60,
};

/// The suggested pace, snapped to whichever offered choice it matches.
///
/// Asserted rather than left to chance: a default that is not in
/// [kExamPerQuestionChoices] would open the picker with nothing selected.
Duration examDefaultLimit(ExamKind kind) {
  final seconds = examDefaultSecondsPerQuestion(kind);
  assert(
    kExamPerQuestionChoices.contains(seconds),
    'default pace for $kind ($seconds s) is not one of the offered choices',
  );
  return Duration(seconds: seconds);
}

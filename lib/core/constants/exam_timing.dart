/// Whether an exam runs against a clock.
///
/// **Both are real exam modes, not a setting.** A timed run is what a JLPT
/// paper actually feels like and is the one worth bragging about; an
/// untimed run is for a learner who is still working out *how* to answer
/// and would simply be beaten by a clock. Offering only the first turns
/// every early attempt into a loss; offering only the second never
/// prepares anyone for the real thing.
enum ExamTiming { timed, untimed }

/// What kind of exam is being timed — each has its own idea of how long a
/// question reasonably takes.
enum ExamKind { kana, kanji, dokkai, choukai }

/// Seconds allowed per question, by exam kind.
///
/// Deliberately different per kind rather than one number for all four:
/// recognising a kana is a glance, while a Dokkai question means reading
/// a passage first. One shared figure would be either brutal for Dokkai
/// or meaningless for Kana.
///
/// These are generous on purpose. The clock is meant to add a little
/// pressure to a learner who already knows the material, not to be the
/// thing that decides the score — a child who knows the answer should
/// never lose it to the timer.
int examSecondsPerQuestion(ExamKind kind) => switch (kind) {
  ExamKind.kana => 15,
  ExamKind.kanji => 20,
  // Listening: the clip has to play before the question can even be
  // considered, and a learner may replay it once.
  ExamKind.choukai => 40,
  // Reading: a passage plus its question.
  ExamKind.dokkai => 60,
};

/// The whole exam's budget — one clock for the paper, not one per
/// question.
///
/// A per-question timer would force the pace of every single question and
/// punish a learner for thinking hard about one of them. A single budget
/// lets them spend it where they need it, which is how a real exam works.
Duration examTimeLimit(ExamKind kind, int questionCount) =>
    Duration(seconds: examSecondsPerQuestion(kind) * questionCount);

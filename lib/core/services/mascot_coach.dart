import 'dart:math';

import '../localization/app_strings.dart';
import '../widgets/mascot_widget.dart';

/// What just happened in a lesson, as far as the mascot is concerned.
enum CoachMoment {
  /// A correct answer, nothing special about it.
  correct,

  /// Several correct in a row — worth more than another "benar!".
  streak,

  /// A wrong answer.
  wrong,

  /// The learner finished, and got most of it right.
  finishedStrong,

  /// The learner finished without a single mistake.
  finishedPerfect,

  /// The learner finished, but struggled. Deliberately still warm.
  finishedWeak,
}

/// One thing for the mascot to say, with the face to say it with.
class CoachLine {
  const CoachLine({required this.mood, required this.message});

  final MascotMood mood;
  final String message;

  @override
  bool operator ==(Object other) =>
      other is CoachLine && other.mood == mood && other.message == message;

  @override
  int get hashCode => Object.hash(mood, message);
}

/// Picks what the mascot says while the learner is working through a lesson.
///
/// Kept as plain logic with no widgets in it, because the part that can
/// actually be wrong is the *choosing* — whether it repeats, whether it
/// stays kind after a wrong answer — and none of that is visible in a
/// screenshot of a single question.
///
/// **Two rules this is built around.**
///
/// It never scolds. A wrong answer gets an encouraging face and the right
/// answer spelled out, never [MascotMood.sad] and never a "wrong!". The
/// audience is children, and the app already made this call once, in
/// Kaiwa: a wrong option costs nothing and every option stays tappable.
/// A mascot that looks hurt when a child guesses wrong would undo that
/// from the other direction.
///
/// It does not repeat itself back to back. Ten questions with the same
/// "Bagus!" underneath each one is worse than silence — it reads as a
/// sticker, not a companion, and children notice faster than adults do.
/// So each moment keeps its own pool and remembers what it said last.
class MascotCoach {
  MascotCoach({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Last line played per moment, so a repeat can be avoided without
  /// forbidding a line from ever coming back.
  final Map<CoachMoment, int> _lastPick = {};

  /// How many correct answers in a row, which is what turns an ordinary
  /// [CoachMoment.correct] into a [CoachMoment.streak].
  int _run = 0;

  /// A run this long earns the louder reaction. Three is deliberate: two
  /// is a coincidence a learner does not feel, and five takes most of a
  /// short quiz to reach, so it would rarely fire at all.
  static const int streakThreshold = 3;

  int get currentRun => _run;

  /// Records an answer and returns what the mascot should say about it.
  ///
  /// [correctAnswer] is named back to the learner when they get it wrong —
  /// the one piece of teaching this can honestly do everywhere. A real
  /// per-question explanation would have to be authored per question, and
  /// inventing one here would mean inventing grammar.
  CoachLine onAnswer(
    AppStrings s, {
    required bool correct,
    required String correctAnswer,
  }) {
    if (!correct) {
      _run = 0;
      return _pick(CoachMoment.wrong, _wrongLines(s, correctAnswer));
    }
    _run++;
    if (_run >= streakThreshold) {
      return _pick(CoachMoment.streak, _streakLines(s, _run));
    }
    return _pick(CoachMoment.correct, _correctLines(s));
  }

  /// What the mascot says once the last question is answered.
  CoachLine onFinished(AppStrings s, {required int score, required int total}) {
    _run = 0;
    if (total > 0 && score == total) {
      return _pick(CoachMoment.finishedPerfect, _perfectLines(s, total));
    }
    // Two thirds, not "all correct": a bar only a perfect run clears turns
    // the warm ending into something most learners never see. Perfect gets
    // its own moment above rather than raising this one.
    final strong = total > 0 && score * 3 >= total * 2;
    return strong
        ? _pick(CoachMoment.finishedStrong, _strongLines(s, score, total))
        : _pick(CoachMoment.finishedWeak, _weakLines(s, score, total));
  }

  /// Resets between lessons, so a fresh quiz does not inherit the previous
  /// one's run of correct answers.
  void reset() {
    _run = 0;
    _lastPick.clear();
  }

  CoachLine _pick(CoachMoment moment, List<CoachLine> pool) {
    if (pool.length == 1) return pool.first;
    final last = _lastPick[moment];
    var index = _random.nextInt(pool.length);
    if (index == last) index = (index + 1) % pool.length;
    _lastPick[moment] = index;
    return pool[index];
  }

  // --- the lines themselves ------------------------------------------------
  //
  // Grouped by moment rather than by mood so the tone of a whole moment can
  // be read at a glance — which is how a wrong-answer line that had crept
  // into scolding would be spotted.

  List<CoachLine> _correctLines(AppStrings s) => [
        CoachLine(mood: MascotMood.happy, message: s.coachCorrect1),
        CoachLine(mood: MascotMood.excited, message: s.coachCorrect2),
        CoachLine(mood: MascotMood.proud, message: s.coachCorrect3),
        CoachLine(mood: MascotMood.happy, message: s.coachCorrect4),
      ];

  List<CoachLine> _streakLines(AppStrings s, int run) => [
        CoachLine(mood: MascotMood.cheering, message: s.coachStreak1(run)),
        CoachLine(mood: MascotMood.proud, message: s.coachStreak2(run)),
        CoachLine(mood: MascotMood.cheering, message: s.coachStreak3(run)),
      ];

  /// Every one of these is encouraging and names the right answer. If a
  /// line is ever added here that a child could read as being told off,
  /// it belongs somewhere else — see this class's own doc comment.
  ///
  /// [MascotMood.encouraging] rather than [MascotMood.happy]: a plainly
  /// happy face over "that was wrong" reads as pleased about the slip.
  /// The encouraging pose is the one that means "it is fine, try again",
  /// which is what these words are actually saying.
  List<CoachLine> _wrongLines(AppStrings s, String answer) => [
        CoachLine(mood: MascotMood.encouraging, message: s.coachWrong1(answer)),
        CoachLine(mood: MascotMood.encouraging, message: s.coachWrong2(answer)),
        CoachLine(mood: MascotMood.determined, message: s.coachWrong3(answer)),
        CoachLine(mood: MascotMood.explaining, message: s.coachWrong4(answer)),
      ];

  List<CoachLine> _strongLines(AppStrings s, int score, int total) => [
        CoachLine(
          mood: MascotMood.cheering,
          message: s.coachFinishedStrong1(score, total),
        ),
        CoachLine(
          mood: MascotMood.proud,
          message: s.coachFinishedStrong2(score, total),
        ),
      ];

  /// A clean sweep gets a face nothing else uses, so the rarest result in
  /// the app does not look the same as a merely good one.
  List<CoachLine> _perfectLines(AppStrings s, int total) => [
        CoachLine(mood: MascotMood.surprised, message: s.coachPerfect1(total)),
        CoachLine(mood: MascotMood.cheering, message: s.coachPerfect2(total)),
      ];

  List<CoachLine> _weakLines(AppStrings s, int score, int total) => [
        CoachLine(
          mood: MascotMood.encouraging,
          message: s.coachFinishedWeak1(score, total),
        ),
        CoachLine(
          mood: MascotMood.determined,
          message: s.coachFinishedWeak2(score, total),
        ),
      ];
}

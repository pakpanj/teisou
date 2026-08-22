import '../../core/localization/app_strings.dart';
import '../../core/widgets/mascot_widget.dart';
import 'coach_mark_tour.dart';

/// Ids the home screen's tour points at.
///
/// Constants rather than bare strings, so a renamed anchor is a compile
/// error on both sides instead of a step that silently finds nothing and
/// skips itself.
const kTutorialHiragana = 'home.hiragana';
const kTutorialCurriculum = 'home.curriculum';
const kTutorialCardGame = 'home.cardGame';
const kTutorialExamTab = 'home.examTab';
const kTutorialProfileTab = 'home.profileTab';

/// The mascot walking a first-time learner around the real home screen.
///
/// Five stops, chosen as the five things a learner has to find to use
/// the app at all: where the alphabet is, where the guided path is,
/// where the game is, where the exams are, and where their own progress
/// lives. Everything else on that screen can be discovered by scrolling.
///
/// **The order is the order a learner should meet them in**, not the
/// order they appear down the page — kana first because nothing else
/// makes sense before it, progress last because there is none yet.
List<CoachStep> homeTourSteps(AppStrings s) => [
      CoachStep(
        anchorId: kTutorialHiragana,
        message: s.tourHiragana,
        mood: MascotMood.explaining,
      ),
      CoachStep(
        anchorId: kTutorialCurriculum,
        message: s.tourCurriculum,
        mood: MascotMood.reading,
      ),
      CoachStep(
        anchorId: kTutorialCardGame,
        message: s.tourCardGame,
        mood: MascotMood.battleReady,
      ),
      CoachStep(
        anchorId: kTutorialExamTab,
        message: s.tourExam,
        mood: MascotMood.determined,
      ),
      CoachStep(
        anchorId: kTutorialProfileTab,
        message: s.tourProfile,
        mood: MascotMood.cheering,
      ),
    ];

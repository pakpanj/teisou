import '../../core/localization/app_strings.dart';
import '../../core/widgets/mascot_widget.dart';
import 'coach_mark_tour.dart';

/// A short coach-mark tour inside each module, shown the first time that
/// module is opened.
///
/// **Not a second copy of the home tour.** The home tour says what each
/// module is for; these say the things a learner cannot work out by
/// looking — the quiz hiding behind an icon in the app bar, a chapter
/// that is locked rather than broken, a character that animates when you
/// tap it. Anything already obvious from the screen is left out, which is
/// why most of these are two steps rather than five.
///
/// Each one lives on the screen where the rule actually applies, not on
/// the module's front page: the quiz icon is on the level screen, so that
/// is where the tour runs.
const kTutorialQuizIcon = 'module.quizIcon';
const kTutorialFirstItem = 'module.firstItem';
const kTutorialSecondItem = 'module.secondItem';

/// Two steps, reused by every module that is "a list of things, plus a
/// quiz behind an icon" — Kanji, Kotoba, Bunpou and Partikel all are.
///
/// The ids are shared rather than one pair per module because only one
/// module is ever on screen at a time, and a shared id keeps a new module
/// from needing its own constants to say the same two things.
List<CoachStep> _listAndQuizTour(String itemMessage, AppStrings s) => [
  CoachStep(
    anchorId: kTutorialFirstItem,
    message: itemMessage,
    mood: MascotMood.explaining,
  ),
  CoachStep(
    anchorId: kTutorialQuizIcon,
    message: s.tourQuizIcon,
    mood: MascotMood.determined,
  ),
];

List<CoachStep> kanjiTourSteps(AppStrings s) =>
    _listAndQuizTour(s.tourKanjiTile, s);

List<CoachStep> kotobaTourSteps(AppStrings s) =>
    _listAndQuizTour(s.tourKotobaTile, s);

List<CoachStep> bunpouTourSteps(AppStrings s) =>
    _listAndQuizTour(s.tourBunpouTile, s);

List<CoachStep> particleTourSteps(AppStrings s) =>
    _listAndQuizTour(s.tourPartikelTile, s);

/// Kana has no quiz icon of its own — the exam lives in its own tab — so
/// it only has the one thing worth pointing at.
List<CoachStep> kanaTourSteps(AppStrings s) => [
  CoachStep(
    anchorId: kTutorialFirstItem,
    message: s.tourKanaTile,
    mood: MascotMood.explaining,
  ),
];

/// The chapters are the one place in the app where something is
/// deliberately unavailable, and a locked card with no explanation reads
/// as a bug rather than as a next step.
List<CoachStep> babTourSteps(AppStrings s) => [
  CoachStep(
    anchorId: kTutorialFirstItem,
    message: s.tourBabActive,
    mood: MascotMood.explaining,
  ),
  CoachStep(
    anchorId: kTutorialSecondItem,
    message: s.tourBabLocked,
    mood: MascotMood.encouraging,
  ),
];

List<CoachStep> kaiwaTourSteps(AppStrings s) => [
  CoachStep(
    anchorId: kTutorialFirstItem,
    message: s.tourKaiwaLevel,
    mood: MascotMood.happy,
  ),
];

List<CoachStep> dokkaiTourSteps(AppStrings s) => [
  CoachStep(
    anchorId: kTutorialFirstItem,
    message: s.tourDokkaiLevel,
    mood: MascotMood.reading,
  ),
];

List<CoachStep> choukaiTourSteps(AppStrings s) => [
  CoachStep(
    anchorId: kTutorialFirstItem,
    message: s.tourChoukaiLevel,
    mood: MascotMood.explaining,
  ),
];

import '../../core/localization/app_strings.dart';
import '../../core/widgets/mascot_widget.dart';
import 'coach_mark_tour.dart';

/// Ids the home screen's tour points at.
///
/// Constants rather than bare strings, so a renamed anchor is a compile
/// error on both sides instead of a step that silently finds nothing and
/// skips itself.
const kTutorialLevel = 'home.level';
const kTutorialHiragana = 'home.hiragana';
const kTutorialKatakana = 'home.katakana';
const kTutorialCurriculum = 'home.curriculum';
const kTutorialCardGame = 'home.cardGame';
const kTutorialKotoba = 'home.kotoba';
const kTutorialKanji = 'home.kanji';
const kTutorialKaiwa = 'home.kaiwa';
const kTutorialDokkai = 'home.dokkai';
const kTutorialChoukai = 'home.choukai';
const kTutorialBunpou = 'home.bunpou';
const kTutorialPartikel = 'home.partikel';
const kTutorialExamTab = 'home.examTab';
const kTutorialProfileTab = 'home.profileTab';

/// The mascot walking a first-time learner around the real home screen.
///
/// Every card a learner can actually open, in the order they appear down
/// the page. **Screen order, not lesson order** — an earlier version put
/// them in the order a learner should meet them in, which read fine as a
/// list of five but sends a fourteen-stop tour scrolling up and down the
/// page between consecutive steps. Following the page instead means each
/// step is a short scroll from the one before, and the page's own layout
/// already groups things sensibly.
///
/// Three cards are deliberately left out: Cam Detector (locked while its
/// bugs are open — see CLAUDE.md), and the two Segera Hadir placeholders,
/// which have nothing behind them to explain.
List<CoachStep> homeTourSteps(AppStrings s) => [
  CoachStep(
    anchorId: kTutorialLevel,
    message: s.tourLevel,
    mood: MascotMood.cheering,
  ),
  CoachStep(
    anchorId: kTutorialHiragana,
    message: s.tourHiragana,
    mood: MascotMood.explaining,
  ),
  CoachStep(
    anchorId: kTutorialKatakana,
    message: s.tourKatakana,
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
    anchorId: kTutorialKotoba,
    message: s.tourKotoba,
    mood: MascotMood.explaining,
  ),
  CoachStep(
    anchorId: kTutorialKanji,
    message: s.tourKanji,
    mood: MascotMood.reading,
  ),
  CoachStep(
    anchorId: kTutorialKaiwa,
    message: s.tourKaiwa,
    mood: MascotMood.happy,
  ),
  CoachStep(
    anchorId: kTutorialDokkai,
    message: s.tourDokkai,
    mood: MascotMood.reading,
  ),
  CoachStep(
    anchorId: kTutorialChoukai,
    message: s.tourChoukai,
    mood: MascotMood.explaining,
  ),
  CoachStep(
    anchorId: kTutorialBunpou,
    message: s.tourBunpou,
    mood: MascotMood.reading,
  ),
  CoachStep(
    anchorId: kTutorialPartikel,
    message: s.tourPartikel,
    mood: MascotMood.explaining,
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

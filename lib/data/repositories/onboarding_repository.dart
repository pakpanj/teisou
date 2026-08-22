import 'package:shared_preferences/shared_preferences.dart';

/// Which walkthrough — there is one per module now.
///
/// The home tour explains the app; Card Game Mode has rules of its own
/// (a star ladder, cards locked to your tier, a ten-second window to
/// choose one) that nothing on the home screen prepares anyone for, so
/// it gets its own. Each is remembered separately: a learner who has
/// used the app for a month and opens the card mode for the first time
/// should still be shown how it works.
///
/// The same holds for every module: what a learner needs told about
/// Choukai (there is audio, and it plays on tap) has nothing to do with
/// what they need told about Kanji (the character animates, and the quiz
/// hides behind an icon), so each is remembered on its own.
enum TutorialId {
  home,
  cardGame,
  kana,
  bab,
  kotoba,
  kanji,
  kaiwa,
  dokkai,
  choukai,
  bunpou,
  particle,
}

extension TutorialIdX on TutorialId {
  /// The stored key.
  ///
  /// Home deliberately keeps the original `onboarding_seen_v1` rather
  /// than moving to a tidier `tutorial_home_v1`. Renaming it would read
  /// as "never seen" for every learner already using the app, and put
  /// the tour back in front of all of them.
  ///
  /// The version suffix is not decoration: rewriting a tutorial for a
  /// redesigned screen and leaving the key alone shows the new version
  /// to nobody who already has the app. Bump it and everyone sees it
  /// once more.
  String get prefsKey => switch (this) {
        TutorialId.home => 'onboarding_seen_v1',
        TutorialId.cardGame => 'tutorial_card_game_v1',
        TutorialId.kana => 'tutorial_kana_v1',
        TutorialId.bab => 'tutorial_bab_v1',
        TutorialId.kotoba => 'tutorial_kotoba_v1',
        TutorialId.kanji => 'tutorial_kanji_v1',
        TutorialId.kaiwa => 'tutorial_kaiwa_v1',
        TutorialId.dokkai => 'tutorial_dokkai_v1',
        TutorialId.choukai => 'tutorial_choukai_v1',
        TutorialId.bunpou => 'tutorial_bunpou_v1',
        TutorialId.particle => 'tutorial_particle_v1',
      };
}

/// Which walkthroughs this device has already seen.
///
/// **Deliberately local only, with no Firestore mirror** — unlike every
/// other progress repository in the app. Learning progress belongs to the
/// person and should follow them to a new phone; "has been shown how this
/// app works" belongs to the *device*. Mirroring it would mean a learner
/// installing on a second phone gets dropped straight onto the home screen
/// with no explanation, which is exactly the case the tutorial exists for.
class OnboardingRepository {
  Future<bool> hasSeen(TutorialId id) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(id.prefsKey) ?? false;
  }

  Future<void> markSeen(TutorialId id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(id.prefsKey, true);
  }

  /// Lets the learner watch one again from Profile. Also what a tester
  /// needs, since otherwise checking a tutorial means reinstalling.
  Future<void> reset(TutorialId id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(id.prefsKey);
  }
}

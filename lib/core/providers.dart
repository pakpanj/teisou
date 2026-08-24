import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/app_language.dart';
import '../data/models/battle_match.dart';
import '../data/models/card_game_rank.dart';
import '../data/models/kanji_entry.dart';
import '../data/models/presence_status.dart';
import '../data/models/stroke_speed.dart';
import '../data/models/app_theme_mode.dart';
import '../data/models/kana_character.dart';
import '../data/models/kana_type.dart';
import '../data/models/kana_type_progress.dart';
import '../data/models/subscription.dart';
import '../data/models/xp_progress.dart';
import '../data/models/user_profile.dart';
import '../data/repositories/language_repository.dart';
import '../data/repositories/stroke_speed_repository.dart';
import '../data/repositories/theme_repository.dart';
import '../data/models/ad_audience.dart';
import '../data/repositories/ad_audience_repository.dart';
import '../data/repositories/bab_progress_repository.dart';
import '../data/repositories/bab_repository.dart';
import '../data/repositories/bunpou_level_repository.dart';
import '../data/repositories/bunpou_progress_repository.dart';
import '../data/repositories/bunpou_repository.dart';
import '../data/repositories/choukai_level_repository.dart';
import '../data/repositories/choukai_repository.dart';
import '../data/repositories/clan_announcement_repository.dart';
import '../data/repositories/clan_message_repository.dart';
import '../data/repositories/battle_repository.dart';
import '../data/repositories/battle_invite_repository.dart';
import '../data/repositories/matchmaking_repository.dart';
import '../data/repositories/clan_repository.dart';
import '../data/repositories/dictionary_repository.dart';
import '../data/repositories/direct_message_repository.dart';
import '../data/repositories/notification_repository.dart';
import '../data/repositories/dokkai_level_repository.dart';
import '../data/repositories/dokkai_repository.dart';
import '../data/repositories/exam_history_repository.dart';
import '../data/repositories/exam_repository.dart';
import '../data/repositories/friend_repository.dart';
import '../data/repositories/kanji_combo_repository.dart';
import '../data/repositories/kaiwa_category_repository.dart';
import '../data/repositories/kaiwa_level_repository.dart';
import '../data/repositories/kaiwa_progress_repository.dart';
import '../data/repositories/kaiwa_repository.dart';
import '../data/repositories/kana_repository.dart';
import '../data/repositories/kanji_level_repository.dart';
import '../data/repositories/kanji_progress_repository.dart';
import '../data/repositories/kanji_repository.dart';
import '../data/repositories/kotoba_category_repository.dart';
import '../data/repositories/kotoba_progress_repository.dart';
import '../data/repositories/kotoba_repository.dart';
import '../data/repositories/leaderboard_repository.dart';
import '../data/repositories/particle_category_repository.dart';
import '../data/repositories/particle_progress_repository.dart';
import '../data/repositories/particle_repository.dart';
import '../data/repositories/progress_repository.dart';
import '../data/repositories/saved_words_repository.dart';
import 'firebase/firestore_paths.dart';
import 'localization/app_strings.dart';
import 'services/ad_service.dart';
import 'services/coin_spend_service.dart';
import 'services/iap_service.dart';
import 'services/auth_service.dart';
import 'services/fcm_service.dart';
import 'services/furigana_dictionary.dart';
import 'services/kana_keyboard_input.dart';
import 'services/presence_service.dart';
import 'services/romaji_converter.dart';
import 'services/rank_skip_service.dart';
import 'services/tts_service.dart';
import '../data/repositories/onboarding_repository.dart';
import '../data/repositories/plan_intro_repository.dart';

final languageRepositoryProvider = Provider<LanguageRepository>(
  (ref) => LanguageRepository(),
);

/// Current UI-chrome language. Initial value is overridden in `main.dart`
/// from the persisted SharedPreferences value before `runApp` — the
/// default here (Indonesian) only applies if that override is somehow
/// missing (e.g. a test harness building the app without it).
final languageProvider = StateProvider<AppLanguage>(
  (ref) => AppLanguage.indonesian,
);

/// Screens read UI-chrome text through this instead of hardcoding
/// Indonesian strings directly — see [AppStrings] for exactly which
/// screens are wired up so far.
final appStringsProvider = Provider<AppStrings>(
  (ref) => AppStrings(ref.watch(languageProvider)),
);

final strokeSpeedRepositoryProvider = Provider<StrokeSpeedRepository>(
  (ref) => StrokeSpeedRepository(),
);

/// How fast the kana flashcard draws each stroke. Overridden in `main.dart`
/// from SharedPreferences before `runApp`, the same way [languageProvider]
/// is, so the deck opens at the chosen speed instead of visibly switching
/// to it on the first card.
final strokeSpeedProvider = StateProvider<StrokeSpeed>(
  (ref) => StrokeSpeed.normal,
);

final themeRepositoryProvider = Provider<ThemeRepository>(
  (ref) => ThemeRepository(),
);

/// Current colour mode, watched by `MaterialApp.themeMode`. Initial value
/// is overridden in `main.dart` from SharedPreferences before `runApp`, the
/// same way [languageProvider] is — the default here (light) only applies
/// if that override is missing, e.g. a test building the app directly.
final themeModeProvider = StateProvider<AppThemeMode>(
  (ref) => AppThemeMode.light,
);

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final ttsServiceProvider = Provider<TtsService>((ref) => TtsService());
final adServiceProvider = Provider<AdService>((ref) => AdService());
final fcmServiceProvider = Provider<FcmService>((ref) => FcmService());
final presenceServiceProvider = Provider<PresenceService>(
  (ref) => PresenceService(),
);
final matchmakingRepositoryProvider = Provider<MatchmakingRepository>(
  (ref) => MatchmakingRepository(),
);

/// Whether this device has already been shown the tutorial.
///
/// A [FutureProvider] rather than a plain read so the entry point can wait
/// on it the same way it waits on the ad audience, and so replaying the
/// tutorial from Profile is one `ref.invalidate` away.
final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => OnboardingRepository(),
);

/// Whether one particular walkthrough has been seen on this device.
///
/// A family rather than a single provider: the home tour and the card
/// mode's are tracked apart, so opening the card mode for the first
/// time after a month of use still explains itself.
/// Bumped to ask the home screen to replay its tour.
///
/// A counter rather than a bool: the tour has to be replayable more than
/// once, and a flag would need clearing again afterwards — which is one
/// more thing to forget. The home screen watches this and starts the
/// tour when the number changes.
///
/// It exists because the tour points at cards on the home tab, and the
/// button that replays it lives on the profile tab. Pushing the tour
/// from there would dim the profile screen and highlight where those
/// cards would have been.
final replayHomeTourProvider = StateProvider<int>((ref) => 0);

final hasSeenTutorialProvider = FutureProvider.family<bool, TutorialId>(
  (ref, id) => ref.watch(onboardingRepositoryProvider).hasSeen(id),
);

final planIntroRepositoryProvider = Provider<PlanIntroRepository>(
  (ref) => PlanIntroRepository(),
);

/// Whether this device has already seen the Free-vs-Premium plan intro
/// shown right after the age question — see [PlanIntroRepository]'s own
/// doc comment for why it's tracked separately from [hasSeenTutorialProvider].
final hasSeenPlanIntroProvider = FutureProvider<bool>(
  (ref) => ref.watch(planIntroRepositoryProvider).hasSeen(),
);

final adAudienceRepositoryProvider =
    Provider<AdAudienceRepository>((ref) => AdAudienceRepository());

/// The learner's stored age answer, or the unknown — and therefore
/// restricted — state. Watched at the app root, which both shows the age
/// question when it is missing and re-applies the AdMob configuration when
/// it is answered.
final adAudienceProvider = FutureProvider<AdAudience>((ref) {
  return ref.watch(adAudienceRepositoryProvider).getAudience();
});
final babRepositoryProvider = Provider<BabRepository>(
  (ref) => BabRepository(),
);
final babProgressRepositoryProvider = Provider<BabProgressRepository>(
  (ref) => BabProgressRepository(),
);
final kanaRepositoryProvider = Provider<KanaRepository>(
  (ref) => KanaRepository(),
);
final kanjiRepositoryProvider = Provider<KanjiRepository>(
  (ref) => KanjiRepository(),
);
final kanjiLevelRepositoryProvider = Provider<KanjiLevelRepository>(
  (ref) => KanjiLevelRepository(),
);
final kanjiProgressRepositoryProvider = Provider<KanjiProgressRepository>(
  (ref) => KanjiProgressRepository(),
);
final bunpouRepositoryProvider = Provider<BunpouRepository>(
  (ref) => BunpouRepository(),
);
final bunpouLevelRepositoryProvider = Provider<BunpouLevelRepository>(
  (ref) => BunpouLevelRepository(),
);
final bunpouProgressRepositoryProvider = Provider<BunpouProgressRepository>(
  (ref) => BunpouProgressRepository(),
);
final particleRepositoryProvider = Provider<ParticleRepository>(
  (ref) => ParticleRepository(),
);
final particleCategoryRepositoryProvider = Provider<ParticleCategoryRepository>(
  (ref) => ParticleCategoryRepository(),
);
final particleProgressRepositoryProvider = Provider<ParticleProgressRepository>(
  (ref) => ParticleProgressRepository(),
);
final kaiwaRepositoryProvider = Provider<KaiwaRepository>(
  (ref) => KaiwaRepository(),
);
final kaiwaCategoryRepositoryProvider = Provider<KaiwaCategoryRepository>(
  (ref) => KaiwaCategoryRepository(),
);
final kaiwaLevelRepositoryProvider = Provider<KaiwaLevelRepository>(
  (ref) => KaiwaLevelRepository(),
);
final kaiwaProgressRepositoryProvider = Provider<KaiwaProgressRepository>(
  (ref) => KaiwaProgressRepository(),
);
final kotobaRepositoryProvider = Provider<KotobaRepository>(
  (ref) => KotobaRepository(),
);

/// Built once per app session and reused — see [FuriganaDictionary]'s own
/// doc comment for why it draws only from Kotoba/Kanji's kana fields.
final furiganaDictionaryProvider = FutureProvider<FuriganaDictionary>(
  (ref) => FuriganaDictionary.build(
    kotoba: ref.watch(kotobaRepositoryProvider),
    kanji: ref.watch(kanjiRepositoryProvider),
  ),
);
final kotobaCategoryRepositoryProvider = Provider<KotobaCategoryRepository>(
  (ref) => KotobaCategoryRepository(),
);
final savedWordsRepositoryProvider = Provider<SavedWordsRepository>(
  (ref) => SavedWordsRepository(),
);
final kotobaProgressRepositoryProvider = Provider<KotobaProgressRepository>(
  (ref) => KotobaProgressRepository(),
);
final dictionaryRepositoryProvider = Provider<DictionaryRepository>(
  (ref) => DictionaryRepository(),
);
final romajiConverterProvider = Provider<RomajiConverter>(
  (ref) => RomajiConverter(ref.watch(kanaRepositoryProvider)),
);
final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepository(),
);
final leaderboardRepositoryProvider = Provider<LeaderboardRepository>(
  (ref) => LeaderboardRepository(),
);
final clanRepositoryProvider = Provider<ClanRepository>(
  (ref) => ClanRepository(),
);
final battleRepositoryProvider = Provider<BattleRepository>(
  (ref) => BattleRepository(),
);
final battleInviteRepositoryProvider = Provider<BattleInviteRepository>(
  (ref) => BattleInviteRepository(),
);
final clanMessageRepositoryProvider = Provider<ClanMessageRepository>(
  (ref) => ClanMessageRepository(),
);
final clanAnnouncementRepositoryProvider =
    Provider<ClanAnnouncementRepository>(
  (ref) => ClanAnnouncementRepository(),
);
final friendRepositoryProvider = Provider<FriendRepository>(
  (ref) => FriendRepository(),
);
final directMessageRepositoryProvider = Provider<DirectMessageRepository>(
  (ref) => DirectMessageRepository(),
);
final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(),
);
final examRepositoryProvider = Provider<ExamRepository>(
  (ref) => ExamRepository(
    kanaRepository: ref.watch(kanaRepositoryProvider),
    progressRepository: ref.watch(progressRepositoryProvider),
    leaderboardRepository: ref.watch(leaderboardRepositoryProvider),
  ),
);
final dokkaiRepositoryProvider = Provider<DokkaiRepository>(
  (ref) => DokkaiRepository(),
);
final dokkaiLevelRepositoryProvider = Provider<DokkaiLevelRepository>(
  (ref) => DokkaiLevelRepository(),
);
final dokkaiExamHistoryRepositoryProvider = Provider<ExamHistoryRepository>(
  (ref) => ExamHistoryRepository(
    FirestorePaths.dokkaiExamHistory,
    category: LeaderboardCategory.dokkai,
    leaderboardRepository: ref.watch(leaderboardRepositoryProvider),
  ),
);
final choukaiRepositoryProvider = Provider<ChoukaiRepository>(
  (ref) => ChoukaiRepository(),
);
final choukaiLevelRepositoryProvider = Provider<ChoukaiLevelRepository>(
  (ref) => ChoukaiLevelRepository(),
);
final choukaiExamHistoryRepositoryProvider = Provider<ExamHistoryRepository>(
  (ref) => ExamHistoryRepository(
    FirestorePaths.choukaiExamHistory,
    category: LeaderboardCategory.choukai,
    leaderboardRepository: ref.watch(leaderboardRepositoryProvider),
  ),
);
final kanjiComboRepositoryProvider = Provider<KanjiComboRepository>(
  (ref) => KanjiComboRepository(
    kanjiRepository: ref.watch(kanjiRepositoryProvider),
    kotobaRepository: ref.watch(kotobaRepositoryProvider),
    kotobaCategoryRepository: ref.watch(kotobaCategoryRepositoryProvider),
  ),
);
final kanjiComboExamHistoryRepositoryProvider = Provider<ExamHistoryRepository>(
  (ref) => ExamHistoryRepository(
    FirestorePaths.kanjiComboExamHistory,
    category: LeaderboardCategory.kanjiCombo,
    leaderboardRepository: ref.watch(leaderboardRepositoryProvider),
  ),
);
/// Ensures anonymous sign-in, then starts the user's profile bookkeeping
/// without waiting for it. Screens should gate progress reads/writes on this
/// resolving.
///
/// **The bookkeeping is deliberately not awaited.** A Firestore write's
/// Future does not complete until the write reaches the server, so with no
/// connection it stays pending indefinitely — the write is safely queued and
/// syncs later, but anything awaiting it hangs. Awaiting these two calls
/// meant that offline this provider never resolved, and every screen gated
/// on it spun forever. That included the entire settings menu, which lives
/// inside the profile body, so an offline learner could not change the app's
/// theme or language — neither of which needs a network at all. Found on a
/// device whose wifi had no working DNS (2026-08-05).
///
/// All three calls are best-effort by nature, the same rule every progress
/// repository here already follows: local state is the source of truth and
/// Firestore is a mirror. Errors are logged rather than surfaced, because
/// there is nothing a learner could do about a failed profile touch and it
/// must not stop the app from opening.
final appStartupProvider = FutureProvider<User>((ref) async {
  final auth = ref.watch(authServiceProvider);
  final user = await auth.ensureSignedIn();
  final progressRepository = ref.watch(progressRepositoryProvider);

  unawaited(
    progressRepository
        .ensureUserProfile(
          user.uid,
          isAnonymous: user.isAnonymous,
          displayName: user.displayName,
        )
        .catchError((Object e) => debugPrint('ensureUserProfile failed: $e')),
  );
  unawaited(
    progressRepository
        .recordDailyActivity(user.uid)
        .catchError((Object e) => debugPrint('recordDailyActivity failed: $e')),
  );
  // Bootstraps leaderboard/{uid} the first time this account is ever seen,
  // so it exists (and is findable via searchPublicUsers) before the user
  // has taken any exam or explicitly renamed themselves — see
  // LeaderboardRepository.ensurePublished's own doc comment for why this
  // is a one-time create, not an ongoing sync. No UserProfile read is
  // needed here: a brand-new account has no customDisplayName yet, so the
  // same fallback resolveDisplayName would use (Auth displayName, else
  // "Pelajar Kana") is already sitting right on `user`.
  unawaited(
    ref
        .read(leaderboardRepositoryProvider)
        .ensurePublished(
          uid: user.uid,
          displayName: user.displayName ?? 'Pelajar Kana',
          photoUrl: user.photoURL,
        )
        .catchError((Object e) => debugPrint('ensurePublished failed: $e')),
  );
  // Drops clan memberships whose roster row is gone — being kicked, or
  // having a clan disbanded under you, leaves one behind that nobody but
  // this account has the rights to remove, and a stale one makes that
  // clan's chat answer every read with permission-denied for ever.
  // Best-effort and unawaited like everything else here.
  unawaited(
    ref
        .read(clanRepositoryProvider)
        .reconcileMemberships(user.uid)
        .catchError(
          (Object e) => debugPrint('reconcileMemberships failed: $e'),
        ),
  );
  // Gives friendships made before conversations were created up front the
  // document `firestore.rules` needs before their messages can be read.
  // Home subscribes to a friend's messages for its unread badge, so a
  // missing one denies from launch, not just inside chat. Once per
  // install, remembered locally — see backfillConversations.
  unawaited(() async {
    try {
      final friends =
          await ref.read(friendRepositoryProvider).getFriendsOnce(user.uid);
      await ref.read(directMessageRepositoryProvider).backfillConversations(
            user.uid,
            [for (final friend in friends) friend.uid],
          );
    } catch (e) {
      debugPrint('backfillConversations failed: $e');
    }
  }());
  // Requests notification permission and saves this device's FCM token —
  // best-effort like everything else here, and deliberately not blocking
  // startup on a permission prompt: a learner who denies it (or a device
  // with no Play Services) just never gets a push, which is not a reason
  // to hold up the whole app.
  unawaited(
    ref
        .read(fcmServiceProvider)
        .init(user.uid)
        .catchError((Object e) => debugPrint('FcmService.init failed: $e')),
  );
  // Card Game Mode presence (see NOTES_CARD_GAME_MODE.md) — best-effort
  // like everything else in this block, and doubly so right now: the
  // Realtime Database instance this needs hasn't been provisioned for
  // this Firebase project yet, so every call here fails silently until
  // that console step happens (see PresenceService's own doc comment).
  unawaited(
    ref
        .read(presenceServiceProvider)
        .goOnline(user.uid)
        .catchError((Object e) => debugPrint('PresenceService.goOnline failed: $e')),
  );

  return user;
});

final kanaListProvider = FutureProvider.family<List<KanaCharacter>, KanaType>((
  ref,
  type,
) {
  return ref.watch(kanaRepositoryProvider).getByType(type);
});

/// Cached so [KanaKeyboardInput.fromAll]'s tenten/maru/youon maps are built
/// once per app session, not rebuilt on every keystroke a [KanaKeyboard]
/// widget renders.
final kanaKeyboardInputProvider = FutureProvider<KanaKeyboardInput>((
  ref,
) async {
  final hiragana = await ref.watch(
    kanaListProvider(KanaType.hiragana).future,
  );
  return KanaKeyboardInput.fromAll(hiragana);
});

/// The full kana + kanji datasets bundled together, cached once — what
/// `battle_deck_builder.dart`'s `buildDeckIds`/`resolveCard` need. Kept
/// as one provider (a record) rather than two separate ones so a
/// consumer that needs both never has to juggle two AsyncValues.
/// The rank-skip exam, which is entirely server-side — see
/// `RankSkipService`.
final rankSkipServiceProvider = Provider<RankSkipService>(
  (ref) => RankSkipService(),
);

final battleCardDataProvider =
    FutureProvider<(List<KanaCharacter>, List<KanjiEntry>)>((ref) async {
      final kana = await ref.watch(kanaRepositoryProvider).getAll();
      final kanji = await ref.watch(kanjiRepositoryProvider).getAll();
      return (kana, kanji);
    });

/// Live progress (status per kana + resume index) for one kana type, kept
/// in sync via a Firestore snapshot stream once the user is signed in.
final typeProgressProvider =
    StreamProvider.family<KanaTypeProgress, KanaType>((ref, type) async* {
      final user = await ref.watch(appStartupProvider.future);
      yield* ref
          .watch(progressRepositoryProvider)
          .watchTypeProgress(user.uid, type);
    });

final userProfileProvider = StreamProvider<UserProfile>((ref) async* {
  final user = await ref.watch(appStartupProvider.future);
  yield* ref
      .watch(progressRepositoryProvider)
      .watchProfile(user.uid)
      .map(UserProfile.fromMap);
});

/// Buying things. One instance for the app's life, because the store's
/// purchase stream has to be listened to continuously — a purchase can
/// land while the app is closed and arrive on the next launch.
final iapServiceProvider = Provider<IapService>((ref) {
  final service = IapService();
  ref.onDispose(service.dispose);
  return service;
});

/// Buying an avatar/frame/cover with coins — see [CoinSpendService]'s
/// own doc comment for why this is a callable rather than a Firestore
/// write. Stateless, unlike [iapServiceProvider]: there's no purchase
/// stream to keep listening to, so a plain provider (no dispose needed)
/// is enough.
final coinSpendServiceProvider =
    Provider<CoinSpendService>((ref) => CoinSpendService());

/// Card skins this learner has bought. Empty — not "everything" — while
/// it loads or when signed out: a wardrobe that briefly shows every paid
/// skin as owned is worse than one that fills in a moment later.
final ownedSkinsProvider = StreamProvider<Set<String>>((ref) async* {
  final user = await ref.watch(appStartupProvider.future);
  yield* ref.watch(progressRepositoryProvider).watchOwnedSkins(user.uid);
});

final subscriptionProvider = StreamProvider<Subscription>((ref) async* {
  final user = await ref.watch(appStartupProvider.future);
  yield* ref.watch(progressRepositoryProvider).watchSubscription(user.uid);
});

/// Coin balance — live, the same way [subscriptionProvider] is, so
/// topping up or winning a weekly Skor Global reward updates the number
/// on screen without a manual refresh. See `ProgressRepository
/// .watchCoinBalance` for why the client can watch this but never write
/// it.
final coinBalanceProvider = StreamProvider<int>((ref) async* {
  final user = await ref.watch(appStartupProvider.future);
  yield* ref.watch(progressRepositoryProvider).watchCoinBalance(user.uid);
});

/// Card Game Mode standing — see `NOTES_CARD_GAME_MODE.md`'s "Tahap 1
/// butir 2". Not read from anywhere yet (no match screen exists to read
/// "which tier, so which card content" from it), but live-watched the
/// same way [subscriptionProvider] is so a future match screen doesn't
/// need a one-shot fetch of its own.
final cardGameRankProvider = StreamProvider<CardGameRank>((ref) async* {
  final user = await ref.watch(appStartupProvider.future);
  yield* ref.watch(progressRepositoryProvider).watchCardGameRank(user.uid);
});

/// Live online/offline status for any single [uid] — not the signed-in
/// user's own status (that's just written, never read back), but whoever
/// a future friend/clan list needs a badge for. Not consumed anywhere
/// yet, same "infrastructure ready ahead of the screen that needs it"
/// shape as [kanaKeyboardInputProvider].
final presenceProvider = StreamProvider.family<PresenceStatus, String>((
  ref,
  uid,
) {
  return ref.watch(presenceServiceProvider).watchPresence(uid);
});

/// Live view of one `battleMatches/{matchId}` doc — not consumed
/// anywhere yet (no match screen exists to watch it from), same
/// "infrastructure ready ahead of the screen that needs it" shape as
/// [presenceProvider]/[kanaKeyboardInputProvider].
final battleMatchProvider = StreamProvider.family<BattleMatch, String>((
  ref,
  matchId,
) {
  return ref.watch(battleRepositoryProvider).watchMatch(matchId);
});

/// Total XP + level + pending level-up rewards — see [XpProgress]. Watched
/// live (not a one-shot fetch) so the Home level card updates the moment
/// any screen calls `ProgressRepository.addXp`, without that call site
/// needing to know this provider exists to invalidate it.
final xpProgressProvider = StreamProvider<XpProgress>((ref) async* {
  final user = await ref.watch(appStartupProvider.future);
  yield* ref.watch(progressRepositoryProvider).watchXpProgress(user.uid);
});

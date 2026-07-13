import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/kana_character.dart';
import '../data/models/kana_type.dart';
import '../data/models/kana_type_progress.dart';
import '../data/models/subscription.dart';
import '../data/models/user_profile.dart';
import '../data/repositories/exam_repository.dart';
import '../data/repositories/kana_repository.dart';
import '../data/repositories/kanji_repository.dart';
import '../data/repositories/kotoba_repository.dart';
import '../data/repositories/leaderboard_repository.dart';
import '../data/repositories/progress_repository.dart';
import 'services/ad_service.dart';
import 'services/auth_service.dart';
import 'services/avatar_upload_service.dart';
import 'services/tts_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final ttsServiceProvider = Provider<TtsService>((ref) => TtsService());
final adServiceProvider = Provider<AdService>((ref) => AdService());
final avatarUploadServiceProvider =
    Provider<AvatarUploadService>((ref) => AvatarUploadService());
final kanaRepositoryProvider = Provider<KanaRepository>(
  (ref) => KanaRepository(),
);
final kanjiRepositoryProvider = Provider<KanjiRepository>(
  (ref) => KanjiRepository(),
);
final kotobaRepositoryProvider = Provider<KotobaRepository>(
  (ref) => KotobaRepository(),
);
final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepository(),
);
final leaderboardRepositoryProvider = Provider<LeaderboardRepository>(
  (ref) => LeaderboardRepository(),
);
final examRepositoryProvider = Provider<ExamRepository>(
  (ref) => ExamRepository(
    kanaRepository: ref.watch(kanaRepositoryProvider),
    progressRepository: ref.watch(progressRepositoryProvider),
    leaderboardRepository: ref.watch(leaderboardRepositoryProvider),
  ),
);
/// Ensures anonymous sign-in and the user profile doc exist. Screens should
/// gate progress reads/writes on this resolving.
final appStartupProvider = FutureProvider<User>((ref) async {
  final auth = ref.watch(authServiceProvider);
  final user = await auth.ensureSignedIn();
  final progressRepository = ref.watch(progressRepositoryProvider);
  await progressRepository.ensureUserProfile(
    user.uid,
    isAnonymous: user.isAnonymous,
    displayName: user.displayName,
  );
  await progressRepository.recordDailyActivity(user.uid);
  return user;
});

final kanaListProvider = FutureProvider.family<List<KanaCharacter>, KanaType>((
  ref,
  type,
) {
  return ref.watch(kanaRepositoryProvider).getByType(type);
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

final subscriptionProvider = StreamProvider<Subscription>((ref) async* {
  final user = await ref.watch(appStartupProvider.future);
  yield* ref.watch(progressRepositoryProvider).watchSubscription(user.uid);
});

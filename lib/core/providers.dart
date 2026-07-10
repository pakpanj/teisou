import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/kana_character.dart';
import '../data/models/kana_type.dart';
import '../data/models/kana_type_progress.dart';
import '../data/repositories/exam_repository.dart';
import '../data/repositories/kana_repository.dart';
import '../data/repositories/progress_repository.dart';
import 'services/auth_service.dart';
import 'services/tts_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final ttsServiceProvider = Provider<TtsService>((ref) => TtsService());
final kanaRepositoryProvider = Provider<KanaRepository>(
  (ref) => KanaRepository(),
);
final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepository(),
);
final examRepositoryProvider = Provider<ExamRepository>(
  (ref) => ExamRepository(
    kanaRepository: ref.watch(kanaRepositoryProvider),
    progressRepository: ref.watch(progressRepositoryProvider),
  ),
);

/// Ensures anonymous sign-in and the user profile doc exist. Screens should
/// gate progress reads/writes on this resolving.
final appStartupProvider = FutureProvider<User>((ref) async {
  final auth = ref.watch(authServiceProvider);
  final user = await auth.ensureSignedIn();
  await ref
      .watch(progressRepositoryProvider)
      .ensureUserProfile(
        user.uid,
        isAnonymous: user.isAnonymous,
        displayName: user.displayName,
      );
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

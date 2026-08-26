import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';

/// Where the app looks for the minimum-build config — a single publicly
/// readable document, not a whole open collection. See `firestore.rules`'
/// own `match /appConfig/minVersion` block, which names this exact path
/// and refuses every other document under `appConfig/` by default.
const minVersionConfigCollection = 'appConfig';
const minVersionConfigDoc = 'minVersion';
const minVersionConfigField = 'minBuildNumber';

/// Whether an installed build may proceed, decided from two already-
/// resolved integers. Deliberately synchronous and free of Firestore/
/// platform-channel types, so every branch below is testable with plain
/// `int?` values — no fake Firestore, no fake `PackageInfo`, needed.
enum MinVersionDecision { allow, block }

/// The one rule this whole gate exists to enforce: **fail open**. A
/// `null` on either side — config missing, config malformed (wrong
/// type, non-positive), the fetch timed out, the device is offline, the
/// running build number couldn't be determined — means "don't block".
/// This mirrors every other gate already in `main.dart`
/// (`_AudienceGate`/`_IdentityGate`/`_PlanIntroGate`/`_PreloadGate` all
/// resolve their own `error` branch by letting the learner through, not
/// by trapping them) — the alternative, fail-closed, would mean this
/// offline-first app cannot even open its own first screen without a
/// live network connection, which is a far worse failure than shipping
/// one more build past the cutoff a version behind schedule.
MinVersionDecision evaluateMinVersion({
  required int? minBuildNumber,
  required int? currentBuildNumber,
}) {
  if (minBuildNumber == null || currentBuildNumber == null) {
    return MinVersionDecision.allow;
  }
  return currentBuildNumber >= minBuildNumber
      ? MinVersionDecision.allow
      : MinVersionDecision.block;
}

/// Runs [task], but treats *any* failure — a thrown error, or simply
/// taking longer than [timeout] — as "no answer", returning `null`
/// instead of letting either propagate.
///
/// This is what actually keeps a dead network from hanging the very
/// first frame of the app: `Future.timeout` alone still leaves a
/// `TimeoutException` for the caller to handle, and a caller that
/// forgets to catch it would freeze here before any other gate — the
/// one thing this project's own startup chain has never done anywhere
/// else. Kept as its own function (not inlined into the repository
/// below) specifically so it can be unit-tested directly with a
/// `Future` that never completes, without needing a real or fake
/// Firestore client to prove the timeout actually fires.
Future<T> failOpenWithTimeout<T>(
  Future<T> Function() task,
  Duration timeout, {
  required T onFailure,
}) async {
  try {
    return await task().timeout(timeout);
  } catch (_) {
    return onFailure;
  }
}

/// Reads `appConfig/minVersion` — see the top-level constants for the
/// exact path — and reports the installed build's own number.
///
/// **Reads are forced to the server, never the local cache.** A stale
/// cached value could still say "you're fine" on a device that has had
/// this exact config document cached since before the minimum was ever
/// raised — the only reason this gate exists is to catch a build that
/// is now behind, so trusting a possibly-months-old cache would defeat
/// it silently. `GetOptions(source: Source.server)` is what forces that;
/// dropping it would still compile and mostly work, which is exactly
/// the kind of regression a code reviewer could miss without this
/// comment.
class MinVersionRepository {
  MinVersionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Short on purpose — this runs before every other gate in the app,
  /// including the age question, so a slow or dead network must not
  /// turn "can't reach Firestore yet" into "the app won't open".
  static const fetchTimeout = Duration(seconds: 3);

  /// Never throws. Missing document, wrong field type, a negative or
  /// zero value, a timeout, or being fully offline all come back as
  /// `null` — "no minimum enforceable right now" — rather than as an
  /// exception the caller has to remember to handle.
  Future<int?> fetchMinBuildNumber() {
    return failOpenWithTimeout<int?>(() async {
      final snapshot = await _firestore
          .collection(minVersionConfigCollection)
          .doc(minVersionConfigDoc)
          .get(const GetOptions(source: Source.server));
      final raw = snapshot.data()?[minVersionConfigField];
      return (raw is int && raw > 0) ? raw : null;
    }, fetchTimeout, onFailure: null);
  }
}

/// The build number this exact install is actually running, read from
/// the OS/APK rather than a hand-kept Dart constant — this project has
/// been bitten more than once by a duplicated value drifting from the
/// one place that was actually true (see `_categories.json` vs. the
/// Kotoba word-list scripts, or Bunpou's own `_levels.json`), and a
/// version gate is the last place to repeat that mistake.
///
/// `null` on any failure (an unexpected platform response, a
/// non-numeric `buildNumber` string) — same fail-open contract as
/// [MinVersionRepository.fetchMinBuildNumber].
Future<int?> currentAppBuildNumber() {
  return failOpenWithTimeout<int?>(() async {
    final info = await PackageInfo.fromPlatform();
    return int.tryParse(info.buildNumber);
  }, const Duration(seconds: 2), onFailure: null);
}

final minVersionRepositoryProvider = Provider<MinVersionRepository>(
  (ref) => MinVersionRepository(),
);

/// Resolves to [MinVersionDecision.block] only when both numbers were
/// read successfully *and* the installed build is genuinely behind —
/// every other outcome (either read failing, or the build being current
/// or ahead) resolves to [MinVersionDecision.allow]. Never itself
/// throws, since both reads it awaits already fail open — the `error`
/// branch anywhere this is consumed is defensive, not a real path.
final minVersionDecisionProvider = FutureProvider<MinVersionDecision>(
  (ref) async {
    final repository = ref.watch(minVersionRepositoryProvider);
    final minBuildNumber = await repository.fetchMinBuildNumber();
    final currentBuildNumber = await currentAppBuildNumber();
    return evaluateMinVersion(
      minBuildNumber: minBuildNumber,
      currentBuildNumber: currentBuildNumber,
    );
  },
);

/// The very first gate in `main.dart`'s startup chain — see that file's
/// own doc comments for why it now sits ahead of `_AudienceGate`: this
/// is the one gate whose whole job is to stop an old build before it
/// reaches anything a future Firestore Rules cutover would otherwise
/// break for it.
///
/// Shows nothing (not even a spinner label) while loading — the same
/// blank-then-content shape `_AudienceGate` already uses for its own
/// loading branch, since this check is meant to resolve near-instantly
/// on the common path (either the config is cached-fresh-enough to
/// answer inside the timeout, or the timeout itself caps the wait at a
/// few seconds either way).
class MinVersionGate extends ConsumerWidget {
  const MinVersionGate({super.key, required this.child});

  /// What to show once the build is confirmed current (or the check
  /// failed open) — `_AudienceGate` in production, swapped out in tests.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decision = ref.watch(minVersionDecisionProvider);
    return decision.when(
      data: (value) =>
          value == MinVersionDecision.block
              ? const UpdateRequiredScreen()
              : child,
      loading: () => const SizedBox.shrink(),
      // Defensive only — `minVersionDecisionProvider` never actually
      // throws, since both of its own reads already fail open.
      error: (_, _) => child,
    );
  }
}

/// Shown when [MinVersionDecision.block] is reached — a dead end on
/// purpose. Every other gate in `main.dart` has a way through (answer
/// the question, dismiss the sheet, wait out the preload); this one
/// doesn't, because letting it through is exactly the case this gate
/// exists to prevent.
class UpdateRequiredScreen extends ConsumerWidget {
  const UpdateRequiredScreen({super.key, this.openUrl = _defaultLaunch});

  /// Injected so a widget test can assert the right URL was requested
  /// without actually invoking the real platform channel, the same
  /// reason `AdService`'s own callbacks are injectable rather than
  /// reaching for the real SDK in tests. Deliberately not named
  /// `launchUrl` — a member of that name would shadow the top-level
  /// `launchUrl` function this file imports from `package:url_launcher`
  /// for the *entire* class body, including the static method below,
  /// which is exactly the bug this naming avoids.
  final Future<bool> Function(Uri uri) openUrl;

  static Future<bool> _defaultLaunch(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  /// The one place this id is ever spelled out — see
  /// `android/app/build.gradle.kts`'s own `applicationId` for the source
  /// of truth this has to keep matching by hand, since a Play Store URL
  /// has no way to derive it from the running app itself.
  static final playStoreUri = Uri.parse(
    'https://play.google.com/store/apps/details?id=com.teisou.kanamaster',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    return Scaffold(
      backgroundColor: context.palette.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.system_update_alt,
                size: 72,
                color: context.palette.primaryCoral,
              ),
              const SizedBox(height: 20),
              Text(
                s.updateRequiredTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: context.palette.textNavy,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                s.updateRequiredBody,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: context.palette.textNavy.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: context.palette.primaryCoral,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => openUrl(playStoreUri),
                  child: Text(s.updateNowButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

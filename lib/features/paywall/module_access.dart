library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/jlpt_level.dart';
import 'paywall_screen.dart';


/// Which learning content is behind the paywall, and how to ask.
///
/// **One place, because the answer is asked from six screens.** The
/// module list gates whole modules; Kanji and Bunpou gate part of
/// themselves by JLPT level. Spread across those, "is this premium"
/// drifts — a level added to one list and not the other, or a module
/// gated on its card and open from a deep link.
///
/// The split itself is the product decision recorded in
/// `memory/project_monetization_roadmap.md`: the first levels of the
/// core path stay free so a learner can get properly started, and the
/// depth is what is sold. Kana, Kotoba, Bab, the dictionary, the exams
/// and Kaiwa's own N5 are all free and stay that way.

/// Modules that are premium in their entirety.
///
/// Ids match [PaywallScreen.moduleId], which is also the key
/// `ProgressRepository.unlockAdReward` writes under — so a rewarded ad
/// watched for a module unlocks that module and nothing else.
class PremiumModules {
  static const particle = 'particle';
  static const kaiwa = 'kaiwa';
  static const choukai = 'choukai';

  /// Used for the level-gated halves of Kanji and Bunpou. One id per
  /// module rather than one per level: watching an ad opens the module's
  /// locked levels together, which is simpler to explain and much
  /// simpler than an ad per JLPT level.
  static const kanji = 'kanji';
  static const bunpou = 'bunpou';
}

/// The first JLPT level of Kanji that costs money. N5 and N4 are free —
/// enough to carry a beginner a long way before anything is asked for.
const kKanjiFreeThrough = JlptLevel.n4;

/// The same line for Bunpou, one level earlier: its N5 set alone is 89
/// patterns, a substantial free module on its own.
const kBunpouFreeThrough = JlptLevel.n5;

/// Whether [level] is inside the free part of a level-gated module.
bool isFreeLevel(JlptLevel level, {required JlptLevel freeThrough}) {
  // `JlptLevel.values` runs easiest-first, so "at or before the line" is
  // an index comparison rather than a list of the free ones — which
  // would be a second thing to update when the line moves.
  return level.index <= freeThrough.index;
}

/// Whether the signed-in learner may open [moduleId] right now.
///
/// True for a premium subscriber, and true while a rewarded-ad preview
/// for that module is still inside its 24-hour window. Anything else —
/// signed out, a failed read — is false: a gate that opens when it
/// cannot tell is not a gate.
final moduleAccessProvider =
    FutureProvider.family<bool, String>((ref, moduleId) async {
  final premium =
      ref.watch(subscriptionProvider).valueOrNull?.isPremium ?? false;
  if (premium) return true;

  final uid = ref.watch(appStartupProvider).valueOrNull?.uid;
  if (uid == null) return false;
  try {
    final rewards =
        await ref.watch(progressRepositoryProvider).getAdRewards(uid);
    return rewards[moduleId]?.isActive ?? false;
  } catch (_) {
    // The read failing is not permission to enter.
    return false;
  }
});

/// Defense-in-depth backstop for a whole-module premium screen
/// (Kaiwa/Choukai/Partikel) — see AUDIT_QUIZ_TUTORIAL_GLOBALSCORE.md /
/// the master monetization audit's own RISK-04 finding: `moduleAccessProvider`
/// was only ever checked at the *tap site* (`_PremiumModuleCard` on
/// Home), never again once the destination screen itself is on screen.
/// Today that gate is genuinely the only way in — every one of these
/// screens is only ever `const`-constructed from that one gated card, no
/// second navigation path exists — so this was not independently
/// exploitable, only a single point of enforcement rather than layered
/// ones. This wraps the destination screen's own `build()` with the same
/// check, so a future navigation path (a deep link, a notification tap, a
/// screen added later that forgets the gate) can't silently reopen it.
///
/// Shows [child] once access resolves true. While the check is still
/// resolving, shows a bare loading screen rather than a flash of real
/// content — same "false while loading" discipline `moduleAccessProvider`
/// itself already documents. Once resolved false (or the check itself
/// fails — fail closed, not open), replaces this screen with the same
/// `PaywallScreen` the tap site would have opened, so reaching this
/// screen any other way lands on the same honest "here's why, here's how
/// to unlock it" surface instead of showing nothing or crashing.
class ModuleAccessGate extends ConsumerWidget {
  const ModuleAccessGate({
    super.key,
    required this.moduleId,
    required this.moduleTitle,
    required this.child,
  });

  final String moduleId;
  final String moduleTitle;
  final Widget child;

  void _redirectToPaywall(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              PaywallScreen(moduleId: moduleId, moduleTitle: moduleTitle),
        ),
      );
    });
  }

  static const _pending = Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(moduleAccessProvider(moduleId));
    return access.when(
      data: (unlocked) {
        if (unlocked) return child;
        _redirectToPaywall(context);
        return _pending;
      },
      loading: () => _pending,
      error: (_, _) {
        _redirectToPaywall(context);
        return _pending;
      },
    );
  }
}

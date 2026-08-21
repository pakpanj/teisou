import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/providers.dart';
import '../../data/repositories/onboarding_repository.dart';
import 'onboarding_screen.dart';

/// Plays a walkthrough the first time a screen is opened, over the top of
/// it rather than in front of it.
///
/// **The home tour used to be a gate.** `main.dart` decided between the
/// tutorial and the home screen, so a first-time learner met the mascot
/// before ever seeing the app, and the home screen did not exist behind
/// it — leaving was leaving to nothing. Wrapping instead means the screen
/// is built and painted first and the tutorial arrives on top of it: the
/// learner can see what is being explained, and closing it drops them
/// straight into the thing they were just shown.
///
/// It also makes a second tutorial cheap, which is what Card Game Mode
/// needed. Anything that wants one wraps itself.
class FirstVisitTutorial extends ConsumerStatefulWidget {
  const FirstVisitTutorial({
    super.key,
    required this.id,
    required this.child,
    this.steps,
    this.finishLabel,
  });

  /// Which walkthrough, and therefore which "seen" flag.
  final TutorialId id;

  final Widget child;

  /// Null plays the home tour — see [OnboardingScreen.steps].
  final List<OnboardingStep> Function(AppStrings)? steps;

  final String? finishLabel;

  @override
  ConsumerState<FirstVisitTutorial> createState() =>
      _FirstVisitTutorialState();
}

class _FirstVisitTutorialState extends ConsumerState<FirstVisitTutorial> {
  /// Guards against a second push.
  ///
  /// `build` runs again for every unrelated rebuild underneath — a theme
  /// change, a provider settling — and without this each one would stack
  /// another copy of the tutorial on the navigator.
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow());
  }

  Future<void> _maybeShow() async {
    if (_handled || !mounted) return;
    _handled = true;

    final repo = ref.read(onboardingRepositoryProvider);
    // Read straight from the repository rather than watching the
    // provider: this runs once, and a watch here would rebuild the whole
    // wrapped screen every time the flag was invalidated.
    //
    // A failed read counts as "seen". If SharedPreferences cannot be
    // read then it cannot be written either, so erring the other way
    // would replay the tutorial on every single launch — worse than
    // missing it once.
    bool seen;
    try {
      seen = await repo.hasSeen(widget.id);
    } catch (_) {
      seen = true;
    }
    if (seen || !mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OnboardingScreen(
          steps: widget.steps,
          finishLabel: widget.finishLabel,
          onFinished: () => Navigator.of(context).pop(),
        ),
      ),
    );

    // Marked after it closes, not before it opens. Closed early still
    // counts: a learner who skipped it chose to, and showing it again
    // next launch would override that choice.
    await repo.markSeen(widget.id);
    ref.invalidate(hasSeenTutorialProvider(widget.id));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

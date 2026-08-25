import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/mascot_widget.dart';
import '../../core/widgets/speech_bubble.dart';

/// One thing the mascot says on the way in.
class OnboardingStep {
  const OnboardingStep({required this.mood, required this.message});

  final MascotMood mood;
  final String message;
}

/// What the mascot says the first time the app is opened.
///
/// Kept as data, apart from the screen, so the wording and the order can
/// be read — and tested — without going through a widget.
List<OnboardingStep> onboardingSteps(AppStrings s) => [
      OnboardingStep(mood: MascotMood.waving, message: s.tutorialGreeting),
      OnboardingStep(mood: MascotMood.explaining, message: s.tutorialKana),
      OnboardingStep(mood: MascotMood.reading, message: s.tutorialCurriculum),
      OnboardingStep(mood: MascotMood.writing, message: s.tutorialKanji),
      OnboardingStep(mood: MascotMood.determined, message: s.tutorialPractice),
      OnboardingStep(mood: MascotMood.cheering, message: s.tutorialReady),
    ];

/// The mascot walking a first-time learner through the app.
///
/// **Deliberately its own screen rather than a spotlight over the real
/// UI.** A coach-mark tour that highlights live widgets has to know where
/// each one is, which means global keys, scroll-into-view, and a layout
/// that silently breaks the tutorial every time a card moves. On a screen
/// whose sections are still being added to before release, that is a
/// tutorial that would be quietly wrong within a month. This says the same
/// things and cannot drift out of position.
///
/// It is the mascot talking, not a slideshow with a picture on it: one
/// large character, one bubble, a new expression each step. The learner
/// taps through at their own pace and can leave at any point.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onFinished,
    this.steps,
    this.finishLabel,
  });

  /// Which walkthrough to play. Null means the home tour, which is what
  /// this screen was built for and still its most common use.
  final List<OnboardingStep> Function(AppStrings)? steps;

  /// The last step's button. Null keeps "Mulai Belajar" — right for the
  /// home tour, wrong for a mode where the next thing is a match.
  final String? finishLabel;

  /// Called once, when the learner reaches the end or skips. The caller
  /// decides what "done" means — first run marks it seen and goes Home;
  /// a replay from Profile just pops.
  final VoidCallback onFinished;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _index = 0;

  /// Guards against the last "Mulai" being tapped twice before the route
  /// changes — which would mark the tutorial seen and pop twice.
  bool _finishing = false;

  void _finish() {
    if (_finishing) return;
    _finishing = true;
    widget.onFinished();
  }

  void _next(int total) {
    if (_index >= total - 1) {
      _finish();
      return;
    }
    setState(() => _index++);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final palette = context.palette;
    final steps = (widget.steps ?? onboardingSteps)(s);
    final step = steps[_index];
    final isLast = _index == steps.length - 1;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                // Always available, including on the last step. A tutorial
                // a child cannot leave is a wall, not a welcome.
                onPressed: _finish,
                child: Text(s.tutorialSkip),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Keyed on the step so the mascot's entrance replays
                    // and the new expression reads as the character
                    // reacting, not as an image being swapped.
                    MascotWidget(
                      key: ValueKey(step.mood),
                      mood: step.mood,
                      // The largest in the app, and it should be: this is
                      // a screen with one character, one sentence and
                      // nothing else on it.
                      size: 240,
                      showBackdrop: false,
                      groundShadow: true,
                    ),
                    const SizedBox(height: 20),
                    SpeechBubble(
                      color: palette.cardWhite,
                      // Pointing up at the character standing above it,
                      // rather than sideways at nothing.
                      tailTopOffset: 0,
                      tailSize: 0,
                      padding: const EdgeInsets.all(20),
                      shadow: BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                      child: Text(
                        step.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.45,
                          color: palette.textNavy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _StepDots(count: steps.length, current: _index),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _next(steps.length),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.primaryCoral,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(isLast
                      ? (widget.finishLabel ?? s.tutorialStart)
                      : s.tutorialNext),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// How far along the tutorial is.
///
/// Worth the twenty lines: without it a child has no idea whether they are
/// two taps from the app or twenty, which is the difference between
/// following along and hunting for the skip button.
class _StepDots extends StatelessWidget {
  const _StepDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == current ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == current
                  ? palette.primaryCoral
                  : palette.primaryCoral.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

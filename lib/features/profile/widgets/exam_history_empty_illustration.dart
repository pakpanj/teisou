import 'package:flutter/material.dart';

import '../../../core/widgets/mascot_widget.dart';

/// Shown when the user has no exam history yet.
///
/// This used to be a "cat napping under a sakura tree" drawn from layered
/// shapes — a brown rounded rectangle for the trunk, three pink circles for
/// the canopy, and 🐱/😴 emoji for the cat. On a real device it did not read
/// as a scene at all; it read as a stick, some plums, and a cat's head, which
/// is exactly how it was reported. The shape-drawing convention it followed
/// made sense when the app had no artwork, but the mascot now has real art in
/// eighteen expressions, so the honest fix is to use it rather than to keep
/// nudging primitives around.
///
/// [MascotMood.sleepy] keeps the original intent — nothing has happened here
/// yet — while looking like the rest of the app.
class ExamHistoryEmptyIllustration extends StatelessWidget {
  const ExamHistoryEmptyIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return const MascotWidget(
      mood: MascotMood.sleepy,
      size: 96,
      showBackdrop: false,
    );
  }
}

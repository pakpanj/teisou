import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../data/models/ad_audience.dart';

/// Asks the learner's birth year, once, before the app is used.
///
/// This exists because the app is mixed-audience — children and adults
/// share one build — and AdMob has to be told which it is dealing with on
/// every request. See [AdAudience] for what the answer changes.
///
/// **Deliberately neutral.** Google requires an age screen that does not
/// steer the answer, so nothing here mentions ads, or that a younger answer
/// restricts anything: a screen that hints at the "better" reply collects a
/// worthless answer. It is also not skippable, since skipping would leave
/// every user in the restricted state and make the question pointless.
class AgeQuestionScreen extends ConsumerStatefulWidget {
  const AgeQuestionScreen({super.key});

  @override
  ConsumerState<AgeQuestionScreen> createState() => _AgeQuestionScreenState();
}

class _AgeQuestionScreenState extends ConsumerState<AgeQuestionScreen> {
  int? _year;
  bool _saving = false;

  Future<void> _save() async {
    final year = _year;
    if (year == null || _saving) return;
    setState(() => _saving = true);
    await ref.read(adAudienceRepositoryProvider).setBirthYear(year);
    // The root listens to this, so re-reading it both dismisses this screen
    // and pushes the new configuration to AdMob.
    ref.invalidate(adAudienceProvider);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final now = DateTime.now();
    // Oldest first would bury a realistic answer at the bottom of a
    // 100-item list; a learner's own year is near the top this way.
    final years = [for (var y = now.year; y > now.year - 100; y--) y];

    return Scaffold(
      backgroundColor: context.palette.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                s.ageQuestionTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: context.palette.textNavy,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                s.ageQuestionBody,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: context.palette.textNavy.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: context.palette.cardWhite,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: _year,
                    hint: Text(s.ageQuestionChooseYear),
                    items: [
                      for (final year in years)
                        DropdownMenuItem(value: year, child: Text('$year')),
                    ],
                    onChanged: (value) => setState(() => _year = value),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _year == null || _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: context.palette.primaryCoral,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(s.ageQuestionContinue),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

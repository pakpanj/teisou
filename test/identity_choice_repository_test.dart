import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kana_master/core/providers.dart';
import 'package:kana_master/data/repositories/identity_choice_repository.dart';
import 'package:kana_master/data/repositories/onboarding_repository.dart';

/// `_IdentityGate`'s own memory — whether this device has already been
/// asked Google-or-Guest — and the migration rule that skips the gate
/// entirely for an install that predates it.
void main() {
  group('remembering the choice', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('a fresh install has not chosen', () async {
      expect(await IdentityChoiceRepository().hasChosen(), isFalse);
    });

    test('once marked, it stays marked', () async {
      final repository = IdentityChoiceRepository();
      await repository.markChosen();
      expect(await repository.hasChosen(), isTrue);

      // A second instance, standing in for the next launch.
      expect(await IdentityChoiceRepository().hasChosen(), isTrue);
    });

    test('does not share its key with the tutorial flag it migrates off '
        'of — the two must be able to disagree during the migration '
        'window itself', () {
      expect(
        IdentityChoiceRepository.prefsKey,
        isNot(TutorialId.home.prefsKey),
      );
    });
  });

  group('migrating an existing install past the gate', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    ProviderContainer container() {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      return c;
    }

    test('a brand-new install (never onboarded) sees the gate', () async {
      final made = await container().read(identityChoiceMadeProvider.future);
      expect(made, isFalse);
    });

    test('an install that already finished the home tour is migrated '
        'silently — the gate is skipped without ever being shown', () async {
      SharedPreferences.setMockInitialValues({'onboarding_seen_v1': true});
      final container_ = container();

      final made = await container_.read(identityChoiceMadeProvider.future);
      expect(made, isTrue);

      // The migration actually persisted the choice, not just answered
      // "true" once from the tutorial flag alone — the next launch (a
      // fresh repository read, not the cached provider) must agree too.
      expect(await IdentityChoiceRepository().hasChosen(), isTrue);
    });

    test('an explicit choice always wins over the tutorial flag, in '
        'either direction', () async {
      // Chosen, but somehow never finished onboarding (e.g. picked
      // Guest, then closed the app before the home tour ever played) —
      // the explicit choice must still be honoured, not overridden by
      // "hasn't finished onboarding yet, show the gate again".
      await IdentityChoiceRepository().markChosen();
      final made = await container().read(identityChoiceMadeProvider.future);
      expect(made, isTrue);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/card_skins.dart';
import '../../core/localization/app_strings.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../leaderboard/leaderboard_providers.dart';

/// Choose the skin you play with.
///
/// **The one cosmetic your opponent sees**, which is why it lives with
/// the battle screens rather than with avatars and covers on the
/// profile: those are for looking at yourself, this one is for being
/// looked at.
///
/// Three families, and they never substitute for each other — free,
/// earned with stars, bought with money. See `CardSkinSource` for why
/// crossing them would ruin both halves.
/// Just the body — [CardGameShell] hosts this as its Skin tab and owns
/// the app bar around it.
class CardSkinPickerBody extends ConsumerStatefulWidget {
  const CardSkinPickerBody({super.key});

  @override
  ConsumerState<CardSkinPickerBody> createState() =>
      _CardSkinPickerBodyState();
}

class _CardSkinPickerBodyState extends ConsumerState<CardSkinPickerBody> {
  bool _saving = false;

  /// Which family is on show. `null` is "Semua"; [_owned] is the one
  /// filter that cuts across families rather than picking one, which is
  /// why it is a separate flag instead of a fifth source.
  CardSkinSource? _filter;
  bool _owned = false;

  Future<void> _select(
    CardSkinPreset skin, {
    required bool unlocked,
    required bool hasPremium,
  }) async {
    final s = ref.read(appStringsProvider);
    if (!unlocked) {
      // No paywall push: the shop cannot sell anything yet, and an
      // achievement skin is not for sale at any price. Saying what it
      // takes is the only honest response.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_requirementOf(skin, s, hasPremium: hasPremium))),
      );
      return;
    }

    final uid = ref.read(appStartupProvider).valueOrNull?.uid;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(progressRepositoryProvider).updateCardSkin(uid, skin.id);
      // Best-effort mirror onto the public row: without it the change is
      // invisible to the only people it is meant for. A miss here is
      // repaired on the way into the next match — see
      // `battleOpponentsProvider`.
      try {
        await ref
            .read(leaderboardRepositoryProvider)
            .updateCardSkinId(uid, skin.id);
      } catch (_) {}
      ref.invalidate(userProfileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.cardSkinSaved)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.cardSkinSaveFailed)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// What a locked skin needs, said plainly. A bare padlock is the one
  /// thing this screen must not do: for an achievement skin, which now
  /// needs both stars and Premium (see `CardSkinSource.achievement`'s own
  /// doc comment), the message names whichever half is still missing.
  String _requirementOf(CardSkinPreset skin, AppStrings s, {required bool hasPremium}) {
    return switch (skin.source) {
      CardSkinSource.achievement => s.cardSkinAchievementRequirement(
        skin.starsRequired,
        _starTotal,
        hasPremium: hasPremium,
      ),
      CardSkinSource.paid => s.cardSkinBuyInShop,
      CardSkinSource.event => s.cardSkinEventLocked,
      CardSkinSource.free => '',
    };
  }

  /// The server-written star total. Read from the public row rather than
  /// summed locally, because the ladder's arithmetic lives in
  /// `functions/battle_stars.js` and is deliberately not duplicated in
  /// Dart.
  int get _starTotal =>
      ref.watch(selfLeaderboardEntryProvider).valueOrNull?.cardGameStarTotal ??
      0;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final palette = context.palette;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final selectedId = profile?.cardSkinId ?? CardSkinPresets.classic.id;
    final starTotal = _starTotal;
    // Bought skins, from the server-written entitlement — this is the
    // `owned` argument `isCardSkinUnlocked` has always taken and never
    // had a source for.
    final owned = ref.watch(ownedSkinsProvider).valueOrNull ?? const <String>{};
    // Premium's "Skin Battle Card eksklusif" benefit — live from
    // `subscriptionProvider`, never stored, so the paid family re-locks
    // the moment a subscription lapses, same as `moduleAccessProvider`.
    final premium =
        ref.watch(subscriptionProvider).valueOrNull?.isPremium ?? false;

    return AbsorbPointer(
        absorbing: _saving,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              s.cardSkinExplanation,
              style: TextStyle(
                color: palette.textNavy.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: s.cardSkinFilterAll,
                    selected: _filter == null && !_owned,
                    onTap: () => setState(() {
                      _filter = null;
                      _owned = false;
                    }),
                  ),
                  _FilterChip(
                    label: s.cardSkinFilterOwned,
                    selected: _owned,
                    onTap: () => setState(() {
                      _owned = true;
                      _filter = null;
                    }),
                  ),
                  for (final source in CardSkinSource.values)
                    _FilterChip(
                      label: s.cardSkinSectionTitle(source),
                      selected: _filter == source && !_owned,
                      onTap: () => setState(() {
                        _filter = source;
                        _owned = false;
                      }),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              // The one thing a player buying a cosmetic actually needs
              // promised: it changes nothing about how a match goes.
              s.cardSkinCosmeticOnly,
              style: TextStyle(
                fontSize: 11,
                color: palette.textNavy.withValues(alpha: 0.55),
              ),
            ),
            if (kCardSkinsAllUnlocked) ...[
              const SizedBox(height: 10),
              // Said out loud on purpose: someone looking at nine
              // unlocked skins should never have to wonder whether the
              // gate is broken or simply switched off for testing.
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: palette.tertiaryAmberCardBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  s.cardSkinDebugAllUnlocked,
                  style: TextStyle(fontSize: 12, color: palette.textNavy),
                ),
              ),
            ],
            for (final source in CardSkinSource.values)
              if (_filter == null || _filter == source) ...[
              const SizedBox(height: 22),
              _SectionHeader(
                title: s.cardSkinSectionTitle(source),
                subtitle: s.cardSkinSectionSubtitle(source),
              ),
              const SizedBox(height: 10),
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.58,
                ),
                children: [
                  for (final skin in CardSkinPresets.ofSource(source))
                    if (!_owned ||
                        isCardSkinUnlocked(
                          skin,
                          starTotal: starTotal,
                          owned: owned.contains(skin.id),
                          premium: premium,
                          allUnlocked: kCardSkinsAllUnlocked,
                        ))
                    Builder(
                      builder: (context) {
                        final unlocked = isCardSkinUnlocked(
                          skin,
                          starTotal: starTotal,
                          owned: owned.contains(skin.id),
                          premium: premium,
                          allUnlocked: kCardSkinsAllUnlocked,
                        );
                        return _SkinTile(
                          skin: skin,
                          selected: skin.id == selectedId,
                          locked: !unlocked,
                          label: skin.labelFor(s.language),
                          requirement: unlocked
                              ? null
                              : _requirementOf(skin, s, hasPremium: premium),
                          onTap: () => _select(
                            skin,
                            unlocked: unlocked,
                            hasPremium: premium,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: palette.textNavy,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: palette.textNavy.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _SkinTile extends StatelessWidget {
  const _SkinTile({
    required this.skin,
    required this.selected,
    required this.locked,
    required this.label,
    required this.requirement,
    required this.onTap,
  });

  final CardSkinPreset skin;
  final bool selected;
  final bool locked;
  final String label;

  /// What it takes, for a locked skin — shown under the tile so the
  /// padlock explains itself instead of just refusing.
  final String? requirement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color:
                          selected ? palette.primaryCoral : palette.divider,
                      width: selected ? 3 : 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: CardSkinBack(
                      skin: skin,
                      borderRadius: 11,
                      showCrest: false,
                    ),
                  ),
                ),
                if (locked)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                if (selected)
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.check_circle,
                        color: palette.primaryCoral,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: palette.textNavy,
            ),
          ),
          if (requirement != null && requirement!.isNotEmpty)
            Text(
              requirement!,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                color: palette.textNavy.withValues(alpha: 0.55),
              ),
            ),
        ],
      ),
    );
  }
}


/// One family filter, in the redesign's pill style.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? palette.primaryCoral : palette.cardWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? palette.primaryCoral : palette.divider,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? Colors.white : palette.textNavy,
            ),
          ),
        ),
      ),
    );
  }
}

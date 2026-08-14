import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/card_skins.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../paywall/paywall_screen.dart';

/// Choose the card back you play with.
///
/// **The one cosmetic your opponent sees**, which is why it lives here
/// rather than with avatars and covers on the profile: those are for
/// looking at yourself, this one is for being looked at.
///
/// Locked skins follow the same gate premium avatars already use — an
/// active subscription, or a rewarded ad — because that is the only
/// purchase machinery this app has. Selling a skin for money needs
/// `in_app_purchase`, which has never been wired up here (see CLAUDE.md's
/// release readiness). When it is, this screen changes in one place: the
/// lock branches on "owned" rather than on [CardSkinPreset.premium].
class CardSkinPickerScreen extends ConsumerStatefulWidget {
  const CardSkinPickerScreen({super.key});

  @override
  ConsumerState<CardSkinPickerScreen> createState() =>
      _CardSkinPickerScreenState();
}

class _CardSkinPickerScreenState extends ConsumerState<CardSkinPickerScreen> {
  bool _saving = false;
  bool _adRewardActive = false;

  @override
  void initState() {
    super.initState();
    _refreshAdReward();
  }

  /// The ad-reward unlock is read back, not assumed — the same gap that
  /// once made `AvatarPickerSheet`'s gallery stay locked after watching
  /// an ad was exactly a reward written and never read.
  Future<void> _refreshAdReward() async {
    final uid = ref.read(appStartupProvider).valueOrNull?.uid;
    if (uid == null) return;
    try {
      final rewards =
          await ref.read(progressRepositoryProvider).getAdRewards(uid);
      final reward = rewards['premium_preview'];
      if (!mounted) return;
      setState(() => _adRewardActive = reward?.isActive ?? false);
    } catch (_) {
      // A failed read just leaves the locks on, which is the safe way
      // round: it never grants something that was not earned.
    }
  }

  Future<void> _select(CardSkinPreset skin, {required bool unlocked}) async {
    if (!unlocked) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const PaywallScreen(
            moduleId: 'card_skin',
            moduleTitle: 'Skin Kartu',
          ),
        ),
      );
      await _refreshAdReward();
      return;
    }

    final uid = ref.read(appStartupProvider).valueOrNull?.uid;
    if (uid == null) return;
    final s = ref.read(appStringsProvider);
    setState(() => _saving = true);
    try {
      await ref.read(progressRepositoryProvider).updateCardSkin(uid, skin.id);
      // Best-effort mirror onto the public row: without it the change is
      // invisible to the only people it is meant for.
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

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final palette = context.palette;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final isPremium =
        ref.watch(subscriptionProvider).valueOrNull?.isPremium ?? false;
    final selectedId = profile?.cardSkinId ?? CardSkinPresets.classic.id;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: Text(s.cardSkinTitle)),
      body: AbsorbPointer(
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
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: CardSkinPresets.all.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.62,
              ),
              itemBuilder: (context, i) {
                final skin = CardSkinPresets.all[i];
                final unlocked =
                    !skin.premium || isPremium || _adRewardActive;
                return _SkinTile(
                  skin: skin,
                  selected: skin.id == selectedId,
                  locked: !unlocked,
                  label: skin.labelFor(s.language),
                  onTap: () => _select(skin, unlocked: unlocked),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SkinTile extends StatelessWidget {
  const _SkinTile({
    required this.skin,
    required this.selected,
    required this.locked,
    required this.label,
    required this.onTap,
  });

  final CardSkinPreset skin;
  final bool selected;
  final bool locked;
  final String label;
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
                      color: selected
                          ? palette.primaryCoral
                          : palette.divider,
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
        ],
      ),
    );
  }
}

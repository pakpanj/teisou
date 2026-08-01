import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/avatars.dart';
import '../../../core/constants/frames.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_profile.dart';
import '../../paywall/paywall_screen.dart';

/// Bottom sheet for picking a profile avatar: Google photo, free presets,
/// and premium presets (locked behind [PaywallScreen] for free users).
///
/// There is deliberately no gallery-upload option. It existed once and was
/// removed: the app has a public global leaderboard and no moderation tools
/// or admin surface, so an arbitrary user-supplied image had no path to
/// being reviewed or taken down. Every avatar a user can now choose is
/// bundled art. Don't reintroduce picking from the device without a
/// moderation story to go with it.
class AvatarPickerSheet extends ConsumerStatefulWidget {
  const AvatarPickerSheet({super.key});

  @override
  ConsumerState<AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

/// The `moduleId` watching an ad on [PaywallScreen] grants a one-time
/// unlock for — the premium-presets grid below, matching the "Avatar
/// Premium" offer on that screen.
const _avatarPremiumModuleId = 'avatar_premium';

enum _PickerMode { avatar, frame }

class _AvatarPickerSheetState extends ConsumerState<AvatarPickerSheet> {
  _PickerMode _mode = _PickerMode.avatar;

  /// Whether an unspent ad-reward unlock for [_avatarPremiumModuleId]
  /// exists. `ProgressRepository.unlockAdReward`/`getAdRewards` already
  /// existed but were a write with no matching read anywhere in the app —
  /// this sheet used to gate its premium entries on [isPremium] alone, so
  /// watching the rewarded ad on [PaywallScreen] recorded the unlock but
  /// nothing ever consulted it: the tile just reopened the paywall again,
  /// which read as "watched the ad but it still won't open" (the exact bug
  /// report this fixed). Refreshed in [initState] (in case
  /// an earlier session's still-unspent unlock exists) and again after
  /// [_openPaywall] returns, since this sheet is only ever pushed over by
  /// `PaywallScreen`, never replaced — its own state must be refreshed
  /// explicitly on return rather than assumed to recompute automatically.
  /// One ad grants exactly one avatar change: picking a premium preset
  /// calls `ProgressRepository.consumeAdReward` right after succeeding,
  /// rather than leaving it active for its full 24h backstop window — see
  /// [_select]'s `consumeReward` param.
  bool _adRewardActive = false;

  @override
  void initState() {
    super.initState();
    _refreshAdRewardStatus();
  }

  Future<void> _refreshAdRewardStatus() async {
    final uid = ref.read(appStartupProvider).valueOrNull?.uid;
    if (uid == null) return;
    final rewards = await ref.read(progressRepositoryProvider).getAdRewards(uid);
    final active = rewards[_avatarPremiumModuleId]?.isActive ?? false;
    if (mounted) setState(() => _adRewardActive = active);
  }

  Future<void> _select(
    String uid,
    AvatarType type,
    String? value, {
    required String displayName,
    String? photoUrl,
    bool consumeReward = false,
  }) async {
    try {
      await ref.read(progressRepositoryProvider).updateAvatar(uid, type, value);
      await ref.read(leaderboardRepositoryProvider).syncProfileInfo(
            uid: uid,
            displayName: displayName,
            photoUrl: photoUrl,
            avatarType: type,
            avatarValue: value,
          );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(appStringsProvider).avatarSaveFailed)),
      );
      return;
    }
    if (consumeReward) {
      // Best-effort only — the avatar itself already saved successfully
      // above, so a hiccup here must not surface as a failure.
      try {
        await ref
            .read(progressRepositoryProvider)
            .consumeAdReward(uid, _avatarPremiumModuleId);
      } catch (_) {}
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _selectFrame(String uid, String? frameId) async {
    try {
      await ref.read(progressRepositoryProvider).updateFrame(uid, frameId);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(appStringsProvider).frameSaveFailed)),
      );
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _openPaywall(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PaywallScreen(
          moduleId: _avatarPremiumModuleId,
          moduleTitle: 'Avatar Premium',
          singleUse: true,
        ),
      ),
    );
    // PaywallScreen pops itself the moment the reward is earned, so by the
    // time this await resolves the write (if any) has already landed —
    // safe to read it back immediately, no extra delay needed.
    if (!mounted) return;
    await _refreshAdRewardStatus();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appStartupProvider).valueOrNull;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final isPremium = ref.watch(subscriptionProvider).valueOrNull?.isPremium ?? false;
    // A real subscription OR an unspent ad-reward unlock both count — see
    // _adRewardActive's doc comment for why the latter needs its own
    // explicit tracking instead of folding into isPremium at the source.
    final unlocked = isPremium || _adRewardActive;
    // Whether the action about to happen would be spending the ad-reward
    // (not a real subscription) — if so, the caller must consume it right
    // after succeeding so one ad only ever buys one change.
    final viaAdReward = !isPremium && _adRewardActive;
    final uid = user?.uid;
    final s = ref.watch(appStringsProvider);
    final displayName = profile?.resolveDisplayName(user) ?? (user?.displayName ?? s.defaultLearnerName);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textNavy.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _PickerModeTab(
                    label: s.pickAvatarTitle,
                    active: _mode == _PickerMode.avatar,
                    onTap: () => setState(() => _mode = _PickerMode.avatar),
                  ),
                  const SizedBox(width: 20),
                  _PickerModeTab(
                    label: s.pickFrameTitle,
                    active: _mode == _PickerMode.frame,
                    onTap: () => setState(() => _mode = _PickerMode.frame),
                  ),
                ],
              ),
              if (_mode == _PickerMode.avatar) ...[
                if (user != null && !user.isAnonymous && user.photoURL != null) ...[
                  _SectionTitle(s.accountPhotoSection),
                  _GoogleAvatarTile(
                    photoUrl: user.photoURL!,
                    label: s.googleAccountPhotoLabel,
                    selected: profile != null && profile.avatarType == AvatarType.google,
                    onTap: uid == null
                        ? null
                        : () => _select(
                              uid,
                              AvatarType.google,
                              null,
                              displayName: displayName,
                              photoUrl: user.photoURL,
                            ),
                  ),
                ],
                _SectionTitle(s.freePresetsSection),
                _PresetGrid(
                  presets: AvatarPresets.free,
                  isSelected: (preset) =>
                      profile?.avatarType == AvatarType.presetFree &&
                      profile?.avatarValue == preset.id,
                  locked: (_) => false,
                  onTap: (preset) {
                    if (uid == null) return;
                    _select(
                      uid,
                      AvatarType.presetFree,
                      preset.id,
                      displayName: displayName,
                      photoUrl: user?.photoURL,
                    );
                  },
                ),
                _SectionTitle(s.premiumPresetsSection),
                _PresetGrid(
                  presets: AvatarPresets.premium,
                  isSelected: (preset) =>
                      profile?.avatarType == AvatarType.presetPremium &&
                      profile?.avatarValue == preset.id,
                  locked: (_) => !unlocked,
                  onTap: (preset) {
                    if (!unlocked) {
                      _openPaywall(context);
                      return;
                    }
                    if (uid == null) return;
                    _select(
                      uid,
                      AvatarType.presetPremium,
                      preset.id,
                      displayName: displayName,
                      photoUrl: user?.photoURL,
                      consumeReward: viaAdReward,
                    );
                  },
                ),
              ] else ...[
                const SizedBox(height: 16),
                _FrameGrid(
                  selectedId: profile?.frameId,
                  noFrameLabel: s.noFrameLabel,
                  onTap: (frameId) {
                    if (uid == null) return;
                    _selectFrame(uid, frameId);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// One of the two labels next to each other at the top of the sheet
/// ("Pilih Avatar" / "Pilih Bingkai") that switch which section is shown
/// below, instead of everything being one long scroll.
class _PickerModeTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _PickerModeTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? AppColors.primaryCoral : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: active
                ? AppColors.textNavy
                : AppColors.textNavy.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textNavy,
        ),
      ),
    );
  }
}

class _GoogleAvatarTile extends StatelessWidget {
  final String photoUrl;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _GoogleAvatarTile({
    required this.photoUrl,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: selected
              ? Border.all(color: AppColors.primaryCoral, width: 2)
              : null,
        ),
        child: Row(
          children: [
            CircleAvatar(radius: 24, backgroundImage: NetworkImage(photoUrl)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: const TextStyle(color: AppColors.textNavy)),
            ),
            if (selected) const Icon(Icons.check_circle, color: AppColors.primaryCoral),
          ],
        ),
      ),
    );
  }
}

class _PresetGrid extends StatelessWidget {
  final List<AvatarPreset> presets;
  final bool Function(AvatarPreset) isSelected;
  final bool Function(AvatarPreset) locked;
  final void Function(AvatarPreset) onTap;

  const _PresetGrid({
    required this.presets,
    required this.isSelected,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: presets.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final preset = presets[index];
        return _PresetTile(
          preset: preset,
          selected: isSelected(preset),
          locked: locked(preset),
          onTap: () => onTap(preset),
        );
      },
    );
  }
}

class _PresetTile extends StatelessWidget {
  final AvatarPreset preset;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  const _PresetTile({
    required this.preset,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 1,
              child: AvatarPresetArt(
                preset: preset,
                imageSize: double.infinity,
                emojiFontSize: 28,
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (selected)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryCoral, width: 2),
                ),
              ),
            ),
          if (selected)
            const Positioned(
              right: 4,
              top: 4,
              child: Icon(Icons.check_circle, color: AppColors.primaryCoral, size: 18),
            ),
          if (locked)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppColors.textNavy,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock, color: Colors.white, size: 12),
              ),
            ),
        ],
      ),
    );
  }
}

/// Grid of selectable avatar frames/borders: a "no frame" tile (index 0,
/// always available) followed by [FramePresets.all] — empty for now until
/// real frame art is supplied, so this grid currently only ever shows the
/// "no frame" tile. Mirrors [CoverPickerSheet]'s default-plus-presets grid
/// shape, not [_PresetGrid]'s (frames aren't premium-gated).
class _FrameGrid extends StatelessWidget {
  final String? selectedId;
  final String noFrameLabel;
  final void Function(String? frameId) onTap;

  const _FrameGrid({
    required this.selectedId,
    required this.noFrameLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final frames = FramePresets.all;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: frames.length + 1,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _FrameTile(
            selected: selectedId == null,
            child: Text(noFrameLabel, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppColors.textNavy)),
            onTap: () => onTap(null),
          );
        }
        final preset = frames[index - 1];
        return _FrameTile(
          selected: selectedId == preset.id,
          // Sized off the tile rather than a fixed 40 — these are detailed
          // wreath illustrations, and at 40 inside a ~92 tile they rendered
          // too small to tell apart. Invisible while FramePresets.all was
          // empty; only showed up once real art landed.
          child: LayoutBuilder(
            builder: (context, constraints) => FrameOverlay(
              preset: preset,
              avatarSize: constraints.maxWidth - 12,
              scale: 1,
            ),
          ),
          onTap: () => onTap(preset.id),
        );
      },
    );
  }
}

class _FrameTile extends StatelessWidget {
  final bool selected;
  final Widget child;
  final VoidCallback onTap;

  const _FrameTile({required this.selected, required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(16),
              border: selected
                  ? Border.all(color: AppColors.primaryCoral, width: 2)
                  : null,
            ),
            alignment: Alignment.center,
            child: child,
          ),
          if (selected)
            const Positioned(
              right: 4,
              top: 4,
              child: Icon(Icons.check_circle, color: AppColors.primaryCoral, size: 18),
            ),
        ],
      ),
    );
  }
}

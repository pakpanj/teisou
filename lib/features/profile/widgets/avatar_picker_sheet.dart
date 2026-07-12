import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/avatars.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_profile.dart';
import '../../paywall/paywall_screen.dart';

/// Bottom sheet for picking a profile avatar: Google photo, free presets,
/// premium presets (locked behind [PaywallScreen] for free users), and a
/// gallery upload entry point (wired up fully once Firebase Storage upload
/// lands).
class AvatarPickerSheet extends ConsumerWidget {
  const AvatarPickerSheet({super.key});

  Future<void> _select(
    BuildContext context,
    WidgetRef ref,
    String uid,
    AvatarType type,
    String? value, {
    required String displayName,
    String? photoUrl,
  }) async {
    await ref.read(progressRepositoryProvider).updateAvatar(uid, type, value);
    await ref.read(leaderboardRepositoryProvider).syncProfileInfo(
          uid: uid,
          displayName: displayName,
          photoUrl: photoUrl,
          avatarType: type,
          avatarValue: value,
        );
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }

  void _openPaywall(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PaywallScreen(
          moduleId: 'avatar_premium',
          moduleTitle: 'Avatar Premium',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appStartupProvider).valueOrNull;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final isPremium = ref.watch(subscriptionProvider).valueOrNull?.isPremium ?? false;
    final uid = user?.uid;
    final displayName = profile?.resolveDisplayName(user) ?? (user?.displayName ?? 'Pelajar Kana');

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
              const Text(
                'Pilih Avatar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textNavy,
                ),
              ),
              if (user != null && !user.isAnonymous && user.photoURL != null) ...[
                const _SectionTitle('Foto Akun'),
                _GoogleAvatarTile(
                  photoUrl: user.photoURL!,
                  selected: profile == null || profile.avatarType == AvatarType.google,
                  onTap: uid == null
                      ? null
                      : () => _select(
                            context,
                            ref,
                            uid,
                            AvatarType.google,
                            null,
                            displayName: displayName,
                            photoUrl: user.photoURL,
                          ),
                ),
              ],
              const _SectionTitle('Preset Gratis'),
              _PresetGrid(
                presets: AvatarPresets.free,
                isSelected: (preset) =>
                    profile?.avatarType == AvatarType.presetFree &&
                    profile?.avatarValue == preset.id,
                locked: (_) => false,
                onTap: (preset) {
                  if (uid == null) return;
                  _select(
                    context,
                    ref,
                    uid,
                    AvatarType.presetFree,
                    preset.id,
                    displayName: displayName,
                    photoUrl: user?.photoURL,
                  );
                },
              ),
              const _SectionTitle('Preset Premium'),
              _PresetGrid(
                presets: AvatarPresets.premium,
                isSelected: (preset) =>
                    profile?.avatarType == AvatarType.presetPremium &&
                    profile?.avatarValue == preset.id,
                locked: (_) => !isPremium,
                onTap: (preset) {
                  if (!isPremium) {
                    _openPaywall(context);
                    return;
                  }
                  if (uid == null) return;
                  _select(
                    context,
                    ref,
                    uid,
                    AvatarType.presetPremium,
                    preset.id,
                    displayName: displayName,
                    photoUrl: user?.photoURL,
                  );
                },
              ),
              const _SectionTitle('Upload dari Galeri'),
              _UploadTile(
                isPremium: isPremium,
                onTap: () {
                  if (!isPremium) {
                    _openPaywall(context);
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Upload avatar akan segera hadir.'),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
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
  final bool selected;
  final VoidCallback? onTap;

  const _GoogleAvatarTile({
    required this.photoUrl,
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
            const Expanded(
              child: Text('Foto akun Google', style: TextStyle(color: AppColors.textNavy)),
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
          Container(
            decoration: BoxDecoration(
              color: preset.background,
              borderRadius: BorderRadius.circular(16),
              border: selected
                  ? Border.all(color: AppColors.primaryCoral, width: 2)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(preset.emoji, style: const TextStyle(fontSize: 28)),
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

class _UploadTile extends StatelessWidget {
  final bool isPremium;
  final VoidCallback onTap;

  const _UploadTile({required this.isPremium, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📷', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            const Text(
              'Upload dari Galeri',
              style: TextStyle(color: AppColors.textNavy, fontWeight: FontWeight.w600),
            ),
            if (!isPremium) ...[
              const SizedBox(width: 8),
              const Icon(Icons.lock, size: 16, color: AppColors.freeBadgeGrey),
            ],
          ],
        ),
      ),
    );
  }
}

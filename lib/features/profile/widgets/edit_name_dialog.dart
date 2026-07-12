import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_profile.dart';

/// Dialog for changing `customDisplayName`. Premium users save instantly;
/// free users must watch a rewarded ad first (gated via [AdService]).
class EditNameDialog extends ConsumerStatefulWidget {
  final String currentName;

  const EditNameDialog({super.key, required this.currentName});

  @override
  ConsumerState<EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends ConsumerState<EditNameDialog> {
  late final _controller = TextEditingController(text: widget.currentName);
  bool _watchingAd = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? get _trimmedOrNull {
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty || trimmed.length > 20) return null;
    return trimmed;
  }

  Future<void> _syncLeaderboard(String uid, String name) {
    final profile = ref.read(userProfileProvider).valueOrNull;
    final user = ref.read(appStartupProvider).valueOrNull;
    return ref.read(leaderboardRepositoryProvider).syncProfileInfo(
          uid: uid,
          displayName: name,
          photoUrl: user?.photoURL,
          avatarType: profile?.avatarType ?? AvatarType.google,
          avatarValue: profile?.avatarValue,
        );
  }

  Future<void> _saveDirectly(String uid, String name) async {
    await ref.read(progressRepositoryProvider).updateCustomDisplayName(uid, name);
    await _syncLeaderboard(uid, name);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _watchAdThenSave(String uid, String name) {
    setState(() => _watchingAd = true);
    ref.read(adServiceProvider).loadAndShowRewarded(
      onRewardEarned: () async {
        await ref.read(progressRepositoryProvider).updateCustomDisplayName(uid, name);
        await _syncLeaderboard(uid, name);
        if (!mounted) return;
        setState(() => _watchingAd = false);
        Navigator.of(context).pop();
      },
      onFailedToLoad: () {
        if (!mounted) return;
        setState(() => _watchingAd = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat iklan, coba lagi.')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(appStartupProvider).valueOrNull?.uid;
    final isPremium = ref.watch(subscriptionProvider).valueOrNull?.isPremium ?? false;
    final name = _trimmedOrNull;

    return AlertDialog(
      title: const Text('Ganti Nama'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            maxLength: 20,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Nama tampilan',
              border: OutlineInputBorder(),
            ),
          ),
          if (!isPremium) ...[
            const SizedBox(height: 4),
            const Text(
              'Ganti nama gratis dengan menonton iklan sebentar.',
              style: TextStyle(fontSize: 13, color: AppColors.textNavy),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _watchingAd ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        if (isPremium)
          FilledButton(
            onPressed: (name == null || uid == null)
                ? null
                : () => _saveDirectly(uid, name),
            child: const Text('Simpan'),
          )
        else
          FilledButton(
            onPressed: (name == null || uid == null || _watchingAd)
                ? null
                : () => _watchAdThenSave(uid, name),
            child: _watchingAd
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Nonton Iklan & Simpan'),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/root_navigator_key.dart';
import '../../../core/providers.dart';
import '../identity_sync.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/user_profile.dart';

/// Dialog for changing `customDisplayName`. Premium users always save
/// instantly. Free users save instantly too, but only the *first* time
/// ever (`UserProfile.lastNameChangeAt` still null — this reuses that
/// existing field rather than adding a new one, since it was already
/// stamped by every successful change and simply never had a reader
/// before this) — every change after that needs a rewarded ad, same as
/// before this change.
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

  /// Pushes the new name to every denormalized copy of it — leaderboard,
  /// clan rosters and friends. Previously synced only the first two, so a
  /// rename left every friend's chat list showing the old name for ever.
  Future<void> _syncIdentity(String uid, String name) async {
    final profile = ref.read(userProfileProvider).valueOrNull;
    final user = ref.read(appStartupProvider).valueOrNull;
    // Root container, not this dialog's own `ref` — see
    // `identity_sync.dart`'s doc comment: a dialog is exactly the kind of
    // widget likely to be popped (or its sheet dismissed) right after the
    // save button is tapped, before these sequential writes finish.
    await syncIdentityEverywhere(
      rootProviderContainer(),
      uid: uid,
      displayName: name,
      photoUrl: user?.photoURL,
      avatarType: profile?.avatarType ?? AvatarType.google,
      avatarValue: profile?.avatarValue,
    );
  }

  Future<void> _saveDirectly(String uid, String name) async {
    try {
      await ref.read(progressRepositoryProvider).updateCustomDisplayName(uid, name);
      await _syncIdentity(uid, name);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(appStringsProvider).nameSaveFailed)),
      );
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _watchAdThenSave(String uid, String name) {
    setState(() => _watchingAd = true);
    final s = ref.read(appStringsProvider);
    ref.read(adServiceProvider).loadAndShowRewarded(
      onRewardEarned: () async {
        try {
          await ref.read(progressRepositoryProvider).updateCustomDisplayName(uid, name);
          await _syncIdentity(uid, name);
        } catch (_) {
          if (!mounted) return;
          setState(() => _watchingAd = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.nameSaveFailed)),
          );
          return;
        }
        if (!mounted) return;
        setState(() => _watchingAd = false);
        Navigator.of(context).pop();
      },
      onFailedToLoad: () {
        if (!mounted) return;
        setState(() => _watchingAd = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.adLoadFailed)),
        );
      },
      onDismissedWithoutReward: () {
        if (!mounted) return;
        setState(() => _watchingAd = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.adClosedEarly)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(appStartupProvider).valueOrNull?.uid;
    final isPremium = ref.watch(subscriptionProvider).valueOrNull?.isPremium ?? false;
    final hasNeverChangedName =
        ref.watch(userProfileProvider).valueOrNull?.lastNameChangeAt == null;
    final canSaveFree = isPremium || hasNeverChangedName;
    final name = _trimmedOrNull;
    final s = ref.watch(appStringsProvider);

    return AlertDialog(
      title: Text(s.changeNameTooltip),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            maxLength: 20,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: s.displayNameHint,
              border: const OutlineInputBorder(),
            ),
          ),
          if (!isPremium) ...[
            const SizedBox(height: 4),
            Text(
              hasNeverChangedName ? s.firstNameChangeFreeHint : s.freeNameChangeHint,
              style: TextStyle(fontSize: 13, color: context.palette.textNavy),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _watchingAd ? null : () => Navigator.of(context).pop(),
          child: Text(s.cancel),
        ),
        if (canSaveFree)
          FilledButton(
            onPressed: (name == null || uid == null)
                ? null
                : () => _saveDirectly(uid, name),
            child: Text(s.saveButton),
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
                : Text(s.watchAdAndSaveButton),
          ),
      ],
    );
  }
}

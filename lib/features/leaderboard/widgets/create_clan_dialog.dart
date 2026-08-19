import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/user_profile.dart';
import '../../paywall/paywall_screen.dart';

/// The `moduleId` watching an ad on [PaywallScreen] grants a one-time
/// unlock for — creating one clan past the free first one. See
/// `ClanRepository.createClan`'s doc comment for the full mechanism
/// (`firestore.rules`' `canCreateClan` is the real gate; this dialog's own
/// eligibility check is just a UX head start).
const _clanExtraModuleId = 'clan_extra';

/// Dialog for creating a new clan. Every account gets exactly one free
/// clan — past that, creating another one requires an active premium
/// subscription or a spent single-use rewarded-ad unlock, checked on open
/// (`_checkEligibility`) before the name form ever shows. On success it
/// swaps its own content to a "here's your join code" view instead of
/// closing immediately — sharing that code with students is the entire
/// point of creating one, so it needs to stay on screen long enough to
/// actually copy/read.
class CreateClanDialog extends ConsumerStatefulWidget {
  const CreateClanDialog({super.key});

  @override
  ConsumerState<CreateClanDialog> createState() => _CreateClanDialogState();
}

class _CreateClanDialogState extends ConsumerState<CreateClanDialog> {
  final _controller = TextEditingController();
  bool _creating = false;
  String? _error;
  String? _createdCode;

  bool _checkingEligibility = true;
  bool _eligible = false;
  // True only when eligibility came from a spent single-use ad reward (not
  // the free slot, not premium) — tells `_create` whether it must consume
  // that reward right after a successful creation.
  bool _viaAdReward = false;

  @override
  void initState() {
    super.initState();
    _checkEligibility();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkEligibility() async {
    if (mounted) setState(() => _checkingEligibility = true);
    final uid = ref.read(appStartupProvider).valueOrNull?.uid;
    if (uid == null) {
      if (mounted) setState(() => _checkingEligibility = false);
      return;
    }

    final bool freeSlotUsed;
    try {
      freeSlotUsed =
          await ref.read(clanRepositoryProvider).hasUsedFreeClanSlot(uid);
    } catch (_) {
      // Fail closed, not open: an unreadable answer must not hand out an
      // unlimited free slot. But it must also not leave the dialog on a
      // spinner it can never come back from.
      if (!mounted) return;
      setState(() {
        _checkingEligibility = false;
        _eligible = false;
        _viaAdReward = false;
      });
      return;
    }
    if (!freeSlotUsed) {
      if (!mounted) return;
      setState(() {
        _checkingEligibility = false;
        _eligible = true;
        _viaAdReward = false;
      });
      return;
    }

    final isPremium =
        ref.read(subscriptionProvider).valueOrNull?.isPremium ?? false;
    if (isPremium) {
      if (!mounted) return;
      setState(() {
        _checkingEligibility = false;
        _eligible = true;
        _viaAdReward = false;
      });
      return;
    }

    final rewards = await ref.read(progressRepositoryProvider).getAdRewards(uid);
    final adActive = rewards[_clanExtraModuleId]?.isActive ?? false;
    if (!mounted) return;
    setState(() {
      _checkingEligibility = false;
      _eligible = adActive;
      _viaAdReward = adActive;
    });
  }

  Future<void> _openPaywall() async {
    final s = ref.read(appStringsProvider);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaywallScreen(
          moduleId: _clanExtraModuleId,
          moduleTitle: s.clanExtraPremiumTitle,
          singleUse: true,
        ),
      ),
    );
    // PaywallScreen pops itself the moment the reward is earned, so by the
    // time this await resolves the write (if any) has already landed —
    // safe to re-check eligibility immediately, no extra delay needed.
    if (!mounted) return;
    await _checkEligibility();
  }

  String? get _trimmedOrNull {
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty || trimmed.length > 30) return null;
    return trimmed;
  }

  Future<void> _create() async {
    final name = _trimmedOrNull;
    final user = ref.read(appStartupProvider).valueOrNull;
    if (name == null || user == null) return;
    final s = ref.read(appStringsProvider);

    setState(() {
      _creating = true;
      _error = null;
    });

    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      final code = await ref.read(clanRepositoryProvider).createClan(
            hostUid: user.uid,
            name: name,
            hostDisplayName: profile?.resolveDisplayName(user) ??
                (user.displayName ?? s.defaultLearnerName),
            photoUrl: user.photoURL,
            avatarType: profile?.avatarType ?? AvatarType.google,
            avatarValue: profile?.avatarValue,
          );
      if (_viaAdReward) {
        // Best-effort only — the clan itself already exists at this point,
        // so a hiccup revoking the reward must not surface as a failure.
        try {
          await ref
              .read(progressRepositoryProvider)
              .consumeAdReward(user.uid, _clanExtraModuleId);
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _creating = false;
        _createdCode = code;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _creating = false;
        _error = s.createClanFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = _createdCode;
    final s = ref.watch(appStringsProvider);

    if (_checkingEligibility) {
      return const AlertDialog(
        content: SizedBox(
          height: 80,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (!_eligible) {
      return AlertDialog(
        title: Text(s.clanCreationLimitTitle),
        content: Text(
          s.clanCreationLimitBody,
          style: TextStyle(color: context.palette.textNavy),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: _openPaywall,
            child: Text(s.clanCreationLimitButton),
          ),
        ],
      );
    }

    if (code != null) {
      return AlertDialog(
        title: Text(s.clanCreatedTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              s.shareCodeMessage,
              style: TextStyle(color: context.palette.textNavy),
            ),
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: context.palette.primaryCoral.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.palette.primaryCoral.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                code,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: context.palette.primaryCoral,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(s.codeCopied)),
              );
            },
            child: Text(s.copyCode),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s.done),
          ),
        ],
      );
    }

    final name = _trimmedOrNull;
    return AlertDialog(
      title: Text(s.createClan),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            maxLength: 30,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: s.clanNameHint,
              border: const OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 4),
            Text(
              _error!,
              style: TextStyle(color: context.palette.errorRed, fontSize: 13),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _creating ? null : () => Navigator.of(context).pop(),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: (name == null || _creating) ? null : _create,
          child: _creating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(s.createButton),
        ),
      ],
    );
  }
}

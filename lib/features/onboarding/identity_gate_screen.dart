import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/services/auth_service.dart' show GoogleAccountConflictException;
import '../../core/theme/app_palette.dart';
import '../../core/widgets/mascot_widget.dart';
import '../battle/widgets/battle_arena.dart' show BattleBackdrop;

/// "Lanjut dengan Google" / "Lanjut sebagai Tamu" — sits between the age
/// question and the Plan Intro paywall (see `main.dart`'s `_IdentityGate`
/// for exactly where and why, and `identityChoiceMadeProvider` for how an
/// existing install never sees this retroactively).
///
/// **Never creates or replaces a Firebase UID itself.** By the time this
/// screen can render, `appStartupProvider` (anonymous sign-in) has
/// already resolved — same guarantee `_PlanIntroGate` already depends on
/// — so an anonymous UID always exists first. "Tamu" just accepts that
/// UID as-is; "Google" links it via `AuthService.linkWithGoogle`, which
/// preserves the UID (and everything keyed by it) rather than minting a
/// new one.
class IdentityGateScreen extends ConsumerStatefulWidget {
  const IdentityGateScreen({super.key});

  @override
  ConsumerState<IdentityGateScreen> createState() =>
      _IdentityGateScreenState();
}

class _IdentityGateScreenState extends ConsumerState<IdentityGateScreen> {
  bool _busy = false;

  Future<void> _continueAsGuest() async {
    setState(() => _busy = true);
    try {
      await ref.read(identityChoiceRepositoryProvider).markChosen();
      ref.invalidate(identityChoiceMadeProvider);
      // No setState(_busy = false) on success — this screen is about to be
      // replaced by _PlanIntroGate the moment identityChoiceMadeProvider
      // resolves true, so there is nothing left to un-busy.
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _continueWithGoogle() async {
    setState(() => _busy = true);
    final s = ref.read(appStringsProvider);
    try {
      final result = await ref.read(authServiceProvider).linkWithGoogle();
      // A cancelled account picker is not a failure — the learner just
      // hasn't decided yet, so they stay on this screen with both options
      // still open, same as if they'd never tapped anything.
      if (result == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      await ref.read(identityChoiceRepositoryProvider).markChosen();
      ref.invalidate(appStartupProvider);
      ref.invalidate(identityChoiceMadeProvider);
    } on GoogleAccountConflictException {
      // This exact conflict (and its own confirm-before-switching
      // handling) already exists on ProfileScreen — a Guest linking
      // Google for the first time on this screen is a much rarer way to
      // hit it than doing so later from Profile, so it is treated the
      // same simple way "Lanjut sebagai Tamu" already is: staying Guest
      // is always safe here, since nothing has been bought yet at this
      // point in the flow, so there is nothing to explain away with a
      // full conflict dialog before it can even matter.
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.googleAccountAlreadyLinked)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.googleSignInFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    return Scaffold(
      backgroundColor: context.palette.background,
      body: BattleBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const MascotWidget(
                  mood: MascotMood.waving,
                  size: 140,
                  showBackdrop: false,
                  groundShadow: true,
                ),
                const SizedBox(height: 28),
                Text(
                  s.identityGateTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: context.palette.textNavy,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  s.identityGateSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.palette.textNavy.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: context.palette.primaryCoral,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _busy ? null : _continueWithGoogle,
                    icon: const Icon(Icons.g_mobiledata, size: 28),
                    label: Text(s.identityGateContinueWithGoogle),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: context.palette.primaryCoral),
                      foregroundColor: context.palette.primaryCoral,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _busy ? null : _continueAsGuest,
                    child: Text(s.identityGateContinueAsGuest),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

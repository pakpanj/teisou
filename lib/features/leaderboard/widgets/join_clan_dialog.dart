import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../data/models/user_profile.dart';

/// Dialog for joining an existing clan by its join code. A code that
/// doesn't resolve to a clan shows an inline error and keeps the dialog
/// open (rather than closing on failure) so the user can retype it.
class JoinClanDialog extends ConsumerStatefulWidget {
  const JoinClanDialog({super.key});

  @override
  ConsumerState<JoinClanDialog> createState() => _JoinClanDialogState();
}

class _JoinClanDialogState extends ConsumerState<JoinClanDialog> {
  final _controller = TextEditingController();
  bool _joining = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _controller.text.trim().toUpperCase();
    final user = ref.read(appStartupProvider).valueOrNull;
    if (code.isEmpty || user == null) return;

    setState(() {
      _joining = true;
      _error = null;
    });

    final clanRepository = ref.read(clanRepositoryProvider);
    final clan = await clanRepository.findByCode(code);
    if (clan == null) {
      if (!mounted) return;
      setState(() {
        _joining = false;
        _error = 'Kode tidak ditemukan.';
      });
      return;
    }

    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      await clanRepository.joinClan(
        code: code,
        uid: user.uid,
        displayName: profile?.resolveDisplayName(user) ??
            (user.displayName ?? 'Pelajar Kana'),
        photoUrl: user.photoURL,
        avatarType: profile?.avatarType ?? AvatarType.google,
        avatarValue: profile?.avatarValue,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _joining = false;
        _error = 'Gagal bergabung, coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Gabung dengan Kode'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            maxLength: 6,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Kode clan',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 4),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _joining ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed:
              (_controller.text.trim().isEmpty || _joining) ? null : _join,
          child: _joining
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Gabung'),
        ),
      ],
    );
  }
}

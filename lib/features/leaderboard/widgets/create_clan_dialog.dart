import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_profile.dart';

/// Dialog for creating a new clan. On success it swaps its own content to
/// a "here's your join code" view instead of closing immediately — sharing
/// that code with students is the entire point of creating one, so it
/// needs to stay on screen long enough to actually copy/read.
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                (user.displayName ?? 'Pelajar Kana'),
            photoUrl: user.photoURL,
            avatarType: profile?.avatarType ?? AvatarType.google,
            avatarValue: profile?.avatarValue,
          );
      if (!mounted) return;
      setState(() {
        _creating = false;
        _createdCode = code;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _creating = false;
        _error = 'Gagal membuat clan, coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = _createdCode;
    if (code != null) {
      return AlertDialog(
        title: const Text('Clan Dibuat!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bagikan kode ini ke murid supaya bisa bergabung:',
              style: TextStyle(color: AppColors.textNavy),
            ),
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.primaryCoral.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryCoral.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                code,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: AppColors.primaryCoral,
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
                const SnackBar(content: Text('Kode disalin.')),
              );
            },
            child: const Text('Salin Kode'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Selesai'),
          ),
        ],
      );
    }

    final name = _trimmedOrNull;
    return AlertDialog(
      title: const Text('Buat Clan'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            maxLength: 30,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Nama clan (mis. SMA 1 Kelas 9A)',
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
          onPressed: _creating ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: (name == null || _creating) ? null : _create,
          child: _creating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Buat'),
        ),
      ],
    );
  }
}

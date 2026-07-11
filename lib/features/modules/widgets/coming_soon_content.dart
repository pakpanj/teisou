import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/mascot_widget.dart';

/// Shared "this module isn't built yet" body, used both as a bottom sheet
/// (tapping a coming-soon card on [ModulesScreen]) and as the entire body
/// of each dedicated placeholder screen (kanji, particle, ...).
class ComingSoonContent extends ConsumerWidget {
  final String moduleId;
  final VoidCallback? onClose;

  const ComingSoonContent({super.key, required this.moduleId, this.onClose});

  Future<void> _remindMe(BuildContext context, WidgetRef ref) async {
    final uid = ref.read(appStartupProvider).valueOrNull?.uid;
    if (uid != null) {
      await ref.read(progressRepositoryProvider).recordModuleInterest(uid, moduleId);
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kami akan mengingatkanmu saat modul ini siap!')),
    );
    onClose?.call();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MascotWidget(mood: MascotMood.sleepy, size: 120),
          const SizedBox(height: 16),
          const Text(
            'Modul ini sedang dalam pengembangan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textNavy,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _remindMe(context, ref),
              child: const Text('Ingatkan Saya'),
            ),
          ),
          if (onClose != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onClose,
                child: const Text('Tutup'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shows [ComingSoonContent] as a rounded bottom sheet.
Future<void> showComingSoonSheet(BuildContext context, {required String moduleId}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => ComingSoonContent(
      moduleId: moduleId,
      onClose: () => Navigator.of(ctx).pop(),
    ),
  );
}

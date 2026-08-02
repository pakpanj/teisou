import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/covers.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_palette.dart';
import 'profile_header_illustration.dart';

/// Bottom sheet for picking the Profile header's cover illustration: the
/// default hand-drawn torii/Fuji/sakura scene, or one of [CoverPresets.all].
/// Mirrors AvatarPickerSheet's grid-of-tiles shape, minus the free/premium
/// split and gallery upload — covers are plain, ungated presets.
class CoverPickerSheet extends ConsumerStatefulWidget {
  const CoverPickerSheet({super.key});

  @override
  ConsumerState<CoverPickerSheet> createState() => _CoverPickerSheetState();
}

class _CoverPickerSheetState extends ConsumerState<CoverPickerSheet> {
  Future<void> _select(String uid, String? coverId) async {
    try {
      await ref.read(progressRepositoryProvider).updateCover(uid, coverId);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(appStringsProvider).coverSaveFailed)),
      );
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appStartupProvider).valueOrNull;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final uid = user?.uid;
    final selectedId = profile?.coverId;
    final s = ref.watch(appStringsProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.palette.background,
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
                    color: context.palette.textNavy.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                s.pickCoverTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.palette.textNavy,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: CoverPresets.all.length + 1,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                ),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _DefaultCoverTile(
                      selected: selectedId == null,
                      label: s.defaultLabel,
                      onTap: uid == null ? null : () => _select(uid, null),
                    );
                  }
                  final preset = CoverPresets.all[index - 1];
                  return _CoverTile(
                    preset: preset,
                    selected: selectedId == preset.id,
                    onTap: uid == null ? null : () => _select(uid, preset.id),
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

class _DefaultCoverTile extends StatelessWidget {
  final bool selected;
  final String label;
  final VoidCallback? onTap;

  const _DefaultCoverTile({
    required this.selected,
    required this.label,
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
              color: context.palette.hiraganaCardBg,
              borderRadius: BorderRadius.circular(16),
              border: selected
                  ? Border.all(color: context.palette.primaryCoral, width: 2)
                  : null,
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              child: ProfileHeaderIllustration(),
            ),
          ),
          if (selected)
            Positioned(
              right: 6,
              top: 6,
              child: Icon(Icons.check_circle, color: context.palette.primaryCoral, size: 20),
            ),
          Positioned(
            left: 8,
            bottom: 6,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: context.palette.textNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverTile extends StatelessWidget {
  final CoverPreset preset;
  final bool selected;
  final VoidCallback? onTap;

  const _CoverTile({required this.preset, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: selected
                      ? Border.all(color: context.palette.primaryCoral, width: 2)
                      : null,
                ),
                clipBehavior: Clip.antiAlias,
                child: CoverArt(
                  preset: preset,
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                ),
              ),
              if (selected)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Icon(Icons.check_circle, color: context.palette.primaryCoral, size: 20),
                ),
              Positioned(
                left: 8,
                bottom: 6,
                child: Text(
                  preset.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.palette.textNavy,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

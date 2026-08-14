import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/clan_icons.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/clan.dart';
import '../clan_providers.dart';

/// Leader-only: pick a clan icon preset and set a clan description. Only
/// ever reachable from a leader-gated button in `clan_tab.dart` (mirrors
/// `ClanMembersScreen`'s invite-button gating), and `firestore.rules`
/// enforces the same restriction server-side regardless — see
/// `ClanRepository.updateClanIcon`/`updateClanDescription`'s own doc
/// comments for exactly which rule covers this.
class ClanSettingsScreen extends ConsumerStatefulWidget {
  final String code;

  const ClanSettingsScreen({super.key, required this.code});

  @override
  ConsumerState<ClanSettingsScreen> createState() =>
      _ClanSettingsScreenState();
}

class _ClanSettingsScreenState extends ConsumerState<ClanSettingsScreen> {
  final _descriptionController = TextEditingController();
  String? _loadedForCode;
  bool _savingIcon = false;
  bool _savingDescription = false;
  bool _disbanding = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _syncDescriptionField(Clan clan) {
    // Only ever overwrite the field from server data once per clan load —
    // otherwise every rebuild while the learner is mid-edit would stomp
    // their unsaved keystrokes back to whatever's currently saved.
    if (_loadedForCode == clan.code) return;
    _loadedForCode = clan.code;
    _descriptionController.text = clan.description ?? '';
  }

  Future<void> _pickIcon(ClanIconPreset? preset) async {
    final s = ref.read(appStringsProvider);
    setState(() => _savingIcon = true);
    try {
      await ref
          .read(clanRepositoryProvider)
          .updateClanIcon(widget.code, preset?.id);
      ref.invalidate(clanDetailsProvider(widget.code));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.clanIconSaved)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.clanIconSaveFailed)));
    } finally {
      if (mounted) setState(() => _savingIcon = false);
    }
  }

  Future<void> _saveDescription() async {
    final s = ref.read(appStringsProvider);
    setState(() => _savingDescription = true);
    try {
      await ref
          .read(clanRepositoryProvider)
          .updateClanDescription(widget.code, _descriptionController.text);
      ref.invalidate(clanDetailsProvider(widget.code));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.clanDescriptionSaved)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.clanDescriptionSaveFailed)));
    } finally {
      if (mounted) setState(() => _savingDescription = false);
    }
  }

  /// Asks first, then disbands. The confirmation names the clan and the
  /// number of people it is about to remove, because "Bubarkan Clan"
  /// alone does not convey that it reaches other accounts too.
  Future<void> _disband(Clan clan) async {
    final s = ref.read(appStringsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.clanDisbandConfirmTitle(clan.name)),
        content: Text(s.clanDisbandConfirmBody(clan.memberCount)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.palette.errorRed,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(s.clanDisbandConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final uid = ref.read(appStartupProvider).valueOrNull?.uid;
    if (uid == null) return;

    setState(() => _disbanding = true);
    try {
      await ref
          .read(clanRepositoryProvider)
          .disbandClan(code: widget.code, hostUid: uid);
      ref.invalidate(clanDetailsProvider(widget.code));
      if (!mounted) return;
      // Straight out of the settings screen: staying would leave the
      // learner looking at the settings of a clan that no longer exists.
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.clanDisbanded)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _disbanding = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.clanDisbandFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final clanAsync = ref.watch(clanDetailsProvider(widget.code));

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: Text(s.clanSettings)),
      body: clanAsync.when(
        data: (clan) {
          if (clan == null) return const SizedBox.shrink();
          _syncDescriptionField(clan);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                s.clanIconSectionTitle,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: context.palette.textNavy,
                ),
              ),
              const SizedBox(height: 12),
              Opacity(
                opacity: _savingIcon ? 0.5 : 1,
                child: IgnorePointer(
                  ignoring: _savingIcon,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: ClanIconPresets.all.length + 1,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _IconTile(
                          selected: clan.iconValue == null,
                          onTap: () => _pickIcon(null),
                          child: const Icon(Icons.groups, color: Colors.white),
                        );
                      }
                      final preset = ClanIconPresets.all[index - 1];
                      return _IconTile(
                        selected: clan.iconValue == preset.id,
                        onTap: () => _pickIcon(preset),
                        child: ClanIconArt(
                          preset: preset,
                          size: 32,
                          emojiFontSize: 24,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                s.clanDescriptionSectionTitle,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: context.palette.textNavy,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                maxLength: 300,
                decoration: InputDecoration(
                  hintText: s.clanDescriptionHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _savingDescription ? null : _saveDescription,
                  child: Text(s.saveButton),
                ),
              ),
              const SizedBox(height: 36),
              Text(
                s.clanDisbandSectionTitle,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: context.palette.errorRed,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s.clanDisbandExplanation,
                style: TextStyle(
                  fontSize: 13,
                  color: context.palette.textNavy.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _disbanding ? null : () => _disband(clan),
                  icon: Icon(
                    Icons.group_off,
                    color: context.palette.errorRed,
                  ),
                  label: Text(
                    s.clanDisbandButton,
                    style: TextStyle(color: context.palette.errorRed),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.palette.errorRed),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const SizedBox.shrink(),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  final bool selected;
  final Widget child;
  final VoidCallback onTap;

  const _IconTile({
    required this.selected,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: context.palette.primaryCoral.withValues(
            alpha: selected ? 0.9 : 0.35,
          ),
          borderRadius: BorderRadius.circular(16),
          border: selected
              ? Border.all(color: context.palette.primaryCoral, width: 2)
              : null,
        ),
        child: Center(child: child),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/module_info.dart';
import '../../bunpou/bunpou_home_screen.dart';
import '../../kaiwa/kaiwa_home_screen.dart';
import '../../kanji/kanji_home_screen.dart';
import '../../kotoba/kotoba_home_screen.dart';
import '../../modules/widgets/coming_soon_content.dart';
import '../../particle/particle_home_screen.dart';

/// The rest of the learning modules (beyond the Hiragana/Katakana/Ujian
/// shortcuts already on the Home tab's header) — formerly the standalone
/// "Belajar" tab's [ModulesScreen], folded into Home so the bottom nav
/// only needs Home/Ujian/Profil. Not a [Scaffold]/[AppBar] — this is meant
/// to be embedded inside Home's own scroll body.
class ModulesSection extends ConsumerWidget {
  const ModulesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(s.otherModules),
        const SizedBox(height: 12),
        _LockedModuleCard(
          emoji: '📷',
          title: s.camDetectorTitle,
          subtitle: s.camDetectorSubtitle,
          reason: s.camDetectorReason,
          fixingBadge: s.fixingBadge,
        ),
        const SizedBox(height: 12),
        _AvailableModuleCard(
          emoji: '📚',
          backgroundColor: AppColors.katakanaCardBg,
          iconColor: AppColors.secondaryBlue,
          title: s.kotobaTitle,
          subtitle: s.kotobaSubtitle,
          onTap: () => AppNavigator.slideFromRight(
            context,
            const KotobaHomeScreen(),
          ),
        ),
        const SizedBox(height: 12),
        _AvailableModuleCard(
          emoji: '字',
          backgroundColor: AppColors.tertiaryAmberCardBg,
          iconColor: AppColors.tertiaryAmber,
          title: s.kanjiTitle,
          subtitle: s.kanjiSubtitle,
          onTap: () => AppNavigator.slideFromRight(
            context,
            const KanjiHomeScreen(),
          ),
        ),
        const SizedBox(height: 12),
        _AvailableModuleCard(
          emoji: '文',
          backgroundColor: AppColors.hiraganaCardBg,
          iconColor: AppColors.primaryCoral,
          title: s.bunpouTitle,
          subtitle: s.bunpouSubtitle,
          onTap: () => AppNavigator.slideFromRight(
            context,
            const BunpouHomeScreen(),
          ),
        ),
        const SizedBox(height: 12),
        // Premium gate temporarily removed for dev testing (2026-07-17) —
        // see memory/project_monetization_roadmap.md. Restore
        // _PremiumModuleCard + PaywallScreen branch before release.
        _AvailableModuleCard(
          emoji: 'を',
          backgroundColor: AppColors.tertiaryAmberCardBg,
          iconColor: AppColors.tertiaryAmber,
          title: s.particleTitle,
          subtitle: s.particleSubtitle,
          onTap: () => AppNavigator.slideFromRight(context, const ParticleHomeScreen()),
        ),
        const SizedBox(height: 12),
        _AvailableModuleCard(
          emoji: '💬',
          backgroundColor: AppColors.hiraganaCardBg,
          iconColor: AppColors.primaryCoral,
          title: s.kaiwaTitle,
          subtitle: s.kaiwaSubtitle,
          onTap: () => AppNavigator.slideFromRight(context, const KaiwaHomeScreen()),
        ),
        const SizedBox(height: 28),
        _SectionHeader(s.comingSoonHeader),
        const SizedBox(height: 12),
        ...kComingSoonModules.map(
          (module) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ComingSoonCard(module: module, strings: s),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textNavy,
      ),
    );
  }
}

class _AvailableModuleCard extends StatelessWidget {
  final String emoji;
  final Color backgroundColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AvailableModuleCard({
    required this.emoji,
    required this.backgroundColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  emoji,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textNavy.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: iconColor),
            ],
          ),
        ),
      ),
    );
  }
}

/// A module that already has real code/screens behind it, but is
/// deliberately kept unreachable from navigation because of known bugs —
/// distinct from [_ComingSoonCard] (which is for modules that don't exist
/// yet). Tapping shows why, via a [SnackBar], instead of the "under
/// development / remind me / premium" [ComingSoonContent] sheet, since that
/// messaging would be misleading for a feature that already exists.
class _LockedModuleCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String reason;
  final String fixingBadge;

  const _LockedModuleCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.reason,
    required this.fixingBadge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(reason)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.freeBadgeGrey.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textNavy,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.freeBadgeGrey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            fixingBadge,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.freeBadgeGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textNavy.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.lock, color: AppColors.freeBadgeGrey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  final ModuleInfo module;
  final AppStrings strings;

  const _ComingSoonCard({required this.module, required this.strings});

  static const _icons = {
    'picture_learning': '🖼️',
    'video_learning': '🎬',
  };

  /// [ModuleInfo.title]/[description] are the dataset's Indonesian-authored
  /// identity strings (see `module_info.dart`) — resolve the localized
  /// display text by id instead of touching the model itself.
  (String, String) _displayText() {
    switch (module.id) {
      case 'picture_learning':
        return (strings.pictureLearningTitle, strings.pictureLearningSubtitle);
      case 'video_learning':
        return (strings.videoLearningTitle, strings.videoLearningSubtitle);
      default:
        return (module.title, module.description);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (title, description) = _displayText();
    return Material(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => showComingSoonSheet(context, moduleId: module.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.freeBadgeGrey.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _icons[module.id] ?? '❓',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textNavy,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.freeBadgeGrey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            strings.comingSoonBadge,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.freeBadgeGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textNavy.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (module.requiresPremium) ...[
                const SizedBox(width: 8),
                const Icon(Icons.lock, color: AppColors.freeBadgeGrey, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

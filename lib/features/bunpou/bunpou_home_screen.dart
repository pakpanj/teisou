import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/navigation/app_navigator.dart';
import '../paywall/paywall_screen.dart';
import '../paywall/module_access.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_refresh_indicator.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../core/widgets/module_level_card.dart';
import '../../core/widgets/module_skyline_banner.dart';
import '../../core/widgets/module_title_plaque.dart';
import '../../data/models/bunpou_level.dart';
import '../../data/models/jlpt_level.dart';
import 'bunpou_level_screen.dart';
import 'bunpou_providers.dart';
import '../../core/widgets/app_loading.dart';

/// Entry point for the Bunpou module: JLPT level picker (N5-N1). Only
/// levels with a real dataset are tappable; the rest show a "Segera"
/// badge, same convention as [KanjiHomeScreen]'s level picker.
class BunpouHomeScreen extends ConsumerWidget {
  const BunpouHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelsAsync = ref.watch(bunpouLevelsProvider);
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      backgroundColor: context.palette.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: context.palette.textNavy,
        title: const ModuleTitlePlaque(title: 'Bunpou'),
      ),
      body: levelsAsync.when(
        data: (levels) => Column(
          children: [
            Expanded(
              child: AppRefreshIndicator(
                onRefresh: () => ref.refresh(bunpouLevelsProvider.future),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    const ModuleSkylineBanner(),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          for (final level in levels) ...[
                            _LevelCard(level: level),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const FreeTierBannerAd(),
          ],
        ),
        loading: () => const AppLoading(),
        error: (e, _) => Center(child: Text(s.failedToLoadLevels(e))),
      ),
    );
  }
}

class _LevelCard extends ConsumerWidget {
  final BunpouLevel level;

  const _LevelCard({required this.level});

  void _open(BuildContext context, AppStrings s, bool premiumOk) {
    if (!premiumOk) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PaywallScreen(
            moduleId: PremiumModules.bunpou,
            moduleTitle: s.bunpouLevelTitle(level.name),
          ),
        ),
      );
      return;
    }
    if (!level.available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.bunpouLevelComingSoon(level.name))),
      );
      return;
    }
    AppNavigator.slideFromRight(
      context,
      BunpouLevelScreen(
        jlptLevel: JlptLevelX.fromKey(level.id),
        levelName: level.name,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // N5 alone is free — 89 patterns, a substantial module on its own —
    // and N4 upward is what is sold. `false` while the answer loads: a
    // card that is briefly open and then locks under a finger is worse
    // than one that resolves the other way.
    final free = isFreeLevel(
      JlptLevelX.fromKey(level.id),
      freeThrough: kBunpouFreeThrough,
    );
    final premiumOk = free ||
        (ref.watch(moduleAccessProvider(PremiumModules.bunpou)).valueOrNull ??
            false);
    final available = level.available && premiumOk;
    final progress = available
        ? ref
              .watch(bunpouLevelProgressProvider(JlptLevelX.fromKey(level.id)))
              .valueOrNull
        : null;
    final s = ref.watch(appStringsProvider);
    final total = progress?.$2 ?? level.bunpouCount ?? 0;
    final learned = progress?.$1 ?? 0;
    final percent = total > 0 ? ((learned / total) * 100).round() : 0;

    return ModuleLevelCard(
      badgeLabel: level.name,
      title: s.bunpouLevelTitle(level.name),
      subtitle: s.bunpouPatternCount(level.bunpouCount ?? 0),
      percent: available ? percent : null,
      available: available,
      soonLabel: premiumOk ? s.soonBadge : s.premiumBadge,
      accent: context.palette.primaryCoral,
      onTap: () => _open(context, s, premiumOk),
    );
  }
}

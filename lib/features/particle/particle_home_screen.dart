import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_refresh_indicator.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../core/widgets/module_level_card.dart';
import '../../core/widgets/module_skyline_banner.dart';
import '../../core/widgets/module_title_plaque.dart';
import '../../data/models/particle_category_info.dart';
import 'particle_category_screen.dart';
import 'particle_providers.dart';
import '../../core/widgets/app_loading.dart';

/// Entry point for the Partikel module: category picker (Kasus /
/// Keterangan / Akhir Kalimat). Only categories with a real dataset are
/// tappable; the rest show a "Segera" badge, same convention as
/// [BunpouHomeScreen]'s level picker.
class ParticleHomeScreen extends ConsumerWidget {
  const ParticleHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(particleCategoriesProvider);
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      backgroundColor: context.palette.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: context.palette.textNavy,
        title: ModuleTitlePlaque(title: s.particleTitle),
      ),
      body: categoriesAsync.when(
        data: (categories) => Column(
          children: [
            Expanded(
              child: AppRefreshIndicator(
                onRefresh: () =>
                    ref.refresh(particleCategoriesProvider.future),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    const ModuleSkylineBanner(),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          for (final category in categories) ...[
                            _CategoryCard(category: category),
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
        error: (e, _) => Center(child: Text(s.failedToLoadCategories(e))),
      ),
    );
  }
}

class _CategoryCard extends ConsumerWidget {
  final ParticleCategoryInfo category;

  const _CategoryCard({required this.category});

  void _open(BuildContext context, AppStrings s) {
    if (!category.available) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.categoryComingSoon(category.localizedName(s.language)))));
      return;
    }
    AppNavigator.slideFromRight(
      context,
      ParticleCategoryScreen(
        category: category.id,
        categoryName: category.localizedName(s.language),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = category.available;
    final progress = available
        ? ref.watch(particleCategoryProgressProvider(category.id)).valueOrNull
        : null;
    final s = ref.watch(appStringsProvider);
    final total = progress?.$2 ?? category.particleCount ?? 0;
    final learned = progress?.$1 ?? 0;
    final percent = total > 0 ? ((learned / total) * 100).round() : 0;

    return ModuleLevelCard(
      badgeLabel: category.icon,
      title: category.localizedName(s.language),
      subtitle: s.particleCount(category.particleCount ?? 0),
      percent: available ? percent : null,
      available: available,
      soonLabel: s.soonBadge,
      accent: context.palette.primaryCoral,
      onTap: () => _open(context, s),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_refresh_indicator.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../data/models/particle_category_info.dart';
import 'particle_category_screen.dart';
import 'particle_providers.dart';

/// Entry point for the Partikel module: category picker (Kasus /
/// Keterangan / Akhir Kalimat). Only categories with a real dataset are
/// tappable; the rest show a "Segera" badge, same convention as
/// [BunpouHomeScreen]'s level picker.
class ParticleHomeScreen extends ConsumerWidget {
  const ParticleHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(particleCategoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Partikel')),
      body: categoriesAsync.when(
        data: (categories) => Column(
          children: [
            Expanded(
              child: AppRefreshIndicator(
                onRefresh: () =>
                    ref.refresh(particleCategoriesProvider.future),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: [
                    for (final category in categories) ...[
                      _CategoryCard(category: category),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
            const FreeTierBannerAd(),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat kategori: $e')),
      ),
    );
  }
}

class _CategoryCard extends ConsumerWidget {
  final ParticleCategoryInfo category;

  const _CategoryCard({required this.category});

  void _open(BuildContext context) {
    if (!category.available) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${category.name} segera hadir!')));
      return;
    }
    AppNavigator.slideFromRight(
      context,
      ParticleCategoryScreen(
        category: category.id,
        categoryName: category.name,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = category.available;
    final progress = available
        ? ref.watch(particleCategoryProgressProvider(category.id)).valueOrNull
        : null;

    return Material(
      color: available ? AppColors.cardWhite : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color:
                      (available
                              ? AppColors.primaryCoral
                              : AppColors.freeBadgeGrey)
                          .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  category.icon,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: available
                            ? AppColors.textNavy
                            : AppColors.freeBadgeGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (available)
                      Text(
                        progress != null && progress.$1 > 0
                            ? '${progress.$1}/${progress.$2} dipelajari'
                            : '${category.particleCount ?? 0} partikel',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textNavy.withValues(alpha: 0.6),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.freeBadgeGrey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Segera',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.freeBadgeGrey,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: available
                    ? AppColors.primaryCoral
                    : AppColors.freeBadgeGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

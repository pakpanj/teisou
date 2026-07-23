import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_refresh_indicator.dart';
import '../../data/models/jlpt_level.dart';
import '../../data/models/kaiwa_category_info.dart';
import 'kaiwa_category_screen.dart';
import 'kaiwa_providers.dart';

/// Theme picker for one Kaiwa JLPT level (Perkenalan / Di Restoran / ...).
/// Only themes with a real dataset are tappable; the rest show a "Segera"
/// badge, same convention as `ParticleHomeScreen`'s category picker — this
/// screen is what `KaiwaHomeScreen` used to be before the level layer was
/// added on top.
class KaiwaLevelScreen extends ConsumerWidget {
  final JlptLevel level;
  final String levelName;

  const KaiwaLevelScreen({
    super.key,
    required this.level,
    required this.levelName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(kaiwaCategoriesByLevelProvider(level));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Kaiwa $levelName')),
      body: categoriesAsync.when(
        data: (categories) => AppRefreshIndicator(
          onRefresh: () =>
              ref.refresh(kaiwaCategoriesByLevelProvider(level).future),
          child: categories.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    Padding(
                      padding: EdgeInsets.only(top: 120, left: 32, right: 32),
                      child: Center(
                        child: Text(
                          'Tema untuk level ini belum tersedia.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textNavy),
                        ),
                      ),
                    ),
                  ],
                )
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: [
                    for (final category in categories) ...[
                      _ThemeCard(category: category),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat tema: $e')),
      ),
    );
  }
}

class _ThemeCard extends ConsumerWidget {
  final KaiwaCategoryInfo category;

  const _ThemeCard({required this.category});

  void _open(BuildContext context) {
    if (!category.available) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${category.name} segera hadir!')));
      return;
    }
    AppNavigator.slideFromRight(
      context,
      KaiwaCategoryScreen(category: category.id, categoryName: category.name),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = category.available;
    final progress = available
        ? ref.watch(kaiwaCategoryProgressProvider(category.id)).valueOrNull
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
                            : '${category.dialogueCount ?? 0} dialog',
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

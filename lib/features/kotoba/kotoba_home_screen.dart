import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/localization/kotoba_category_i18n.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_refresh_indicator.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../data/models/kotoba_category.dart';
import 'kotoba_category_screen.dart';
import 'kotoba_providers.dart';

/// Entry point for the Kotoba (vocabulary) module: all 45 planned
/// categories grouped by theme, grid-style. Only categories with a real
/// dataset are tappable; the rest show a "Segera" badge and are disabled.
class KotobaHomeScreen extends ConsumerWidget {
  const KotobaHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(kotobaCategoryGroupsProvider);
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: Text(s.kotobaTitle)),
      body: groupsAsync.when(
        data: (groups) => Column(
          children: [
            Expanded(
              child: AppRefreshIndicator(
                onRefresh: () =>
                    ref.refresh(kotobaCategoryGroupsProvider.future),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: [
                    for (final entry in groups.entries) ...[
                      _GroupHeader(
                        title: KotobaCategoryI18n.group(entry.key, s.language),
                      ),
                      const SizedBox(height: 12),
                      _CategoryGrid(categories: entry.value),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
            const FreeTierBannerAd(),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(s.failedToLoadCategories(e))),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String title;

  const _GroupHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: context.palette.textNavy,
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final List<KotobaCategory> categories;

  const _CategoryGrid({required this.categories});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.4,
      ),
      itemBuilder: (context, index) =>
          _CategoryCard(category: categories[index]),
    );
  }
}

class _CategoryCard extends ConsumerWidget {
  final KotobaCategory category;

  const _CategoryCard({required this.category});

  void _openCategory(BuildContext context, AppStrings s) {
    if (!category.available) {
      final localizedName = KotobaCategoryI18n.name(category.name, s.language);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.categoryComingSoon(localizedName))));
      return;
    }
    AppNavigator.slideFromRight(
      context,
      KotobaCategoryScreen(category: category),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = category.available;
    final progress = available
        ? ref.watch(kotobaCategoryProgressProvider(category.id)).valueOrNull
        : null;
    final s = ref.watch(appStringsProvider);
    return Material(
      color: available ? context.palette.cardWhite : context.palette.mutedSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openCategory(context, s),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      (available
                              ? context.palette.primaryCoral
                              : context.palette.freeBadgeGrey)
                          .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  category.icon,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      KotobaCategoryI18n.name(category.name, s.language),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: available
                            ? context.palette.textNavy
                            : context.palette.freeBadgeGrey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (available)
                      Text(
                        progress != null && progress.$1 > 0
                            ? s.progressLearned(progress.$1, progress.$2)
                            : s.wordCount(category.wordCount ?? 0),
                        style: TextStyle(
                          fontSize: 11,
                          color: context.palette.textNavy.withValues(alpha: 0.6),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: context.palette.freeBadgeGrey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          s.soonBadge,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: context.palette.freeBadgeGrey,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

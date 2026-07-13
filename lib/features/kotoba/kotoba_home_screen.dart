import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/theme/app_colors.dart';
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Kosakata')),
      body: groupsAsync.when(
        data: (groups) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            for (final entry in groups.entries) ...[
              _GroupHeader(title: entry.key),
              const SizedBox(height: 12),
              _CategoryGrid(categories: entry.value),
              const SizedBox(height: 24),
            ],
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat kategori: $e')),
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
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textNavy,
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
      itemBuilder: (context, index) => _CategoryCard(category: categories[index]),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final KotobaCategory category;

  const _CategoryCard({required this.category});

  void _openCategory(BuildContext context) {
    if (!category.available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${category.name} segera hadir!')),
      );
      return;
    }
    AppNavigator.slideFromRight(context, KotobaCategoryScreen(category: category));
  }

  @override
  Widget build(BuildContext context) {
    final available = category.available;
    return Material(
      color: available ? AppColors.cardWhite : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openCategory(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (available ? AppColors.primaryCoral : AppColors.freeBadgeGrey)
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(category.icon, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: available ? AppColors.textNavy : AppColors.freeBadgeGrey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (available)
                      Text(
                        '${category.wordCount ?? 0} kata',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textNavy.withValues(alpha: 0.6),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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
            ],
          ),
        ),
      ),
    );
  }
}

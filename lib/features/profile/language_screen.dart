import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/app_language.dart';

/// Picker for the app's UI-chrome language (Bahasa Indonesia / English).
/// Selecting a tile updates [languageProvider] immediately (every screen
/// watching [appStringsProvider] rebuilds right away) and persists the
/// choice via [LanguageRepository] so it survives app restarts.
class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  Future<void> _select(WidgetRef ref, AppLanguage language) async {
    ref.read(languageProvider.notifier).state = language;
    await ref.read(languageRepositoryProvider).setLanguage(language);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final current = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(s.appLanguage)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            s.chooseAppLanguage,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textNavy,
            ),
          ),
          const SizedBox(height: 12),
          for (final language in AppLanguage.values) ...[
            _LanguageTile(
              language: language,
              selected: current == language,
              onTap: () => _select(ref, language),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 8),
          Text(
            s.languageScopeNote,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textNavy.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: selected
                ? Border.all(color: AppColors.primaryCoral, width: 2)
                : null,
          ),
          child: Row(
            children: [
              Text(language.flagEmoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  language.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textNavy,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: AppColors.primaryCoral)
              else
                Icon(
                  Icons.circle_outlined,
                  color: AppColors.textNavy.withValues(alpha: 0.3),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

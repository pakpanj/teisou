import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../data/models/app_theme_mode.dart';

/// Picker for the app's colour mode (light / dark / follow system).
/// Mirrors [LanguageScreen]: selecting a tile updates [themeModeProvider]
/// immediately — `MaterialApp` watches it, so the repaint is instant — and
/// persists the choice via [ThemeRepository] so it survives a restart.
///
/// This screen reads its own colours from `context.palette` rather than
/// [AppColors], which is what lets it actually look dark once dark is
/// picked. Screens still on the constants stay light until migrated; see
/// [AppPalette].
class ThemeScreen extends ConsumerWidget {
  const ThemeScreen({super.key});

  Future<void> _select(WidgetRef ref, AppThemeMode mode) async {
    ref.read(themeModeProvider.notifier).state = mode;
    await ref.read(themeRepositoryProvider).setThemeMode(mode);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final palette = context.palette;
    final current = ref.watch(themeModeProvider);

    String labelFor(AppThemeMode mode) {
      switch (mode) {
        case AppThemeMode.light:
          return s.themeLight;
        case AppThemeMode.dark:
          return s.themeDark;
        case AppThemeMode.system:
          return s.themeSystem;
      }
    }

    String descFor(AppThemeMode mode) {
      switch (mode) {
        case AppThemeMode.light:
          return s.themeLightDesc;
        case AppThemeMode.dark:
          return s.themeDarkDesc;
        case AppThemeMode.system:
          return s.themeSystemDesc;
      }
    }

    IconData iconFor(AppThemeMode mode) {
      switch (mode) {
        case AppThemeMode.light:
          return Icons.light_mode;
        case AppThemeMode.dark:
          return Icons.dark_mode;
        case AppThemeMode.system:
          return Icons.brightness_auto;
      }
    }

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: Text(s.appTheme)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            s.chooseAppTheme,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: palette.textNavy,
            ),
          ),
          const SizedBox(height: 12),
          for (final mode in AppThemeMode.values) ...[
            _ThemeTile(
              icon: iconFor(mode),
              label: labelFor(mode),
              description: descFor(mode),
              selected: current == mode,
              onTap: () => _select(ref, mode),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 8),
          Text(
            s.themeScopeNote,
            style: TextStyle(
              fontSize: 12,
              color: palette.textNavy.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.cardWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: selected
                ? Border.all(color: palette.primaryCoral, width: 2)
                : null,
          ),
          child: Row(
            children: [
              Icon(icon, size: 24, color: palette.primaryCoral),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: palette.textNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.textNavy.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (selected)
                Icon(Icons.check_circle, color: palette.primaryCoral)
              else
                Icon(
                  Icons.circle_outlined,
                  color: palette.textNavy.withValues(alpha: 0.3),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// The app's colour mode — light (the original and default look), dark, or
/// follow whatever the OS is set to. Mirrors [AppLanguage]'s shape: a small
/// enum with a stable string key for persistence, so the stored value never
/// depends on enum declaration order.
enum AppThemeMode { light, dark, system }

extension AppThemeModeX on AppThemeMode {
  String get key {
    switch (this) {
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.dark:
        return 'dark';
      case AppThemeMode.system:
        return 'system';
    }
  }

  /// What `MaterialApp.themeMode` needs. The two are deliberately kept as
  /// separate types: this one is persisted and shown in the picker, and
  /// shouldn't be tied to a Flutter enum that could gain values.
  ThemeMode get material {
    switch (this) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  /// Defaults to [AppThemeMode.light] for anything unrecognised, including
  /// null — a fresh install has no stored value and must boot into the look
  /// the app has always had, not into whatever the OS happens to be set to.
  static AppThemeMode fromKey(String? key) {
    switch (key) {
      case 'dark':
        return AppThemeMode.dark;
      case 'system':
        return AppThemeMode.system;
      case 'light':
      default:
        return AppThemeMode.light;
    }
  }
}

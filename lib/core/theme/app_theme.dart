import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Both themes are built by the same function from an [AppPalette], so the
/// light and dark variants can't drift apart — adding a widget theme here
/// covers both at once. Each theme also carries its palette as a
/// [ThemeExtension], which is how screens read colours that respond to the
/// mode; see [AppPalette] for why call sites migrate gradually.
class AppTheme {
  AppTheme._();

  static ThemeData get light =>
      _build(AppPalette.light, Brightness.light);

  static ThemeData get dark => _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette palette, Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: palette.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.primaryCoral,
        brightness: brightness,
        primary: palette.primaryCoral,
        secondary: palette.secondaryBlue,
        tertiary: palette.tertiaryAmber,
        error: palette.errorRed,
        surface: palette.cardWhite,
      ),
    );

    return base.copyWith(
      extensions: [palette],
      textTheme: base.textTheme.apply(
        bodyColor: palette.textNavy,
        displayColor: palette.textNavy,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.textNavy,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: palette.textNavy,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      // Kept white in both modes on purpose: the coral stays saturated
      // enough in dark that white label text is still the readable choice,
      // and flipping it to the dark background colour would wash out.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primaryCoral,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.primaryCoral,
          side: BorderSide(color: palette.primaryCoral, width: 1.5),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.cardWhite,
        elevation: 2,
        shadowColor: brightness == Brightness.dark
            ? Colors.black45
            : Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}

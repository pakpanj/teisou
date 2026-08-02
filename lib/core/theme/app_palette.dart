import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The app's colour tokens, resolved per theme rather than baked in as
/// constants — this is what makes dark mode possible.
///
/// [AppColors] still exists and still holds the light values. It is a class
/// of `static const`s referenced ~737 times across ~68 files, and a `const`
/// cannot change at runtime, so those call sites are frozen in light mode
/// by construction. Rather than rewrite all of them in one pass, screens
/// are migrated a batch at a time: swap `AppColors.textNavy` for
/// `context.palette.textNavy` and that screen starts responding to the
/// theme. Anything not migrated yet keeps working, just always light.
///
/// **Token names describe a role, not a literal colour.** [textNavy] is the
/// primary text colour and is a pale off-white in dark mode; [cardWhite] is
/// the raised-surface colour and is dark grey there. The names are kept as
/// they are so migrating a call site is a mechanical prefix change instead
/// of a rename touching hundreds of lines. Read them as "primary text" and
/// "card surface".
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color background;
  final Color primaryCoral;
  final Color secondaryBlue;
  final Color tertiaryAmber;
  final Color tertiaryAmberCardBg;
  final Color textNavy;
  final Color successGreen;
  final Color errorRed;
  final Color cardWhite;
  final Color hiraganaCardBg;
  final Color katakanaCardBg;
  final Color premiumGoldStart;
  final Color premiumGoldEnd;
  final Color freeBadgeGrey;

  /// Laid over the profile header's cover art so the avatar, name and motto
  /// stay legible on top of any of the 19 covers. White at 62% in light
  /// mode; in dark mode it has to be a dark wash instead, or a light cover
  /// would stay bright and swallow the (now pale) text.
  final Color headerScrim;

  /// Hairline dividers and card outlines. Previously written inline as
  /// `textNavy.withValues(alpha: ...)` at each call site, which produces a
  /// near-black line on a dark surface — hence its own token.
  final Color divider;

  /// A recessed surface, one step back from [cardWhite] — the locked and
  /// "coming soon" module cards, which read as unavailable rather than
  /// tappable. Was `Colors.grey.shade100` inline, which is a bright panel
  /// on a dark background.
  final Color mutedSurface;

  const AppPalette({
    required this.background,
    required this.primaryCoral,
    required this.secondaryBlue,
    required this.tertiaryAmber,
    required this.tertiaryAmberCardBg,
    required this.textNavy,
    required this.successGreen,
    required this.errorRed,
    required this.cardWhite,
    required this.hiraganaCardBg,
    required this.katakanaCardBg,
    required this.premiumGoldStart,
    required this.premiumGoldEnd,
    required this.freeBadgeGrey,
    required this.headerScrim,
    required this.divider,
    required this.mutedSurface,
  });

  /// Exactly the values [AppColors] has always held, so a migrated screen
  /// looks identical to an unmigrated one while the theme is light.
  static const light = AppPalette(
    background: AppColors.background,
    primaryCoral: AppColors.primaryCoral,
    secondaryBlue: AppColors.secondaryBlue,
    tertiaryAmber: AppColors.tertiaryAmber,
    tertiaryAmberCardBg: AppColors.tertiaryAmberCardBg,
    textNavy: AppColors.textNavy,
    successGreen: AppColors.successGreen,
    errorRed: AppColors.errorRed,
    cardWhite: AppColors.cardWhite,
    hiraganaCardBg: AppColors.hiraganaCardBg,
    katakanaCardBg: AppColors.katakanaCardBg,
    premiumGoldStart: AppColors.premiumGoldStart,
    premiumGoldEnd: AppColors.premiumGoldEnd,
    freeBadgeGrey: AppColors.freeBadgeGrey,
    headerScrim: Color(0x9EFFFFFF), // white @ 62%
    divider: Color(0x141E2A47), // textNavy @ 8%
    mutedSurface: Color(0xFFF5F5F5),
  );

  /// Built around the app's existing navy rather than neutral grey, so dark
  /// mode reads as the same product. Accents are lifted a few steps from
  /// their light values: the light coral/blue/amber are tuned for contrast
  /// against white and go muddy on a dark surface.
  static const dark = AppPalette(
    background: Color(0xFF121620),
    primaryCoral: Color(0xFFFF8296),
    secondaryBlue: Color(0xFF6BA9F7),
    tertiaryAmber: Color(0xFFF0C766),
    tertiaryAmberCardBg: Color(0xFF332C1B),
    textNavy: Color(0xFFE8EAF0),
    successGreen: Color(0xFF5FC486),
    errorRed: Color(0xFFFF6B70),
    cardWhite: Color(0xFF1C2130),
    hiraganaCardBg: Color(0xFF34232B),
    katakanaCardBg: Color(0xFF1F2838),
    premiumGoldStart: Color(0xFFF6D365),
    premiumGoldEnd: Color(0xFFC9A227),
    freeBadgeGrey: Color(0xFF8A93A1),
    headerScrim: Color(0xB3121620), // background @ 70%
    divider: Color(0x1FE8EAF0), // textNavy @ 12%
    mutedSurface: Color(0xFF181C27),
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? primaryCoral,
    Color? secondaryBlue,
    Color? tertiaryAmber,
    Color? tertiaryAmberCardBg,
    Color? textNavy,
    Color? successGreen,
    Color? errorRed,
    Color? cardWhite,
    Color? hiraganaCardBg,
    Color? katakanaCardBg,
    Color? premiumGoldStart,
    Color? premiumGoldEnd,
    Color? freeBadgeGrey,
    Color? headerScrim,
    Color? divider,
    Color? mutedSurface,
  }) {
    return AppPalette(
      background: background ?? this.background,
      primaryCoral: primaryCoral ?? this.primaryCoral,
      secondaryBlue: secondaryBlue ?? this.secondaryBlue,
      tertiaryAmber: tertiaryAmber ?? this.tertiaryAmber,
      tertiaryAmberCardBg: tertiaryAmberCardBg ?? this.tertiaryAmberCardBg,
      textNavy: textNavy ?? this.textNavy,
      successGreen: successGreen ?? this.successGreen,
      errorRed: errorRed ?? this.errorRed,
      cardWhite: cardWhite ?? this.cardWhite,
      hiraganaCardBg: hiraganaCardBg ?? this.hiraganaCardBg,
      katakanaCardBg: katakanaCardBg ?? this.katakanaCardBg,
      premiumGoldStart: premiumGoldStart ?? this.premiumGoldStart,
      premiumGoldEnd: premiumGoldEnd ?? this.premiumGoldEnd,
      freeBadgeGrey: freeBadgeGrey ?? this.freeBadgeGrey,
      headerScrim: headerScrim ?? this.headerScrim,
      divider: divider ?? this.divider,
      mutedSurface: mutedSurface ?? this.mutedSurface,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      primaryCoral: Color.lerp(primaryCoral, other.primaryCoral, t)!,
      secondaryBlue: Color.lerp(secondaryBlue, other.secondaryBlue, t)!,
      tertiaryAmber: Color.lerp(tertiaryAmber, other.tertiaryAmber, t)!,
      tertiaryAmberCardBg:
          Color.lerp(tertiaryAmberCardBg, other.tertiaryAmberCardBg, t)!,
      textNavy: Color.lerp(textNavy, other.textNavy, t)!,
      successGreen: Color.lerp(successGreen, other.successGreen, t)!,
      errorRed: Color.lerp(errorRed, other.errorRed, t)!,
      cardWhite: Color.lerp(cardWhite, other.cardWhite, t)!,
      hiraganaCardBg: Color.lerp(hiraganaCardBg, other.hiraganaCardBg, t)!,
      katakanaCardBg: Color.lerp(katakanaCardBg, other.katakanaCardBg, t)!,
      premiumGoldStart:
          Color.lerp(premiumGoldStart, other.premiumGoldStart, t)!,
      premiumGoldEnd: Color.lerp(premiumGoldEnd, other.premiumGoldEnd, t)!,
      freeBadgeGrey: Color.lerp(freeBadgeGrey, other.freeBadgeGrey, t)!,
      headerScrim: Color.lerp(headerScrim, other.headerScrim, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      mutedSurface: Color.lerp(mutedSurface, other.mutedSurface, t)!,
    );
  }
}

extension AppPaletteX on BuildContext {
  /// The palette for the current theme. Falls back to [AppPalette.light]
  /// rather than throwing if the extension is somehow absent — a widget
  /// built under a bare `ThemeData()` (some tests, some previews) should
  /// render in the original colours, not crash on a null assertion.
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/localization/kotoba_category_i18n.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_refresh_indicator.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../core/widgets/mascot_widget.dart';
import '../../data/models/kotoba_category.dart';
import 'kotoba_category_screen.dart';
import 'kotoba_providers.dart';
import '../../core/widgets/app_loading.dart';

/// Entry point for the Kotoba (vocabulary) module: all 45 planned
/// categories grouped by theme, grid-style. Only categories with a real
/// dataset are tappable; the rest show a "Segera" badge and are disabled.
///
/// This screen's header is deliberately its own design rather than the
/// shared `ModuleSkylineBanner`/`ModuleTitlePlaque` pair every other
/// module uses (Bunpou/Partikel/Kaiwa/Dokkai/Choukai/Kanji/Bab) — a
/// reference mockup the user shared asked for this specific screen to
/// feel more alive: a bigger mascot, a colour-per-category system, and a
/// small icon in front of every group heading. Deliberately scoped to
/// Kosakata alone per that request, not applied to the other modules'
/// shared header.
class KotobaHomeScreen extends ConsumerWidget {
  const KotobaHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(kotobaCategoryGroupsProvider);
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      backgroundColor: context.palette.background,
      body: Column(
        children: [
          Expanded(
            child: AppRefreshIndicator(
              onRefresh: () =>
                  ref.refresh(kotobaCategoryGroupsProvider.future),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  // Always rendered, independent of groupsAsync's state —
                  // the title needs to be on screen immediately (same
                  // contract the AppBar it replaced had), not only once
                  // the category data has loaded.
                  _KosakataHeaderBanner(title: s.kotobaTitle),
                  groupsAsync.when(
                    data: (groups) => Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final entry in groups.entries) ...[
                            _GroupHeader(
                              groupKey: entry.key,
                              title: KotobaCategoryI18n.group(
                                entry.key,
                                s.language,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _CategoryGrid(categories: entry.value),
                            const SizedBox(height: 24),
                          ],
                        ],
                      ),
                    ),
                    // AppLoading's own ListView needs a bounded height —
                    // it's normally the direct body of a Scaffold (whose
                    // constraints bound it), but here it's one item inside
                    // an *outer* ListView, whose main axis is unbounded.
                    // A bare Padding only insets, it doesn't bound, so
                    // this threw "Vertical viewport was given unbounded
                    // height" until a fixed-height SizedBox was added.
                    loading: () => const SizedBox(
                      height: 420,
                      child: AppLoading(),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: Text(s.failedToLoadCategories(e))),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const FreeTierBannerAd(),
        ],
      ),
    );
  }
}

/// Kosakata's own header: `assets/module_frames/bg_kosakata_header.png`
/// (a real generated illustration — see `scripts/kosakata_header_prompt.md`
/// — replacing a first pass that code-drew the torii/skyline and looked
/// noticeably rougher than the other modules' real banner art), a waving
/// mascot standing at the edge (not inside a card, so no backdrop disc —
/// same reasoning `MascotAdvisor` documents), and the title with a short
/// accent underline rather than the plaque every other module uses.
/// Draws its own back button since there's no `AppBar` behind it.
class _KosakataHeaderBanner extends StatelessWidget {
  final String title;

  const _KosakataHeaderBanner({required this.title});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      height: 232,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/module_frames/bg_kosakata_header.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              // Bundled at build time — a missing file is a packaging
              // bug, not a runtime state; still won't crash the screen,
              // just falls back to a plain gradient instead of the real
              // illustration.
              errorBuilder: (context, error, stackTrace) => DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [palette.katakanaCardBg, palette.background],
                    stops: const [0.0, 0.85],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: -8,
            bottom: -6,
            child: IgnorePointer(
              child: MascotWidget(
                mood: MascotMood.waving,
                size: 150,
                showBackdrop: false,
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: _BackButton(),
          ),
          Positioned(
            top: 78,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: palette.textNavy,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.secondaryBlue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.cardWhite,
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(context).maybePop(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.arrow_back, color: context.palette.textNavy, size: 20),
        ),
      ),
    );
  }
}

/// One emoji per group, matching the reference mockup's small icon-in-
/// front-of-heading treatment — same "emoji, not a generated glyph"
/// convention every category icon in this module already uses, just one
/// level up. Every one of the 7 groups this dataset actually has must be
/// covered; a missing entry falls back to a plain sakura bullet rather
/// than crashing, since a future 8th group is more likely than a typo
/// being caught here.
const Map<String, String> _groupEmoji = {
  'Alam & Lingkungan': '🌿',
  'Makanan & Minuman': '🍴',
  'Tubuh & Kesehatan': '❤️',
  'Tempat & Transportasi': '🏙️',
  'Manusia & Sosial': '👥',
  'Pendidikan & Pekerjaan': '🎓',
  'Waktu & Angka': '🕐',
};

class _GroupHeader extends StatelessWidget {
  final String groupKey;
  final String title;

  const _GroupHeader({required this.groupKey, required this.title});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: palette.secondaryBlue.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            _groupEmoji[groupKey] ?? '🌸',
            style: const TextStyle(fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: palette.textNavy,
          ),
        ),
      ],
    );
  }
}

/// Two-column layout for one group's category cards.
///
/// Was a `GridView.builder(shrinkWrap: true, ...)` — that combination,
/// nested inside a `Column` that itself sits as one item of an outer
/// scrollable `ListView` (needed so the header banner could sit above
/// it), reserved a full extra row's worth of blank space above every
/// group's actual cards. Confirmed on a physical device with a debug
/// colour fill: the phantom gap sat *inside* the grid's own painted
/// bounds, not around it, so something in that specific (shrinkWrap
/// GridView) + (non-scrollable ancestor Column) + (scrollable ListView
/// ancestor) nesting was mis-sizing the sliver viewport. Rebuilt as a
/// plain hand-rolled two-column `Column`-of-`Row`s instead — no nested
/// Scrollable/Viewport at all, so there's nothing left to mis-size.
class _CategoryGrid extends StatelessWidget {
  final List<KotobaCategory> categories;

  const _CategoryGrid({required this.categories});

  /// Cycled by position within the group, not a per-category fixed
  /// colour — matches the reference mockup's row-by-row rotation rather
  /// than tying a colour permanently to one category, which would need a
  /// hand-curated 45-entry mapping for no real benefit.
  static const _accentSlots = [
    AppPaletteAccentSlot.coral,
    AppPaletteAccentSlot.blue,
    AppPaletteAccentSlot.green,
    AppPaletteAccentSlot.amber,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < categories.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 2.4,
                  child: _CategoryCard(
                    category: categories[i],
                    accentSlot: _accentSlots[i % _accentSlots.length],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: i + 1 < categories.length
                    ? AspectRatio(
                        aspectRatio: 2.4,
                        child: _CategoryCard(
                          category: categories[i + 1],
                          accentSlot:
                              _accentSlots[(i + 1) % _accentSlots.length],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// One of the app's existing accent tokens — kept as an enum rather than
/// passing a raw [Color] so [_CategoryGrid] never has to construct a
/// colour literal itself, which `theme_consistency_test.dart` forbids
/// outside [AppPalette].
enum AppPaletteAccentSlot { coral, blue, green, amber }

extension on AppPaletteAccentSlot {
  Color resolve(AppPalette palette) {
    switch (this) {
      case AppPaletteAccentSlot.coral:
        return palette.primaryCoral;
      case AppPaletteAccentSlot.blue:
        return palette.secondaryBlue;
      case AppPaletteAccentSlot.green:
        return palette.successGreen;
      case AppPaletteAccentSlot.amber:
        return palette.tertiaryAmber;
    }
  }
}

class _CategoryCard extends ConsumerWidget {
  final KotobaCategory category;
  final AppPaletteAccentSlot accentSlot;

  const _CategoryCard({required this.category, required this.accentSlot});

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
    final palette = context.palette;
    // Colour-per-card only when available — a locked/"Segera" card stays
    // flat grey, same rule every other module's cards already follow, so
    // "not open yet" keeps reading as muted rather than picking up a
    // random accent it hasn't earned.
    final accent = available ? accentSlot.resolve(palette) : palette.freeBadgeGrey;
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
                  color: accent.withValues(alpha: 0.15),
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
              if (available)
                Icon(Icons.chevron_right, color: accent, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

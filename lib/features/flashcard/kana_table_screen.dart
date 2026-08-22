import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_loading.dart';
import '../../core/widgets/app_refresh_indicator.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../data/models/kana_character.dart';
import '../../data/models/kana_type.dart';
import 'flashcard_screen.dart';
import '../../data/repositories/onboarding_repository.dart';
import '../../features/onboarding/coach_mark_tour.dart';
import '../../features/onboarding/first_visit_tutorial.dart';
import '../../features/onboarding/module_tours.dart';

/// The gojuon chart, and the way into the flashcards.
///
/// The deck is 104 characters per script since dakuten, handakuten and youon
/// were added. Stepping to a specific one — say ぴょ, the last row — meant
/// something like eighty swipes, so the only practical way to reach a
/// character was to already be next to it. This screen is the picker that
/// makes any of them one tap away, and it is what "Belajar Hiragana" opens
/// now; [FlashcardScreen] is what a tap here pushes.
///
/// **Laid out as the chart, not as a plain grid.** Cells are placed by the
/// dataset's own `row`/`column`, and a gap in the chart is rendered as a gap
/// rather than closed up — so や sits under か with nothing beside it, and ん
/// stands alone. Closing those holes would save a little space and quietly
/// teach the wrong shape: the alignment down each vowel column is the thing
/// a kana chart exists to show.
class KanaTableScreen extends ConsumerWidget {
  final KanaType type;

  const KanaTableScreen({super.key, required this.type});

  bool get _isHiragana => type == KanaType.hiragana;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final kanaAsync = ref.watch(kanaListProvider(type));

    return FirstVisitTutorial(
      id: TutorialId.kana,
      tour: kanaTourSteps,
      child: Scaffold(
        backgroundColor: context.palette.background,
        appBar: AppBar(title: Text(_isHiragana ? 'Hiragana' : 'Katakana')),
        body: kanaAsync.when(
          data: (all) => Column(
            children: [
              Expanded(
                child: AppRefreshIndicator(
                  onRefresh: () => ref.refresh(kanaListProvider(type).future),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      Text(
                        s.kanaTableHint,
                        style: TextStyle(
                          fontSize: 14,
                          color: context.palette.textNavy.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (final (i, section) in _sectionsOf(all, s).indexed)
                        _Section(
                          first: i == 0,
                          section: section,
                          type: type,
                          all: all,
                          strings: s,
                          columnCount: _columnCountOf(all),
                        ),
                    ],
                  ),
                ),
              ),
              const FreeTierBannerAd(),
            ],
          ),
          loading: () => const AppLoading(),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  /// One column count for the whole chart, taken from the widest block.
  ///
  /// Per-section widths were the obvious thing and looked wrong: the
  /// combined block is three columns, so sizing its cells to a third of the
  /// screen made them nearly three times the area of a basic-block cell and
  /// turned that section into a wall of oversized tiles. Sizing every block
  /// to the widest one keeps the tiles identical and leaves the combined
  /// rows short, which is what a printed chart does too.
  static int _columnCountOf(List<KanaCharacter> all) =>
      all.map((k) => k.column).fold<int>(0, (a, b) => a > b ? a : b) + 1;

  /// Splits the deck into the three blocks a kana chart is taught in.
  ///
  /// The boundaries are the dataset's own row numbers: 0-10 are the 46 basic
  /// characters, 11-15 the 25 that add a tenten or a maru, and 16 upwards the
  /// 33 two-character combinations. Anything past the last named block still
  /// lands in it, so a future row cannot silently vanish from the chart.
  static List<_KanaSection> _sectionsOf(List<KanaCharacter> all, AppStrings s) {
    List<KanaCharacter> between(int from, int to) =>
        all.where((k) => k.row >= from && k.row <= to).toList();

    return [
      _KanaSection(s.kanaSectionBasic, between(0, 10)),
      _KanaSection(s.kanaSectionDakuten, between(11, 15)),
      _KanaSection(s.kanaSectionYouon, between(16, 9999)),
    ].where((section) => section.characters.isNotEmpty).toList();
  }
}

class _KanaSection {
  final String title;
  final List<KanaCharacter> characters;

  const _KanaSection(this.title, this.characters);
}

class _Section extends StatelessWidget {
  /// Whether this is the gojūon block at the top. Only that one carries
  /// the tour's anchor — the tour points at a row of characters, and
  /// every section having the same id would leave it pointing at
  /// whichever section built last, usually one off the bottom.
  final bool first;

  final _KanaSection section;
  final KanaType type;
  final List<KanaCharacter> all;
  final AppStrings strings;
  final int columnCount;

  const _Section({
    required this.first,
    required this.section,
    required this.type,
    required this.all,
    required this.strings,
    required this.columnCount,
  });

  @override
  Widget build(BuildContext context) {
    final rows = section.characters.map((k) => k.row).toSet().toList()..sort();

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                section.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.palette.textNavy,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                strings.kanaSectionCount(section.characters.length),
                style: TextStyle(
                  fontSize: 13,
                  color: context.palette.textNavy.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final (i, row) in rows.indexed)
            anchorWhen(
              first && i == 0,
              kTutorialFirstItem,
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    for (var column = 0; column < columnCount; column++) ...[
                      if (column > 0) const SizedBox(width: 8),
                      Expanded(child: _cellAt(row, column, type, all)),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cellAt(int row, int column, KanaType type, List<KanaCharacter> all) {
    for (final kana in section.characters) {
      if (kana.row == row && kana.column == column) {
        return _KanaCell(kana: kana, type: type, all: all);
      }
    }
    // A hole in the chart. Kept as empty space on purpose — see the class
    // doc on why the columns must stay aligned.
    return const AspectRatio(aspectRatio: 1, child: SizedBox.shrink());
  }
}

class _KanaCell extends StatelessWidget {
  final KanaCharacter kana;
  final KanaType type;
  final List<KanaCharacter> all;

  const _KanaCell({required this.kana, required this.type, required this.all});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tint = type == KanaType.hiragana
        ? palette.hiraganaCardBg
        : palette.katakanaCardBg;

    return AspectRatio(
      aspectRatio: 1,
      child: Material(
        color: tint,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          // The flashcard steps through the same list this chart was built
          // from, so its index is simply this character's place in it.
          onTap: () => AppNavigator.slideFromRight(
            context,
            FlashcardScreen(type: type, initialIndex: all.indexOf(kana)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Youon are two characters wide and would otherwise wrap or
              // overflow in a cell sized for one.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  kana.character,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: palette.textNavy,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  kana.romaji,
                  style: TextStyle(
                    fontSize: 11,
                    color: palette.textNavy.withValues(alpha: 0.65),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/avatars.dart';
import '../../core/constants/frames.dart';
import '../../core/localization/app_strings.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_refresh_indicator.dart';
import '../../data/models/card_game_rank.dart' show CardGameTierX;
import '../../data/models/leaderboard_entry.dart';
import '../../data/models/user_profile.dart' show AvatarType;
import 'leaderboard_providers.dart';
import 'public_profile_screen.dart' show openPublicProfile;
import 'widgets/clan_leaderboard_banner.dart';
import 'widgets/clan_tab.dart';
import 'widgets/top_clan_tab.dart';
import '../../core/widgets/app_loading.dart';

/// Tabs cover score/clan ranking, plus Card Game Mode's own star ranking
/// — chat and friend requests moved to their own dedicated
/// `ChatHubScreen`/`AddFriendScreen`, each with its own icon on
/// `ProfileScreen`'s app bar, per an explicit request to give them
/// separate mapped menus instead of living inside a tab here.
class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: context.palette.background,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: context.palette.textNavy,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆 ', style: TextStyle(fontSize: 18)),
              Text(s.leaderboardTitle),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: _TabPickerRow(
                labels: [
                  s.tabGlobalScore,
                  s.tabCardGameStars,
                  s.tabClan,
                  s.tabTopClan,
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            _GlobalScoreTab(),
            _CardGameStarsTab(),
            ClanTab(),
            TopClanTab(),
          ],
        ),
      ),
    );
  }
}

/// The tab picker — one separate solid pill per tab, not one shared
/// translucent bar. A single tinted [TabBar] indicator was tried first
/// and rejected: it read as one merged strip rather than distinct
/// choices, and its low-alpha fill looked washed out rather than like a
/// real control. Built directly on [TabController] instead of [TabBar]
/// so each pill can carry its own full-opacity background; renders
/// however many [labels] it's given, so adding a tab is just adding one
/// more label + [TabBarView] child above, no change needed here.
class _TabPickerRow extends StatefulWidget {
  final List<String> labels;

  const _TabPickerRow({required this.labels});

  @override
  State<_TabPickerRow> createState() => _TabPickerRowState();
}

class _TabPickerRowState extends State<_TabPickerRow> {
  TabController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = DefaultTabController.of(context);
    if (controller != _controller) {
      _controller?.animation?.removeListener(_onChange);
      _controller = controller..animation?.addListener(_onChange);
    }
  }

  @override
  void dispose() {
    _controller?.animation?.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final controller = _controller!;
    final liveIndex =
        (controller.animation?.value ?? controller.index.toDouble()).round();

    return Row(
      children: [
        for (var i = 0; i < widget.labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => controller.animateTo(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: liveIndex == i
                      ? palette.successGreen
                      : palette.cardWhite,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: liveIndex == i
                        ? palette.successGreen
                        : palette.successGreen.withValues(alpha: 0.4),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.labels[i],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: liveIndex == i ? Colors.white : palette.textNavy,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The headline number for [entry]: every exam category's Rekor summed, as
/// "N poin" — or "Belum ada" when nothing has been attempted at all, which
/// a bare "0 poin" would otherwise be indistinguishable from. Public so the
/// Clan tab's scoped ranking renders identically. Rounded to whole points:
/// the underlying averages carry decimals, but a leaderboard aimed at
/// children reads better without them, and ties are harmless here.
String globalScoreLabel(LeaderboardEntry entry, AppStrings strings) {
  if (!entry.hasAnyRecord) return strings.noRecordYet;
  return strings.globalScorePoints(
    entry.computedGlobalScore.toStringAsFixed(0),
  );
}

/// The four Rekor values that add up to [globalScoreLabel]'s total, as one
/// compact line — so the score reads as an accumulation the learner can
/// break down, not an opaque number. Empty when nothing's been attempted
/// (the row shows "Belum ada" as its value instead).
String globalScoreBreakdown(LeaderboardEntry entry, AppStrings strings) {
  if (!entry.hasAnyRecord) return '';
  String part(String label, double value) =>
      '$label ${value.toStringAsFixed(0)}';
  return [
    part(strings.scorePartKana, entry.kanaRecordAvg),
    part(strings.scorePartDokkai, entry.dokkaiRecordAvg),
    part(strings.scorePartChoukai, entry.choukaiRecordAvg),
    part(strings.scorePartKanjiCombo, entry.kanjiComboRecordAvg),
  ].join(' · ');
}

class _GlobalScoreTab extends ConsumerWidget {
  const _GlobalScoreTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topAsync = ref.watch(leaderboardTopProvider);
    final selfEntryAsync = ref.watch(selfLeaderboardEntryProvider);
    final selfRankAsync = ref.watch(selfRankProvider);
    final s = ref.watch(appStringsProvider);

    return Column(
      children: [
        const LeaderboardBannerHeader(),
        const SizedBox(height: 14),
        _SelfHeader(
          entry: selfEntryAsync.valueOrNull,
          rank: selfRankAsync.valueOrNull,
          valueLabel: selfEntryAsync.valueOrNull == null
              ? ''
              : globalScoreLabel(selfEntryAsync.valueOrNull!, s),
          subtitle: selfEntryAsync.valueOrNull == null ||
                  !selfEntryAsync.valueOrNull!.hasAnyRecord
              ? ''
              : globalScoreBreakdown(selfEntryAsync.valueOrNull!, s),
          strings: s,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(
            s.globalScoreExplainer,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: context.palette.textNavy.withValues(alpha: 0.6),
            ),
          ),
        ),
        Expanded(
          child: AppRefreshIndicator(
            onRefresh: () {
              // Invalidating the shared entry is enough to refetch it — the
              // rank provider watches it, so refreshing rank last picks up
              // the fresh entry and returns a consumable result (a bare
              // awaited `refresh` would trip `unused_result`).
              ref.invalidate(selfLeaderboardEntryProvider);
              return ref.refresh(selfRankProvider.future);
            },
            child: topAsync.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 120),
                        child: Center(
                          child: Text(
                            s.noRankingData,
                            style: TextStyle(color: context.palette.textNavy),
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => LeaderboardTile(
                    rank: index + 1,
                    entry: entries[index],
                    valueLabel: globalScoreLabel(entries[index], s),
                    subtitle: globalScoreBreakdown(entries[index], s),
                  ),
                );
              },
              loading: () => const AppLoading(),
              error: (e, _) =>
                  Center(child: Text(s.failedToLoadLeaderboard(e))),
            ),
          ),
        ),
      ],
    );
  }
}

/// The headline number for [entry] on the Card Game Mode star tab: total
/// stars accumulated this season, or [AppStrings.cardGameNeverPlayed]
/// when [LeaderboardEntry.hasPlayedCardGame] is false — a bare "0
/// bintang" would otherwise be indistinguishable from having never
/// played a ranked match at all, the same "Belum ada" reasoning
/// [globalScoreLabel] already applies to exam scores.
String cardGameStarValueLabel(LeaderboardEntry entry, AppStrings strings) {
  if (!entry.hasPlayedCardGame) return strings.cardGameNeverPlayed;
  return strings.cardGameStarTotalLabel(entry.cardGameStarTotal!);
}

/// The tier/division/stars-within-division line under [entry]'s name —
/// "Bronze IV · 2/3 bintang" (or the uncapped Emerald form, mirroring
/// exactly what the Home entry card and match-result screen already
/// show for one's own standing). Empty when the player has never
/// played, so the row shows only [cardGameStarValueLabel] with no
/// second line — the same "hasAnyRecord" pattern
/// [globalScoreBreakdown] uses.
String cardGameStarSubtitle(LeaderboardEntry entry, AppStrings strings) {
  if (!entry.hasPlayedCardGame) return '';
  final standing = entry.cardGameRankStanding;
  final starsLabel = standing.tier.hasDivisions
      ? strings.battleRankStars(standing.stars, standing.tier.starsPerDivision)
      : strings.battleRankStarsUncapped(standing.stars);
  return '${standing.displayName} · $starsLabel';
}

class _CardGameStarsTab extends ConsumerWidget {
  const _CardGameStarsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topAsync = ref.watch(cardGameStarsTopProvider);
    final selfEntryAsync = ref.watch(selfLeaderboardEntryProvider);
    final selfRankAsync = ref.watch(selfCardGameStarsRankProvider);
    final s = ref.watch(appStringsProvider);
    final selfEntry = selfEntryAsync.valueOrNull;

    return Column(
      children: [
        const LeaderboardBannerHeader(),
        const SizedBox(height: 14),
        _SelfHeader(
          entry: selfEntry,
          rank: selfRankAsync.valueOrNull,
          valueLabel:
              selfEntry == null ? '' : cardGameStarValueLabel(selfEntry, s),
          subtitle:
              selfEntry == null ? '' : cardGameStarSubtitle(selfEntry, s),
          strings: s,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(
            s.cardGameStarsExplainer,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: context.palette.textNavy.withValues(alpha: 0.6),
            ),
          ),
        ),
        Expanded(
          child: AppRefreshIndicator(
            onRefresh: () {
              // Same shape as _GlobalScoreTab's own refresh: invalidating
              // the shared entry is enough, since the rank provider
              // watches it and refreshing rank last leaves a consumable
              // result (a bare awaited `refresh` would trip
              // `unused_result`).
              ref.invalidate(selfLeaderboardEntryProvider);
              return ref.refresh(selfCardGameStarsRankProvider.future);
            },
            child: topAsync.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 120),
                        child: Center(
                          child: Text(
                            s.noRankingData,
                            style: TextStyle(color: context.palette.textNavy),
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => LeaderboardTile(
                    rank: index + 1,
                    entry: entries[index],
                    valueLabel: cardGameStarValueLabel(entries[index], s),
                    subtitle: cardGameStarSubtitle(entries[index], s),
                  ),
                );
              },
              loading: () => const AppLoading(),
              error: (e, _) =>
                  Center(child: Text(s.failedToLoadLeaderboard(e))),
            ),
          ),
        ),
      ],
    );
  }
}

/// The signed-in learner's own rank/name/avatar card, shown above the
/// ranked list on every tab that has one. [valueLabel]/[subtitle] are
/// passed in pre-computed rather than derived from [entry] here — each
/// tab ranks by a different number ([globalScoreLabel]/
/// [cardGameStarValueLabel]), so this widget stays agnostic to which one
/// it's showing, the same shape [LeaderboardTile] already uses.
/// [subtitle] empty hides that line entirely.
class _SelfHeader extends StatelessWidget {
  final LeaderboardEntry? entry;
  final int? rank;
  final String valueLabel;
  final String subtitle;
  final AppStrings strings;

  const _SelfHeader({
    required this.entry,
    required this.rank,
    required this.valueLabel,
    this.subtitle = '',
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    if (entry == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.palette.primaryCoral.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.palette.primaryCoral.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                rank != null ? strings.rankOf(rank!) : strings.notRankedYet,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: context.palette.primaryCoral,
                ),
              ),
              const SizedBox(width: 8),
              Text('•', style: TextStyle(color: context.palette.textNavy)),
              const SizedBox(width: 8),
              LeaderboardAvatar(entry: entry!, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry!.displayName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.palette.textNavy),
                ),
              ),
              Text(
                valueLabel,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: context.palette.textNavy,
                ),
              ),
            ],
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: context.palette.textNavy.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A single ranked row — reused by both the global leaderboard tab and the
/// Clan tab's scoped ranking (`ClanTab`), which is why this and
/// [LeaderboardAvatar] are public rather than private to this file.
///
/// [subtitle] carries the per-category score breakdown. It replaced the
/// row's old "last updated" date, which said little on a leaderboard and
/// cost the one line now spent showing what the total is actually made of.
class LeaderboardTile extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;
  final String valueLabel;
  final String subtitle;
  final bool isHost;

  const LeaderboardTile({
    super.key,
    required this.rank,
    required this.entry,
    required this.valueLabel,
    this.subtitle = '',
    this.isHost = false,
  });

  String get _rankBadge {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '$rank';
    }
  }

  /// Tints the top 3 rows gold/silver/bronze, matching the reference
  /// design's medal-podium treatment — mapped onto tokens this app's
  /// palette already has (there's no dedicated "bronze" token) rather
  /// than a new hardcoded colour, so it stays theme-consistent and
  /// [test/theme_consistency_test.dart] keeps passing.
  (Color bg, Color accent)? _podiumColors(AppPalette palette) {
    switch (rank) {
      case 1:
        return (palette.tertiaryAmberCardBg, palette.tertiaryAmber);
      case 2:
        return (palette.katakanaCardBg, palette.secondaryBlue);
      case 3:
        return (palette.hiraganaCardBg, palette.primaryCoral);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final podium = _podiumColors(context.palette);
    return Material(
      color: podium?.$1 ?? context.palette.cardWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => openPublicProfile(context, entry),
        child: podium != null
            ? DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: podium.$2.withValues(alpha: 0.5)),
                ),
                child: _content(context),
              )
            : _content(context),
      ),
    );
  }

  Widget _content(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              _rankBadge,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: context.palette.textNavy,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
          LeaderboardAvatar(entry: entry, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isHost)
                      const Text('👑 ', style: TextStyle(fontSize: 13)),
                    Flexible(
                      child: Text(
                        entry.displayName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: context.palette.textNavy,
                        ),
                      ),
                    ),
                  ],
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.palette.textNavy.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            valueLabel,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: context.palette.primaryCoral,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders a leaderboard/clan row's avatar. Presets are looked up locally
/// (not via `UserAvatar`, which needs a live Firebase `User`) since
/// leaderboard/clan-member entries only carry the resolved
/// avatarType/avatarValue/photoUrl.
///
/// Layers [entry.frameId]'s border art on top when present, mirroring
/// `UserAvatar`'s own frame handling — see [LeaderboardEntry.frameId]'s doc
/// comment for why the entry carries this at all (published from
/// `AvatarPickerSheet`'s frame tab so it shows up everywhere this widget
/// renders someone else's row, not just on their own device).
class LeaderboardAvatar extends StatelessWidget {
  final LeaderboardEntry entry;
  final double size;

  const LeaderboardAvatar({super.key, required this.entry, required this.size});

  static const _frameScale = 1.25;

  @override
  Widget build(BuildContext context) {
    final avatarWidget = _buildAvatar(context);
    final frame = FramePresets.byId(entry.frameId);
    if (frame == null) return avatarWidget;

    final frameSize = size * _frameScale;
    return SizedBox(
      width: frameSize,
      height: frameSize,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          avatarWidget,
          FrameOverlay(preset: frame, avatarSize: size, scale: _frameScale),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    if (entry.avatarType == AvatarType.presetFree ||
        entry.avatarType == AvatarType.presetPremium) {
      final preset = AvatarPresets.byId(entry.avatarValue);
      if (preset != null) {
        return ClipOval(
          child: SizedBox(
            width: size,
            height: size,
            child: AvatarPresetArt(
              preset: preset,
              imageSize: size,
              emojiFontSize: size * 0.4,
              fit: BoxFit.cover,
            ),
          ),
        );
      }
    }

    final photoUrl = entry.photoUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(photoUrl),
      );
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: context.palette.hiraganaCardBg,
      child: Text('🐱', style: TextStyle(fontSize: size * 0.5)),
    );
  }
}

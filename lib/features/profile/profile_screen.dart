import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/covers.dart';
import '../../core/localization/app_strings.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_refresh_indicator.dart';
import '../../core/widgets/count_badge.dart';
import '../../core/widgets/user_avatar.dart';
import '../../data/models/bab_entry.dart';
import '../../data/models/jlpt_level.dart';
import '../../data/models/kana_status.dart';
import '../../data/models/kana_type.dart';
import '../bab/bab_providers.dart';
import '../home/home_screen.dart';
import '../leaderboard/add_friend_screen.dart';
import '../leaderboard/chat_hub_screen.dart';
import '../leaderboard/chat_providers.dart';
import '../leaderboard/friend_providers.dart';
import '../leaderboard/leaderboard_providers.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../leaderboard/public_profile_screen.dart' show BabProgressBody;
import '../saved_words/saved_words_screen.dart';
import 'about_screen.dart';
import 'exam_history_screen.dart';
import 'language_screen.dart';
import 'theme_screen.dart';
import 'notification_screen.dart';
import 'profile_providers.dart';
import 'widgets/avatar_picker_sheet.dart';
import 'widgets/cover_picker_sheet.dart';
import 'widgets/edit_name_dialog.dart';
import 'widgets/exam_history_empty_illustration.dart';
import 'widgets/exam_history_tile.dart';
import '../onboarding/onboarding_screen.dart';
import '../../core/widgets/app_loading.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(appStartupProvider);
    final s = ref.watch(appStringsProvider);
    final pendingFriendRequests = ref.watch(pendingFriendRequestCountProvider);
    final unreadChats = ref.watch(totalUnreadChatCountProvider);

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        title: Text(s.profile),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Text('🏆', style: TextStyle(fontSize: 22)),
            tooltip: s.leaderboardTooltip,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
            ),
          ),
          IconButton(
            icon: CountBadge(
              count: unreadChats,
              child: const Icon(Icons.chat_bubble_outline),
            ),
            tooltip: s.chatMenuTitle,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ChatHubScreen()),
            ),
          ),
          IconButton(
            icon: CountBadge(
              count: pendingFriendRequests,
              child: const Icon(Icons.person_add_alt_1),
            ),
            tooltip: s.addFriendMenuTitle,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddFriendScreen()),
            ),
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) => _ProfileBody(user: user),
        loading: () => const AppLoading(),
        error: (e, _) => Center(child: Text(s.failedToLoadProfile(e))),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  final User user;

  const _ProfileBody({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppRefreshIndicator(
      onRefresh: () => ref.refresh(appStartupProvider.future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          _HeaderCard(user: user),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ProgressStatCard(
                  type: KanaType.hiragana,
                  color: context.palette.primaryCoral,
                  cardBg: context.palette.hiraganaCardBg,
                  label: 'Hiragana',
                  character: 'あ',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ProgressStatCard(
                  type: KanaType.katakana,
                  color: context.palette.secondaryBlue,
                  cardBg: context.palette.katakanaCardBg,
                  label: 'Katakana',
                  character: 'ア',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _StreakCard(),
          const SizedBox(height: 16),
          const _MyScoreAndCurriculumCard(),
          const SizedBox(height: 24),
          const _ExamHistorySection(),
          const SizedBox(height: 24),
          const _SettingsMenu(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _HeaderCard extends ConsumerWidget {
  final User user;

  const _HeaderCard({required this.user});

  Future<void> _linkGoogle(BuildContext context, WidgetRef ref) async {
    try {
      final result = await ref.read(authServiceProvider).linkWithGoogle();
      if (result == null) return; // user cancelled the account picker
      if (!context.mounted) return;
      ref.invalidate(appStartupProvider);
    } catch (e) {
      if (!context.mounted) return;
      final s = ref.read(appStringsProvider);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyGoogleSignInError(e, s))));
    }
  }

  /// Google Sign-In failures are usually device/OAuth-config issues (bad
  /// network, Play Services hiccup, misconfigured OAuth consent screen)
  /// rather than something the user can fix by retrying differently, so we
  /// keep the message generic instead of surfacing the raw exception.
  String _friendlyGoogleSignInError(Object e, AppStrings s) {
    if (e is FirebaseAuthException && e.code == 'credential-already-in-use') {
      return s.googleAccountAlreadyLinked;
    }
    return s.googleSignInFailed;
  }

  void _editName(BuildContext context, String currentName) {
    showDialog<void>(
      context: context,
      builder: (_) => EditNameDialog(currentName: currentName),
    );
  }

  void _pickAvatar(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AvatarPickerSheet(),
    );
  }

  void _pickCover(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CoverPickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider).valueOrNull;
    final isPremium = subscription?.isPremium ?? false;
    final isAnonymous = user.isAnonymous;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final s = ref.watch(appStringsProvider);
    final displayName =
        profile?.resolveDisplayName(user) ??
        (user.displayName ?? s.defaultLearnerName);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          // Full-bleed cover background — the selected preset's art, or
          // CoverPresets.fallback when the user has never picked one.
          Positioned.fill(
            child: _HeaderBackground(coverId: profile?.coverId),
          ),
          // Scrim so avatar/name/text stay legible over any cover photo,
          // busy or plain. Comes from the palette because it has to invert:
          // a white wash under dark mode's pale text would leave the two
          // fighting each other on the lighter covers.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(color: context.palette.headerScrim),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => _pickAvatar(context),
                  child: Stack(
                    children: [
                      UserAvatar(profile: profile, user: user, radius: 40),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: context.palette.primaryCoral,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.palette.textNavy,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.edit,
                        size: 18,
                        color: context.palette.textNavy,
                      ),
                      tooltip: s.changeNameTooltip,
                      onPressed: () => _editName(context, displayName),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                if (profile?.userId != null) ...[
                  const SizedBox(height: 2),
                  _UserIdChip(userId: profile!.userId!, strings: s),
                ],
                _TierBadge(isPremium: isPremium),
                const SizedBox(height: 8),
                Text(
                  s.profileMotivation,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: context.palette.textNavy),
                ),
                if (isAnonymous) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: context.palette.cardWhite,
                        foregroundColor: context.palette.primaryCoral,
                        side: BorderSide(color: context.palette.primaryCoral),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () => _linkGoogle(context, ref),
                      icon: const Icon(Icons.login, size: 18),
                      label: Text(s.signInWithGoogle),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: GestureDetector(
              onTap: () => _pickCover(context),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-bleed background for [_HeaderCard]: the selected cover preset's art
/// (or its emoji placeholder) filling the whole card, or — with no cover
/// chosen — the plain brand-color background with the original decorative
/// torii/Fuji/sakura scene anchored in a corner, matching how it looked
/// before covers existed.
class _HeaderBackground extends StatelessWidget {
  final String? coverId;

  const _HeaderBackground({required this.coverId});

  @override
  Widget build(BuildContext context) {
    // Falls back to a real cover rather than the old hand-drawn scene — see
    // CoverPresets.fallback. byId also returns null for a coverId left over
    // from a preset that no longer exists, which lands here too.
    final preset = CoverPresets.byId(coverId) ?? CoverPresets.fallback;
    return LayoutBuilder(
      builder: (context, constraints) => CoverArt(
        preset: preset,
        width: constraints.maxWidth,
        height: constraints.maxHeight,
      ),
    );
  }
}

/// The learner's own short, unique id (see `ProgressRepository
/// ._reserveUserId`) — shown so a user can find and share it, since many
/// accounts share the exact same display name and the id is what actually
/// disambiguates them in `SearchInviteScreen`.
class _UserIdChip extends StatelessWidget {
  final String userId;
  final AppStrings strings;

  const _UserIdChip({required this.userId, required this.strings});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Clipboard.setData(ClipboardData(text: userId));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.userIdCopied)));
      },
      child: Tooltip(
        message: strings.userIdTooltip,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Text(
            strings.userIdLabel(userId),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: context.palette.textNavy.withValues(alpha: 0.75),
            ),
          ),
        ),
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  final bool isPremium;

  const _TierBadge({required this.isPremium});

  @override
  Widget build(BuildContext context) {
    if (isPremium) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [context.palette.premiumGoldStart, context.palette.premiumGoldEnd],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: 14, color: Colors.white),
            SizedBox(width: 4),
            Text(
              'PREMIUM',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: context.palette.cardWhite.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '🌸 FREE',
        style: TextStyle(
          color: context.palette.primaryCoral,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ProgressStatCard extends ConsumerWidget {
  final KanaType type;
  final Color color;
  final Color cardBg;
  final String label;
  final String character;

  const _ProgressStatCard({
    required this.type,
    required this.color,
    required this.cardBg,
    required this.label,
    required this.character,
  });

  /// Only used as a placeholder while `kanaListProvider` hasn't resolved
  /// yet — the real total below always comes from the actual dataset, so
  /// this never goes stale if the kana list's size ever changes.
  static const _fallbackTotal = 46;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(typeProgressProvider(type)).valueOrNull;
    final total =
        ref.watch(kanaListProvider(type)).valueOrNull?.length ?? _fallbackTotal;
    final mastered =
        progress?.items.values
            .where((p) => p.status == KanaStatus.mastered)
            .length ??
        0;
    final ratio = total == 0 ? 0.0 : mastered / total;
    final s = ref.watch(appStringsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: context.palette.textNavy,
                ),
              ),
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Text(
                  character,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            s.masteredCount(mastered, total),
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

/// The learner's own global score and curriculum progress, mirroring what
/// [PublicProfileScreen] shows other people about them — so "how am I
/// doing" is answerable from the Profile tab without a trip to the
/// leaderboard.
///
/// Progress is read from the **local** `babCompletedIdsProvider`, not the
/// `babCompletedCount` published to `leaderboard/{uid}`: local
/// SharedPreferences is the source of truth for one's own progress (same
/// rule as every other progress repository in this app), so this stays
/// correct offline and never lags a failed best-effort publish.
class _MyScoreAndCurriculumCard extends ConsumerWidget {
  const _MyScoreAndCurriculumCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final entry = ref.watch(selfLeaderboardEntryProvider).valueOrNull;
    final allBab = ref.watch(babAllProvider).valueOrNull;
    final completed = ref.watch(babCompletedIdsProvider).valueOrNull;
    final levels = ref.watch(babLevelProgressProvider).valueOrNull;

    // Both sources have to be in before anything is drawn. Rendering as
    // soon as `allBab` arrived showed "belum mulai" to a learner who
    // simply had progress still loading — a wrong answer, not a slow one.
    final ready = allBab != null && completed != null;
    final done = ready
        ? allBab.where((b) => completed.contains(b.id)).toList()
        : const <BabEntry>[];
    final highestOrder = done.fold<int>(
      0,
      (highest, b) => b.order > highest ? b.order : highest,
    );
    final current = levels?.lastWhere((l) => l.reachedByProgress);
    final allComplete = levels != null && levels.every((l) => l.isComplete);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.cardWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s.tabGlobalScore,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: context.palette.textNavy,
                  ),
                ),
              ),
              Text(
                entry == null ? s.noRecordYet : globalScoreLabel(entry, s),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.palette.primaryCoral,
                ),
              ),
            ],
          ),
          if (entry != null && entry.hasAnyRecord) ...[
            const SizedBox(height: 4),
            Text(
              globalScoreBreakdown(entry, s),
              style: TextStyle(
                fontSize: 11,
                color: context.palette.textNavy.withValues(alpha: 0.6),
              ),
            ),
          ],
          const Divider(height: 24),
          Text(
            s.curriculumProgressTitle,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: context.palette.textNavy,
            ),
          ),
          if (current != null) ...[
            const SizedBox(height: 6),
            Text(
              allComplete
                  ? s.babAllLevelsComplete
                  : s.babLevelStandingSummary(
                      current.level.key,
                      current.completed,
                      current.total,
                    ),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.palette.primaryCoral,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (!ready)
            const Center(child: CircularProgressIndicator())
          else
            BabProgressBody(
              completedCount: done.length,
              highestOrder: highestOrder,
              totalChapters: allBab.length,
              furthestTitle: highestOrder == 0
                  ? null
                  : allBab
                      .firstWhere((b) => b.order == highestOrder)
                      .localizedTitle(s.language),
              levels: levels,
            ),
        ],
      ),
    );
  }
}

class _StreakCard extends ConsumerWidget {
  const _StreakCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak =
        ref.watch(userProfileProvider).valueOrNull?.currentStreak ?? 0;
    final s = ref.watch(appStringsProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.tertiaryAmberCardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.streak,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: context.palette.tertiaryAmber,
                  ),
                ),
                Text(
                  s.streakDays(streak),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: context.palette.textNavy,
                  ),
                ),
                Text(
                  s.keepYourStreak,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.palette.textNavy.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StreakDayBadge(streak: streak, daysLabel: s.days),
        ],
      ),
    );
  }
}

class _StreakDayBadge extends StatelessWidget {
  final int streak;
  final String daysLabel;

  const _StreakDayBadge({required this.streak, required this.daysLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      decoration: BoxDecoration(
        color: context.palette.cardWhite,
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            color: context.palette.tertiaryAmber,
            padding: const EdgeInsets.symmetric(vertical: 2),
            alignment: Alignment.center,
            child: Text(
              '$streak',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text(
              daysLabel,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: context.palette.textNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamHistorySection extends ConsumerWidget {
  const _ExamHistorySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(recentExamHistoryProvider).valueOrNull ?? [];
    final s = ref.watch(appStringsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              s.examHistory,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.palette.textNavy,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ExamHistoryScreen()),
              ),
              child: Text(s.seeAll),
            ),
          ],
        ),
        if (history.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    s.noExamHistory,
                    style: TextStyle(
                      color: context.palette.textNavy.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                const ExamHistoryEmptyIllustration(),
              ],
            ),
          )
        else
          ...history.map((entry) => ExamHistoryTile(entry: entry)),
      ],
    );
  }
}

class _SettingsMenu extends ConsumerWidget {
  const _SettingsMenu();

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final s = ref.read(appStringsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.logoutConfirmTitle),
        content: Text(s.logoutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              s.logout,
              style: TextStyle(
                color: context.palette.primaryCoral,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(authServiceProvider).signOut();
    ref.invalidate(appStartupProvider);
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    return Container(
      decoration: BoxDecoration(
        color: context.palette.cardWhite,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _MenuTile(
            emoji: '📖',
            title: s.savedWords,
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SavedWordsScreen())),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _MenuTile(
            emoji: '🌐',
            title: s.appLanguage,
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const LanguageScreen())),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _MenuTile(
            emoji: '🎨',
            title: s.appTheme,
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ThemeScreen())),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _MenuTile(
            emoji: '🔔',
            title: s.notifications,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationScreen()),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _MenuTile(
            emoji: '🐱',
            // The tutorial only ever shows itself once, so without this it
            // would be unreachable after the first launch — including for
            // anyone testing it, who would otherwise have to reinstall.
            title: s.tutorialReplay,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OnboardingScreen(
                  // A replay only closes itself. It deliberately does not
                  // touch the seen flag: this is not the first run, and
                  // clearing it would put the tutorial back in front of
                  // the next launch.
                  onFinished: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _MenuTile(
            emoji: 'ℹ️',
            title: s.aboutApp,
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AboutScreen())),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _MenuTile(
            emoji: '🚪',
            title: s.logout,
            onTap: () => _confirmLogout(context, ref),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final String emoji;
  final String title;
  final VoidCallback onTap;

  const _MenuTile({
    required this.emoji,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(emoji, style: const TextStyle(fontSize: 20)),
      title: Text(title, style: TextStyle(color: context.palette.textNavy)),
      trailing: Icon(Icons.chevron_right, color: context.palette.textNavy),
      onTap: onTap,
    );
  }
}


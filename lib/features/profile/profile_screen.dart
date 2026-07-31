import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/covers.dart';
import '../../core/localization/app_strings.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_refresh_indicator.dart';
import '../../core/widgets/user_avatar.dart';
import '../../data/models/kana_status.dart';
import '../../data/models/kana_type.dart';
import '../home/home_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../saved_words/saved_words_screen.dart';
import 'about_screen.dart';
import 'exam_history_screen.dart';
import 'language_screen.dart';
import 'notification_screen.dart';
import 'profile_providers.dart';
import 'widgets/avatar_picker_sheet.dart';
import 'widgets/cover_picker_sheet.dart';
import 'widgets/edit_name_dialog.dart';
import 'widgets/exam_history_empty_illustration.dart';
import 'widgets/exam_history_tile.dart';
import 'widgets/profile_header_illustration.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(appStartupProvider);
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
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
        ],
      ),
      body: userAsync.when(
        data: (user) => _ProfileBody(user: user),
        loading: () => const Center(child: CircularProgressIndicator()),
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
                  color: AppColors.primaryCoral,
                  cardBg: AppColors.hiraganaCardBg,
                  label: 'Hiragana',
                  character: 'あ',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ProgressStatCard(
                  type: KanaType.katakana,
                  color: AppColors.secondaryBlue,
                  cardBg: AppColors.katakanaCardBg,
                  label: 'Katakana',
                  character: 'ア',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _StreakCard(),
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
          // Full-bleed cover background — either the selected preset's art
          // (or its emoji placeholder) or, with no cover chosen, the plain
          // brand-color background with the original decorative scene
          // anchored in a corner.
          Positioned.fill(
            child: _HeaderBackground(coverId: profile?.coverId),
          ),
          // Scrim so avatar/name/text stay legible over any cover photo,
          // busy or plain.
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color.fromRGBO(255, 255, 255, 0.62),
              ),
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
                          decoration: const BoxDecoration(
                            color: AppColors.primaryCoral,
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textNavy,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        size: 18,
                        color: AppColors.textNavy,
                      ),
                      tooltip: s.changeNameTooltip,
                      onPressed: () => _editName(context, displayName),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                _TierBadge(isPremium: isPremium),
                const SizedBox(height: 8),
                Text(
                  s.profileMotivation,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textNavy),
                ),
                if (isAnonymous) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryCoral,
                        side: const BorderSide(color: AppColors.primaryCoral),
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
    final preset = CoverPresets.byId(coverId);
    if (preset == null) {
      return const ColoredBox(
        color: AppColors.hiraganaCardBg,
        child: Align(
          alignment: Alignment.centerRight,
          child: ProfileHeaderIllustration(),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => CoverArt(
        preset: preset,
        width: constraints.maxWidth,
        height: constraints.maxHeight,
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
          gradient: const LinearGradient(
            colors: [AppColors.premiumGoldStart, AppColors.premiumGoldEnd],
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
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        '🌸 FREE',
        style: TextStyle(
          color: AppColors.primaryCoral,
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textNavy,
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
        color: AppColors.tertiaryAmberCardBg,
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
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.tertiaryAmber,
                  ),
                ),
                Text(
                  s.streakDays(streak),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textNavy,
                  ),
                ),
                Text(
                  s.keepYourStreak,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textNavy.withValues(alpha: 0.6),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            color: AppColors.tertiaryAmber,
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
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: AppColors.textNavy,
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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textNavy,
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
                      color: AppColors.textNavy.withValues(alpha: 0.6),
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
              style: const TextStyle(
                color: AppColors.primaryCoral,
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
        color: AppColors.cardWhite,
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
            emoji: '🔔',
            title: s.notifications,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationScreen()),
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
      title: Text(title, style: const TextStyle(color: AppColors.textNavy)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textNavy),
      onTap: onTap,
    );
  }
}


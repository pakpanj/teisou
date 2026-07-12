import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/user_avatar.dart';
import '../../data/models/exam_mode.dart';
import '../../data/models/exam_result.dart';
import '../../data/models/kana_status.dart';
import '../../data/models/kana_type.dart';
import '../home/home_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import 'about_screen.dart';
import 'exam_history_screen.dart';
import 'language_screen.dart';
import 'notification_screen.dart';
import 'profile_providers.dart';
import 'widgets/avatar_picker_sheet.dart';
import 'widgets/edit_name_dialog.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(appStartupProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Text('🏆', style: TextStyle(fontSize: 22)),
            tooltip: 'Papan Peringkat',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
            ),
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) => _ProfileBody(user: user),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat profil: $e')),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  final User user;

  const _ProfileBody({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
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
                label: 'Hiragana',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ProgressStatCard(
                type: KanaType.katakana,
                color: AppColors.secondaryBlue,
                label: 'Katakana',
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
      ref.invalidate(appStartupProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyGoogleSignInError(e))),
      );
    }
  }

  /// Google Sign-In failures are usually device/OAuth-config issues (bad
  /// network, Play Services hiccup, misconfigured OAuth consent screen)
  /// rather than something the user can fix by retrying differently, so we
  /// keep the message generic instead of surfacing the raw exception.
  String _friendlyGoogleSignInError(Object e) {
    if (e is FirebaseAuthException && e.code == 'credential-already-in-use') {
      return 'Akun Google ini sudah terhubung ke akun lain.';
    }
    return 'Gagal masuk dengan Google. Periksa koneksi internet kamu dan coba lagi.';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider).valueOrNull;
    final isPremium = subscription?.isPremium ?? false;
    final isAnonymous = user.isAnonymous;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final displayName = profile?.resolveDisplayName(user) ?? (user.displayName ?? 'Pelajar Kana');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
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
                    child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textNavy,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: AppColors.textNavy),
                tooltip: 'Ganti Nama',
                onPressed: () => _editName(context, displayName),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          _TierBadge(isPremium: isPremium),
          if (isAnonymous) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _linkGoogle(context, ref),
              icon: const Icon(Icons.login, size: 18),
              label: const Text('Masuk dengan Google'),
            ),
          ],
        ],
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
        color: AppColors.freeBadgeGrey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'FREE',
        style: TextStyle(
          color: AppColors.freeBadgeGrey,
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
  final String label;

  const _ProgressStatCard({
    required this.type,
    required this.color,
    required this.label,
  });

  static const _total = 46;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(typeProgressProvider(type)).valueOrNull;
    final mastered = progress?.items.values
            .where((p) => p.status == KanaStatus.mastered)
            .length ??
        0;
    final ratio = mastered / _total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textNavy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$mastered/$_total Mastered',
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
    final streak = ref.watch(userProfileProvider).valueOrNull?.currentStreak ?? 0;

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
            child: Text(
              '$streak hari berturut-turut belajar',
              style: const TextStyle(
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Riwayat Ujian',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textNavy,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ExamHistoryScreen()),
              ),
              child: const Text('Lihat Semua'),
            ),
          ],
        ),
        if (history.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Belum ada riwayat ujian.',
              style: TextStyle(color: AppColors.textNavy.withValues(alpha: 0.6)),
            ),
          )
        else
          ...history.map((result) => _ExamHistoryTile(result: result)),
      ],
    );
  }
}

class _ExamHistoryTile extends StatelessWidget {
  final ExamResult result;

  const _ExamHistoryTile({required this.result});

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              result.mode.title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textNavy,
              ),
            ),
          ),
          Text(
            '${result.score}/${result.total}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryCoral,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatDate(result.completedAt),
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textNavy.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsMenu extends ConsumerWidget {
  const _SettingsMenu();

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Yakin mau keluar? Progress kamu sudah tersimpan di cloud dan '
          'bisa diakses kembali setelah login.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Keluar',
              style: TextStyle(
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

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final step1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset semua progress?'),
        content: const Text('Yakin mau reset semua progress?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lanjut'),
          ),
        ],
      ),
    );
    if (step1 != true || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => const _ResetConfirmDialog(),
    );
    if (confirmed != true) return;

    final uid = ref.read(appStartupProvider).valueOrNull?.uid;
    if (uid == null) return;
    await ref.read(progressRepositoryProvider).resetAllProgress(uid);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Progress berhasil direset.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _MenuTile(
            emoji: '🌐',
            title: 'Bahasa App',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LanguageScreen()),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _MenuTile(
            emoji: '🔔',
            title: 'Notifikasi',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationScreen()),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _MenuTile(
            emoji: 'ℹ️',
            title: 'Tentang App',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _MenuTile(
            emoji: '🗑️',
            title: 'Reset Progress',
            titleColor: AppColors.errorRed,
            onTap: () => _confirmReset(context, ref),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _MenuTile(
            emoji: '🚪',
            title: 'Keluar',
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
  final Color? titleColor;

  const _MenuTile({
    required this.emoji,
    required this.title,
    required this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(emoji, style: const TextStyle(fontSize: 20)),
      title: Text(
        title,
        style: TextStyle(color: titleColor ?? AppColors.textNavy),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textNavy),
      onTap: onTap,
    );
  }
}

class _ResetConfirmDialog extends StatefulWidget {
  const _ResetConfirmDialog();

  @override
  State<_ResetConfirmDialog> createState() => _ResetConfirmDialogState();
}

class _ResetConfirmDialogState extends State<_ResetConfirmDialog> {
  final _controller = TextEditingController();
  bool _valid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Konfirmasi Reset'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progress yang dihapus tidak bisa dikembalikan. Ketik RESET '
            'untuk konfirmasi.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            onChanged: (value) => setState(() => _valid = value == 'RESET'),
            decoration: const InputDecoration(
              hintText: 'RESET',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: _valid ? () => Navigator.pop(context, true) : null,
          child: const Text(
            'Hapus',
            style: TextStyle(
              color: AppColors.errorRed,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

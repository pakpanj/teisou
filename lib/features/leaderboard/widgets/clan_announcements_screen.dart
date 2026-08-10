import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../data/models/clan_announcement.dart';
import '../../../data/models/clan_member.dart';
import '../../../data/repositories/clan_announcement_repository.dart';
import '../clan_providers.dart';

/// Read by every clan member; posting a new one is leader-only (mirrors
/// `firestore.rules`' `actorRole(...) == 'leader'` check — the compose
/// button only ever shows for a leader, same "UI hides an action the server
/// would refuse anyway" discipline `ClanMembersScreen` already follows).
/// Posting triggers `functions/index.js`'s `onClanAnnouncementCreated`,
/// which fans a real push out to every other member.
class ClanAnnouncementsScreen extends ConsumerStatefulWidget {
  final String code;
  final String clanName;

  const ClanAnnouncementsScreen({
    super.key,
    required this.code,
    required this.clanName,
  });

  @override
  ConsumerState<ClanAnnouncementsScreen> createState() =>
      _ClanAnnouncementsScreenState();
}

class _ClanAnnouncementsScreenState
    extends ConsumerState<ClanAnnouncementsScreen> {
  /// Same "only write a read-marker when the visible latest item actually
  /// changes" guard `ClanChatScreen._maybeMarkRead` already uses, so opening
  /// this screen doesn't re-issue the same merge write on every rebuild.
  String? _lastMarkedId;

  void _maybeMarkRead(List<ClanAnnouncement> announcements) {
    if (announcements.isEmpty) return;
    final latestId = announcements.first.id;
    if (latestId == _lastMarkedId) return;
    _lastMarkedId = latestId;
    final myUid = ref.read(appStartupProvider).valueOrNull?.uid;
    if (myUid == null) return;
    ref
        .read(clanAnnouncementRepositoryProvider)
        .markRead(widget.code, myUid)
        .catchError((_) {});
  }

  Future<void> _compose() async {
    final s = ref.read(appStringsProvider);
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.composeAnnouncement),
        content: TextField(
          controller: controller,
          maxLines: 5,
          maxLength: ClanAnnouncementRepository.maxAnnouncementLength,
          decoration: InputDecoration(
            hintText: s.announcementHint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(s.postAnnouncementButton),
          ),
        ],
      ),
    );
    if (text == null || text.trim().isEmpty) return;
    if (text.trim().length > ClanAnnouncementRepository.maxAnnouncementLength) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.announcementTooLong)));
      return;
    }

    final user = ref.read(appStartupProvider).valueOrNull;
    if (user == null) return;
    final profile = ref.read(userProfileProvider).valueOrNull;
    final authorName = profile?.resolveDisplayName(user) ??
        (user.displayName ?? s.defaultLearnerName);

    try {
      await ref.read(clanAnnouncementRepositoryProvider).postAnnouncement(
            code: widget.code,
            authorUid: user.uid,
            authorName: authorName,
            text: text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.announcementPosted)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.announcementSendFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final announcementsAsync = ref.watch(clanAnnouncementsProvider(widget.code));
    final myRole =
        ref.watch(myRoleInClanProvider(widget.code)).valueOrNull;
    final canCompose = myRole == ClanRole.leader;

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: Text(s.clanAnnouncements)),
      floatingActionButton: canCompose
          ? FloatingActionButton.extended(
              onPressed: _compose,
              icon: const Icon(Icons.campaign_outlined),
              label: Text(s.composeAnnouncement),
            )
          : null,
      body: announcementsAsync.when(
        data: (announcements) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _maybeMarkRead(announcements));
          if (announcements.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  s.clanAnnouncementsEmpty,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.palette.textNavy.withValues(alpha: 0.6),
                  ),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: announcements.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                _AnnouncementCard(announcement: announcements[index]),
          );
        },
        loading: () => const AppLoading(),
        error: (e, _) => Center(child: Text(s.failedToLoadAnnouncements(e))),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final ClanAnnouncement announcement;

  const _AnnouncementCard({required this.announcement});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.palette.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.palette.primaryCoral.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.campaign_outlined,
                size: 16,
                color: context.palette.primaryCoral,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  announcement.authorName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: context.palette.primaryCoral,
                  ),
                ),
              ),
              Text(
                _formatDate(announcement.createdAt),
                style: TextStyle(
                  fontSize: 11,
                  color: context.palette.textNavy.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            announcement.text,
            style: TextStyle(color: context.palette.textNavy),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime time) {
    final day = time.day.toString().padLeft(2, '0');
    final month = time.month.toString().padLeft(2, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$day/$month $hour.$minute';
  }
}

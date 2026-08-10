import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/providers.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/clan_message.dart';
import '../../../data/repositories/clan_message_repository.dart';
import '../clan_providers.dart';
import 'chat_composer.dart';

/// Group chat for one clan's own members. See
/// `ClanMessageRepository`'s doc comment for the scope/safety reasoning —
/// this is deliberately clan-only, not open messaging to any public user.
class ClanChatScreen extends ConsumerStatefulWidget {
  final String code;
  final String clanName;

  const ClanChatScreen({super.key, required this.code, required this.clanName});

  @override
  ConsumerState<ClanChatScreen> createState() => _ClanChatScreenState();
}

class _ClanChatScreenState extends ConsumerState<ClanChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  DateTime? _lastSentAt;
  static const _sendCooldown = Duration(seconds: 2);
  bool _sending = false;

  /// The id of the latest message this screen has already told the
  /// server was read — tracked so [_maybeMarkRead] only fires a write
  /// when the visible latest message actually changes (on open, and
  /// again whenever a new one arrives while this screen stays open),
  /// instead of re-issuing the same merge write on every rebuild.
  String? _lastMarkedMessageId;

  @override
  void initState() {
    super.initState();
    // See FcmService.currentOpenChatKey's own doc comment: suppresses the
    // foreground push banner for the exact clan chat already on screen.
    FcmService.currentOpenChatKey = 'clan:${widget.code}';
  }

  @override
  void dispose() {
    if (FcmService.currentOpenChatKey == 'clan:${widget.code}') {
      FcmService.currentOpenChatKey = null;
    }
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _maybeMarkRead(List<ClanMessage> messages) {
    if (messages.isEmpty) return;
    final latestId = messages.last.id;
    if (latestId == _lastMarkedMessageId) return;
    _lastMarkedMessageId = latestId;
    final myUid = ref.read(appStartupProvider).valueOrNull?.uid;
    if (myUid == null) return;
    // Best-effort — a missed read-marker just means the unread badge
    // stays on a beat longer, never a blocking failure.
    ref.read(clanMessageRepositoryProvider).markRead(widget.code, myUid).catchError((_) {});
  }

  Future<void> _send() async {
    final s = ref.read(appStringsProvider);
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    if (text.trim().length > ClanMessageRepository.maxMessageLength) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.messageTooLong)));
      return;
    }
    final lastSent = _lastSentAt;
    if (lastSent != null && DateTime.now().difference(lastSent) < _sendCooldown) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.messageSendTooFast)));
      return;
    }

    final user = ref.read(appStartupProvider).valueOrNull;
    if (user == null) return;
    final profile = ref.read(userProfileProvider).valueOrNull;
    final senderName = profile?.resolveDisplayName(user) ??
        (user.displayName ?? s.defaultLearnerName);

    setState(() => _sending = true);
    try {
      await ref.read(clanMessageRepositoryProvider).sendMessage(
            code: widget.code,
            senderUid: user.uid,
            senderName: senderName,
            text: text,
          );
      _lastSentAt = DateTime.now();
      _controller.clear();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.messageSendFailed)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _toggleBlock(String uid, bool currentlyBlocked) async {
    final s = ref.read(appStringsProvider);
    final myUid = ref.read(appStartupProvider).valueOrNull?.uid;
    if (myUid == null) return;
    try {
      final repo = ref.read(clanMessageRepositoryProvider);
      if (currentlyBlocked) {
        await repo.unblockUser(uid: myUid, blockedUid: uid);
      } else {
        await repo.blockUser(uid: myUid, blockedUid: uid);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.blockActionFailed)));
    }
  }

  Future<void> _report(ClanMessage message) async {
    final s = ref.read(appStringsProvider);
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.reportMessageTitle),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: s.reportMessageHint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(reasonController.text),
            child: Text(s.reportMessageSubmit),
          ),
        ],
      ),
    );
    if (reason == null) return;

    final myUid = ref.read(appStartupProvider).valueOrNull?.uid;
    if (myUid == null) return;
    try {
      await ref.read(clanMessageRepositoryProvider).reportMessage(
            code: widget.code,
            messageId: message.id,
            reporterUid: myUid,
            reason: reason,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.reportMessageSent)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.reportMessageFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final messagesAsync = ref.watch(clanMessagesProvider(widget.code));
    final blockedUids = ref.watch(myBlockedUsersProvider).valueOrNull ?? const {};
    final myUid = ref.watch(appStartupProvider).valueOrNull?.uid;

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: context.palette.primaryCoral.withValues(alpha: 0.15),
              child: Text(
                widget.clanName.isEmpty ? '👥' : widget.clanName[0].toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: context.palette.primaryCoral,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.clanName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _maybeMarkRead(messages));
                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        s.clanChatEmpty,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.palette.textNavy.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final previous = index > 0 ? messages[index - 1] : null;
                    final showSenderName = message.senderUid != myUid &&
                        previous?.senderUid != message.senderUid;
                    return _MessageBubble(
                      message: message,
                      isMine: message.senderUid == myUid,
                      showSenderName: showSenderName,
                      isBlocked: blockedUids.contains(message.senderUid),
                      strings: s,
                      onBlock: () => _toggleBlock(
                        message.senderUid,
                        blockedUids.contains(message.senderUid),
                      ),
                      onReport: () => _report(message),
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
            ),
          ),
          ChatComposer(
            controller: _controller,
            sending: _sending,
            onSend: _send,
            hint: s.messageHint,
            maxLength: ClanMessageRepository.maxMessageLength,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ClanMessage message;
  final bool isMine;
  final bool showSenderName;
  final bool isBlocked;
  final AppStrings strings;
  final VoidCallback onBlock;
  final VoidCallback onReport;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.showSenderName,
    required this.isBlocked,
    required this.strings,
    required this.onBlock,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final s = strings;
    final bubbleColor = isMine
        ? context.palette.primaryCoral.withValues(alpha: 0.16)
        : context.palette.cardWhite;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: isMine
            ? null
            : () => showModalBottomSheet(
                  context: context,
                  builder: (context) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.block),
                          title: Text(
                            isBlocked ? s.unblockUser : s.blockUser,
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            onBlock();
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.flag_outlined),
                          title: Text(s.reportMessage),
                          onTap: () {
                            Navigator.of(context).pop();
                            onReport();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.fromLTRB(14, 8, 10, 6),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMine ? 16 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showSenderName)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    message.senderName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: context.palette.primaryCoral,
                    ),
                  ),
                ),
              Text(
                isBlocked ? s.blockedMessagePlaceholder : message.text,
                style: TextStyle(
                  color: isBlocked
                      ? context.palette.textNavy.withValues(alpha: 0.4)
                      : context.palette.textNavy,
                  fontStyle: isBlocked ? FontStyle.italic : FontStyle.normal,
                ),
              ),
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: context.palette.textNavy.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour.$minute';
  }
}

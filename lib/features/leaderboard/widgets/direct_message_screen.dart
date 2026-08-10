import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/providers.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/direct_message.dart';
import '../../../data/repositories/direct_message_repository.dart';
import '../friend_providers.dart';
import 'chat_composer.dart';

/// Private 1:1 chat with [friendUid] — see `DirectMessageRepository`'s doc
/// comment for the child-safety reasoning behind why this only opens
/// between accepted friends. Structurally a near-copy of `ClanChatScreen`
/// (same send-cooldown/length-cap/report flow, same `ChatComposer`), minus
/// the block feature: unfriending (`FriendRepository.removeFriend`, an
/// app-bar action right on this screen — there's no separate friend-list
/// screen anymore, chat is reached via `ChatHubScreen`'s picker) is the
/// equivalent action here, and it does something clan chat's block can't —
/// it actually revokes both sides' read/write access at the
/// `firestore.rules` level, not just hides messages client-side.
class DirectMessageScreen extends ConsumerStatefulWidget {
  final String friendUid;
  final String friendName;

  const DirectMessageScreen({
    super.key,
    required this.friendUid,
    required this.friendName,
  });

  @override
  ConsumerState<DirectMessageScreen> createState() =>
      _DirectMessageScreenState();
}

class _DirectMessageScreenState extends ConsumerState<DirectMessageScreen> {
  final _controller = TextEditingController();
  DateTime? _lastSentAt;
  static const _sendCooldown = Duration(seconds: 2);
  bool _sending = false;
  String? _myUid;

  /// Same "only write when the visible latest message actually changes"
  /// guard `ClanChatScreen` uses — see its own doc comment.
  String? _lastMarkedMessageId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  /// **Deliberately does not set [_myUid] until `ensureConversation` has
  /// resolved.** `_myUid` is what `build()` waits on before starting the
  /// live `messages` listen — an earlier version set it immediately, on
  /// the (wrong) assumption that a `messages` read attempted before the
  /// parent `directMessages/{conversationId}` doc existed would just "come
  /// back empty" until the doc showed up. It doesn't: `firestore.rules`'
  /// `messages` read rule does a `get()` on that parent doc, which errors
  /// when the doc is missing, so the very first frame's listener attached
  /// with `PERMISSION_DENIED` — confirmed via on-device logcat showing
  /// exactly that Listen failing — and a Firestore snapshot listener that
  /// starts denied does not retry itself once the doc shows up moments
  /// later; it stays in that error state for the rest of the screen's
  /// life. Waiting here means `build()`'s first `messages` listen only
  /// ever starts once the parent doc is confirmed to exist, so there's no
  /// window for that race.
  Future<void> _init() async {
    final uid = ref.read(appStartupProvider).valueOrNull?.uid;
    if (uid == null) return;
    // Best-effort — if this fails, the messages listen right after will
    // legitimately fail too (the parent doc never got created), which is
    // at least a real, diagnosable permission error rather than a race.
    try {
      await ref.read(directMessageRepositoryProvider).ensureConversation(
            uidA: uid,
            uidB: widget.friendUid,
          );
    } catch (_) {}
    if (!mounted) return;
    setState(() => _myUid = uid);
    // See FcmService.currentOpenChatKey's own doc comment: suppresses the
    // foreground push banner for the exact conversation already on
    // screen, since a redundant notification over a message the learner
    // can already see arrive live would be more annoying than helpful.
    FcmService.currentOpenChatKey =
        'dm:${DirectMessageRepository.conversationId(uid, widget.friendUid)}';
  }

  @override
  void dispose() {
    if (FcmService.currentOpenChatKey ==
        'dm:${DirectMessageRepository.conversationId(_myUid ?? '', widget.friendUid)}') {
      FcmService.currentOpenChatKey = null;
    }
    _controller.dispose();
    super.dispose();
  }

  void _maybeMarkRead(String conversationId, List<DirectMessage> messages) {
    if (messages.isEmpty) return;
    final latestId = messages.last.id;
    if (latestId == _lastMarkedMessageId) return;
    _lastMarkedMessageId = latestId;
    final myUid = ref.read(appStartupProvider).valueOrNull?.uid;
    if (myUid == null) return;
    ref
        .read(directMessageRepositoryProvider)
        .markRead(conversationId, myUid)
        .catchError((_) {});
  }

  Future<void> _send() async {
    final s = ref.read(appStringsProvider);
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    if (text.trim().length > DirectMessageRepository.maxMessageLength) {
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
    final conversationId =
        DirectMessageRepository.conversationId(user.uid, widget.friendUid);

    setState(() => _sending = true);
    try {
      await ref.read(directMessageRepositoryProvider).sendMessage(
            conversationId: conversationId,
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

  Future<void> _report(DirectMessage message, String conversationId) async {
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
      await ref.read(directMessageRepositoryProvider).reportMessage(
            conversationId: conversationId,
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

  Future<void> _removeFriend(String myUid) async {
    final s = ref.read(appStringsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.removeFriendConfirmTitle(widget.friendName)),
        content: Text(s.removeFriendConfirmBody(widget.friendName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.removeFriend),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref
          .read(friendRepositoryProvider)
          .removeFriend(uid: myUid, friendUid: widget.friendUid);
      if (!mounted) return;
      // Unfriending revokes both sides' read/write access to this
      // conversation at the firestore.rules level (see this class's own
      // doc comment) — staying on the chat screen would just show a
      // permission-denied stream error, so leave it instead.
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.removeFriendFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    // Strictly _myUid, no fallback to appStartupProvider directly — see
    // _init's own doc comment for why gating on it (not just "some uid is
    // known") is what actually prevents the messages listener race.
    final myUid = _myUid;

    if (myUid == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.friendName)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final conversationId =
        DirectMessageRepository.conversationId(myUid, widget.friendUid);
    final messagesAsync = ref.watch(directMessagesProvider(conversationId));

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
                widget.friendName.isEmpty
                    ? '🐱'
                    : widget.friendName[0].toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: context.palette.primaryCoral,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.friendName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: s.removeFriend,
            icon: const Icon(Icons.person_remove_outlined),
            onPressed: () => _removeFriend(myUid),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _maybeMarkRead(conversationId, messages),
                );
                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        s.directMessageEmpty,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.palette.textNavy.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _MessageBubble(
                      message: message,
                      isMine: message.senderUid == myUid,
                      strings: s,
                      onReport: () => _report(message, conversationId),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
            ),
          ),
          ChatComposer(
            controller: _controller,
            sending: _sending,
            onSend: _send,
            hint: s.messageHint,
            maxLength: DirectMessageRepository.maxMessageLength,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final DirectMessage message;
  final bool isMine;
  final AppStrings strings;
  final VoidCallback onReport;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.strings,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
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
                    child: ListTile(
                      leading: const Icon(Icons.flag_outlined),
                      title: Text(strings.reportMessage),
                      onTap: () {
                        Navigator.of(context).pop();
                        onReport();
                      },
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
              Text(
                message.text,
                style: TextStyle(color: context.palette.textNavy),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/direct_message.dart';
import '../../../data/repositories/direct_message_repository.dart';
import '../friend_providers.dart';

/// Private 1:1 chat with [friendUid] — see `DirectMessageRepository`'s doc
/// comment for the child-safety reasoning behind why this only opens
/// between accepted friends. Structurally a near-copy of `ClanChatScreen`
/// (same send-cooldown/length-cap/report flow), minus the block feature:
/// unfriending (`FriendRepository.removeFriend`, reached from the Friends
/// tab, not from inside this screen) is the equivalent action here, and it
/// does something clan chat's block can't — it actually revokes both
/// sides' read/write access at the `firestore.rules` level, not just hides
/// messages client-side.
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

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final uid = ref.read(appStartupProvider).valueOrNull?.uid;
    if (uid == null) return;
    if (mounted) setState(() => _myUid = uid);
    // Best-effort — a failed ensure just means the conversation doc gets
    // created lazily on the next open/send attempt instead; the messages
    // read below will simply come back empty until it exists.
    try {
      await ref.read(directMessageRepositoryProvider).ensureConversation(
            uidA: uid,
            uidB: widget.friendUid,
          );
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final myUid = _myUid ?? ref.watch(appStartupProvider).valueOrNull?.uid;

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
      appBar: AppBar(title: Text(widget.friendName)),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
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
                  padding: const EdgeInsets.all(12),
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
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLength: DirectMessageRepository.maxMessageLength,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: s.messageHint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
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
        ? context.palette.primaryCoral.withValues(alpha: 0.15)
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
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message.text,
            style: TextStyle(color: context.palette.textNavy),
          ),
        ),
      ),
    );
  }
}

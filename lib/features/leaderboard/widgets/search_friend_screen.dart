import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/leaderboard_entry.dart';
import '../../../data/models/user_profile.dart' show AvatarType;
import '../leaderboard_screen.dart' show LeaderboardAvatar, globalScoreLabel;

/// Search the public leaderboard by name or exact unique id and send a
/// friend request — the "personal friend" counterpart to
/// `SearchInviteScreen`'s clan-invite flow, same search
/// (`LeaderboardRepository.searchPublicUsers`), different action.
///
/// Requiring the target to actively accept a request before any chat opens
/// is what keeps this different from open messaging — see
/// `DirectMessageRepository`'s doc comment for the full reasoning.
class SearchFriendScreen extends ConsumerStatefulWidget {
  const SearchFriendScreen({super.key});

  @override
  ConsumerState<SearchFriendScreen> createState() =>
      _SearchFriendScreenState();
}

class _SearchFriendScreenState extends ConsumerState<SearchFriendScreen> {
  final _controller = TextEditingController();
  List<LeaderboardEntry>? _results;
  bool _searching = false;
  final Set<String> _sentUids = {};

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() => _results = null);
      return;
    }
    setState(() => _searching = true);
    final myUid = ref.read(appStartupProvider).valueOrNull?.uid;
    final results = await ref
        .read(leaderboardRepositoryProvider)
        .searchPublicUsers(trimmed);
    if (!mounted) return;
    setState(() {
      // Can't friend yourself.
      _results = results.where((e) => e.uid != myUid).toList();
      _searching = false;
    });
  }

  Future<void> _sendRequest(LeaderboardEntry target) async {
    final s = ref.read(appStringsProvider);
    final user = ref.read(appStartupProvider).valueOrNull;
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (user == null) return;

    try {
      await ref.read(friendRepositoryProvider).sendFriendRequest(
            fromUid: user.uid,
            fromName: profile?.resolveDisplayName(user) ??
                (user.displayName ?? s.defaultLearnerName),
            fromPhotoUrl: user.photoURL,
            fromAvatarType: profile?.avatarType ?? AvatarType.google,
            fromAvatarValue: profile?.avatarValue,
            targetUid: target.uid,
          );
      if (!mounted) return;
      setState(() => _sentUids.add(target.uid));
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.friendRequestSent)));
    } on StateError catch (e) {
      if (!mounted) return;
      final message = e.message == 'already_friend'
          ? s.alreadyFriendError
          : e.message == 'already_pending'
              ? s.friendRequestAlreadySentError
              : s.friendRequestSendFailed;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.friendRequestSendFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final results = _results;

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: Text(s.searchFriendTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onSubmitted: _search,
              onChanged: (value) {
                if (value.trim().isEmpty) setState(() => _results = null);
              },
              decoration: InputDecoration(
                hintText: s.searchFriendHint,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _search(_controller.text),
                ),
              ),
            ),
          ),
          if (_searching) const LinearProgressIndicator(),
          Expanded(
            child: results == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        s.searchFriendEmpty,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.palette.textNavy.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  )
                : results.isEmpty
                    ? Center(
                        child: Text(
                          s.searchUserNoResults,
                          style: TextStyle(color: context.palette.textNavy),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: results.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final entry = results[index];
                          final sent = _sentUids.contains(entry.uid);
                          return Material(
                            color: context.palette.cardWhite,
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  LeaderboardAvatar(entry: entry, size: 36),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.displayName,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: context.palette.textNavy,
                                          ),
                                        ),
                                        _SearchResultSubtitle(
                                          entry: entry,
                                          strings: s,
                                        ),
                                      ],
                                    ),
                                  ),
                                  sent
                                      ? Icon(Icons.check_circle,
                                          color: context.palette.successGreen)
                                      : OutlinedButton(
                                          onPressed: () => _sendRequest(entry),
                                          child: Text(s.sendFriendRequestButton),
                                        ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

/// Mirrors `search_invite_screen.dart`'s own `_ResultSubtitle` — kept as a
/// separate small copy rather than a shared export, since the two screens'
/// result rows are otherwise unrelated and this is the only piece either
/// would need from the other.
class _SearchResultSubtitle extends StatelessWidget {
  final LeaderboardEntry entry;
  final AppStrings strings;

  const _SearchResultSubtitle({required this.entry, required this.strings});

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      fontSize: 12,
      color: context.palette.textNavy.withValues(alpha: 0.6),
    );
    final userId = entry.userId;
    if (userId == null) {
      return Text(globalScoreLabel(entry, strings), style: baseStyle);
    }
    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: '${globalScoreLabel(entry, strings)} · '),
          TextSpan(
            text: strings.userIdLabel(userId),
            style: baseStyle.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

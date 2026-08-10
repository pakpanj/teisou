import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/leaderboard_entry.dart';
import '../../../data/models/user_profile.dart' show AvatarType;
import '../leaderboard_screen.dart' show LeaderboardAvatar, globalScoreLabel;

/// The "Cari" tab of `AddFriendScreen` — search the public leaderboard by
/// name or exact unique id and send a friend request. Same search
/// (`LeaderboardRepository.searchPublicUsers`) as `SearchInviteScreen`'s
/// clan-invite flow, different action.
///
/// Requiring the target to actively accept a request before any chat opens
/// is what keeps this different from open messaging — see
/// `DirectMessageRepository`'s doc comment for the full reasoning.
///
/// Body-only (no `Scaffold`/`AppBar` of its own) — it used to be a
/// standalone `SearchFriendScreen`, but `AddFriendScreen` now hosts it
/// as one of two tabs alongside incoming requests, so the app bar lives
/// there instead.
class SearchFriendTab extends ConsumerStatefulWidget {
  const SearchFriendTab({super.key});

  @override
  ConsumerState<SearchFriendTab> createState() => _SearchFriendTabState();
}

class _SearchFriendTabState extends ConsumerState<SearchFriendTab> {
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

    return Column(
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
              filled: true,
              fillColor: context.palette.cardWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: results.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final entry = results[index];
                        final sent = _sentUids.contains(entry.uid);
                        return Container(
                          decoration: BoxDecoration(
                            color: context.palette.cardWhite,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                LeaderboardAvatar(entry: entry, size: 40),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.displayName,
                                        maxLines: 1,
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
                                const SizedBox(width: 8),
                                sent
                                    ? Icon(Icons.check_circle,
                                        color: context.palette.successGreen)
                                    : OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
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
      return Text(
        globalScoreLabel(entry, strings),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: baseStyle,
      );
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
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

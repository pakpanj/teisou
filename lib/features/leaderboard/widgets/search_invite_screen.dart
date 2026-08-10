import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/leaderboard_entry.dart';
import '../leaderboard_screen.dart' show LeaderboardAvatar, globalScoreLabel;

/// Search the public leaderboard by name and send a clan invite — the
/// leader/co-leader path for "mengundang user public" (inviting a specific
/// learner directly, as opposed to just handing out the join code, which
/// stays available too via `CreateClanDialog`'s share-code flow).
///
/// Deliberately a plain name search, not a live-invite-status list — an
/// invite's own success/failure is reported per tap via a SnackBar, and
/// `myPendingInvitesProvider` is what the *invited* learner watches to see
/// it; this screen has no reason to track who's already been invited.
class SearchInviteScreen extends ConsumerStatefulWidget {
  final String code;
  final String clanName;

  const SearchInviteScreen({
    super.key,
    required this.code,
    required this.clanName,
  });

  @override
  ConsumerState<SearchInviteScreen> createState() =>
      _SearchInviteScreenState();
}

class _SearchInviteScreenState extends ConsumerState<SearchInviteScreen> {
  final _controller = TextEditingController();
  List<LeaderboardEntry>? _results;
  bool _searching = false;
  final Set<String> _invitedUids = {};

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
      // Can't invite yourself.
      _results = results.where((e) => e.uid != myUid).toList();
      _searching = false;
    });
  }

  Future<void> _invite(LeaderboardEntry target) async {
    final s = ref.read(appStringsProvider);
    final user = ref.read(appStartupProvider).valueOrNull;
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (user == null) return;

    try {
      await ref.read(clanRepositoryProvider).sendInvite(
            code: widget.code,
            clanName: widget.clanName,
            targetUid: target.uid,
            invitedByUid: user.uid,
            invitedByName: profile?.resolveDisplayName(user) ??
                (user.displayName ?? s.defaultLearnerName),
          );
      if (!mounted) return;
      setState(() => _invitedUids.add(target.uid));
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.inviteSent)));
    } on StateError {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.alreadyMemberError)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.inviteSendFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final results = _results;

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: Text(s.inviteMember)),
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
                hintText: s.searchUserHint,
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
                        s.searchUserEmpty,
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
                          final invited = _invitedUids.contains(entry.uid);
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
                                        Text(
                                          globalScoreLabel(entry, s),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: context.palette.textNavy
                                                .withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  invited
                                      ? Icon(Icons.check_circle,
                                          color: context.palette.successGreen)
                                      : OutlinedButton(
                                          onPressed: () => _invite(entry),
                                          child: Text(s.inviteButton),
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

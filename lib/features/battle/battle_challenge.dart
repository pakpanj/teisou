import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/providers.dart';
import '../../core/services/battle_deck_builder.dart';
import '../../core/theme/app_palette.dart';
import '../../data/models/battle_invite.dart';
import '../../data/models/card_game_rank.dart';
import '../../data/models/user_profile.dart' show AvatarType;
import 'battle_invite_providers.dart';
import 'battle_invite_waiting_screen.dart';
import 'battle_screen.dart';

/// Human-readable label for a [CardTierContent] — the same 5 values
/// `CardGameTierX.cardContent` maps a rank tier to, but shown here as a
/// free pick for a friend/clan challenge (see
/// `NOTES_CARD_GAME_MODE.md`'s "Kecuali lawan teman dan clan — di sana
/// kartunya bebas dipilih").
String cardTierContentLabel(CardTierContent content, AppStrings s) {
  switch (content) {
    case CardTierContent.hiragana:
      return s.battleTierHiragana;
    case CardTierContent.katakanaAndKanaCombo:
      return s.battleTierKatakanaCombo;
    case CardTierContent.kanjiN5:
      return s.battleTierKanjiN5;
    case CardTierContent.kanjiN4N3:
      return s.battleTierKanjiN4N3;
    case CardTierContent.kanjiN2N1:
      return s.battleTierKanjiN2N1;
  }
}

/// Sends a "Tantang" challenge to [targetUid] and, on success, drops the
/// challenger straight into the match — see `BattleInvite.matchId`'s own
/// doc comment for why the match is created *before* the invite
/// document, not after the target accepts.
///
/// Call from a friend row or a clan member row; both just need a
/// `targetUid`/`targetName` and which [BattleInviteSource] they came
/// from. Shows its own tier-picker bottom sheet, a non-dismissible
/// "sending" dialog while the multi-step write runs, and a SnackBar on
/// failure — callers don't need any loading state of their own.
Future<void> sendBattleChallenge({
  required BuildContext context,
  required WidgetRef ref,
  required String targetUid,
  required String targetName,
  required BattleInviteSource source,
}) async {
  final s = ref.read(appStringsProvider);
  final content = await showModalBottomSheet<CardTierContent>(
    context: context,
    builder: (sheetContext) => _TierPickerSheet(
      title: s.battleChallengeTitle(targetName),
      subtitle: s.battleChallengePickTier,
    ),
  );
  if (content == null || !context.mounted) return;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      content: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(s.battleChallengeSending)),
        ],
      ),
    ),
  );

  String? matchId;
  DateTime? expiresAt;
  try {
    final myUid = ref.read(appStartupProvider).valueOrNull?.uid;
    final myUser = ref.read(appStartupProvider).valueOrNull;
    final myProfile = ref.read(userProfileProvider).valueOrNull;
    if (myUid == null) throw StateError('not signed in');

    final myName =
        myProfile?.resolveDisplayName(myUser) ??
        (myUser?.displayName ?? s.defaultLearnerName);
    final myPhotoUrl = myUser?.photoURL;
    final myAvatarType = myProfile?.avatarType ?? AvatarType.google;
    final myAvatarValue = myProfile?.avatarValue;

    final cardData = await ref.read(battleCardDataProvider.future);
    final myDeck = buildDeckIds(
      content: content,
      allKana: cardData.$1,
      allKanji: cardData.$2,
    );
    final targetDeck = buildDeckIds(
      content: content,
      allKana: cardData.$1,
      allKanji: cardData.$2,
    );

    matchId = await ref
        .read(battleRepositoryProvider)
        .createMatch(
          firstCandidateUid: myUid,
          firstCandidateDeck: myDeck,
          secondCandidateUid: targetUid,
          secondCandidateDeck: targetDeck,
          cardTierContent: content,
          rankedMatch: false,
          // Nobody plays until the other side says yes, and the round
          // clock stays parked until they do — see
          // `BattleInviteWaitingScreen` for what this used to look like.
          awaitingAccept: true,
        );

    final now = DateTime.now();
    expiresAt = now.add(const Duration(minutes: 2));
    await ref
        .read(battleInviteRepositoryProvider)
        .sendInvite(
          targetUid: targetUid,
          invite: BattleInvite(
            id: '',
            fromUid: myUid,
            fromName: myName,
            fromPhotoUrl: myPhotoUrl,
            fromAvatarType: myAvatarType,
            fromAvatarValue: myAvatarValue,
            source: source,
            cardTierContent: content,
            matchId: matchId,
            createdAt: now,
            expiresAt: expiresAt,
          ),
        );

    await ref
        .read(notificationRepositoryProvider)
        .create(
          targetUid,
          title: s.battleChallengeNotificationTitle(myName),
          body: s.battleChallengeNotificationBody(
            cardTierContentLabel(content, s),
          ),
          category: 'battle_invite',
        );
  } catch (_) {
    if (context.mounted) Navigator.of(context).pop(); // close sending dialog
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.battleChallengeFailed)));
    }
    return;
  }

  if (!context.mounted) return;
  Navigator.of(context).pop(); // close sending dialog
  // Wait, rather than walking into the arena alone — the whole point of
  // this screen. See its doc comment for what the old straight-to-match
  // push actually did.
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => BattleInviteWaitingScreen(
        matchId: matchId!,
        targetName: targetName,
        expiresAt: expiresAt!,
      ),
    ),
  );
}

/// A small "⚔️ Tantang" icon button, reused by the friend list
/// (`chat_hub_screen.dart`) and the clan member list
/// (`clan_members_screen.dart`) — calls [sendBattleChallenge] on tap.
/// Gated on live presence (`NOTES_CARD_GAME_MODE.md`'s "Tombol 'Tantang'
/// hanya aktif kalau target online"): greyed out and untappable, with a
/// tooltip explaining why, whenever the target isn't currently online.
class ChallengeButton extends ConsumerWidget {
  final String targetUid;
  final String targetName;
  final BattleInviteSource source;

  const ChallengeButton({
    super.key,
    required this.targetUid,
    required this.targetName,
    required this.source,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final online =
        ref.watch(presenceProvider(targetUid)).valueOrNull?.isOnline ?? false;

    return IconButton(
      tooltip: online
          ? s.battleChallengeTitle(targetName)
          : s.battleChallengeOfflineTooltip,
      icon: Icon(
        Icons.sports_esports,
        color: online
            ? context.palette.primaryCoral
            : context.palette.textNavy.withValues(alpha: 0.25),
      ),
      onPressed: online
          ? () => sendBattleChallenge(
              context: context,
              ref: ref,
              targetUid: targetUid,
              targetName: targetName,
              source: source,
            )
          : null,
    );
  }
}

class _TierPickerSheet extends ConsumerWidget {
  final String title;
  final String subtitle;

  const _TierPickerSheet({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: context.palette.textNavy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: context.palette.textNavy.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 12),
            for (final content in CardTierContent.values)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(cardTierContentLabel(content, s)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).pop(content),
              ),
          ],
        ),
      ),
    );
  }
}

/// Pending "Tantang" challenges for the signed-in learner — lives on Card
/// Battle's own Battle tab, alongside [BattleChallengeScreen]. Used to sit
/// on Profile's `ChatHubScreen` instead; moved here for the same reason
/// challenging itself moved — accepting into a match is a Card Battle
/// action, not a chat one. A challenge can arrive from either a friend or
/// a clan mate and is time-sensitive (2-minute expiry, see
/// `BattleInvite.expiresAt`), so this shows regardless of which of the two
/// sent it. Collapses to nothing when there are none, same "never a
/// permanent slice of the screen" discipline as Clan tab's own
/// `_PendingInvitesStrip`.
class PendingBattleInvitesStrip extends ConsumerWidget {
  const PendingBattleInvitesStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitesAsync = ref.watch(myPendingBattleInvitesProvider);
    final invites = invitesAsync.valueOrNull ?? const [];
    if (invites.isEmpty) return const SizedBox.shrink();

    final s = ref.watch(appStringsProvider);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.palette.primaryCoral.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.pendingBattleInvitesTitle(invites.length),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: context.palette.textNavy,
            ),
          ),
          for (final invite in invites)
            _BattleInviteRow(invite: invite, strings: s),
        ],
      ),
    );
  }
}

class _BattleInviteRow extends ConsumerStatefulWidget {
  final BattleInvite invite;
  final AppStrings strings;

  const _BattleInviteRow({required this.invite, required this.strings});

  @override
  ConsumerState<_BattleInviteRow> createState() => _BattleInviteRowState();
}

class _BattleInviteRowState extends ConsumerState<_BattleInviteRow> {
  bool _responding = false;

  Future<void> _decline() async {
    final uid = ref.read(appStartupProvider).valueOrNull?.uid;
    if (uid == null) return;
    setState(() => _responding = true);
    try {
      // The match first, so the challenger stops waiting now rather than
      // sitting out the invite's full two minutes for an answer that has
      // already been given. Best-effort — a failure here only costs them
      // that wait, and must not stop the row from being dismissed.
      try {
        await ref
            .read(battleRepositoryProvider)
            .respondToMatchInvite(
              matchId: widget.invite.matchId,
              accept: false,
            );
      } catch (_) {}
      await ref
          .read(battleInviteRepositoryProvider)
          .respondToInvite(uid: uid, invite: widget.invite, accept: false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _responding = false);
    }
    // On success the row disappears on its own via watchMyInvites' own
    // `status == pending` filter — nothing else to reset here.
  }

  Future<void> _accept() async {
    final uid = ref.read(appStartupProvider).valueOrNull?.uid;
    if (uid == null) return;
    setState(() => _responding = true);

    // Claiming the match is **not** fire-and-forget, unlike the invite
    // row's own status below. It is what releases the waiting challenger
    // into the arena, and it is what starts the round clock — joining
    // without it means playing alone against a clock that never began.
    // It can also legitimately fail: the challenger may have cancelled a
    // moment earlier, and then there is no match left to join.
    bool claimed;
    try {
      claimed = await ref
          .read(battleRepositoryProvider)
          .respondToMatchInvite(matchId: widget.invite.matchId, accept: true);
    } catch (_) {
      claimed = false;
    }
    if (!mounted) return;
    if (!claimed) {
      setState(() => _responding = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.strings.battleInviteGoneAway)),
      );
      return;
    }

    try {
      // This one stays fire-and-forget: the invite row's status only
      // decides how long it lingers in the pending list, and the match
      // has already been joined by the time that matters.
      unawaited(
        ref
            .read(battleInviteRepositoryProvider)
            .respondToInvite(uid: uid, invite: widget.invite, accept: true),
      );
    } catch (_) {
      // Deliberately swallowed — see the comment above.
    }
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BattleScreen(matchId: widget.invite.matchId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tierLabel = cardTierContentLabel(
      widget.invite.cardTierContent,
      widget.strings,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.strings.battleInvitedBy(widget.invite.fromName, tierLabel),
              style: TextStyle(color: context.palette.textNavy, fontSize: 13),
            ),
          ),
          if (_responding)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else ...[
            TextButton(
              onPressed: _decline,
              child: Text(widget.strings.declineInvite),
            ),
            FilledButton(
              onPressed: _accept,
              child: Text(widget.strings.acceptInvite),
            ),
          ],
        ],
      ),
    );
  }
}

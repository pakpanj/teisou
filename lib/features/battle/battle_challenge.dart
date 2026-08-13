import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/providers.dart';
import '../../core/services/battle_deck_builder.dart';
import '../../core/theme/app_palette.dart';
import '../../data/models/battle_invite.dart';
import '../../data/models/card_game_rank.dart';
import '../../data/models/user_profile.dart' show AvatarType;
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
  try {
    final myUid = ref.read(appStartupProvider).valueOrNull?.uid;
    final myUser = ref.read(appStartupProvider).valueOrNull;
    final myProfile = ref.read(userProfileProvider).valueOrNull;
    if (myUid == null) throw StateError('not signed in');

    final myName = myProfile?.resolveDisplayName(myUser) ??
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

    matchId = await ref.read(battleRepositoryProvider).createMatch(
          firstCandidateUid: myUid,
          firstCandidateDeck: myDeck,
          secondCandidateUid: targetUid,
          secondCandidateDeck: targetDeck,
          cardTierContent: content,
          rankedMatch: false,
        );

    final now = DateTime.now();
    await ref.read(battleInviteRepositoryProvider).sendInvite(
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
            expiresAt: now.add(const Duration(minutes: 2)),
          ),
        );

    await ref.read(notificationRepositoryProvider).create(
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.battleChallengeFailed)));
    }
    return;
  }

  if (!context.mounted) return;
  Navigator.of(context).pop(); // close sending dialog
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => BattleScreen(matchId: matchId!)),
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

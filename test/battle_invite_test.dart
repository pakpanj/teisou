import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/localization/app_strings.dart';
import 'package:kana_master/data/models/app_language.dart';
import 'package:kana_master/data/models/battle_invite.dart';
import 'package:kana_master/data/models/card_game_rank.dart';
import 'package:kana_master/features/battle/battle_challenge.dart';

void main() {
  group('BattleInviteStatus', () {
    test('key/fromKey round-trip for every status', () {
      for (final status in BattleInviteStatus.values) {
        expect(BattleInviteStatusX.fromKey(status.key), status);
      }
    });

    test('fromKey falls back to pending for null or unknown keys', () {
      expect(BattleInviteStatusX.fromKey(null), BattleInviteStatus.pending);
      expect(
        BattleInviteStatusX.fromKey('nonsense'),
        BattleInviteStatus.pending,
      );
    });
  });

  group('BattleInviteSource', () {
    test('key/fromKey round-trip for every source', () {
      for (final source in BattleInviteSource.values) {
        expect(BattleInviteSourceX.fromKey(source.key), source);
      }
    });

    test('fromKey falls back to friend for null or unknown keys', () {
      expect(BattleInviteSourceX.fromKey(null), BattleInviteSource.friend);
      expect(
        BattleInviteSourceX.fromKey('nonsense'),
        BattleInviteSource.friend,
      );
    });
  });

  group('BattleInvite', () {
    test('fromMap parses a full document, including nested tier/matchId',
        () {
      final now = DateTime(2026, 8, 14, 12);
      final invite = BattleInvite.fromMap('invite-1', {
        'fromUid': 'uid-a',
        'fromName': 'Budi',
        'fromPhotoUrl': null,
        'fromAvatarType': 'google',
        'fromAvatarValue': null,
        'source': 'clan',
        'cardTierContent': 'kanjiN5',
        'matchId': 'match-1',
        'status': 'pending',
        'createdAt': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(now.add(const Duration(minutes: 2))),
      });
      expect(invite.id, 'invite-1');
      expect(invite.fromUid, 'uid-a');
      expect(invite.fromName, 'Budi');
      expect(invite.source, BattleInviteSource.clan);
      expect(invite.cardTierContent, CardTierContent.kanjiN5);
      expect(invite.matchId, 'match-1');
      expect(invite.status, BattleInviteStatus.pending);
    });

    test('fromMap defaults missing fields rather than throwing', () {
      final invite = BattleInvite.fromMap('invite-2', {});
      expect(invite.fromUid, '');
      expect(invite.source, BattleInviteSource.friend);
      expect(invite.cardTierContent, CardTierContent.hiragana);
      expect(invite.matchId, '');
      expect(invite.status, BattleInviteStatus.pending);
    });

    test('toMap carries every field with the right key shape', () {
      final now = DateTime(2026, 8, 14, 12);
      final invite = BattleInvite(
        id: '',
        fromUid: 'uid-a',
        fromName: 'Budi',
        source: BattleInviteSource.friend,
        cardTierContent: CardTierContent.kanjiN4N3,
        matchId: 'match-2',
        createdAt: now,
        expiresAt: now.add(const Duration(minutes: 2)),
      );
      final map = invite.toMap();
      expect(map['fromUid'], 'uid-a');
      expect(map['source'], 'friend');
      expect(map['cardTierContent'], 'kanjiN4N3');
      expect(map['matchId'], 'match-2');
      expect(map['status'], 'pending');
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['expiresAt'], isA<Timestamp>());
    });

    test('isExpired is true once expiresAt is in the past', () {
      final expired = BattleInvite(
        id: '',
        fromUid: 'uid-a',
        fromName: 'Budi',
        source: BattleInviteSource.friend,
        cardTierContent: CardTierContent.hiragana,
        matchId: 'match-3',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        expiresAt: DateTime.now().subtract(const Duration(minutes: 3)),
      );
      expect(expired.isExpired, isTrue);

      final active = BattleInvite(
        id: '',
        fromUid: 'uid-a',
        fromName: 'Budi',
        source: BattleInviteSource.friend,
        cardTierContent: CardTierContent.hiragana,
        matchId: 'match-4',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 2)),
      );
      expect(active.isExpired, isFalse);
    });
  });

  group('cardTierContentLabel', () {
    test('every CardTierContent value has a distinct, non-empty label in '
        'both languages', () {
      const id = AppStrings(AppLanguage.indonesian);
      const en = AppStrings(AppLanguage.english);
      for (final strings in [id, en]) {
        final labels = CardTierContent.values
            .map((content) => cardTierContentLabel(content, strings))
            .toList();
        expect(labels.every((label) => label.isNotEmpty), isTrue);
        expect(labels.toSet().length, labels.length);
      }
    });
  });
}

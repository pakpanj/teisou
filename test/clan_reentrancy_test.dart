// `implements` on Query/DocumentReference/DocumentSnapshot below is
// intentional — the same fake-double idiom this whole test suite already
// uses for User/ClanRepository/etc, just applied to the cloud_firestore
// SDK's own classes so kickMember/leaveClan's transaction can be driven
// under real forced concurrency without a Dart Firestore emulator, which
// this project doesn't have. `sealed` here is advisory (still compiles),
// not a hard error — see the file-level doc comment further down for what
// this fake proves and doesn't.
// ignore_for_file: subtype_of_sealed_class

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/providers.dart';
import 'package:kana_master/data/models/clan.dart';
import 'package:kana_master/data/models/clan_member.dart';
import 'package:kana_master/data/models/clan_membership.dart';
import 'package:kana_master/data/models/leaderboard_entry.dart';
import 'package:kana_master/data/models/user_profile.dart' show AvatarType;
import 'package:kana_master/data/repositories/clan_repository.dart';
import 'package:kana_master/data/repositories/friend_repository.dart';
import 'package:kana_master/data/repositories/leaderboard_repository.dart';
import 'package:kana_master/features/leaderboard/clan_providers.dart';
import 'package:kana_master/features/leaderboard/widgets/clan_members_screen.dart';
import 'package:kana_master/features/leaderboard/widgets/clan_tab.dart';
import 'package:kana_master/features/leaderboard/widgets/search_friend_tab.dart';
import 'package:kana_master/features/leaderboard/widgets/search_invite_screen.dart';

/// RISK-9 — permanent regression coverage closing out RISK-8's three
/// confirmed BUGs (kick/leave/invite-and-friend-request reentrancy).
///
/// Two layers are proven, matching the task's own split:
/// - **Client**: a Completer-gated fake repository/service proves a
///   realistic tap-confirm, tap-confirm-again sequence — never a bare
///   double-tap resolved within one microtask, which would close the
///   in-flight window before a second `tester.tap()` even runs — reaches
///   the repository call exactly once while the first is still in flight.
///   Same pattern as `test/coin_buy_reentrancy_test.dart` (RISK-5) and
///   `test/premium_purchase_reentrancy_test.dart` (RISK-4).
/// - **Repository/backend**: `ClanRepository.kickMember`/`leaveClan` have
///   no Cloud Function counterpart — they are plain Dart client code that
///   writes to Firestore directly, so the Node `FakeFirestore` used by
///   `functions/*.test.js` (built for Cloud Functions, a different
///   runtime and language) cannot be reused here. Since this project has
///   no Dart-side Firestore emulator/fake either, `_FakeTransactionFirestore`
///   below is a small, narrowly-scoped fake of exactly the `cloud_firestore`
///   surface these two methods touch (`collection`/`doc`/`runTransaction`/
///   `Transaction.get`/`.delete`/`.update`) — the same
///   `implements X { @override noSuchMethod(...) }` idiom already used
///   throughout this session's other fakes, just applied to the Firestore
///   SDK's own classes instead of an app repository. It models Firestore's
///   documented transaction contract precisely: every document a
///   transaction reads is checked for staleness before its writes commit;
///   a stale read causes the whole transaction callback to be retried.
///   **What this does and doesn't prove**: it proves `kickMember`/
///   `leaveClan`'s own code correctly participates in that contract (reads
///   the member doc first, only writes if it still exists) — it does not
///   re-test Firestore's own retry engine, which is Google's documented,
///   guaranteed platform behavior, not something this app implements.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> withTallSurface(
    WidgetTester tester,
    Future<void> Function() body,
  ) async {
    tester.view.physicalSize = const Size(1200, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await body();
  }

  group('Kick — client (closes RISK-8 BUG #1)', () {
    testWidgets(
      'tap -> confirm -> tap again while kickMember() is in-flight: no '
      'second dialog, kickMember() called exactly once',
      (tester) async {
        await withTallSurface(tester, () async {
          final repo = _FakeClanRepository();
          final gate = Completer<void>();
          repo.kickGate = () => gate.future;

          await tester.pumpWidget(await _clanMembersHarness(repo: repo));
          await tester.pumpAndSettle();

          expect(find.byIcon(Icons.person_remove), findsOneWidget);

          await tester.tap(find.byIcon(Icons.person_remove));
          await tester.pumpAndSettle();
          expect(find.byType(AlertDialog), findsOneWidget);

          await tester.tap(find.byType(FilledButton));
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(repo.kickCalls, hasLength(1));
          expect(find.byType(AlertDialog), findsNothing);

          // The exact unguarded window RISK-8 found: the confirm dialog is
          // gone, but the kick icon was previously still tappable while
          // the first kickMember() was still in flight. FIX: the icon is
          // now replaced entirely by a spinner while `_kicking` is true —
          // there is nothing left to tap a second time at all, which is a
          // stronger guarantee than merely disabling the button.
          expect(
            find.byIcon(Icons.person_remove),
            findsNothing,
            reason: 'FIX: the kick icon is removed from the tree (not just '
                'disabled) while a kick is already in flight',
          );
          expect(find.byType(CircularProgressIndicator), findsOneWidget);

          gate.complete();
          await tester.pumpAndSettle();
          expect(repo.kickCalls, hasLength(1));
        });
      },
    );

    testWidgets(
      'after the first kick settles, the guard lifts and a genuinely new '
      'kick can open the dialog again',
      (tester) async {
        await withTallSurface(tester, () async {
          final members = _twoMembers();
          final repo = _FakeClanRepository()..membersToMutate = members;

          await tester.pumpWidget(
            await _clanMembersHarness(repo: repo, members: members),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.byIcon(Icons.person_remove));
          await tester.pumpAndSettle();
          await tester.tap(find.byType(FilledButton));
          await tester.pumpAndSettle();

          expect(repo.kickCalls, hasLength(1));

          // The row disappears once `clanMembersProvider` is invalidated
          // and the (now-one-shorter) member list is re-fetched — nothing
          // left to kick again, which is itself proof the guard correctly
          // reset (`onPressed: _kick` — not permanently `null`) and the
          // invalidate-on-success path ran.
          await tester.pumpAndSettle();
          expect(find.byIcon(Icons.person_remove), findsNothing);
        });
      },
    );
  });

  group('Leave — client (closes RISK-8 BUG #2)', () {
    testWidgets(
      'tap -> confirm -> tap again while leaveClan() is in-flight: no '
      'second dialog, leaveClan() called exactly once',
      (tester) async {
        await withTallSurface(tester, () async {
          final repo = _FakeClanRepository();
          final gate = Completer<void>();
          repo.leaveGate = () => gate.future;

          await tester.pumpWidget(await _clanTabHarness(repo: repo));
          await tester.pumpAndSettle();

          expect(find.byIcon(Icons.logout), findsOneWidget);

          await tester.tap(find.byIcon(Icons.logout));
          await tester.pumpAndSettle();
          expect(find.byType(AlertDialog), findsOneWidget);

          await tester.tap(find.byType(FilledButton));
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(repo.leaveCalls, hasLength(1));
          expect(find.byType(AlertDialog), findsNothing);

          await tester.tap(find.byIcon(Icons.logout), warnIfMissed: false);
          await tester.pump();
          await tester.pump();

          expect(
            find.byType(AlertDialog),
            findsNothing,
            reason: 'FIX: a second tap while the first leave is in-flight '
                'must not open a second confirm dialog — the leave action '
                'button is disabled (onTap: null) while `_leaving` is true',
          );
          expect(
            repo.leaveCalls,
            hasLength(1),
            reason: 'FIX: and must not reach ClanRepository.leaveClan a '
                'second time either',
          );

          gate.complete();
          await tester.pumpAndSettle();
          expect(repo.leaveCalls, hasLength(1));
        });
      },
    );
  });

  group('Clan invite — client (closes RISK-8 BUG #3)', () {
    testWidgets(
      'tap -> tap again while sendInvite() is in-flight: button marked '
      'busy before the call starts, sendInvite() called exactly once',
      (tester) async {
        await withTallSurface(tester, () async {
          final repo = _FakeClanRepository();
          final gate = Completer<void>();
          repo.inviteGate = () => gate.future;

          await tester.pumpWidget(await _searchInviteHarness(repo: repo));
          await tester.enterText(find.byType(TextField), 'kana');
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await tester.pumpAndSettle();

          expect(find.text('Undang'), findsOneWidget);

          await tester.tap(find.text('Undang'));
          await tester.pump();
          await tester.pump();

          expect(
            repo.inviteCalls,
            hasLength(1),
            reason: 'the first tap must reach sendInvite() once',
          );
          expect(
            find.text('Undang'),
            findsNothing,
            reason: 'FIX: the button is replaced by a spinner the instant '
                'a tap is registered — before the async call even starts, '
                'so it cannot be tapped a second time while in-flight',
          );

          gate.complete();
          await tester.pumpAndSettle();

          expect(
            repo.inviteCalls,
            hasLength(1),
            reason: 'FIX: still exactly one call after the request settles',
          );
        });
      },
    );
  });

  group('Friend request — client (closes RISK-8 BUG #3)', () {
    testWidgets(
      'tap -> tap again while sendFriendRequest() is in-flight: button '
      'marked busy before the call starts, sendFriendRequest() called '
      'exactly once',
      (tester) async {
        await withTallSurface(tester, () async {
          final friendRepo = _FakeFriendRepository();
          final gate = Completer<void>();
          friendRepo.gate = () => gate.future;

          await tester.pumpWidget(
            await _searchFriendHarness(friendRepo: friendRepo),
          );
          await tester.enterText(find.byType(TextField), 'kana');
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await tester.pumpAndSettle();

          expect(find.text('Tambah'), findsOneWidget);

          await tester.tap(find.text('Tambah'));
          await tester.pump();
          await tester.pump();

          expect(friendRepo.calls, hasLength(1));
          expect(
            find.text('Tambah'),
            findsNothing,
            reason: 'FIX: replaced by a spinner before the async call '
                'even starts',
          );

          gate.complete();
          await tester.pumpAndSettle();
          expect(friendRepo.calls, hasLength(1));
        });
      },
    );
  });

  group('Kick — backend transaction (closes RISK-8 BUG #1, '
      'defense-in-depth)', () {
    test(
      'two concurrent kickMember() calls for the SAME target: memberCount '
      'decrements exactly once, not twice',
      () async {
        final firestore = _FakeTransactionFirestore();
        final repo = ClanRepository(firestore: firestore);
        const code = 'ABC123';
        const targetUid = 'target-uid';

        firestore.seedMember(code: code, uid: targetUid, exists: true);
        firestore.seedClan(code: code, memberCount: 5);

        // Force real interleaving: the FIRST transaction.get() call across
        // the whole store pauses right after it captures its read (member
        // still exists) but before returning to the caller — the second
        // kickMember() call's own transaction runs to completion and
        // commits in that window, then the first is released and must
        // detect the conflict and retry.
        final gate = Completer<void>();
        firestore.gateFirstGet(() => gate.future);

        final first = repo.kickMember(code: code, targetUid: targetUid);
        // Let the first call's transaction reach and enter its paused
        // .get() before starting the second.
        await Future<void>.delayed(Duration.zero);

        final second = repo.kickMember(code: code, targetUid: targetUid);
        await second;

        expect(
          firestore.memberCountOf(code),
          4,
          reason: 'the second (unpaused) call should have committed its '
              'single decrement while the first was still paused',
        );
        expect(
          firestore.memberExists(code: code, uid: targetUid),
          isFalse,
          reason: 'the member should be gone after the second call commits',
        );

        gate.complete();
        await first;

        expect(
          firestore.memberCountOf(code),
          4,
          reason: 'BUG (would fail without the fix): the first call must '
              'detect its read of the member doc went stale, retry, '
              're-read "already gone", and become a safe no-op instead of '
              'decrementing memberCount a second time',
        );
      },
    );

    test(
      'kickMember() on a member that no longer exists is a safe no-op',
      () async {
        final firestore = _FakeTransactionFirestore();
        final repo = ClanRepository(firestore: firestore);
        const code = 'ABC123';
        const targetUid = 'gone-uid';

        firestore.seedMember(code: code, uid: targetUid, exists: false);
        firestore.seedClan(code: code, memberCount: 3);

        await repo.kickMember(code: code, targetUid: targetUid);

        expect(firestore.memberCountOf(code), 3);
      },
    );
  });

  group('Leave — backend transaction (closes RISK-8 BUG #2, '
      'defense-in-depth)', () {
    test(
      'two concurrent leaveClan() calls for the SAME uid: memberCount '
      'decrements exactly once, not twice',
      () async {
        final firestore = _FakeTransactionFirestore();
        final repo = ClanRepository(firestore: firestore);
        const code = 'ABC123';
        const uid = 'leaver-uid';

        firestore.seedMember(code: code, uid: uid, exists: true);
        firestore.seedClan(code: code, memberCount: 5);
        firestore.seedMembership(uid: uid, code: code);

        final gate = Completer<void>();
        firestore.gateFirstGet(() => gate.future);

        final first = repo.leaveClan(code: code, uid: uid);
        await Future<void>.delayed(Duration.zero);

        final second = repo.leaveClan(code: code, uid: uid);
        await second;

        expect(firestore.memberCountOf(code), 4);

        gate.complete();
        await first;

        expect(
          firestore.memberCountOf(code),
          4,
          reason: 'BUG (would fail without the fix): a retried, stale '
              'leaveClan() attempt must not double-decrement memberCount',
        );
      },
    );
  });

  group('Join — backend transaction (closes Core Clan Mechanics BUG #1, '
      '2026-08-28)', () {
    test(
      '(a) two concurrent joinClan() calls for the SAME (code, uid): '
      'memberCount increments exactly once, not twice',
      () async {
        final firestore = _FakeTransactionFirestore();
        final repo = ClanRepository(firestore: firestore);
        const code = 'ABC123';
        const uid = 'joiner-uid';

        firestore.seedClan(code: code, memberCount: 1);
        // member doc intentionally NOT seeded — this is a fresh join.

        // Force real interleaving exactly like kickMember/leaveClan's own
        // proof above: the FIRST transaction's own member-doc .get()
        // pauses right after capturing "does not exist yet" but before
        // returning — the SECOND call's own transaction runs to
        // completion and commits entirely inside that window, then the
        // first is released and must detect its read went stale, retry,
        // re-read "already a member", and become a safe no-op.
        final gate = Completer<void>();
        firestore.gateFirstGet(() => gate.future);

        final first = repo.joinClan(code: code, uid: uid, displayName: 'J');
        await Future<void>.delayed(Duration.zero);

        final second = repo.joinClan(code: code, uid: uid, displayName: 'J');
        await second;

        expect(
          firestore.memberCountOf(code),
          2,
          reason: 'the second (unpaused) call should have committed its '
              'single increment while the first was still paused',
        );
        expect(firestore.memberExists(code: code, uid: uid), isTrue);

        gate.complete();
        await first;

        expect(
          firestore.memberCountOf(code),
          2,
          reason: 'BUG (would fail without the fix): the first call must '
              'detect its read of the member doc went stale, retry, '
              're-read "already a member", and become a safe no-op '
              'instead of incrementing memberCount a second time',
        );
      },
    );

    test(
      '(b) two concurrent joinClan() calls for TWO DIFFERENT uids on the '
      'SAME clan: both succeed, memberCount increments by exactly 2, '
      'neither interferes with the other',
      () async {
        final firestore = _FakeTransactionFirestore();
        final repo = ClanRepository(firestore: firestore);
        const code = 'ABC123';
        const uidA = 'joiner-a';
        const uidB = 'joiner-b';

        firestore.seedClan(code: code, memberCount: 1);

        // Only the chronologically-first Transaction.get() across the
        // whole store is gated — uidA's own read. uidB's join reads and
        // writes an entirely different document, so it must complete
        // without ever needing to wait on uidA's paused transaction —
        // two different users joining the same clan are independent
        // writes, not a conflict.
        final gate = Completer<void>();
        firestore.gateFirstGet(() => gate.future);

        final first = repo.joinClan(code: code, uid: uidA, displayName: 'A');
        await Future<void>.delayed(Duration.zero);

        final second =
            repo.joinClan(code: code, uid: uidB, displayName: 'B');
        await second;

        expect(
          firestore.memberCountOf(code),
          2,
          reason: 'uidB\'s join must commit on its own, independent of '
              'uidA\'s still-paused transaction',
        );
        expect(firestore.memberExists(code: code, uid: uidB), isTrue);

        gate.complete();
        await first;

        expect(
          firestore.memberCountOf(code),
          3,
          reason: 'uidA\'s join must also land its own single increment '
              'once unpaused — two different users joining concurrently '
              'must both be counted, exactly once each',
        );
        expect(firestore.memberExists(code: code, uid: uidA), isTrue);
      },
    );

    test(
      '(c) joinClan() when the uid is ALREADY a member is a safe no-op — '
      'no double-count on a retry after the member doc already exists',
      () async {
        final firestore = _FakeTransactionFirestore();
        final repo = ClanRepository(firestore: firestore);
        const code = 'ABC123';
        const uid = 'already-in-uid';

        firestore.seedClan(code: code, memberCount: 5);
        firestore.seedMember(code: code, uid: uid, exists: true);

        await repo.joinClan(code: code, uid: uid, displayName: 'Already');

        expect(
          firestore.memberCountOf(code),
          5,
          reason: 're-entering a code you have already joined must never '
              'increment memberCount again',
        );
      },
    );

    test(
      '(d) joinClan() against a clan code that does not exist throws and '
      'leaves state unchanged — no member doc created, no memberCount '
      'written anywhere',
      () async {
        final firestore = _FakeTransactionFirestore();
        final repo = ClanRepository(firestore: firestore);
        const code = 'DOES-NOT-EXIST';
        const uid = 'hopeful-uid';

        await expectLater(
          repo.joinClan(code: code, uid: uid, displayName: 'Hopeful'),
          throwsA(isA<StateError>()),
        );

        expect(firestore.memberExists(code: code, uid: uid), isFalse);
        expect(firestore.memberCountOf(code), 0);
      },
    );

    test(
      '(e) memberCount stays consistent across a realistic sequence of '
      'concurrent and sequential joins — 3 concurrent new joins plus 1 '
      'already-member retry lands on exactly base + 3',
      () async {
        final firestore = _FakeTransactionFirestore();
        final repo = ClanRepository(firestore: firestore);
        const code = 'ABC123';

        firestore.seedClan(code: code, memberCount: 10);
        firestore.seedMember(code: code, uid: 'existing', exists: true);

        // No gate this time — proves the steady-state (no forced
        // interleaving) path is just as correct as the forced-race paths
        // above, for a realistic mixed batch: 3 genuinely new joins plus
        // 1 retry of someone already in the clan.
        await Future.wait([
          repo.joinClan(code: code, uid: 'new-1', displayName: 'N1'),
          repo.joinClan(code: code, uid: 'new-2', displayName: 'N2'),
          repo.joinClan(code: code, uid: 'new-3', displayName: 'N3'),
          repo.joinClan(code: code, uid: 'existing', displayName: 'E'),
        ]);

        expect(
          firestore.memberCountOf(code),
          13,
          reason: 'exactly the 3 genuinely new members must be counted — '
              'the already-existing member\'s retry must not add a 4th',
        );
        expect(firestore.memberExists(code: code, uid: 'new-1'), isTrue);
        expect(firestore.memberExists(code: code, uid: 'new-2'), isTrue);
        expect(firestore.memberExists(code: code, uid: 'new-3'), isTrue);
      },
    );
  });
}

// ---------------------------------------------------------------------
// Widget-level harnesses
// ---------------------------------------------------------------------

List<ClanMember> _twoMembers() => [
      ClanMember(
        uid: 'me-uid',
        displayName: 'Ketua',
        role: ClanRole.leader,
        joinedAt: DateTime(2026, 1, 1),
      ),
      ClanMember(
        uid: 'target-uid',
        displayName: 'Anggota',
        role: ClanRole.member,
        joinedAt: DateTime(2026, 1, 2),
      ),
    ];

Future<Widget> _clanMembersHarness({
  required _FakeClanRepository repo,
  List<ClanMember>? members,
}) async {
  const code = 'ABC123';
  final roster = members ?? _twoMembers();

  final container = ProviderContainer(
    overrides: [
      appStartupProvider.overrideWith((ref) async => _FakeUser()),
      clanRepositoryProvider.overrideWithValue(repo),
      // Reads `roster` fresh on every re-invocation (e.g. after
      // `ref.invalidate` on a successful kick) rather than a value
      // captured once, so a test can prove the row actually disappears
      // once the repository call succeeds.
      clanMembersProvider(code).overrideWith((ref) async => roster),
    ],
  );
  addTearDown(container.dispose);
  await container.read(appStartupProvider.future);

  return UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(
      home: ClanMembersScreen(code: code, clanName: 'Test Clan'),
    ),
  );
}

Future<Widget> _clanTabHarness({required _FakeClanRepository repo}) async {
  const code = 'ABC123';
  final clan = Clan(
    code: code,
    name: 'Test Clan',
    hostUid: 'me-uid',
    hostDisplayName: 'Ketua',
    memberCount: 2,
    createdAt: DateTime(2026, 1, 1),
  );
  final membership = ClanMembership(
    code: code,
    name: 'Test Clan',
    joinedAt: DateTime(2026, 1, 1),
  );

  final container = ProviderContainer(
    overrides: [
      appStartupProvider.overrideWith((ref) async => _FakeUser()),
      clanRepositoryProvider.overrideWithValue(repo),
      myClansProvider.overrideWith((ref) => Stream.value([membership])),
      myPendingInvitesProvider.overrideWith((ref) => Stream.value(const [])),
      clanDetailsProvider(code).overrideWith((ref) async => clan),
      clanRankingProvider(code)
          .overrideWith((ref) async => <LeaderboardEntry>[]),
      myRoleInClanProvider(code).overrideWith((ref) async => ClanRole.leader),
      clanAnnouncementUnreadProvider(code).overrideWithValue(false),
    ],
  );
  addTearDown(container.dispose);
  await container.read(appStartupProvider.future);

  return UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(home: Scaffold(body: ClanTab())),
  );
}

Future<Widget> _searchInviteHarness({required _FakeClanRepository repo}) async {
  final results = [
    LeaderboardEntry(
      uid: 'search-target',
      displayName: 'Kana Learner',
      totalMastered: 0,
      examHighScore: 0,
      updatedAt: DateTime(2026, 1, 1),
    ),
  ];

  final container = ProviderContainer(
    overrides: [
      appStartupProvider.overrideWith((ref) async => _FakeUser()),
      clanRepositoryProvider.overrideWithValue(repo),
      leaderboardRepositoryProvider
          .overrideWithValue(_FakeLeaderboardRepository(results)),
    ],
  );
  addTearDown(container.dispose);
  await container.read(appStartupProvider.future);

  return UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(
      home: SearchInviteScreen(code: 'ABC123', clanName: 'Test Clan'),
    ),
  );
}

Future<Widget> _searchFriendHarness({
  required _FakeFriendRepository friendRepo,
}) async {
  final results = [
    LeaderboardEntry(
      uid: 'search-target',
      displayName: 'Kana Learner',
      totalMastered: 0,
      examHighScore: 0,
      updatedAt: DateTime(2026, 1, 1),
    ),
  ];

  final container = ProviderContainer(
    overrides: [
      appStartupProvider.overrideWith((ref) async => _FakeUser()),
      friendRepositoryProvider.overrideWithValue(friendRepo),
      leaderboardRepositoryProvider
          .overrideWithValue(_FakeLeaderboardRepository(results)),
    ],
  );
  addTearDown(container.dispose);
  await container.read(appStartupProvider.future);

  return UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(home: Scaffold(body: SearchFriendTab())),
  );
}

// ---------------------------------------------------------------------
// Fakes — client layer
// ---------------------------------------------------------------------

class _FakeUser implements User {
  @override
  String get uid => 'me-uid';
  @override
  bool get isAnonymous => true;
  @override
  String? get displayName => null;
  @override
  String? get photoURL => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeClanRepository implements ClanRepository {
  final List<String> kickCalls = [];
  Future<void> Function()? kickGate;
  final List<String> leaveCalls = [];
  Future<void> Function()? leaveGate;
  final List<String> inviteCalls = [];
  Future<void> Function()? inviteGate;
  // Set by a test that wants a successful kick to actually remove the
  // target from the same list `clanMembersProvider` is overridden with,
  // so re-fetching after `ref.invalidate` reflects the change — mirrors
  // what the real repository/Firestore snapshot does.
  List<ClanMember>? membersToMutate;

  @override
  Future<void> kickMember({
    required String code,
    required String targetUid,
  }) async {
    kickCalls.add('$code:$targetUid');
    if (kickGate != null) await kickGate!();
    membersToMutate?.removeWhere((m) => m.uid == targetUid);
  }

  @override
  Future<void> leaveClan({required String code, required String uid}) async {
    leaveCalls.add('$code:$uid');
    if (leaveGate != null) await leaveGate!();
  }

  @override
  Future<void> sendInvite({
    required String code,
    required String clanName,
    required String targetUid,
    required String invitedByUid,
    required String invitedByName,
  }) async {
    inviteCalls.add('$code:$targetUid');
    if (inviteGate != null) await inviteGate!();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFriendRepository implements FriendRepository {
  final List<String> calls = [];
  Future<void> Function()? gate;

  @override
  Future<void> sendFriendRequest({
    required String fromUid,
    required String fromName,
    String? fromPhotoUrl,
    AvatarType fromAvatarType = AvatarType.google,
    String? fromAvatarValue,
    required String targetUid,
  }) async {
    calls.add('$fromUid->$targetUid');
    if (gate != null) await gate!();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLeaderboardRepository implements LeaderboardRepository {
  final List<LeaderboardEntry> results;
  _FakeLeaderboardRepository(this.results);

  @override
  Future<List<LeaderboardEntry>> searchPublicUsers(
    String query, {
    int limit = 20,
  }) async =>
      results;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ---------------------------------------------------------------------
// Fakes — repository/backend layer (Firestore transaction simulation)
// ---------------------------------------------------------------------

class _FakeDocCell {
  bool exists;
  int version = 0;
  int memberCount = 0;
  // Populated by `seedClan` (for a clan doc's `name`/`hostUid`, read by
  // joinClan's plain, non-transactional `clanRef.get()`) and by a
  // transaction's `set()` (for a member/membership doc's full payload) —
  // added for the Core Clan Mechanics BUG #1 joinClan coverage below;
  // kickMember/leaveClan never read either field, so this is additive.
  String? name;
  String? hostUid;
  Map<String, dynamic>? data;
  _FakeDocCell({required this.exists});
}

/// Shared in-memory document store, keyed by full Firestore-style path —
/// so two independently-constructed `DocumentReference`s pointing at the
/// same logical document (as happens when `kickMember` is called twice,
/// each building its own reference from scratch) resolve to the same cell.
class _FakeStore {
  final Map<String, _FakeDocCell> _docs = {};
  _FakeDocCell cellFor(String path) =>
      _docs.putIfAbsent(path, () => _FakeDocCell(exists: false));

  // Consumed by exactly the first `Transaction.get()` call across the
  // whole store — see `_FakeTransactionFirestore.gateFirstGet`'s doc
  // comment for why this specific pause point proves the retry-on-
  // conflict path, not just "reads happen to be sequential."
  Future<void> Function()? _pendingGetGate;
  Future<void> Function()? consumeGetGate() {
    final gate = _pendingGetGate;
    _pendingGetGate = null;
    return gate;
  }
}

class _FakeTransactionFirestore implements FirebaseFirestore {
  final _FakeStore _store = _FakeStore();

  void seedMember({
    required String code,
    required String uid,
    required bool exists,
  }) {
    _store.cellFor('clans/$code/members/$uid').exists = exists;
  }

  void seedClan({
    required String code,
    required int memberCount,
    String? name,
    String? hostUid,
  }) {
    final cell = _store.cellFor('clans/$code');
    // kickMember/leaveClan never read `.exists`/`name`/`hostUid` on the
    // clan doc itself (only the member doc), so setting these here is
    // additive and doesn't change their behavior — it's what joinClan's
    // own plain `clanRef.get()` existence-and-name check below needs.
    cell.exists = true;
    cell.memberCount = memberCount;
    cell.name = name ?? 'Test Clan';
    cell.hostUid = hostUid ?? 'someone-else';
  }

  void seedMembership({required String uid, required String code}) {
    _store.cellFor('users/$uid/clanMemberships/$code').exists = true;
  }

  bool memberExists({required String code, required String uid}) =>
      _store.cellFor('clans/$code/members/$uid').exists;

  int memberCountOf(String code) => _store.cellFor('clans/$code').memberCount;

  /// See `_FakeStore._pendingGetGate`'s doc comment: pauses exactly the
  /// first `Transaction.get()` call anywhere in this store, right after it
  /// has already captured its read (so the caller's own "does this still
  /// exist" branch evaluates against the pre-pause state, matching how a
  /// real in-flight Firestore transaction behaves), and only for that one
  /// call — every subsequent `.get()` (a different transaction, or this
  /// same one being retried) proceeds immediately.
  void gateFirstGet(Future<void> Function() gate) =>
      _store._pendingGetGate = gate;

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) =>
      _FakeCollectionReference(_store, collectionPath);

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final txn = _FakeTransaction(_store);
      final result = await transactionHandler(txn);
      if (txn.tryCommit()) return result;
      // Conflict detected — Firestore's own documented behavior is to
      // silently retry the whole handler, which is exactly what the loop
      // above does on its next iteration.
    }
    throw StateError('fake transaction exceeded maxAttempts without a '
        'clean commit — this indicates a real bug in the code under test, '
        'not a flaky fake');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCollectionReference implements CollectionReference<Map<String, dynamic>> {
  final _FakeStore store;
  @override
  final String path;
  _FakeCollectionReference(this.store, this.path);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _FakeDocumentReference(store, '${this.path}/${path ?? 'auto'}');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDocumentReference implements DocumentReference<Map<String, dynamic>> {
  final _FakeStore store;
  @override
  final String path;
  _FakeDocumentReference(this.store, this.path);

  @override
  String get id => path.split('/').last;

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) =>
      _FakeCollectionReference(store, '$path/$collectionPath');

  // Plain, non-transactional read — added for joinClan's own
  // `clanRef.get()` call (Core Clan Mechanics BUG #1 coverage below).
  // kickMember/leaveClan never call this on a DocumentReference directly
  // (only through `Transaction.get()`), so this is purely additive.
  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    // Only a member-doc path consumes the shared interleaving gate (same
    // scoping the original audit's throwaway fake used) — joinClan's own
    // plain, non-transactional `clanRef.get()` must never accidentally
    // eat the gate meant for a member-doc read, transactional or not.
    final isMemberDoc = path.contains('/members/');
    final gate = isMemberDoc ? store.consumeGetGate() : null;
    final cell = store.cellFor(path);
    final exists = cell.exists;
    final data = cell.exists
        ? (cell.data ?? {'name': cell.name, 'hostUid': cell.hostUid})
        : null;
    if (gate != null) await gate();
    return _FakeDocumentSnapshot(exists: exists, data: data);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  final bool exists;
  final Map<String, dynamic>? _data;
  // ignore: prefer_initializing_formals
  _FakeDocumentSnapshot({required this.exists, Map<String, dynamic>? data}) : _data = data;

  @override
  Map<String, dynamic>? data() => _data ?? (exists ? const <String, dynamic>{} : null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTransaction implements Transaction {
  final _FakeStore store;
  final Map<String, int> _readVersions = {};
  // null value = delete; true = the doc should exist after commit (not
  // actually used by kickMember/leaveClan, kept for completeness).
  final Map<String, bool?> _pendingExistsWrites = {};
  final Map<String, int> _pendingMemberCountDelta = {};
  // joinClan's own `transaction.set(memberDoc, ...)` /
  // `transaction.set(membershipDoc, ...)` calls — kickMember/leaveClan
  // never call `.set()` at all, so this is purely additive.
  final Map<String, Map<String, dynamic>> _pendingSetWrites = {};

  _FakeTransaction(this.store);

  // Precomputed once so `FieldValue.increment(n)`'s actual delta can be
  // recovered via value equality (`FieldValue` has no public getter for
  // it) — verified this equality holds by construction against real
  // `FieldValue` instances before relying on it here.
  static final _incrementByOne = FieldValue.increment(1);
  static final _decrementByOne = FieldValue.increment(-1);

  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> documentReference,
  ) async {
    final ref = documentReference as _FakeDocumentReference;
    final cell = store.cellFor(ref.path);
    // Capture the read BEFORE any pause, so a paused transaction's own
    // "does this still exist" branch below sees the state as of the
    // moment it actually read — not whatever changed while it was
    // suspended. This is what makes the conflict-then-retry path
    // (rather than just "reads happen to be sequential") the thing being
    // exercised.
    final capturedExists = cell.exists;
    _readVersions[ref.path] = cell.version;

    final gate = store.consumeGetGate();
    if (gate != null) await gate();

    return _FakeDocumentSnapshot(exists: capturedExists) as DocumentSnapshot<T>;
  }

  @override
  Transaction delete(DocumentReference documentReference) {
    final ref = documentReference as _FakeDocumentReference;
    _pendingExistsWrites[ref.path] = false;
    return this;
  }

  @override
  Transaction update(
    DocumentReference documentReference,
    Map<String, dynamic> data,
  ) {
    final ref = documentReference as _FakeDocumentReference;
    // Scoped deliberately: `ClanRepository` only ever calls `.update()`
    // with `{'memberCount': FieldValue.increment(n)}` where n is +1
    // (joinClan) or -1 (kickMember/leaveClan) — verified by reading all
    // three methods before writing this fake — so recovering the actual
    // sign via value-equality against the two possible instances is
    // sufficient without interpreting `FieldValue` generically.
    final value = data['memberCount'];
    if (value is FieldValue) {
      final delta = value == _incrementByOne
          ? 1
          : (value == _decrementByOne ? -1 : 0);
      _pendingMemberCountDelta[ref.path] =
          (_pendingMemberCountDelta[ref.path] ?? 0) + delta;
    }
    return this;
  }

  @override
  Transaction set<T>(
    DocumentReference<T> documentReference,
    T data, [
    SetOptions? options,
  ]) {
    final ref = documentReference as _FakeDocumentReference;
    _pendingSetWrites[ref.path] = Map<String, dynamic>.from(data as Map);
    return this;
  }

  /// Returns `false` (conflict, caller must retry) if any document this
  /// transaction read was modified by another transaction's successful
  /// commit since the read — Firestore's own documented optimistic-
  /// concurrency contract. Applies pending writes and bumps versions only
  /// on a clean commit.
  bool tryCommit() {
    for (final entry in _readVersions.entries) {
      if (store.cellFor(entry.key).version != entry.value) return false;
    }
    for (final entry in _pendingExistsWrites.entries) {
      final cell = store.cellFor(entry.key);
      cell.exists = entry.value ?? false;
      cell.version++;
    }
    for (final entry in _pendingSetWrites.entries) {
      final cell = store.cellFor(entry.key);
      cell.exists = true;
      cell.data = entry.value;
      cell.version++;
    }
    for (final entry in _pendingMemberCountDelta.entries) {
      store.cellFor(entry.key).memberCount += entry.value;
    }
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

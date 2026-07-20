import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase/firestore_paths.dart';
import '../models/clan.dart';
import '../models/clan_member.dart';
import '../models/clan_membership.dart';
import '../models/user_profile.dart' show AvatarType;

/// Manages clan/host creation, joining, leaving, and membership lookups.
/// Every write mirrors the read-then-write / batch style already
/// established by `LeaderboardRepository`/`ExamRepository`, except
/// `memberCount` which uses `FieldValue.increment` since it's a bare
/// counter (no averaging needed, unlike the Rekor feature's percentage
/// fields) — the right tool for that specific case, not an inconsistency.
class ClanRepository {
  static const _codeLength = 6;
  static const _codeAlphabet =
      'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I — avoids read-aloud/write mixups
  static const _maxCodeAttempts = 5;

  final FirebaseFirestore _firestore;
  final Random _random;

  ClanRepository({FirebaseFirestore? firestore, Random? random})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _random = random ?? Random();

  CollectionReference<Map<String, dynamic>> get _clans =>
      _firestore.collection(FirestorePaths.clans);

  CollectionReference<Map<String, dynamic>> _membersOf(String code) =>
      _clans.doc(code).collection(FirestorePaths.clanMembers);

  CollectionReference<Map<String, dynamic>> _membershipsOf(String uid) =>
      _firestore
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection(FirestorePaths.clanMemberships);

  String _generateCode() => List.generate(
        _codeLength,
        (_) => _codeAlphabet[_random.nextInt(_codeAlphabet.length)],
      ).join();

  /// Creates a new clan, auto-joining [hostUid] as its first member. The
  /// clan's Firestore document id doubles as the join code, so retrying
  /// with a fresh random code on collision (checked via a plain `.get()`,
  /// the same non-transactional accepted trade-off used throughout this
  /// app) is the only "uniqueness" step needed — no separate lookup index.
  Future<String> createClan({
    required String hostUid,
    required String name,
    required String hostDisplayName,
    String? photoUrl,
    AvatarType avatarType = AvatarType.google,
    String? avatarValue,
  }) async {
    for (var attempt = 0; attempt < _maxCodeAttempts; attempt++) {
      final code = _generateCode();
      final doc = _clans.doc(code);
      final existing = await doc.get();
      if (existing.exists) continue;

      final now = DateTime.now();
      final clan = Clan(
        code: code,
        name: name,
        hostUid: hostUid,
        hostDisplayName: hostDisplayName,
        memberCount: 1,
        createdAt: now,
      );
      final member = ClanMember(
        uid: hostUid,
        displayName: hostDisplayName,
        photoUrl: photoUrl,
        avatarType: avatarType,
        avatarValue: avatarValue,
        joinedAt: now,
      );
      final membership =
          ClanMembership(code: code, name: name, joinedAt: now);

      final batch = _firestore.batch();
      batch.set(doc, clan.toMap());
      batch.set(_membersOf(code).doc(hostUid), member.toMap());
      batch.set(_membershipsOf(hostUid).doc(code), membership.toMap());
      await batch.commit();
      return code;
    }
    throw StateError('Gagal membuat kode clan unik, coba lagi.');
  }

  Future<Clan?> findByCode(String code) async {
    final doc = await _clans.doc(code.trim().toUpperCase()).get();
    if (!doc.exists) return null;
    return Clan.fromMap(doc.id, doc.data()!);
  }

  /// No-op if [uid] is already a member — re-entering a code you've
  /// already joined shouldn't double-count `memberCount`.
  Future<void> joinClan({
    required String code,
    required String uid,
    required String displayName,
    String? photoUrl,
    AvatarType avatarType = AvatarType.google,
    String? avatarValue,
  }) async {
    final normalizedCode = code.trim().toUpperCase();
    final memberDoc = _membersOf(normalizedCode).doc(uid);
    final existingMember = await memberDoc.get();
    if (existingMember.exists) return;

    final clanDoc = await _clans.doc(normalizedCode).get();
    if (!clanDoc.exists) {
      throw StateError('Clan dengan kode tersebut tidak ditemukan.');
    }

    final now = DateTime.now();
    final clanName = clanDoc.data()?['name'] as String? ?? 'Clan';
    final member = ClanMember(
      uid: uid,
      displayName: displayName,
      photoUrl: photoUrl,
      avatarType: avatarType,
      avatarValue: avatarValue,
      joinedAt: now,
    );
    final membership =
        ClanMembership(code: normalizedCode, name: clanName, joinedAt: now);

    final batch = _firestore.batch();
    batch.set(memberDoc, member.toMap());
    batch.set(_membershipsOf(uid).doc(normalizedCode), membership.toMap());
    batch.update(_clans.doc(normalizedCode), {
      'memberCount': FieldValue.increment(1),
    });
    await batch.commit();
  }

  Future<void> leaveClan({required String code, required String uid}) async {
    final normalizedCode = code.trim().toUpperCase();
    final memberDoc = _membersOf(normalizedCode).doc(uid);
    final existingMember = await memberDoc.get();
    if (!existingMember.exists) return;

    final batch = _firestore.batch();
    batch.delete(memberDoc);
    batch.delete(_membershipsOf(uid).doc(normalizedCode));
    batch.update(_clans.doc(normalizedCode), {
      'memberCount': FieldValue.increment(-1),
    });
    await batch.commit();
  }

  /// Live — kept small (one user's own clan list) so it can update
  /// instantly on create/join/leave without a manual refresh.
  Stream<List<ClanMembership>> watchMyClans(String uid) {
    return _membershipsOf(uid)
        .orderBy('joinedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ClanMembership.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// One-shot fetch, not a live stream — a clan's roster can run into the
  /// dozens/hundreds for a whole school, and the ranking screen re-fetches
  /// on tab visit rather than holding that many realtime listeners open.
  Future<List<ClanMember>> getMembersOnce(String code) async {
    final snapshot = await _membersOf(code.trim().toUpperCase()).get();
    return snapshot.docs
        .map((doc) => ClanMember.fromMap(doc.id, doc.data()))
        .toList();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// There is deliberately no "uploaded from gallery" variant. One existed
/// (`customUpload`, stored as `custom_upload`) and was removed along with
/// the picker entry that produced it — with a public global leaderboard and
/// no moderation tooling, an arbitrary user-supplied image had no path to
/// review or takedown. [AvatarTypeX.fromKey] still has to cope with the old
/// key sitting in existing Firestore documents; see the note there.
enum AvatarType {
  google, // pakai photoURL Google
  presetFree, // avatar preset gratis
  presetPremium, // avatar preset premium (butuh premium)
}

extension AvatarTypeX on AvatarType {
  String get key {
    switch (this) {
      case AvatarType.google:
        return 'google';
      case AvatarType.presetFree:
        return 'preset_free';
      case AvatarType.presetPremium:
        return 'preset_premium';
    }
  }

  /// Note the missing `custom_upload` case: gallery uploads were removed,
  /// but documents written before that still carry the key. It falls
  /// through to [AvatarType.google] on purpose, so an image uploaded back
  /// then stops being rendered rather than surviving the removal — which
  /// is the whole point of taking the feature out. Those users land on
  /// their Google photo, or the default emoji if they have none.
  static AvatarType fromKey(String? key) {
    switch (key) {
      case 'preset_free':
        return AvatarType.presetFree;
      case 'preset_premium':
        return AvatarType.presetPremium;
      case 'google':
      default:
        return AvatarType.google;
    }
  }
}

class UserProfile {
  final String? displayName;
  final bool isAnonymous;
  final bool linkedGoogle;
  final int currentStreak;
  final String? customDisplayName;
  final AvatarType avatarType;
  final String? avatarValue;
  final String? coverId;
  final String? frameId;
  final DateTime? lastNameChangeAt;

  UserProfile({
    this.displayName,
    required this.isAnonymous,
    required this.linkedGoogle,
    required this.currentStreak,
    this.customDisplayName,
    this.avatarType = AvatarType.google,
    this.avatarValue,
    this.coverId,
    this.frameId,
    this.lastNameChangeAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        displayName: map['displayName'] as String?,
        isAnonymous: map['isAnonymous'] as bool? ?? true,
        linkedGoogle: map['linkedGoogle'] as bool? ?? false,
        currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
        customDisplayName: map['customDisplayName'] as String?,
        avatarType: AvatarTypeX.fromKey(map['avatarType'] as String?),
        avatarValue: map['avatarValue'] as String?,
        coverId: map['coverId'] as String?,
        frameId: map['frameId'] as String?,
        lastNameChangeAt: _toDateTime(map['lastNameChangeAt']),
      );

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  /// Resolution priority: custom name > Firebase Auth displayName (Google) >
  /// anonymous fallback.
  String resolveDisplayName(User? user) {
    final custom = customDisplayName?.trim();
    if (custom != null && custom.isNotEmpty) return custom;
    final authName = user?.displayName;
    if (authName != null && authName.isNotEmpty) return authName;
    return 'Pelajar Kana';
  }
}

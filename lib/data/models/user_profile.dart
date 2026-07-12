import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum AvatarType {
  google, // pakai photoURL Google
  presetFree, // avatar preset gratis
  presetPremium, // avatar preset premium (butuh premium)
  customUpload, // upload dari galeri (butuh premium)
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
      case AvatarType.customUpload:
        return 'custom_upload';
    }
  }

  static AvatarType fromKey(String? key) {
    switch (key) {
      case 'preset_free':
        return AvatarType.presetFree;
      case 'preset_premium':
        return AvatarType.presetPremium;
      case 'custom_upload':
        return AvatarType.customUpload;
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
  final DateTime? lastNameChangeAt;

  UserProfile({
    this.displayName,
    required this.isAnonymous,
    required this.linkedGoogle,
    required this.currentStreak,
    this.customDisplayName,
    this.avatarType = AvatarType.google,
    this.avatarValue,
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

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/models/user_profile.dart';
import '../constants/avatars.dart';

/// Renders a user's avatar following the resolution priority: custom
/// Storage upload > premium preset > free preset > Google photo > default
/// placeholder. Centralizing this here means ProfileScreen, leaderboard
/// rows, etc. never duplicate the priority logic.
class UserAvatar extends StatelessWidget {
  final UserProfile? profile;
  final User? user;
  final double radius;

  const UserAvatar({
    super.key,
    required this.profile,
    required this.user,
    this.radius = 40,
  });

  static const _defaultBackground = Color(0xFFFEEDEC);
  static const _defaultEmoji = '🐱';

  @override
  Widget build(BuildContext context) {
    final avatarType = profile?.avatarType;
    final avatarValue = profile?.avatarValue;

    if (avatarType == AvatarType.customUpload &&
        avatarValue != null &&
        avatarValue.isNotEmpty) {
      return CircleAvatar(radius: radius, backgroundImage: NetworkImage(avatarValue));
    }

    if (avatarType == AvatarType.presetPremium) {
      final preset = AvatarPresets.byId(avatarValue);
      if (preset != null) return _PresetCircle(preset: preset, radius: radius);
    }

    if (avatarType == AvatarType.presetFree) {
      final preset = AvatarPresets.byId(avatarValue);
      if (preset != null) return _PresetCircle(preset: preset, radius: radius);
    }

    final photoUrl = user?.photoURL;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(radius: radius, backgroundImage: NetworkImage(photoUrl));
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: _defaultBackground,
      child: Text(_defaultEmoji, style: TextStyle(fontSize: radius * 0.9)),
    );
  }
}

class _PresetCircle extends StatelessWidget {
  final AvatarPreset preset;
  final double radius;

  const _PresetCircle({required this.preset, required this.radius});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: preset.background,
      child: Text(preset.emoji, style: TextStyle(fontSize: radius * 0.8)),
    );
  }
}

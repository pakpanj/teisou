import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/models/user_profile.dart';
import '../constants/avatars.dart';
import '../constants/frames.dart';

/// Renders a user's avatar following the resolution priority: premium
/// preset > free preset > Google photo > default placeholder. (A custom
/// Storage upload used to sit above all of these; that feature is gone —
/// see [AvatarType].) Centralizing this here means ProfileScreen, leaderboard
/// rows, etc. never duplicate the priority logic. If [profile.frameId]
/// resolves to a [FramePreset], its border art is layered on top,
/// overflowing past the avatar's own edge — see [FrameOverlay].
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
  static const _frameScale = 1.25;

  @override
  Widget build(BuildContext context) {
    final avatarWidget = _buildAvatar(context);
    final frame = FramePresets.byId(profile?.frameId);
    if (frame == null) return avatarWidget;

    final frameSize = radius * 2 * _frameScale;
    return SizedBox(
      width: frameSize,
      height: frameSize,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          avatarWidget,
          FrameOverlay(preset: frame, avatarSize: radius * 2, scale: _frameScale),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final avatarType = profile?.avatarType;
    final avatarValue = profile?.avatarValue;

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
    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: AvatarPresetArt(
          preset: preset,
          imageSize: radius * 2,
          emojiFontSize: radius * 0.8,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

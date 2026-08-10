import 'package:flutter/material.dart';

/// One selectable clan icon preset — the same emoji-placeholder-until-real-
/// art shape as `AvatarPreset`, deliberately reused rather than a free-form
/// photo upload. See `Clan.iconValue`'s own doc comment for why: this app
/// already removed gallery avatar upload entirely for child-safety/COPPA
/// reasons, and a leader-chosen "clan photo" that any member then sees is
/// exactly that same risk at a group scale instead of a personal one. A
/// curated preset set carries no such risk — nothing here can ever be an
/// image someone else uploaded.
class ClanIconPreset {
  final String id;
  final String emoji;

  const ClanIconPreset({required this.id, required this.emoji});

  /// Where this preset's PNG art lives once supplied — same
  /// filename-matches-id convention as `AvatarPreset.assetPath`, so real art
  /// can be dropped in later with no code changes.
  String get assetPath => 'assets/clan_icons/$id.png';
}

/// Renders a preset's real PNG art, falling back to its emoji on any load
/// failure (no art supplied yet, decode error, etc.) — same never-crash
/// contract as [AvatarPresetArt]/`KotobaImage`/`KaiwaImage`.
class ClanIconArt extends StatelessWidget {
  final ClanIconPreset? preset;
  final double size;
  final double emojiFontSize;

  const ClanIconArt({
    super.key,
    required this.preset,
    required this.size,
    required this.emojiFontSize,
  });

  @override
  Widget build(BuildContext context) {
    if (preset == null) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Icon(Icons.groups, size: emojiFontSize, color: Colors.white),
        ),
      );
    }
    return Image.asset(
      preset!.assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Center(
        child: Text(preset!.emoji, style: TextStyle(fontSize: emojiFontSize)),
      ),
    );
  }
}

/// A small, deliberately group/team-themed set — distinct from the
/// individual-learner `AvatarPresets` (those are all "neko_..." character
/// personas; these read as a badge/crest instead), so a clan icon never
/// looks like it's impersonating one specific member.
class ClanIconPresets {
  ClanIconPresets._();

  static const all = [
    ClanIconPreset(id: 'crest_shield', emoji: '🛡️'),
    ClanIconPreset(id: 'crest_flag', emoji: '🚩'),
    ClanIconPreset(id: 'crest_star', emoji: '⭐'),
    ClanIconPreset(id: 'crest_trophy', emoji: '🏆'),
    ClanIconPreset(id: 'crest_book', emoji: '📖'),
    ClanIconPreset(id: 'crest_torii', emoji: '⛩️'),
    ClanIconPreset(id: 'crest_sakura', emoji: '🌸'),
    ClanIconPreset(id: 'crest_fox', emoji: '🦊'),
    ClanIconPreset(id: 'crest_owl', emoji: '🦉'),
    ClanIconPreset(id: 'crest_dragon', emoji: '🐉'),
    ClanIconPreset(id: 'crest_lantern', emoji: '🏮'),
    ClanIconPreset(id: 'crest_wave', emoji: '🌊'),
  ];

  static ClanIconPreset? byId(String? id) {
    if (id == null) return null;
    for (final preset in all) {
      if (preset.id == id) return preset;
    }
    return null;
  }
}

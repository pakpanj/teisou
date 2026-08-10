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
///
/// **Deliberately Japanese-cultural motifs, not generic badge shapes** — a
/// second pass over the original 12 (shield/flag/star/trophy/book/wave were
/// generic Western badge iconography with no real connection to a Japanese-
/// learning app). Several were chosen specifically because they already
/// carry a "good luck for studying/achieving a goal" meaning in Japanese
/// culture (`daruma`, `ema`, `hamaya`, `koi`), which fits a clan of learners
/// working toward something, not just decoration.
///
/// The `emoji` fallback is a best-effort nearest match, not a literal
/// depiction — Unicode has no dedicated glyph for most of these (no daruma,
/// no torii-adjacent ema/kabuto/temari/hamaya/ume emoji exist at all), so
/// several presets intentionally share an emoji with a visually related one
/// until real art lands (see `scripts/clan_icon_prompts.md`) and makes each
/// one visually distinct on its own. Two of the closer matches (`sensu`'s
/// 🪭 folding fan, `uchiwa` sharing it) are recent Unicode additions
/// (2022) that render as a blank "tofu box" on older device fonts —
/// confirmed on the Moto G52J test device — harmless and self-resolving
/// once real art replaces the emoji fallback, not worth chasing an older
/// but less accurate substitute for.
class ClanIconPresets {
  ClanIconPresets._();

  static const all = [
    ClanIconPreset(id: 'crest_torii', emoji: '⛩️'),
    ClanIconPreset(id: 'crest_sakura', emoji: '🌸'),
    ClanIconPreset(id: 'crest_fuji', emoji: '🗻'),
    ClanIconPreset(id: 'crest_koi', emoji: '🐟'),
    ClanIconPreset(id: 'crest_daruma', emoji: '🪆'),
    ClanIconPreset(id: 'crest_manekineko', emoji: '🐱'),
    ClanIconPreset(id: 'crest_orizuru', emoji: '🕊️'),
    ClanIconPreset(id: 'crest_sensu', emoji: '🪭'),
    ClanIconPreset(id: 'crest_kokeshi', emoji: '🎎'),
    ClanIconPreset(id: 'crest_lantern', emoji: '🏮'),
    ClanIconPreset(id: 'crest_koinobori', emoji: '🎏'),
    ClanIconPreset(id: 'crest_tanuki', emoji: '🦝'),
    ClanIconPreset(id: 'crest_kitsune', emoji: '🦊'),
    ClanIconPreset(id: 'crest_uchiwa', emoji: '🪭'),
    ClanIconPreset(id: 'crest_temari', emoji: '🧶'),
    ClanIconPreset(id: 'crest_kabuto', emoji: '🛡️'),
    ClanIconPreset(id: 'crest_ema', emoji: '🪧'),
    ClanIconPreset(id: 'crest_hamaya', emoji: '🏹'),
    ClanIconPreset(id: 'crest_ginkgo', emoji: '🍂'),
    ClanIconPreset(id: 'crest_ume', emoji: '🌼'),
  ];

  static ClanIconPreset? byId(String? id) {
    if (id == null) return null;
    for (final preset in all) {
      if (preset.id == id) return preset;
    }
    return null;
  }
}

/// Total XP earned across every learning action, the level derived from
/// it, and which level-up rewards are still waiting to be claimed.
///
/// Deliberately a flat curve — every level costs the same [xpPerLevel] —
/// rather than an escalating one. It's the simplest thing that still reads
/// as progress, and it's a single constant to retune later if it turns out
/// to feel too fast or too slow; nothing else in this model assumes a flat
/// curve, so switching to a cumulative/escalating one later only touches
/// [level] and [xpIntoLevel].
class XpProgress {
  static const xpPerLevel = 150;

  final int totalXp;

  /// The highest level whose reward has already been claimed via the gift
  /// button. [pendingRewards] is derived from the gap between this and
  /// [level] rather than stored as a list of "which levels" — every
  /// pending reward grants the same kind of thing (one random unlocked
  /// cosmetic), so there is nothing level-specific worth remembering once
  /// it's claimed.
  final int claimedLevel;

  const XpProgress({required this.totalXp, required this.claimedLevel});

  factory XpProgress.fromMap(Map<String, dynamic>? map) => XpProgress(
        totalXp: (map?['totalXp'] as num?)?.toInt() ?? 0,
        claimedLevel: (map?['claimedLevel'] as num?)?.toInt() ?? 0,
      );

  static const empty = XpProgress(totalXp: 0, claimedLevel: 0);

  int get level => (totalXp ~/ xpPerLevel) + 1;

  int get xpIntoLevel => totalXp % xpPerLevel;

  double get levelProgress => xpIntoLevel / xpPerLevel;

  /// [level] starts at 1 for a brand-new account with zero XP — that
  /// starting level is not itself a level-*up* and must never look like a
  /// free reward before the learner has done anything. Subtracting 1
  /// makes the count "how many times has this account leveled up past
  /// its starting level", which is what a claim actually represents.
  int get pendingRewards => (level - 1 - claimedLevel).clamp(0, 1 << 30);
}

/// Which preset gallery a claimed reward came from — the claim dialog
/// renders each kind with that gallery's own art, so it needs to know
/// more than just "you got something".
/// Which learning action just happened, for [ProgressRepository.addXp] to
/// pass to the `awardXp` Cloud Function.
///
/// **Not an amount — the amount is not this app's to decide anymore.**
/// Before the Security & Monetization Remediation Plan's Blocker #2 fix,
/// `addXp` took a raw `int` the caller supplied, and `xp.totalXp` was
/// incremented by whatever that was — a forged, arbitrarily large amount
/// worked exactly as well as a legitimate one, since nothing checked it.
/// `functions/award_xp.js`'s `XP_AMOUNTS` table is the only place an
/// amount is decided now; the client just names which action happened,
/// and the value here has to match that table's keys exactly (`.name`).
///
/// One value per amount already in use before this change (confirmed by
/// reading every `addXp` call site rather than guessing): a word/kanji/
/// pattern/particle/dialogue marked learned (2 XP), an exam of any kind
/// completed (10 XP), a Bab gate quiz passed (15 XP), and the once-a-day
/// "opened the app and did something" streak tick
/// ([ProgressRepository.recordDailyActivity], 5 XP).
enum XpAction { wordLearned, examCompleted, babGatePassed, dailyActive }

enum XpRewardKind { avatar, frame, cover }

/// One level-up reward: a specific, now-permanently-unlocked preset from
/// [XpRewardKind]. [label] is the preset's own display label/emoji, reused
/// as-is rather than inventing new reward-specific copy.
class XpReward {
  final XpRewardKind kind;
  final String id;
  final String label;

  const XpReward({required this.kind, required this.id, required this.label});
}

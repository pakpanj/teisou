import 'package:flutter_test/flutter_test.dart';
import 'package:kana_master/data/models/xp_progress.dart';

/// A brand-new account starts at Level 1 with zero XP. That starting
/// level is not a level-*up* and must never present as a free claimable
/// reward — this pinned a real off-by-one caught on a physical device,
/// where a fresh account's gift button showed a "1" badge before the
/// learner had done anything at all.
void main() {
  test('a fresh account has no pending reward', () {
    const progress = XpProgress(totalXp: 0, claimedLevel: 0);
    expect(progress.level, 1);
    expect(progress.pendingRewards, 0);
  });

  test('reaching level 2 grants exactly one pending reward', () {
    const progress = XpProgress(totalXp: XpProgress.xpPerLevel, claimedLevel: 0);
    expect(progress.level, 2);
    expect(progress.pendingRewards, 1);
  });

  test('claiming a reward (advancing claimedLevel) clears it', () {
    const progress = XpProgress(totalXp: XpProgress.xpPerLevel, claimedLevel: 1);
    expect(progress.pendingRewards, 0);
  });

  test('multiple level-ups without claiming stack up as pending rewards', () {
    const progress = XpProgress(totalXp: XpProgress.xpPerLevel * 3, claimedLevel: 0);
    expect(progress.level, 4);
    expect(progress.pendingRewards, 3);
  });

  test('xp into the current level resets every level', () {
    const progress = XpProgress(totalXp: XpProgress.xpPerLevel + 40, claimedLevel: 0);
    expect(progress.level, 2);
    expect(progress.xpIntoLevel, 40);
  });
}

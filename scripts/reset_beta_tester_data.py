#!/usr/bin/env python3
"""Resets Teisou beta-tester progress/points/profile-cosmetics before public
release, while keeping their Firebase Auth accounts (anonymous/Google) intact
so they can keep using the app with a clean slate.

DRY-RUN BY DEFAULT. Nothing is written to Firestore until you pass --confirm.

Scope
-----
KEPT untouched:
  - Firebase Auth accounts (this script never touches Auth at all)
  - users/{uid}.profile: displayName, isAnonymous, linkedGoogle, userId,
    createdAt, lastLoginAt
  - users/{uid}.subscription (premium status)
  - users/{uid}.adRewards
  - savedItems / savedWords / moduleInterest subcollections (bookmarks,
    not progress or points)
  - clan/friend data

RESET to default, or deleted:
  - users/{uid}.profile: currentStreak, lastActiveDate, customDisplayName,
    avatarType, avatarValue, coverId, frameId, lastNameChangeAt
    -> name/avatar/cover fall back to the Google photo or default emoji,
       exactly like a brand-new account.
  - users/{uid}.progress (kana per-character progress)
  - users/{uid}.xp (totalXp, claimedLevel, unlocked{Avatar,Frame,Cover}Ids)
    -> any avatar/frame/cover a tester earned via XP leveling is un-earned.
  - users/{uid}/{kotobaProgress,kanjiProgress,bunpouProgress,
    particleProgress,kaiwaProgress,babProgress} -> every doc deleted
  - users/{uid}/{examHistory,dokkaiExamHistory,choukaiExamHistory,
    kanjiComboExamHistory} -> every doc deleted
  - leaderboard/{uid} -> doc deleted outright. Self-heals to a fresh
    bare-minimum row (displayName from Auth, avatarType=google,
    totalMastered=0, examHighScore=0) the next time the app calls
    LeaderboardRepository.ensurePublished on startup - no manual recreation
    needed.

NOT in scope (not asked for, left alone): local SharedPreferences progress
already stored on each tester's own device (kanji_learned_ids,
kotoba_learned_words, bunpou_learned_ids, particle_learned_ids,
kaiwa_learned_ids). This script only touches Firestore - a tester's device
will keep showing their old local progress until they clear app data or
reinstall, even after this script runs.

Usage
-----
    pip install firebase-admin

    # Dry run across every user - prints what WOULD change, writes nothing.
    python scripts/reset_beta_tester_data.py --service-account path/to/key.json

    # Sanity-check on exactly one uid first.
    python scripts/reset_beta_tester_data.py --service-account path/to/key.json --uid abc123 --confirm

    # Apply to every user in the `users` collection. Irreversible.
    python scripts/reset_beta_tester_data.py --service-account path/to/key.json --confirm
"""
import argparse
import sys

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
except ImportError:
    sys.exit("Missing dependency. Run: pip install firebase-admin")

PROGRESS_SUBCOLLECTIONS = [
    "kotobaProgress",
    "kanjiProgress",
    "bunpouProgress",
    "particleProgress",
    "kaiwaProgress",
    "babProgress",
    "examHistory",
    "dokkaiExamHistory",
    "choukaiExamHistory",
    "kanjiComboExamHistory",
]

PROFILE_RESET_FIELDS = {
    "currentStreak": 0,
    "lastActiveDate": None,
    "customDisplayName": None,
    "avatarType": "google",
    "avatarValue": None,
    "coverId": None,
    "frameId": None,
    "lastNameChangeAt": None,
}


def reset_user(db, uid, confirm):
    user_ref = db.collection("users").document(uid)
    snapshot = user_ref.get()
    if not snapshot.exists:
        print(f"  [skip] users/{uid} does not exist")
        return

    print(f"users/{uid}:")
    print(f"  profile -> reset {list(PROFILE_RESET_FIELDS.keys())}")
    print("  progress -> cleared")
    print("  xp -> cleared")

    for sub in PROGRESS_SUBCOLLECTIONS:
        docs = list(user_ref.collection(sub).stream())
        if docs:
            print(f"  {sub} -> delete {len(docs)} doc(s)")
        if confirm:
            for doc in docs:
                doc.reference.delete()

    leaderboard_ref = db.collection("leaderboard").document(uid)
    if leaderboard_ref.get().exists:
        print("  leaderboard/{uid} -> delete (self-heals on next app launch)")
        if confirm:
            leaderboard_ref.delete()

    if confirm:
        user_ref.set(
            {"profile": PROFILE_RESET_FIELDS, "progress": {}, "xp": {}},
            merge=True,
        )
    print()


def main():
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--service-account",
        required=True,
        help="Path to the Firebase Admin SDK service account JSON",
    )
    parser.add_argument("--uid", help="Only reset this one uid (for testing)")
    parser.add_argument(
        "--confirm",
        action="store_true",
        help="Actually write changes. Without this, dry-run only.",
    )
    args = parser.parse_args()

    cred = credentials.Certificate(args.service_account)
    firebase_admin.initialize_app(cred)
    db = firestore.client()

    if not args.confirm:
        print("=== DRY RUN - no data will be changed. Pass --confirm to apply. ===\n")

    if args.uid:
        reset_user(db, args.uid, args.confirm)
        return

    uids = [doc.id for doc in db.collection("users").stream()]
    print(f"Found {len(uids)} user(s) in users/ collection.\n")
    for uid in uids:
        reset_user(db, uid, args.confirm)

    if not args.confirm:
        print("Dry run complete. Re-run with --confirm to actually apply.")
    else:
        print("Done.")


if __name__ == "__main__":
    main()

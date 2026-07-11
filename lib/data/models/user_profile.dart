class UserProfile {
  final String? displayName;
  final bool isAnonymous;
  final bool linkedGoogle;
  final int currentStreak;

  UserProfile({
    this.displayName,
    required this.isAnonymous,
    required this.linkedGoogle,
    required this.currentStreak,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        displayName: map['displayName'] as String?,
        isAnonymous: map['isAnonymous'] as bool? ?? true,
        linkedGoogle: map['linkedGoogle'] as bool? ?? false,
        currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
      );
}

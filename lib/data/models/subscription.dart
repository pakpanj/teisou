import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionTier { free, premium }

extension SubscriptionTierX on SubscriptionTier {
  String get key => this == SubscriptionTier.premium ? 'premium' : 'free';

  static SubscriptionTier fromKey(String? key) =>
      key == 'premium' ? SubscriptionTier.premium : SubscriptionTier.free;
}

class Subscription {
  final SubscriptionTier tier;
  final DateTime? purchasedAt;
  final DateTime? expiresAt;

  Subscription({
    required this.tier,
    this.purchasedAt,
    this.expiresAt,
  });

  factory Subscription.free() => Subscription(tier: SubscriptionTier.free);

  bool get isPremium => tier == SubscriptionTier.premium;
  bool get isFree => tier == SubscriptionTier.free;

  factory Subscription.fromMap(Map<String, dynamic>? map) {
    if (map == null) return Subscription.free();
    return Subscription(
      tier: SubscriptionTierX.fromKey(map['tier'] as String?),
      purchasedAt: _toDateTime(map['purchasedAt']),
      expiresAt: _toDateTime(map['expiresAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'tier': tier.key,
        'purchasedAt': purchasedAt != null
            ? Timestamp.fromDate(purchasedAt!)
            : null,
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      };

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

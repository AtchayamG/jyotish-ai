// lib/features/auth/domain/entities/user_entity.dart

enum UserTier { free, basic, premium, max, admin }

extension UserTierX on UserTier {
  String get label {
    switch (this) {
      case UserTier.free:    return 'Free';
      case UserTier.basic:   return 'Basic';
      case UserTier.premium: return 'Premium';
      case UserTier.max:     return 'Max';
      case UserTier.admin:   return 'Admin';
    }
  }

  int get maxProfiles {
    switch (this) {
      case UserTier.free:    return 0;
      case UserTier.basic:   return 0;  // Basic: full features, no extra profiles
      case UserTier.premium: return 2;
      case UserTier.max:     return 5;
      case UserTier.admin:   return 999;
    }
  }

  bool get canAddProfiles => maxProfiles > 0;

  /// Free tier gets a 3-day trial; all other tiers have unlimited access.
  bool get hasTrial => this == UserTier.free;
}

class UserEntity {
  final String id, email, fullName;
  final String? phone;
  final bool isPremium, isAdmin;
  final UserTier userTier;

  // Birth details — filled in at registration, used for all astro features
  final String? dateOfBirth;    // "YYYY-MM-DD"
  final String? timeOfBirth;    // "HH:MM"
  final String? placeOfBirth;   // "Chennai, Tamil Nadu, India"
  final double? birthLatitude;
  final double? birthLongitude;
  final double? birthTimezone;  // UTC offset hours, e.g. 5.5
  final String? moonSign;       // Vedic moon sign (rashi), cached after kundli

  /// ISO-8601 registration timestamp, e.g. "2026-05-05T10:30:00"
  /// Used to compute the 3-day free trial window.
  final String? registeredAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.isPremium,
    required this.isAdmin,
    this.userTier = UserTier.free,
    this.dateOfBirth,
    this.timeOfBirth,
    this.placeOfBirth,
    this.birthLatitude,
    this.birthLongitude,
    this.birthTimezone,
    this.moonSign,
    this.registeredAt,
  });

  bool get hasBirthDetails =>
      dateOfBirth != null && birthLatitude != null && birthLongitude != null;

  /// True when a free-tier user's 3-day trial has expired.
  /// Paid and admin tiers always return false.
  bool get isTrialExpired {
    if (userTier != UserTier.free) return false;
    if (registeredAt == null) return false;
    try {
      final regDate = DateTime.parse(registeredAt!).toLocal();
      final expiry  = regDate.add(const Duration(days: 3));
      return DateTime.now().isAfter(expiry);
    } catch (_) {
      return false;
    }
  }
}

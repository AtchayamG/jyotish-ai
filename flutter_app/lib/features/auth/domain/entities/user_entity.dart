// lib/features/auth/domain/entities/user_entity.dart
class UserEntity {
  final String id, email, fullName;
  final String? phone;
  final bool isPremium, isAdmin;

  // Birth details — filled in at registration, used for all astro features
  final String? dateOfBirth;    // "YYYY-MM-DD"
  final String? timeOfBirth;    // "HH:MM"
  final String? placeOfBirth;   // "Chennai, Tamil Nadu, India"
  final double? birthLatitude;
  final double? birthLongitude;
  final double? birthTimezone;  // UTC offset hours, e.g. 5.5
  final String? moonSign;       // Vedic moon sign (rashi), cached after kundli

  const UserEntity({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.isPremium,
    required this.isAdmin,
    this.dateOfBirth,
    this.timeOfBirth,
    this.placeOfBirth,
    this.birthLatitude,
    this.birthLongitude,
    this.birthTimezone,
    this.moonSign,
  });

  bool get hasBirthDetails =>
      dateOfBirth != null && birthLatitude != null && birthLongitude != null;
}

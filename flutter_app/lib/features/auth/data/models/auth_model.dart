// lib/features/auth/data/models/auth_model.dart
import '../../domain/entities/user_entity.dart';

class AuthModel {
  final String accessToken;
  final String refreshToken;
  final UserModel user;
  const AuthModel({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthModel.fromJson(Map<String, dynamic> j) => AuthModel(
        accessToken: j["access_token"] as String,
        refreshToken: j["refresh_token"] as String,
        user: UserModel.fromJson(j["user"] as Map<String, dynamic>),
      );
}

class UserModel {
  final String id, email, fullName;
  final String? phone;
  final bool isPremium, isAdmin;
  final UserTier userTier;
  // Birth details returned from backend
  final String? dateOfBirth;
  final String? timeOfBirth;
  final String? placeOfBirth;
  final double? birthLatitude;
  final double? birthLongitude;
  final double? birthTimezone;
  final String? moonSign;
  // Registration timestamp — used for 3-day free trial
  final String? registeredAt;

  const UserModel({
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

  factory UserModel.fromJson(Map<String, dynamic> j) {
    final tierStr = j["user_tier"] as String? ?? "free";
    final tier = UserTier.values.firstWhere(
      (t) => t.name == tierStr,
      orElse: () => UserTier.free,
    );
    return UserModel(
      id: j["id"] as String,
      email: j["email"] as String,
      fullName: j["full_name"] as String,
      phone: j["phone"] as String?,
      isPremium: j["is_premium"] as bool? ?? false,
      isAdmin: j["is_admin"] as bool? ?? false,
      userTier: tier,
      dateOfBirth: j["date_of_birth"] as String?,
      timeOfBirth: j["time_of_birth"] as String?,
      placeOfBirth: j["place_of_birth"] as String?,
      birthLatitude: (j["birth_latitude"] as num?)?.toDouble(),
      birthLongitude: (j["birth_longitude"] as num?)?.toDouble(),
      birthTimezone: (j["birth_timezone"] as num?)?.toDouble(),
      moonSign: j["moon_sign"] as String?,
      registeredAt: j["created_at"] as String?,
    );
  }
}

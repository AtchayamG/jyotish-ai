// lib/features/auth/data/models/auth_model.dart

class AuthModel {
  final String accessToken;
  final String refreshToken;
  final UserModel user;
  const AuthModel({required this.accessToken, required this.refreshToken, required this.user});

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
  const UserModel({
    required this.id, required this.email, required this.fullName,
    this.phone, required this.isPremium, required this.isAdmin,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id: j["id"] as String, email: j["email"] as String,
    fullName: j["full_name"] as String, phone: j["phone"] as String?,
    isPremium: j["is_premium"] as bool? ?? false,
    isAdmin: j["is_admin"] as bool? ?? false,
  );
}

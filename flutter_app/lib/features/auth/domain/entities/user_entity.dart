// lib/features/auth/domain/entities/user_entity.dart
class UserEntity {
  final String id, email, fullName;
  final String? phone;
  final bool isPremium, isAdmin;
  const UserEntity({
    required this.id, required this.email, required this.fullName,
    this.phone, required this.isPremium, required this.isAdmin,
  });
}

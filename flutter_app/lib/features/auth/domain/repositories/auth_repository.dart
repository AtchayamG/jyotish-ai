// lib/features/auth/domain/repositories/auth_repository.dart
import "../entities/user_entity.dart";

typedef AuthResult = ({String accessToken, String refreshToken, UserEntity user});

abstract class AuthRepository {
  Future<AuthResult> login(String email, String password);
  Future<AuthResult> register(String email, String password, String fullName);
}

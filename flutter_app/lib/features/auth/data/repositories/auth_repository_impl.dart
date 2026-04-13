// lib/features/auth/data/repositories/auth_repository_impl.dart
import "../../domain/entities/user_entity.dart";
import "../../domain/repositories/auth_repository.dart";
import "../datasources/auth_remote_datasource.dart";

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _ds;
  AuthRepositoryImpl(this._ds);

  @override
  Future<AuthResult> login(String email, String password) async {
    final m = await _ds.login(email: email, password: password);
    return (
      accessToken: m.accessToken, refreshToken: m.refreshToken,
      user: UserEntity(
        id: m.user.id, email: m.user.email, fullName: m.user.fullName,
        phone: m.user.phone, isPremium: m.user.isPremium, isAdmin: m.user.isAdmin,
      ),
    );
  }

  @override
  Future<AuthResult> register(String email, String password, String fullName) async {
    final m = await _ds.register(email: email, password: password, fullName: fullName);
    return (
      accessToken: m.accessToken, refreshToken: m.refreshToken,
      user: UserEntity(
        id: m.user.id, email: m.user.email, fullName: m.user.fullName,
        phone: m.user.phone, isPremium: m.user.isPremium, isAdmin: m.user.isAdmin,
      ),
    );
  }
}

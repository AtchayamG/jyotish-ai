// ══════════════════════════════════════════════════════════════════════════════
// FEATURE: AUTH — Complete Clean Architecture
// ══════════════════════════════════════════════════════════════════════════════

// ── Domain Entity ─────────────────────────────────────────────────────────────
// lib/features/auth/domain/entities/user_entity.dart

class UserEntity {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final bool isPremium;
  final String createdAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.isPremium,
    required this.createdAt,
  });
}

class AuthTokenEntity {
  final String accessToken;
  final String refreshToken;
  final UserEntity user;

  const AuthTokenEntity({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });
}

// ── Domain Repository Interface ───────────────────────────────────────────────
// lib/features/auth/domain/repositories/auth_repository.dart

abstract class AuthRepository {
  Future<AuthTokenEntity> login(String email, String password);
  Future<AuthTokenEntity> register(String email, String password, String fullName);
  Future<void> logout();
  Future<AuthTokenEntity?> getStoredSession();
}

// ── Use Cases ─────────────────────────────────────────────────────────────────
// lib/features/auth/domain/usecases/login_usecase.dart

class LoginUseCase {
  final AuthRepository _repo;
  LoginUseCase(this._repo);
  Future<AuthTokenEntity> call(String email, String password) =>
      _repo.login(email, password);
}

// lib/features/auth/domain/usecases/register_usecase.dart

class RegisterUseCase {
  final AuthRepository _repo;
  RegisterUseCase(this._repo);
  Future<AuthTokenEntity> call(String email, String password, String fullName) =>
      _repo.register(email, password, fullName);
}

// lib/features/auth/domain/usecases/logout_usecase.dart

class LogoutUseCase {
  final AuthRepository _repo;
  LogoutUseCase(this._repo);
  Future<void> call() => _repo.logout();
}

// ── Data Models ───────────────────────────────────────────────────────────────
// lib/features/auth/data/models/auth_model.dart

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final bool isPremium;
  final String createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.isPremium,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    email: json['email'] as String,
    fullName: json['full_name'] as String,
    phone: json['phone'] as String?,
    isPremium: json['is_premium'] as bool? ?? false,
    createdAt: json['created_at'] as String? ?? '',
  );

  UserEntity toEntity() => UserEntity(
    id: id, email: email, fullName: fullName,
    phone: phone, isPremium: isPremium, createdAt: createdAt,
  );
}

class AuthTokenModel {
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  const AuthTokenModel({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthTokenModel.fromJson(Map<String, dynamic> json) => AuthTokenModel(
    accessToken: json['access_token'] as String,
    refreshToken: json['refresh_token'] as String,
    user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
  );

  AuthTokenEntity toEntity() => AuthTokenEntity(
    accessToken: accessToken,
    refreshToken: refreshToken,
    user: user.toEntity(),
  );
}

// ── Remote Data Source ────────────────────────────────────────────────────────
// lib/features/auth/data/datasources/auth_remote_datasource.dart

import 'package:dio/dio.dart';

abstract class AuthRemoteDataSource {
  Future<AuthTokenModel> login(String email, String password);
  Future<AuthTokenModel> register(String email, String password, String fullName);
}

class AuthRemoteDataSourceImpl extends AuthRemoteDataSource {
  final Dio _dio;
  AuthRemoteDataSourceImpl(this._dio);

  @override
  Future<AuthTokenModel> login(String email, String password) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email, 'password': password,
    });
    return AuthTokenModel.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<AuthTokenModel> register(String email, String password, String fullName) async {
    final res = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'full_name': fullName,
    });
    return AuthTokenModel.fromJson(res.data as Map<String, dynamic>);
  }
}

// ── Repository Implementation ─────────────────────────────────────────────────
// lib/features/auth/data/repositories/auth_repository_impl.dart

import '../../../../core/api/secure_storage.dart';
import '../../../../core/utils/app_constants.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final SecureStorage _storage;

  AuthRepositoryImpl(this._remote, this._storage);

  @override
  Future<AuthTokenEntity> login(String email, String password) async {
    final model = await _remote.login(email, password);
    await _saveTokens(model);
    return model.toEntity();
  }

  @override
  Future<AuthTokenEntity> register(String email, String password, String fullName) async {
    final model = await _remote.register(email, password, fullName);
    await _saveTokens(model);
    return model.toEntity();
  }

  @override
  Future<void> logout() async {
    await _storage.deleteAll();
  }

  @override
  Future<AuthTokenEntity?> getStoredSession() async {
    final token = await _storage.read(AppConstants.accessTokenKey);
    if (token == null) return null;
    // In production: decode JWT to get user info or call /me endpoint
    return null;
  }

  Future<void> _saveTokens(AuthTokenModel model) async {
    await _storage.write(AppConstants.accessTokenKey, model.accessToken);
    await _storage.write(AppConstants.refreshTokenKey, model.refreshToken);
    await _storage.write(AppConstants.userIdKey, model.user.id);
  }
}

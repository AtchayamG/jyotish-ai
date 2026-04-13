// lib/core/storage/secure_storage.dart
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "../api/token_interceptor.dart";

class SecureStorage implements TokenStorage {
  static FlutterSecureStorage? _storage;

  static FlutterSecureStorage get _s {
    _storage ??= const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      webOptions: WebOptions(
        dbName: "jyotish_ai_secure",
        publicKey: "jyotish_ai_key",
      ),
    );
    return _storage!;
  }

  static const _kAccess = "access_token";
  static const _kRefresh = "refresh_token";
  static const _kUserId = "user_id";
  static const _kEmail = "user_email";
  static const _kName = "user_name";

  @override
  Future<String?> getAccessToken() async {
    try {
      return await _s.read(key: _kAccess);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> getRefreshToken() async {
    try {
      return await _s.read(key: _kRefresh);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveTokens(
      {required String access, required String refresh}) async {
    try {
      await _s.write(key: _kAccess, value: access);
      await _s.write(key: _kRefresh, value: refresh);
    } catch (_) {}
  }

  @override
  Future<void> clearTokens() async {
    try {
      await _s.deleteAll();
    } catch (_) {}
  }

  Future<void> saveUser({
    required String id,
    required String email,
    required String name,
  }) async {
    try {
      await _s.write(key: _kUserId, value: id);
      await _s.write(key: _kEmail, value: email);
      await _s.write(key: _kName, value: name);
    } catch (_) {}
  }

  Future<String?> getUserId() async {
    try {
      return await _s.read(key: _kUserId);
    } catch (_) {
      return null;
    }
  }

  Future<String?> getUserEmail() async {
    try {
      return await _s.read(key: _kEmail);
    } catch (_) {
      return null;
    }
  }

  Future<String?> getUserName() async {
    try {
      return await _s.read(key: _kName);
    } catch (_) {
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    return (await getAccessToken()) != null;
  }
}

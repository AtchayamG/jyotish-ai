// lib/core/api/secure_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static SecureStorage? _instance;
  late final FlutterSecureStorage _storage;

  SecureStorage._() {
    _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    );
  }

  static SecureStorage get instance {
    _instance ??= SecureStorage._();
    return _instance!;
  }

  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
  Future<String?> read(String key) => _storage.read(key: key);
  Future<void> delete(String key) => _storage.delete(key: key);
  Future<void> deleteAll() => _storage.deleteAll();
}

// ─────────────────────────────────────────────────────────────────────────────
// lib/core/api/base_remote_datasource.dart
// All remote datasources extend this for shared error handling.

import 'package:dio/dio.dart';
import 'error_interceptor.dart';

abstract class BaseRemoteDataSource {
  /// Wraps a Dio call and maps DioException → AppFailure.
  Future<T> handleRequest<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw AppFailure.fromDioException(e);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}

// lib/core/api/token_interceptor.dart
// Automatically attaches Bearer token and handles 401 → refresh flow.

import 'package:dio/dio.dart';

abstract class TokenStorage {
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> saveTokens({required String access, required String refresh});
  Future<void> clearTokens();
}

class TokenInterceptor extends Interceptor {
  final TokenStorage tokenStorage;
  final Dio dio;

  TokenInterceptor({required this.tokenStorage, required this.dio});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await tokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      try {
        final refreshToken = await tokenStorage.getRefreshToken();
        if (refreshToken == null) {
          await tokenStorage.clearTokens();
          return handler.next(err);
        }
        // Attempt token refresh
        final resp = await dio.post('/api/v1/auth/refresh',
            data: {'refresh_token': refreshToken});
        final newAccess  = resp.data['access_token'] as String;
        final newRefresh = resp.data['refresh_token'] as String;
        await tokenStorage.saveTokens(access: newAccess, refresh: newRefresh);
        // Retry original request
        err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
        final retried = await dio.fetch(err.requestOptions);
        return handler.resolve(retried);
      } catch (_) {
        await tokenStorage.clearTokens();
      }
    }
    handler.next(err);
  }
}

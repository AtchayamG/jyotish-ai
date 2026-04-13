// lib/core/api/auth_interceptor.dart
// Automatically attaches Bearer token to every request.
// On 401 → attempts token refresh → retries original request.

import 'package:dio/dio.dart';

import '../utils/app_constants.dart';
import 'secure_storage.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await SecureStorage.instance.read(AppConstants.accessTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        // Retry original request with new token
        final token = await SecureStorage.instance.read(AppConstants.accessTokenKey);
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $token';
        try {
          final dio = Dio(BaseOptions(baseUrl: opts.baseUrl));
          final response = await dio.fetch(opts);
          return handler.resolve(response);
        } catch (_) {}
      }
    }
    handler.next(err);
  }

  Future<bool> _tryRefresh() async {
    try {
      final refreshToken = await SecureStorage.instance.read(AppConstants.refreshTokenKey);
      if (refreshToken == null) return false;

      final dio = Dio();
      final response = await dio.post(
        '${AppConstants.baseUrlDev}/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final data = response.data as Map<String, dynamic>;
      await SecureStorage.instance.write(AppConstants.accessTokenKey, data['access_token']);
      await SecureStorage.instance.write(AppConstants.refreshTokenKey, data['refresh_token']);
      return true;
    } catch (_) {
      await SecureStorage.instance.delete(AppConstants.accessTokenKey);
      await SecureStorage.instance.delete(AppConstants.refreshTokenKey);
      return false;
    }
  }
}

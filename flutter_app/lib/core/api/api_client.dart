// lib/core/api/api_client.dart
import "package:dio/dio.dart";
import "package:logger/logger.dart";
import "../errors/app_error.dart";
import "token_interceptor.dart";

class ApiClient {
  late final Dio _dio;
  final Logger _log = Logger();

  ApiClient({required String baseUrl, required TokenStorage tokenStorage}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {"Content-Type": "application/json", "Accept": "application/json"},
    ));
    _dio.interceptors.addAll([
      TokenInterceptor(tokenStorage: tokenStorage, dio: _dio),
      LogInterceptor(requestBody: true, responseBody: true,
        logPrint: (obj) => _log.d(obj.toString())),
    ]);
  }

  // fromJson accepts Map<String,dynamic> — matches all model fromJson signatures
  Future<T> get<T>(String path, {
    Map<String, dynamic>? queryParams,
    T Function(Map<String, dynamic>)? fromJson,
  }) => _request("GET", path, queryParams: queryParams, fromJson: fromJson);

  Future<T> post<T>(String path, {
    dynamic body,
    T Function(Map<String, dynamic>)? fromJson,
  }) => _request("POST", path, body: body, fromJson: fromJson);

  Future<T> put<T>(String path, {
    dynamic body,
    T Function(Map<String, dynamic>)? fromJson,
  }) => _request("PUT", path, body: body, fromJson: fromJson);

  Future<T> delete<T>(String path, {
    T Function(Map<String, dynamic>)? fromJson,
  }) => _request("DELETE", path, fromJson: fromJson);

  Future<T> _request<T>(String method, String path, {
    Map<String, dynamic>? queryParams,
    dynamic body,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final resp = await _dio.request<Map<String, dynamic>>(
        path, data: body, queryParameters: queryParams,
        options: Options(method: method),
      );
      final data = resp.data;
      if (fromJson != null && data != null) return fromJson(data);
      return data as T;
    } on DioException catch (e) {
      throw _mapError(e);
    } catch (e) {
      throw AppError.unknown(e.toString());
    }
  }

  AppError _mapError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const AppError.network("Request timed out");
      case DioExceptionType.connectionError:
        return const AppError.network("No internet connection");
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode ?? 0;
        final data = e.response?.data;
        final msg  = (data is Map ? data["detail"] : data?.toString()) ?? "Server error";
        if (code == 401) return AppError.unauthorized(msg.toString());
        if (code == 404) return AppError.notFound(msg.toString());
        if (code == 409) return AppError.conflict(msg.toString());
        if (code == 422) return AppError.validation(msg.toString());
        return AppError.server(msg.toString(), code);
      case DioExceptionType.cancel:
        return const AppError.cancelled("Request cancelled");
      default:
        return AppError.unknown(e.message ?? "Unknown error");
    }
  }
}

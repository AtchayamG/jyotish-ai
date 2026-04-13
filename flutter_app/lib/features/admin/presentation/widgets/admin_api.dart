// lib/features/admin/presentation/widgets/admin_api.dart
import "package:dio/dio.dart";
import "../../../../core/api/api_constants.dart";
import "../../../../core/di/service_locator.dart";
import "../../../../core/storage/secure_storage.dart";

class AdminApi {
  static Dio get _dio => Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  ));

  static Future<Map<String, String>> _headers() async {
    final token = await sl<SecureStorage>().getAccessToken();
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  static Future<dynamic> getStats() async {
    final r = await _dio.get("/api/v1/admin/stats", options: Options(headers: await _headers()));
    return r.data;
  }

  static Future<List> getUsers() async {
    final r = await _dio.get("/api/v1/admin/users", options: Options(headers: await _headers()));
    return r.data as List;
  }

  static Future<void> createUser(Map<String, dynamic> body) async {
    await _dio.post("/api/v1/admin/users", data: body, options: Options(headers: await _headers()));
  }

  static Future<void> updateUser(String id, Map<String, dynamic> body) async {
    await _dio.put("/api/v1/admin/users/$id", data: body, options: Options(headers: await _headers()));
  }

  static Future<void> deleteUser(String id) async {
    await _dio.delete("/api/v1/admin/users/$id", options: Options(headers: await _headers()));
  }

  static Future<Map> sendNotification(Map<String, dynamic> body) async {
    final r = await _dio.post("/api/v1/admin/notifications/send",
        data: body, options: Options(headers: await _headers()));
    return r.data as Map;
  }
}

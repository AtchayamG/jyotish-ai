// lib/core/api/error_interceptor.dart
// Converts Dio errors into typed AppFailure objects.

import 'package:dio/dio.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(_mapError(err));
  }

  DioException _mapError(DioException err) {
    return err.copyWith(
      error: AppFailure.fromDioException(err),
    );
  }
}

// ── Failure Types ─────────────────────────────────────────────────────────────

abstract class AppFailure {
  final String message;
  const AppFailure(this.message);

  factory AppFailure.fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkFailure('Connection timed out. Please check your internet.');

      case DioExceptionType.connectionError:
        return const NetworkFailure('No internet connection. Please try again.');

      case DioExceptionType.badResponse:
        return _fromResponse(e.response);

      case DioExceptionType.cancel:
        return const CancelledFailure();

      default:
        return ServerFailure(e.message ?? 'Unexpected error occurred');
    }
  }

  static AppFailure _fromResponse(Response? response) {
    if (response == null) return const ServerFailure('No response from server');
    final detail = _extractDetail(response.data);
    switch (response.statusCode) {
      case 400: return ValidationFailure(detail);
      case 401: return const UnauthorisedFailure();
      case 403: return const ForbiddenFailure();
      case 404: return NotFoundFailure(detail);
      case 409: return ConflictFailure(detail);
      case 422: return ValidationFailure(detail);
      case 429: return const RateLimitFailure();
      case 500: return const ServerFailure('Server error. Please try again later.');
      default:  return ServerFailure(detail);
    }
  }

  static String _extractDetail(dynamic data) {
    if (data is Map) return data['detail']?.toString() ?? 'Something went wrong';
    return data?.toString() ?? 'Something went wrong';
  }

  @override
  String toString() => message;
}

class NetworkFailure extends AppFailure {
  const NetworkFailure([super.message = 'Network error']);
}

class ServerFailure extends AppFailure {
  const ServerFailure([super.message = 'Server error']);
}

class UnauthorisedFailure extends AppFailure {
  const UnauthorisedFailure() : super('Session expired. Please log in again.');
}

class ForbiddenFailure extends AppFailure {
  const ForbiddenFailure() : super('You do not have permission for this action.');
}

class NotFoundFailure extends AppFailure {
  const NotFoundFailure([super.message = 'Resource not found']);
}

class ValidationFailure extends AppFailure {
  const ValidationFailure([super.message = 'Validation error']);
}

class ConflictFailure extends AppFailure {
  const ConflictFailure([super.message = 'Conflict error']);
}

class RateLimitFailure extends AppFailure {
  const RateLimitFailure() : super('Too many requests. Please slow down.');
}

class CancelledFailure extends AppFailure {
  const CancelledFailure() : super('Request cancelled');
}
